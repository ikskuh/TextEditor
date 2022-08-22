const std = @import("std");

const pkgs = struct {
    const ziglyph = std.build.Pkg{
        .name = "ziglyph",
        .source = .{ .path = "vendor/ziglyph/src/ziglyph.zig" },
    };
    const zigstr = std.build.Pkg{
        .name = "zigstr",
        .source = .{ .path = "vendor/zigstr/src/Zigstr.zig" },
        .dependencies = &.{ziglyph},
    };
};

pub fn build(b: *std.build.Builder) !void {
    const mode = b.standardReleaseOptions();
    const test_step = b.step("test", "Runs the test suite.");

    const test_runner = b.addTest("src/testsuite.zig");
    test_runner.setBuildMode(mode);
    test_runner.addPackage(pkgs.ziglyph);
    test_runner.addPackage(pkgs.zigstr);

    test_step.dependOn(&test_runner.step);
}
