const std = @import("std");
const Zigstr = @import("zigstr");

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

data: Zigstr,
cursor: usize,

pub fn init(allocator: std.mem.Allocator, initial_text: []const u8) !TextEditor {
    _ = allocator;
    std.debug.assert(std.unicode.utf8ValidateSlice(initial_text));
    @panic("not implemented yet");
}

pub fn deinit(editor: *TextEditor) void {
    editor.* = undefined;
    @panic("not implemented yet");
}

/// Replaces the contents of the editor with `text` and moves the cursor to the right.
pub fn setText(editor: *TextEditor, text: []const u8) !void {
    std.debug.assert(std.unicode.utf8ValidateSlice(text));
    _ = editor;
    _ = text;
    @panic("not implemented yet");
}

/// Returns the current text content.
pub fn constSlice(editor: TextEditor) []const u8 {
    return editor.data.bytes.items;
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
pub fn insertText(editor: *TextEditor, text: []const u8) !void {
    std.debug.assert(std.unicode.utf8ValidateSlice(text));
    _ = editor;
    _ = text;
    @panic("not implemented yet");
}
