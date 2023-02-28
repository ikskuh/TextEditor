const std = @import("std");

const pkgs = struct {
    const ziglyph = std.build.Pkg{
        .name = "ziglyph",
        .source = .{ .path = "vendor/ziglyph/src/ziglyph.zig" },
    };
};

pub fn build(b: *std.build.Builder) !void {
    b.addModule(.{
        .name = "text-editor",
        .source_file = .{ .path = "src/TextEditor.zig" },
        .dependencies = &.{
            .{ .name = "ziglyph", .module = b.dependency("ziglyph", .{}).module("ziglyph") },
        },
    });

    const optimize = b.standardOptimizeOption(.{});
    const test_step = b.step("test", "Runs the test suite.");

    const test_runner = b.addTest(.{
        .root_source_file = .{ .path = "src/testsuite.zig" },
        .optimize = optimize,
        .target = .{},
    });
    test_runner.addModule("ziglyph", b.dependency("ziglyph", .{}).module("ziglyph"));

    test_step.dependOn(&test_runner.step);
}
