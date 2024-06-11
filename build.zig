const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const ziglyph = b.dependency("ziglyph", .{ .target = target, .optimize = optimize }).module("ziglyph");

    const text_editor = b.addModule("text-editor", .{
        .root_source_file = b.path("src/TextEditor.zig"),
        .target = target,
        .optimize = optimize,
    });
    text_editor.addImport("ziglyph", ziglyph);

    const test_runner = b.addTest(.{
        .root_source_file = b.path("src/testsuite.zig"),
        .target = target,
        .optimize = optimize,
    });
    test_runner.root_module.addImport("text-editor", text_editor);

    b.getInstallStep().dependOn(&test_runner.step);
}
