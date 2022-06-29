const std = @import("std");
const Pkg = std.build.Pkg;
const FileSource = std.build.FileSource;

pub const pkgs = struct {
    pub const clap = Pkg{
        .name = "clap",
        .source = FileSource{
            .path = ".gyro/zig-clap-hejsil-github.com-996821a3/pkg/clap.zig",
        },
    };

    pub fn addAllTo(artifact: *std.build.LibExeObjStep) void {
        artifact.addPackage(pkgs.clap);
    }
};

pub const exports = struct {
    pub const las = Pkg{
        .name = "las",
        .source = FileSource{ .path = "src/main.zig" },
        .dependencies = &[_]Pkg{
            pkgs.clap,
        },
    };
};
