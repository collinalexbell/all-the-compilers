const Builder = @import("std").build.Builder;

pub fn build(b: *Builder) void {
    const rel_opts = b.standardReleaseOptions();

    const c_obj = b.addObject("cfuncs", null);
    c_obj.addCSourceFile("cfuncs.c", &[_][]const u8{"-std=c99"});
    c_obj.setBuildMode(rel_opts);
    c_obj.linkSystemLibrary("c");

    const main = b.addTest("main.zig");
    main.setBuildMode(rel_opts);
    main.addObject(c_obj);

    const test_step = b.step("test", "Test the program");
    test_step.dependOn(&main.step);

    b.default_step.dependOn(test_step);
}
