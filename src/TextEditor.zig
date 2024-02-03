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

/// A buffer the text editor will operate on.
/// Can be allocating or non-allocating. This is especially useful in
/// embedded/freestanding contexts or low memory situations.
pub const Buffer = union(enum) {
    pub const Error = error{OutOfMemory};

    dynamic: std.ArrayList(u8),
    static: Static,

    pub fn initStatic(buffer: []u8) Buffer {
        return Buffer{ .static = Static{ .ptr = buffer, .len = 0 } };
    }

    pub fn initAllocator(allocator: std.mem.Allocator) Buffer {
        return Buffer{ .dynamic = std.ArrayList(u8).init(allocator) };
    }

    pub fn deinit(tb: *Buffer) void {
        switch (tb.*) {
            .dynamic => |*list| list.deinit(),
            .static => {},
        }
        tb.* = undefined;
    }

    pub fn set(tb: *Buffer, string: []const u8) Error!void {
        switch (tb.*) {
            .dynamic => |*list| {
                try list.ensureTotalCapacity(string.len);
                list.appendSliceAssumeCapacity(string);
            },
            .static => |*static| {
                if (string.len > static.ptr.len)
                    return error.OutOfMemory;
                @memcpy(static.ptr, string);
                static.len = string.len;
            },
        }
    }

    pub fn replaceRange(tb: *Buffer, start: usize, length: usize, string: []const u8) Error!void {
        switch (tb.*) {
            .dynamic => |*list| try list.replaceRange(start, length, string),
            .static => |*static| {
                const items = static.ptr[0..static.len];
                const after_range = start + length;
                const range = items[start..after_range];

                if (range.len == string.len)
                    @memcpy(range, string)
                else if (range.len < string.len) {
                    const first = string[0..range.len];
                    const rest = string[range.len..];

                    @memcpy(range, first);

                    if (static.len + rest.len > static.ptr.len)
                        return error.OutOfMemory;

                    static.len += rest.len;
                    const self_items = static.ptr[0..static.len];

                    std.mem.copyBackwards(u8, self_items[after_range + rest.len .. self_items.len], self_items[after_range .. self_items.len - rest.len]);
                    @memcpy(self_items[after_range .. after_range + rest.len], rest);
                } else {
                    @memcpy(range, string);
                    const after_subrange = start + string.len;

                    for (items[after_range..], 0..) |item, i| {
                        items[after_subrange..][i] = item;
                    }

                    static.len -= length - string.len;
                }
            },
        }
    }

    pub fn slice(tb: Buffer) []u8 {
        return switch (tb) {
            .dynamic => |list| list.items,
            .static => |static| static.ptr[0..static.len],
        };
    }

    pub fn size(tb: Buffer) usize {
        return switch (tb) {
            .dynamic => |list| list.items.len,
            .static => |static| static.len,
        };
    }

    pub const Static = struct {
        ptr: []u8,
        len: usize,
    };
};

bytes: Buffer,
cursor: usize,

pub fn init(tb: Buffer, initial_text: []const u8) InsertError!TextEditor {
    if (!std.unicode.utf8ValidateSlice(initial_text))
        return error.InvalidUtf8;
    var str = tb; // clone for mut
    try str.set(initial_text);
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
    if (std.mem.eql(u8, editor.bytes.slice(), text))
        return;
    try editor.bytes.replaceRange(0, editor.bytes.size(), text);
    editor.cursor = editor.graphemeCount();
}

/// Returns the current text content.
pub fn getText(editor: TextEditor) []const u8 {
    return editor.bytes.slice();
}

/// Returns a portion of the text content.
pub fn getSubString(editor: TextEditor, start: usize, length: ?usize) []const u8 {
    const offset = editor.graphemeToByteOffset(start);
    const substring = editor.bytes.slice()[offset..];

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
                    var iter = WordIterator.init(editor.bytes.slice()) catch |e| unreachableUtf8(e);

                    var last_word: ?Word = null;
                    while (iter.next()) |word| {
                        if (word.offset >= byte_cursor) {
                            break;
                        }
                        last_word = word;
                    }

                    if (last_word) |word| {
                        editor.cursor = countGraphemes(editor.bytes.slice()[0..word.offset]);
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
                    const rest_string = editor.bytes.slice()[byte_cursor..];
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

    const byte_range_start = editor.graphemeToByteOffset(@min(cursor_start, cursor_end));
    const byte_range_end = editor.graphemeToByteOffset(@max(cursor_start, cursor_end));

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
    try editor.bytes.replaceRange(offset, 0, text);
    editor.cursor += countGraphemes(text);
}

/// Returns the number of graphemes in the input buffer.
pub fn graphemeCount(editor: TextEditor) usize {
    return countGraphemes(editor.bytes.slice());
}

fn ValidateFont(comptime T: type) type {
    return struct {
        const Self = @This();
        inner: T,

        pub fn measureStringWidth(self: Self, string: []const u8) u15 {
            return self.inner.measureStringWidth(string);
        }
    };
}

fn validateFont(font: anytype) ValidateFont(@TypeOf(font)) {
    return .{ .inner = font };
}

/// Sets the cursor position based on a visual position on the screen.
pub fn setGraphicalCursor(editor: *TextEditor, font: anytype, x: i16, y: i16) void {
    const safe_font = validateFont(font);
    _ = y; // we don't do multiline editing yet

    var iter = editor.graphemeIterator();

    if (x < 0) {
        editor.cursor = 0;
        return;
    }
    // const abs_x = std.math.absCast(x);

    // TODO: Optimize by using binary search on the string instead of linear search.

    const string = editor.bytes.slice();
    var left_edge: u15 = 0;
    var index: usize = 0;
    while (iter.next()) |wc| : (index += 1) {
        const right_edge = safe_font.measureStringWidth(string[0 .. wc.offset + wc.bytes.len]);
        defer left_edge = right_edge;

        if (x >= left_edge and x < right_edge) {
            const center = (left_edge + right_edge) / 2;
            if (x <= center) { // slightly prefer left placement over right placement
                editor.cursor = index;
            } else {
                editor.cursor = index + 1;
            }
            break;
        }
    }
    editor.cursor = index;
}

fn graphemeIterator(editor: TextEditor) GraphemeIterator {
    return makeGraphemeIteratorUnsafe(editor.bytes.slice());
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
    return editor.bytes.size();
}

/// Creates a new grapheme iterator assuming `string` is valid utf8
fn makeGraphemeIteratorUnsafe(string: []const u8) GraphemeIterator {
    return GraphemeIterator.init(string);
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
