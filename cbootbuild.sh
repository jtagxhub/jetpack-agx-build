#!/bin/bash

function cinstall()
{
	echo; echo "cboot install..."
	edo mv $CBOOT_OUT/build-t194/lk.bin $L4TOUT/bootloader/cboot_t194.bin
	echo "Done"; echo
}

function cbuildimage()
{
	_getnumcpus

	local MAKE_OPTIONS="TEGRA_TOP=$CBOOT_ROOT PROJECT=t194 TOOLCHAIN_PREFIX=$KERNEL_TOOLCHAIN DEBUG=2 BUILDROOT=$CBOOT_OUT NV_TARGET_BOARD=t194ref NV_BUILD_SYSTEM_TYPE=l4t NOECHO=@ -j${NUMCPUS}"

	echo; echo "start Image build..."
	edo make -C $CBOOT_ROOT/bootloader/partner/t18x/cboot $MAKE_OPTIONS
}

function cbuild()
{
	_cboot_prepare_dirs

	cbuildimage && cinstall

	echo "Done"; echo
}

echo -e "${red}cbuild${normal}: \t\tbuild and install cboot"
