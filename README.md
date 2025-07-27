# Busybox static executables and a script to build them

All works well and checks out, very easy to follow. Did not invest too much effort on it, sort of combined the other static build projects, and code from PscgBuildOS

Supported archs:
- x86_64
- aarch64
- arm
- armhf
- riscv64
- loongarch64

## Notes about i386
`-m32` was built and tested, but it is not included, as it requires adding gcc-multilib and I don't recommend doing so, in general.
 Therefore, you can use i686 (recommended) or alternatively set your own machine with gcc-multilib and copy from it.

For this, you would likely want to disable the other tupples (or arrange your own cross compilers for them, as gcc-multilib will remove them) and install and build like this:

```
apt-get install build-essential gcc-multilib # will likely remove your other distro toolchains
USE_MULTILIB_FOR_32BIT_X86=true ./build-busybox.sh
```
