const std = @import("std");

const ziglyph = @import("ziglyph");
const CodePointIterator = ziglyph.CodePointIterator;
const Grapheme = ziglyph.Grapheme;
const GraphemeIterator = Grapheme.GraphemeIterator;
const Word = @import("ziglyph").Word;
const WordIterator = Word.WordIterator;

// const Zigstr = @import("zigstr");

const TextEditor = @This();

pub const EditDirection = enum { left, right };

pub const EditUnit = enum {
    /// A grapheme cluster, so one mental component which words are build of.
    /// The smallest unit of editing.
    letter,

    /// A word is a sequence of letters separated by space characters.
    word,

    /// A line is a sequence of letters separated by `LF`.
    line,
};

pub const InsertError = std.mem.Allocator.Error || error{InvalidUtf8};

bytes: std.ArrayList(u8),
cursor: usize,

pub fn init(allocator: std.mem.Allocator, initial_text: []const u8) InsertError!TextEditor {
    if (!std.unicode.utf8ValidateSlice(initial_text))
        return error.InvalidUtf8;
    var str = try std.ArrayList(u8).initCapacity(allocator, initial_text.len);
    str.appendSliceAssumeCapacity(initial_text);
    var editor = TextEditor{
        .bytes = str,
        .cursor = 0,
    };
    editor.cursor = editor.graphemeCount();
    return editor;
}

pub fn deinit(editor: *TextEditor) void {
    editor.bytes.deinit();
    editor.* = undefined;
}

/// Replaces the contents of the editor with `text` and moves the cursor to the right.
pub fn setText(editor: *TextEditor, text: []const u8) InsertError!void {
    if (!std.unicode.utf8ValidateSlice(text))
        return error.InvalidUtf8;
    try editor.bytes.replaceRange(0, editor.bytes.items.len, text);
    editor.cursor = editor.graphemeCount();
}

/// Returns the current text content.
pub fn getText(editor: TextEditor) []const u8 {
    return editor.bytes.items;
}

/// Returns a portion of the text content.
pub fn getSubString(editor: TextEditor, start: usize, length: ?usize) []const u8 {
    const offset = editor.graphemeToByteOffset(start);
    const substring = editor.bytes.items[offset..];

    if (length) |len| {
        var i: usize = 0;
        var iter = makeGraphemeIteratorUnsafe(substring);
        while (i < len) : (i += 1) {
            _ = iter.next();
        }
        if (iter.next()) |end_offset| {
            return substring[0..end_offset.offset];
        } else {
            return substring;
        }
    } else {
        return substring;
    }
}

pub const SetCursorError = error{OutOfBounds};

/// Moves the cursor to the grapheme `offset`. Allowed range is from `0` up to `graphemeCount()`.
pub fn setCursor(editor: *TextEditor, offset: usize) SetCursorError!void {
    const limit = editor.graphemeCount();
    if (offset > limit)
        return error.OutOfBounds;
    editor.cursor = offset;
}

/// Moves the cursor one `unit` into `direction`.
pub fn moveCursor(editor: *TextEditor, direction: EditDirection, unit: EditUnit) void {
    const byte_cursor = editor.graphemeToByteOffset(editor.cursor);
    switch (direction) {
        .left => {
            if (editor.cursor == 0) // trivial case
                return;

            switch (unit) {
                .line => editor.cursor = 0,
                .word => {
                    var iter = WordIterator.init(editor.bytes.items) catch |e| unreachableUtf8(e);

                    var last_word: ?Word = null;
                    while (iter.next()) |word| {
                        if (word.offset >= byte_cursor) {
                            break;
                        }
                        last_word = word;
                    }

                    if (last_word) |word| {
                        editor.cursor = countGraphemes(editor.bytes.items[0..word.offset]);
                    } else {
                        // no last word means we're in the first word.
                        // cursor full-throttle to the left
                        editor.cursor = 0;
                    }
                },
                .letter => {
                    editor.cursor -= 1;
                },
            }
        },
        .right => {
            const upper_limit = editor.graphemeCount();
            if (editor.cursor == upper_limit) // trivial case
                return;

            switch (unit) {
                // cursor to the end of the editing window
                .line => editor.cursor = upper_limit,

                // moving a word means we have to find a word boundary
                .word => {
                    const rest_string = editor.bytes.items[byte_cursor..];
                    var iter = WordIterator.init(rest_string) catch |e| unreachableUtf8(e);

                    // assume we're in a word right now, so let's skip that
                    _ = iter.next();

                    if (iter.next()) |word| {
                        // advance grapheme count in the word
                        editor.cursor += countGraphemes(rest_string[0..word.offset]);
                    } else {
                        // last word:
                        // move the cursor to the right
                        editor.cursor = upper_limit;
                    }
                },

                // moving the cursor one letter right is easy:
                // just skip one grapheme
                .letter => editor.cursor += 1,
            }
        },
    }
}

/// Deletes the `unit` based on the cursor into `direction`.
pub fn delete(editor: *TextEditor, direction: EditDirection, unit: EditUnit) void {
    const cursor_start = editor.cursor;
    editor.moveCursor(direction, unit);
    const cursor_end = editor.cursor;

    if (cursor_start == cursor_end)
        return;

    const byte_range_start = editor.graphemeToByteOffset(std.math.min(cursor_start, cursor_end));
    const byte_range_end = editor.graphemeToByteOffset(std.math.max(cursor_start, cursor_end));

    // cannot fail as we're always reducing the range by at least one byte, never increase!
    editor.bytes.replaceRange(byte_range_start, byte_range_end - byte_range_start, "") catch unreachable;

    switch (direction) {
        .left => {}, // no cursor movement needed, as it is done already in moveCursor
        .right => editor.cursor = cursor_start, // move cursor back to start as the movement is only used for range detection
    }
}

/// Inserts utf-8 encoded `text` at the cursor.
pub fn insertText(editor: *TextEditor, text: []const u8) InsertError!void {
    if (!std.unicode.utf8ValidateSlice(text))
        return error.InvalidUtf8;

    const offset = editor.graphemeToByteOffset(editor.cursor);
    try editor.bytes.insertSlice(offset, text);
    editor.cursor += countGraphemes(text);
}

/// Returns the number of graphemes in the input buffer.
pub fn graphemeCount(editor: TextEditor) usize {
    return countGraphemes(editor.bytes.items);
}

fn graphemeIterator(editor: TextEditor) GraphemeIterator {
    return makeGraphemeIteratorUnsafe(editor.bytes.items);
}

/// Converts a grapheme offset into a byte offset. This is required to get indices
/// into `.bytes` from editing operations.
fn graphemeToByteOffset(editor: TextEditor, offset: usize) usize {
    var iter = editor.graphemeIterator();

    var i: usize = 0;
    while (iter.next()) |gc| : (i += 1) {
        if (i == offset) {
            return gc.offset;
        }
    }

    std.debug.assert(i == offset);
    return editor.bytes.items.len;
}

/// Creates a new grapheme iterator assuming `string` is valid utf8
fn makeGraphemeIteratorUnsafe(string: []const u8) GraphemeIterator {
    return GraphemeIterator.init(string) catch |e| unreachableUtf8(e);
}

// out editor guarantees that we always have valid utf8
fn unreachableUtf8(err: error{InvalidUtf8}) noreturn {
    switch (err) {
        else => unreachable,
    }
}

/// Counts the graphemes in `string` asuming valid utf8.
fn countGraphemes(string: []const u8) usize {
    var i: usize = 0;
    var iter = makeGraphemeIteratorUnsafe(string);
    while (iter.next() != null) {
        i += 1;
    }
    return i;
}
