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

test "setCursor" {
    var editor = try TextEditor.init(std.testing.allocator, "[😊] Häuschen");
    defer editor.deinit();

    try editor.setCursor(0);
    try std.testing.expectEqual(@as(usize, 0), editor.cursor);

    try editor.setCursor(4);
    try std.testing.expectEqual(@as(usize, 4), editor.cursor);

    try editor.setCursor(12);
    try std.testing.expectEqual(@as(usize, 12), editor.cursor);

    try std.testing.expectError(error.OutOfBounds, editor.setCursor(13));
    try std.testing.expectEqual(@as(usize, 12), editor.cursor);
}

test "moveCursor (line)" {
    var editor = try TextEditor.init(std.testing.allocator, "[😊] Häuschen");
    defer editor.deinit();

    try editor.setCursor(4);
    editor.moveCursor(.left, .line);
    try std.testing.expectEqual(@as(usize, 0), editor.cursor);
    editor.moveCursor(.left, .line);
    try std.testing.expectEqual(@as(usize, 0), editor.cursor);

    editor.moveCursor(.right, .line);
    try std.testing.expectEqual(@as(usize, 12), editor.cursor);

    try editor.setCursor(4);
    editor.moveCursor(.right, .line);
    try std.testing.expectEqual(@as(usize, 12), editor.cursor);
}

test "moveCursor (letter)" {
    var editor = try TextEditor.init(std.testing.allocator, "[😊] Häuschen");
    defer editor.deinit();

    try editor.setCursor(4);
    editor.moveCursor(.left, .letter);
    try std.testing.expectEqual(@as(usize, 3), editor.cursor);
    editor.moveCursor(.left, .letter);
    try std.testing.expectEqual(@as(usize, 2), editor.cursor);
    editor.moveCursor(.left, .letter);
    try std.testing.expectEqual(@as(usize, 1), editor.cursor);
    editor.moveCursor(.left, .letter);
    try std.testing.expectEqual(@as(usize, 0), editor.cursor);
    editor.moveCursor(.left, .letter);
    try std.testing.expectEqual(@as(usize, 0), editor.cursor);

    editor.moveCursor(.right, .letter);
    try std.testing.expectEqual(@as(usize, 1), editor.cursor);

    try editor.setCursor(10);
    editor.moveCursor(.right, .letter);
    try std.testing.expectEqual(@as(usize, 11), editor.cursor);
    editor.moveCursor(.right, .letter);
    try std.testing.expectEqual(@as(usize, 12), editor.cursor);
    editor.moveCursor(.right, .letter);
    try std.testing.expectEqual(@as(usize, 12), editor.cursor);
}

test "moveCursor (word, right)" {
    var editor = try TextEditor.init(std.testing.allocator, "[😊] Häuschen");
    defer editor.deinit();

    try editor.setCursor(3);
    editor.moveCursor(.right, .word);
    try std.testing.expectEqual(@as(usize, 4), editor.cursor);

    try editor.setCursor(4);
    editor.moveCursor(.right, .word);
    try std.testing.expectEqual(@as(usize, 12), editor.cursor);
    editor.moveCursor(.right, .word);
    try std.testing.expectEqual(@as(usize, 12), editor.cursor);

    try editor.setCursor(6);
    editor.moveCursor(.right, .word);
    try std.testing.expectEqual(@as(usize, 12), editor.cursor);
    editor.moveCursor(.right, .word);
    try std.testing.expectEqual(@as(usize, 12), editor.cursor);

    try editor.setCursor(10);
    editor.moveCursor(.right, .word);
    try std.testing.expectEqual(@as(usize, 12), editor.cursor);
    editor.moveCursor(.right, .word);
    try std.testing.expectEqual(@as(usize, 12), editor.cursor);

    try editor.setText("void main foo bar");
    try editor.setCursor(2);
    editor.moveCursor(.right, .word);
    try std.testing.expectEqual(@as(usize, 4), editor.cursor);
    editor.moveCursor(.right, .word);
    try std.testing.expectEqual(@as(usize, 5), editor.cursor);
    editor.moveCursor(.right, .word);
    try std.testing.expectEqual(@as(usize, 9), editor.cursor);
    editor.moveCursor(.right, .word);
    try std.testing.expectEqual(@as(usize, 10), editor.cursor);
    editor.moveCursor(.right, .word);
    try std.testing.expectEqual(@as(usize, 13), editor.cursor);
    editor.moveCursor(.right, .word);
    try std.testing.expectEqual(@as(usize, 14), editor.cursor);
    editor.moveCursor(.right, .word);
    try std.testing.expectEqual(@as(usize, 17), editor.cursor);
    editor.moveCursor(.right, .word);
    try std.testing.expectEqual(@as(usize, 17), editor.cursor);
}

test "moveCursor (word, left)" {
    var editor = try TextEditor.init(std.testing.allocator, "[😊] Häuschen");
    defer editor.deinit();

    try editor.setCursor(12);
    editor.moveCursor(.left, .word);
    try std.testing.expectEqual(@as(usize, 4), editor.cursor);
    editor.moveCursor(.left, .word);
    try std.testing.expectEqual(@as(usize, 3), editor.cursor);
    editor.moveCursor(.left, .word);
    try std.testing.expectEqual(@as(usize, 2), editor.cursor);
    editor.moveCursor(.left, .word);
    try std.testing.expectEqual(@as(usize, 1), editor.cursor);
    editor.moveCursor(.left, .word);
    try std.testing.expectEqual(@as(usize, 0), editor.cursor);
    editor.moveCursor(.left, .word);
    try std.testing.expectEqual(@as(usize, 0), editor.cursor);

    try editor.setText("void main foo  bar");
    try std.testing.expectEqual(@as(usize, 18), editor.cursor);
    editor.moveCursor(.left, .word);
    try std.testing.expectEqual(@as(usize, 15), editor.cursor);
    editor.moveCursor(.left, .word);
    try std.testing.expectEqual(@as(usize, 13), editor.cursor);
    editor.moveCursor(.left, .word);
    try std.testing.expectEqual(@as(usize, 10), editor.cursor);
    editor.moveCursor(.left, .word);
    try std.testing.expectEqual(@as(usize, 9), editor.cursor);
    editor.moveCursor(.left, .word);
    try std.testing.expectEqual(@as(usize, 5), editor.cursor);
    editor.moveCursor(.left, .word);
    try std.testing.expectEqual(@as(usize, 4), editor.cursor);
    editor.moveCursor(.left, .word);
    try std.testing.expectEqual(@as(usize, 0), editor.cursor);
    editor.moveCursor(.left, .word);
    try std.testing.expectEqual(@as(usize, 0), editor.cursor);
}

test "delete (line)" {
    var editor = try TextEditor.init(std.testing.allocator, "");
    defer editor.deinit();

    try editor.setText("[😊] Häuschen");
    try editor.setCursor(2);
    editor.delete(.right, .line);
    try std.testing.expectEqualStrings("[😊", editor.getText());

    try editor.setText("[😊] Häuschen");
    try editor.setCursor(2);
    editor.delete(.left, .line);
    try std.testing.expectEqualStrings("] Häuschen", editor.getText());
}

test "delete (letter, left)" {
    var editor = try TextEditor.init(std.testing.allocator, "");
    defer editor.deinit();

    try editor.setText("[😊] Häuschen");
    try editor.setCursor(4);
    editor.delete(.left, .letter);
    try std.testing.expectEqualStrings("[😊]Häuschen", editor.getText());
    try std.testing.expectEqual(@as(usize, 3), editor.cursor);

    editor.delete(.left, .letter);
    try std.testing.expectEqualStrings("[😊Häuschen", editor.getText());
    try std.testing.expectEqual(@as(usize, 2), editor.cursor);

    editor.delete(.left, .letter);
    try std.testing.expectEqualStrings("[Häuschen", editor.getText());
    try std.testing.expectEqual(@as(usize, 1), editor.cursor);

    editor.delete(.left, .letter);
    try std.testing.expectEqualStrings("Häuschen", editor.getText());
    try std.testing.expectEqual(@as(usize, 0), editor.cursor);

    editor.delete(.left, .letter);
    try std.testing.expectEqualStrings("Häuschen", editor.getText());
    try std.testing.expectEqual(@as(usize, 0), editor.cursor);
}

test "delete (letter, right)" {
    var editor = try TextEditor.init(std.testing.allocator, "");
    defer editor.deinit();

    try editor.setText("[😊] Häuschen");
    try editor.setCursor(2);
    editor.delete(.right, .letter);
    try std.testing.expectEqualStrings("[😊 Häuschen", editor.getText());
    try std.testing.expectEqual(@as(usize, 2), editor.cursor);

    editor.delete(.right, .letter);
    try std.testing.expectEqualStrings("[😊Häuschen", editor.getText());
    try std.testing.expectEqual(@as(usize, 2), editor.cursor);

    editor.delete(.right, .letter);
    try std.testing.expectEqualStrings("[😊äuschen", editor.getText());
    try std.testing.expectEqual(@as(usize, 2), editor.cursor);

    editor.delete(.right, .letter);
    try std.testing.expectEqualStrings("[😊uschen", editor.getText());
    try std.testing.expectEqual(@as(usize, 2), editor.cursor);

    editor.delete(.right, .letter);
    try std.testing.expectEqualStrings("[😊schen", editor.getText());
    try std.testing.expectEqual(@as(usize, 2), editor.cursor);

    try editor.setCursor(6);

    editor.delete(.right, .letter);
    try std.testing.expectEqualStrings("[😊sche", editor.getText());
    try std.testing.expectEqual(@as(usize, 6), editor.cursor);

    editor.delete(.right, .letter);
    try std.testing.expectEqualStrings("[😊sche", editor.getText());
    try std.testing.expectEqual(@as(usize, 6), editor.cursor);
}

test "delete (word, right)" {
    var editor = try TextEditor.init(std.testing.allocator, "");
    defer editor.deinit();

    try editor.setText("[😊] Häuschen");
    try editor.setCursor(2);
    editor.delete(.right, .word);
    try std.testing.expectEqualStrings("[😊 Häuschen", editor.getText());
    try std.testing.expectEqual(@as(usize, 2), editor.cursor);
    editor.delete(.right, .word);
    try std.testing.expectEqualStrings("[😊Häuschen", editor.getText());
    try std.testing.expectEqual(@as(usize, 2), editor.cursor);
    editor.delete(.right, .word);
    try std.testing.expectEqualStrings("[😊", editor.getText());
    try std.testing.expectEqual(@as(usize, 2), editor.cursor);
    editor.delete(.right, .word);
    try std.testing.expectEqualStrings("[😊", editor.getText());
    try std.testing.expectEqual(@as(usize, 2), editor.cursor);
}

test "delete (word, left)" {
    var editor = try TextEditor.init(std.testing.allocator, "");
    defer editor.deinit();

    try editor.setText("[😊] Häuschen");
    try editor.setCursor(8);
    editor.delete(.left, .word);
    try std.testing.expectEqualStrings("[😊] chen", editor.getText());
    try std.testing.expectEqual(@as(usize, 4), editor.cursor);
    editor.delete(.left, .word);
    try std.testing.expectEqualStrings("[😊]chen", editor.getText());
    try std.testing.expectEqual(@as(usize, 3), editor.cursor);
    editor.delete(.left, .word);
    try std.testing.expectEqualStrings("[😊chen", editor.getText());
    try std.testing.expectEqual(@as(usize, 2), editor.cursor);
    editor.delete(.left, .word);
    try std.testing.expectEqualStrings("[chen", editor.getText());
    try std.testing.expectEqual(@as(usize, 1), editor.cursor);
    editor.delete(.left, .word);
    try std.testing.expectEqualStrings("chen", editor.getText());
    try std.testing.expectEqual(@as(usize, 0), editor.cursor);
    editor.delete(.left, .word);
    try std.testing.expectEqualStrings("chen", editor.getText());
    try std.testing.expectEqual(@as(usize, 0), editor.cursor);
}
