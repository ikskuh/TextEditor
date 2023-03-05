const std = @import("std");

pub fn build(b: *std.build.Builder) !void {
    const ziglyph = b.dependency("ziglyph", .{}).module("ziglyph");

    _ = b.addModule("text-editor", .{
        .source_file = .{ .path = "src/TextEditor.zig" },
        .dependencies = &.{
            .{ .name = "ziglyph", .module = ziglyph },
        },
    });

    const optimize = b.standardOptimizeOption(.{});
    const test_step = b.step("test", "Runs the test suite.");

    const test_runner = b.addTest(.{
        .root_source_file = .{ .path = "src/testsuite.zig" },
        .optimize = optimize,
        .target = .{},
    });
    test_runner.addModule("ziglyph", ziglyph);

    test_step.dependOn(&test_runner.step);
}
