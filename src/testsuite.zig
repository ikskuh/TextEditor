const std = @import("std");
const TextEditor = @import("TextEditor.zig");

test "empty init" {
    var editor = try TextEditor.init(std.testing.allocator, "");
    defer editor.deinit();

    try std.testing.expectEqualStrings("", editor.constSlice());
    try std.testing.expect(editor.cursor == 0);
}

test "preloaded init" {
    var editor = try TextEditor.init(std.testing.allocator, "[😊] Häuschen");
    defer editor.deinit();

    try std.testing.expectEqualStrings("[😊] Häuschen", editor.constSlice());
    try std.testing.expectEqual(@as(usize, 12), editor.cursor);
}
