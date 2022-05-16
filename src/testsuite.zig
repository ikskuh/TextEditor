const std = @import("std");
const TextEditor = @import("TextEditor.zig");

test "empty init" {
    var editor = try TextEditor.init(std.testing.allocator, "");
    defer editor.deinit();

    try std.testing.expectEqualStrings("", editor.getText());
    try std.testing.expect(editor.cursor == 0);
}

test "preloaded init" {
    var editor = try TextEditor.init(std.testing.allocator, "[😊] Häuschen");
    defer editor.deinit();

    try std.testing.expectEqualStrings("[😊] Häuschen", editor.getText());
    try std.testing.expectEqual(@as(usize, 12), editor.cursor);
}

test "basic insert" {
    var editor = try TextEditor.init(std.testing.allocator, "");
    defer editor.deinit();

    try editor.insertText("[😊");
    try editor.insertText("] Hä");
    try editor.insertText("uschen");

    try std.testing.expectEqualStrings("[😊] Häuschen", editor.getText());
    try std.testing.expectEqual(@as(usize, 12), editor.cursor);
}

test "setText" {
    var editor = try TextEditor.init(std.testing.allocator, "");
    defer editor.deinit();

    try std.testing.expectEqualStrings("", editor.getText());
    try std.testing.expect(editor.cursor == 0);

    try editor.setText("[😊] Häuschen");

    try std.testing.expectEqualStrings("[😊] Häuschen", editor.getText());
    try std.testing.expect(editor.cursor == 12);
}
