#!/bin/bash

################################################################################
##
## To support:
##  1. krebuild: kernel Image and dtb build
##  2. kmenuconfig & ksavedefconfig: kernel defconfig update
##
################################################################################

_kernel_prepare_dirs()
{
	mkdir -p $KERNEL_OUT
	mkdir -p $INSTALL_KERNEL_MODULES_PATH
}

function kmenuconfig()
{
	_kernel_prepare_dirs

	local MAKE_OPTIONS="ARCH=arm64 CROSS_COMPILE=$KERNEL_TOOLCHAIN O=$KERNEL_OUT"

	edo make -C $KERNEL_PATH $MAKE_OPTIONS menuconfig
}

function kdefconfig()
{
	_kernel_prepare_dirs

	local MAKE_OPTIONS="ARCH=arm64 CROSS_COMPILE=$KERNEL_TOOLCHAIN O=$KERNEL_OUT"

	edo make -C $KERNEL_PATH $MAKE_OPTIONS $TARGET_KERNEL_CONFIG
}

function ksavedefconfig()
{
	local MAKE_OPTIONS="ARCH=arm64 CROSS_COMPILE=$KERNEL_TOOLCHAIN O=$KERNEL_OUT"

	edo make -C $KERNEL_PATH $MAKE_OPTIONS savedefconfig
	edo cp $KERNEL_OUT/defconfig $KERNEL_PATH/arch/arm64/configs/$TARGET_KERNEL_CONFIG
}

function kinstall()
{
	_kernel_prepare_dirs

	echo; echo "kernel install..."
	edo cp $KERNEL_OUT/arch/arm64/boot/Image $L4TOUT/kernel/
	edo cp $KERNEL_OUT/arch/arm64/boot/dts/*.dtb $L4TOUT/kernel/dtb/
	if [ "X-m" == "X$1" ]
	then
		pushd $INSTALL_KERNEL_MODULES_PATH &> /dev/null
		edo tar --owner root --group root -cjf kernel_supplements.tbz2 lib/modules
		popd &> /dev/null
		edo mv $INSTALL_KERNEL_MODULES_PATH/kernel_supplements.tbz2 $L4TOUT/kernel/
	fi
	echo "Done"; echo
}

function kbuildimage()
{
	_kernel_prepare_dirs
	_getnumcpus

	local MAKE_OPTIONS="ARCH=arm64 CROSS_COMPILE=$KERNEL_TOOLCHAIN O=$KERNEL_OUT -j${NUMCPUS} V=0"

	echo; echo "start Image build..."
	edo make -C $KERNEL_PATH $MAKE_OPTIONS Image
}

function kbuilddtb()
{
	_kernel_prepare_dirs
	_getnumcpus

	local MAKE_OPTIONS="ARCH=arm64 CROSS_COMPILE=$KERNEL_TOOLCHAIN O=$KERNEL_OUT -j${NUMCPUS} V=0"

	echo; echo "start dtbs build..."
	edo make -C $KERNEL_PATH $MAKE_OPTIONS dtbs
}

function kbuildmodule()
{
	_kernel_prepare_dirs
	_getnumcpus

	local MAKE_OPTIONS="ARCH=arm64 CROSS_COMPILE=$KERNEL_TOOLCHAIN O=$KERNEL_OUT -j${NUMCPUS} V=0"

	echo ; echo; echo "start modules build..."
	edo make -C $KERNEL_PATH $MAKE_OPTIONS modules DESTDIR=$INSTALL_KERNEL_MODULES_PATH
	edo make -C $KERNEL_PATH $MAKE_OPTIONS modules_install INSTALL_MOD_PATH=$INSTALL_KERNEL_MODULES_PATH
}

function kbuild()
{
	local KINSTALL_ARG

	while getopts 'm' OPT; do
		case $OPT in
			m)
				KINSTALL_ARG="-m";;
			?)
				echo "Usage: kbuild [-m]"
		esac
	done

	_kernel_prepare_dirs

	[ -f $KERNEL_OUT/.config ] || kdefconfig

	kbuildimage && kbuilddtb && kbuildmodule && kinstall $KINSTALL_ARG

	echo "Done"; echo
}

echo "${red}kmenuconfig${normal}:    kernel menuconfig"
echo "${red}kdefconfig${normal}:    kernel defconfig"
echo "${red}ksavedefconfig${normal}:    update kernel defconfig"
echo "${red}kbuild${normal}:    build and install kernel image, dtb"
echo "${red}kbuild -m${normal}:    build and install kernel image, dtb, module"
