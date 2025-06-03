#
# An example of how to create busybox statically for different architectures
#
# Used to accompany The PSCG's training/Ron Munitz's talks
#
: ${SRC_PROJECT=$(readlink -f ./busybox)}
: ${USE_MULTILIB_FOR_32BIT_X86=false}	# if true - use -m32. This conflicts with all cross-compilers. A better alternative for 2025 is to use native toolchain distro, i686-linux-gnu-...

declare -A ARCHS
ARCHS[x86_64-linux-gnu]=x86_64
ARCHS[aarch64-linux-gnu]=arm64
ARCHS[riscv64-linux-gnu]=riscv
ARCHS[arm-linux-gnueabi]=arm
ARCHS[arm-linux-gnueabihf]=arm
ARCHS[i686-linux-gnu]=i386

: ${MORE_CONFIGURE_FLAGS=""}
: ${MORE_TUPPLES=""}



# Copying some things from PscgBuildOS to save time. This busybox external project is just nice to have and I make it to store prebuilts in an easily accessible way,
# as I do not use prebuilts neither in PSCG-mini-linux nor in PscgBuildOS
warn() { echo -e "\x1b[33m$@\x1b[0m" ; }
fatalError() { echo -e "\x1b[41m$@\x1b[0m" ; exit 1 ; }

#
# Common modifications [for make defconfig]. [for now] in this project we intend to use defconfig for each architecture, and apply common changes
# 
# $1 src dir
# $2 build dir
# $3 install dir
#
configure_defaults() {
	: ${BUSYBOX_DEFCONFIG=defconfig}
	: ${BUSYBOX_CONFIG_FILE=""} 
	local BUSYBOX_SOURCE_DIR=$1
	local BUSYBOX_BUILD_DIR=$2
	local BUSYBOX_INSTALL_DIR=$3

	echo "Configuring: $1 --> $2 --> $3"

	## handle multilb here, if (different from the other projects, I just want to quickly get it over with)
	if [ "$ARCH" = "i386" -o "$ARCH" = "x86" ] && [ -z "$CROSS_COMPILE" ] ; then
		echo "This would be a good use case for USE_MULTILIB_FOR_32BIT_X86 - which in busybox building, and Linux kernel building is NOT required, and the m32 parameters work well!"
		warn "Building 32 bit busybox without a cross compiler. Assuming you have multilib installed, otherwise you will fail"
		warn "Some heuristics for you would be to check if you have /usr/<x86-toolchain>/  or /usr/include/<x86-toolchain> If not, busybox will fail building on include <asm/errno.h>"
		CFLAGS="$CFLAGS -m32"
		LDFLAGS="$LDFLAGS -m32"
		busybox_build_flags="CFLAGS=-m32 LDFLAGS=-m32"
	else
		busybox_build_flags=""
	fi

	mkdir -p $BUSYBOX_BUILD_DIR $BUSYBOX_INSTALL_DIR || fatalError "Can't create dirs"
	if [ -n "$BUSYBOX_CONFIG_FILE" ] ; then
		cp $BUSYBOX_CONFIG_FILE $BUSYBOX_BUILD_DIR || fatalError "Can't copy $BUSYBOX_CONFIG_FILE"
	else
		echo $busybox_build_flags make -C $BUSYBOX_SOURCE_DIR O=$BUSYBOX_BUILD_DIR $BUSYBOX_DEFCONFIG
		eval $busybox_build_flags make -C $BUSYBOX_SOURCE_DIR O=$BUSYBOX_BUILD_DIR $BUSYBOX_DEFCONFIG
	fi

	sed -i 's:# CONFIG_STATIC is not set:CONFIG_STATIC=y:' $BUSYBOX_BUILD_DIR/.config || fatalError "Failed to make the busybox config static"
	sed -i 's:CONFIG_TC=y:CONFIG_TC=n:' $BUSYBOX_BUILD_DIR/.config || fatalError "Failed to unset CONFIG_TC which is known to not to not work (build) in linux kernel > v6.7"
}

#
# $1: build directory
# $2: install directory
#
build_with_installing() (
	set -euo pipefail # will only apply to this subshell. Prints were added - if nothing is being done - it might be because the folder exists and you will see it in the arch logs
	builddir=$(readlink -f $1)
	installdir=$(readlink -f $2)
	#mkdir $1 # You must create the build and install directories. make will not do that for you
	#cd $1

	echo -e "\x1b[34mConfiguring $tuple\x1b[0m"
	configure_defaults $SRC_PROJECT $(readlink -f $1) $installdir

	echo -e "\x1b[34mBuilding and installing $tuple\x1b[0m ($PWD)"
	echo "$busybox_build_flags make -C $builddir CONFIG_PREFIX=$installdir install -j$(nproc)"
	eval $busybox_build_flags make -C $builddir CONFIG_PREFIX=$installdir install -j$(nproc) || fatalError "Failed to build/install to $installdir"

	echo -e "\x1b[34mStripping $tuple\x1b[0m ($PWD)" || { echo -e "\x1b[31mFailed to strip for $installdir\x1b[0m" ; exit 1 ; }
	find $installdir -executable -not -type d | xargs ${CROSS_COMPILE}strip -s
	echo -e "\x1b[32m$tuple - Done!\x1b[0m ($PWD)"
)


# This example builds for several tuples
# The function above can be used from outside a script, assuming that the CROSS_COMPILE variable is set
# It may however need more configuration if you do not build for gnulibc
build_for_several_tuples() {
	local failing_tuples=""
	for tuple in x86_64-linux-gnu aarch64-linux-gnu riscv64-linux-gnu arm-linux-gnueabi arm-linux-gnueabihf i686-linux-gnu $MORE_TUPPLES ; do
	#for tuple in $MORE_TUPPLES aarch64-linux-gnu ; do
		echo -e "\x1b[35mConfiguring and building $tuple\x1b[0m"
		export CROSS_COMPILE=${tuple}- # we'll later strip it but CROSS_COMPILE is super standard, and autotools is "a little less standard"
		export ARCH=${ARCHS[$tuple]}
		build_with_installing $tuple-build $tuple-install 2> err.$tuple || failing_tuples="$failing_tuples $tuple"
	done

	if [ -z "$failing_tuples" ] ; then
		echo -e "\x1b[32mDone\x1b[0m"
	else
		echo "\x1b[33mDone\x1b[0m You can see errors in $(for x in $failing_tuples ; do echo err.$x ; done)"
	fi
}

#
# Build 32 bit x86 on x86_64 hosts. This is not cross compilation, but rather requires some make flags and the installation of multilib
#
build_and_install_32bitx86_on_x86_64() {
	export CROSS_COMPILE=""
	export ARCH=i386
	local tuple=i386-linux-gnu # pretty much arbitrary
	local builddir=$PWD/$tuple-build
	local installdir=$PWD/$tuple-install

	
	echo -e "\x1b[34mConfiguring $tuple\x1b[0m"
	configure_defaults $SRC_PROJECT $builddir $installdir

	echo -e "\x1b[34mBuilding and installing $tuple\x1b[0m ($PWD)"
	echo "$busybox_build_flags make -C $builddir CONFIG_PREFIX=$installdir install -j$(nproc)"
	eval $busybox_build_flags make -C $builddir CONFIG_PREFIX=$installdir install -j$(nproc) || fatalError "Failed to build/install to $installdir"

	echo -e "\x1b[34mStripping $tuple\x1b[0m ($PWD)" || { echo -e "\x1b[31mFailed to strip for $installdir\x1b[0m" ; exit 1 ; }
	find $installdir -executable -not -type d | xargs ${CROSS_COMPILE}strip -s
	echo -e "\x1b[32m$tuple - Done!\x1b[0m ($PWD)"
}

fetch() (
	# the last time this was updated, master was at commit 5f07327251c93184dfcfc8d978fc35705930ec53 (2025, during the development of v1.38.0")
	# it is not explicitly mentioned, because it could be rebased
	: ${CHECKOUT_COMMIT=""} #

	git clone git://git.busybox.net/busybox.git
)

main() {
	fetch || exit 1
	build_for_several_tuples
	if [ "$(uname -m)" = "x86_64" ] ; then
		if [ "$USE_MULTILIB_FOR_32BIT_X86" = "true" ] ; then
			build_and_install_32bitx86_on_x86_64
		fi
	fi
}

main $@
