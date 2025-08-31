# dtc (Device Tree Compiler) static executables and a script to build them

All works well and checks out, very easy to follow. Did not invest too much effort on it, sort of combined the other static build projects, and code from PscgBuildOS
This is different than most of the other builds, as it uses Meson.

## Build status
Known to build properly:
```
x86_64-linux-gnu aarch64-linux-gnu riscv64-linux-gnu arm-linux-gnueabi arm-linux-gnueabihf i686-linux-gnu loongarch64-linux-gnu
alpha-linux-gnu arc-linux-gnu m68k-linux-gnu mips64-linux-gnuabi64 mips64el-linux-gnuabi64 mips-linux-gnu mipsel-linux-gnu powerpc-linux-gnu powerpc64-linux-gnu powerpc64le-linux-gnu sh4-linux-gnu sparc64-linux-gnu s390x-linux-gnu
```

Known to not build properly:\
None at the moment
