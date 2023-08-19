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

    const test_runner = b.addTest(.{
        .root_source_file = .{ .path = "src/testsuite.zig" },
        .optimize = optimize,
        .target = .{},
    });
    test_runner.addModule("ziglyph", ziglyph);

    b.getInstallStep().dependOn(&test_runner.step);
}
