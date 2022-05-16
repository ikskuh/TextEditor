const std = @import("std");

const ziglyph = @import("ziglyph");
const CodePointIterator = ziglyph.CodePointIterator;
const Grapheme = ziglyph.Grapheme;
const GraphemeIterator = Grapheme.GraphemeIterator;

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
    var editor = TextEditor{ .bytes = str, .cursor = 0 };
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

/// Moves the cursor one `unit` into `direction`.
pub fn moveCursor(editor: *TextEditor, direction: EditDirection, unit: EditUnit) void {
    //
    _ = editor;
    _ = direction;
    _ = unit;
    @panic("not implemented yet");
}

/// Deletes the `unit` based on the cursor into `direction`.
pub fn delete(editor: *TextEditor, direction: EditDirection, unit: EditUnit) void {
    //
    _ = editor;
    _ = direction;
    _ = unit;
    @panic("not implemented yet");
}

/// Inserts utf-8 encoded `text` at the cursor.
pub fn insertText(editor: *TextEditor, text: []const u8) InsertError!void {
    if (!std.unicode.utf8ValidateSlice(text))
        return error.InvalidUtf8;

    const offset = editor.graphemeToByteOffset(editor.cursor);
    try editor.bytes.insertSlice(offset, text);
    editor.cursor += countGraphemes(text);
}

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

/// Returns the number of graphemes in the input buffer.
pub fn graphemeCount(editor: TextEditor) usize {
    return countGraphemes(editor.bytes.items);
}

fn graphemeIterator(editor: TextEditor) GraphemeIterator {
    return makeGraphemeIteratorUnsafe(editor.bytes.items);
}

/// Creates a new grapheme iterator assuming `string` is valid utf8
fn makeGraphemeIteratorUnsafe(string: []const u8) GraphemeIterator {
    return GraphemeIterator.init(string) catch |e| switch (e) {
        // out editor guarantees that we always have valid utf8
        error.InvalidUtf8 => unreachable,
    };
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
