# TextEditor

A backend for text editors. It implements the common textbox editing options, but is both rendering and input agnostic.

Keyboard input must be translated into operations like `editor.delete(.right, .word)` to emulate what a typical text box implementation would do when `CTRL DELETE` is pressed.

For mouse input, the editor component needs to be made aware about the font that is used. For this, an abstract font interface is required.

## API

```zig
const TextEditor = @import("src/TextEditor.zig");

fn init(TextEditor.Buffer, initial_text: []const u8) InsertError!TextEditor {
fn deinit(*TextEditor) void;
fn setText(*TextEditor, text: []const u8) InsertError!void;
fn getText(TextEditor) []const u8;
fn getSubString(editor: TextEditor, start: usize, length: ?usize) []const u8;
fn setCursor(*TextEditor, offset: usize) SetCursorError!void;
fn moveCursor(*TextEditor, direction: EditDirection, unit: EditUnit) void;
fn delete(*TextEditor, direction: EditDirection, unit: EditUnit) void;
fn insertText(*TextEditor, text: []const u8) InsertError!void;
fn graphemeCount(TextEditor) usize;
```

## Common Key Mappings

| Keyboard Input   | Editor Call                          |
| ---------------- | ------------------------------------ |
| `Left`           | `editor.moveCursor(.left, .letter)`  |
| `Right`          | `editor.moveCursor(.right, .letter)` |
| `Ctrl+Left`      | `editor.moveCursor(.left, .word)`    |
| `Ctrl+Right`     | `editor.moveCursor(.right, .word)`   |
| `Home`           | `editor.moveCursor(.left, .line)`    |
| `End`            | `editor.moveCursor(.right, .line)`   |
| `Backspace`      | `editor.delete(.left, .letter)`      |
| `Delete`         | `editor.delete(.right, .letter)`     |
| `Ctrl+Backspace` | `editor.delete(.left, .word)`        |
| `Ctrl+Delete`    | `editor.delete(.right, .word)`       |
| _text input_     | `try editor.insert("string")`        |
