#!/bin/bash
################################################################################
##
## To support:
##  1. bspsetup: toolchain, kernel and u-boot source setup
##  2. l4tout_setup: setup Linux_for_Tegra
##
################################################################################

function _later_check()
{
	[ -d $L4TOUT ] || (echo "${red} _early_check failed${normal}" && return 1)
	[ -f ${KERNEL_TOOLCHAIN}gcc ] || (echo "${red} ${KERNEL_TOOLCHAIN}gcc check failed${normal}" && return 1)
	[ -f ${BSP_TOOLCHAIN}gcc ] || (echo "${red} ${BSP_TOOLCHAIN}gcc check failed${normal}" && return 1)
	[ -d $KERNEL_PATH ] || (echo "$KERNEL_PATH check failed${normal}" && return 1)
}

function _toolchain_setup()
{
	# for bsp
	if [ ! -f ${BSP_TOOLCHAIN}gcc ]
	then
		if [ ! -f $BSP_TOOLCHAIN_PACKAGE ] || [ $(wget_size $BSP_TOOLCHAIN_LINK) -ne $(local_size $BSP_TOOLCHAIN_PACKAGE) ]
		then
			edo wget $BSP_TOOLCHAIN_LINK -O $BSP_TOOLCHAIN_PACKAGE
		fi
		edo tar xpf $BSP_TOOLCHAIN_PACKAGE -C $BSP_TOOLCHAIN_ROOT
		if [ ! -f ${BSP_TOOLCHAIN}gcc ] && [ -x $BSP_TOOLCHAIN_ROOT/make-arm-hf-toolchain.sh ]
		then
			pushd $BSP_TOOLCHAIN_ROOT &> /dev/null
			edo ./make-arm-hf-toolchain.sh
			popd &> /dev/null
		fi
	fi

	# for kernel
	if [ ! -f ${KERNEL_TOOLCHAIN}gcc ]
	then
		if [ ! -f $KERNEL_TOOLCHAIN_PACKAGE ] || [ $(wget_size $KERNEL_TOOLCHAIN_LINK) -ne $(local_size $KERNEL_TOOLCHAIN_PACKAGE) ]
		then
			edo wget $KERNEL_TOOLCHAIN_LINK -O $KERNEL_TOOLCHAIN_PACKAGE
		fi
		edo tar xpf $KERNEL_TOOLCHAIN_PACKAGE -C $KERNEL_TOOLCHAIN_ROOT
		if [ ! -f ${KERNEL_TOOLCHAIN}gcc ] && [ -x $KERNEL_TOOLCHAIN_ROOT/make-aarch64-toolchain.sh ]
		then
			pushd $KERNEL_TOOLCHAIN_ROOT &> /dev/null
			edo ./make-aarch64-toolchain.sh
			popd &> /dev/null
		fi
	fi
}

function _sources_setup()
{
	# Source download
	if [ ! -f $SOURCE_PACKAGE ] || [ $(wget_size $SOURCES_LINK) -ne $(local_size $SOURCE_PACKAGE) ]
	then
		edo mkdir -p $DOANLOAD_ROOT
		echo; echo "download source code..."
		edo wget $SOURCES_LINK -O $SOURCE_PACKAGE
	fi

	if [ ! -d $SOURCE_UNPACK ]
	then
		echo; echo "Unpack source..."
		edo tar xpf $SOURCE_PACKAGE -C $DOANLOAD_ROOT
		
	fi

	# kernel source
	if [ -z "$(ls -A $KERNEL_ROOT)" ]
	then
		echo; echo "Setup kernel source code..."
		edo git init $KERNEL_ROOT
		edo tar xpf $KERNEL_PACKAGE -C $KERNEL_ROOT
		pushd $KERNEL_ROOT &> /dev/null
		edo git add .
		edo git commit -s -m "${TARGET_DEV}-${TARGET_RELEASE}"
		popd &> /dev/null
	fi

	edo rm -rf $DOANLOAD_ROOT

	if [ ! -f $CBOOT_PACKAGE ]
	then
		echo; echo "${yel}************************************************************"
		echo "If you need cboot, please download cboot source code from"
		echo "$CBOOT_SOURCE_LINK"
		echo "move to below place and rerun bspsetup."
		dirname $CBOOT_PACKAGE
		echo "************************************************************${normal}"
		echo
		return 0
		edo wget $CBOOT_SOURCE_LINK -O $CBOOT_PACKAGE
	else
		if [ -z "$(ls -A $CBOOT_ROOT)" ]
		then
			edo git init $CBOOT_ROOT
			echo; echo "Setup cboot source code..."
			edo tar xpf $CBOOT_PACKAGE -C $CBOOT_ROOT
			pushd $CBOOT_ROOT &> /dev/null
			edo git add .
			edo git commit -s -m "${TARGET_DEV}-${TARGET_RELEASE}"
			popd &> /dev/null
		fi
	fi


}

function l4tout_setup()
{
	mkdir -p `dirname $L4TOUT`

	echo -n "${yel}Are you sure to setup l4tout? [n/y] "
	read ANSWER
	if [ "$ANSWER"x != "y"x ]
	then
		return 0
	fi
	echo "${normal}"

	edo sudo rm -rf $L4TOUT

	mkdir -p $DOANLOAD_ROOT
	mkdir -p $TMP_ROOT
	if [ ! -f $BSP_PACKAGE ] || [ $(wget_size $BSP_LINK) -ne $(local_size $BSP_PACKAGE) ]
	then
		echo; echo "download BSP package..."
		edo wget $BSP_LINK -O $BSP_PACKAGE
	fi
	edo tar xpf $BSP_PACKAGE -C $TMP_ROOT
	edo mv $TMP_ROOT/Linux_for_Tegra $L4TOUT
	edo rm -rf $TMP_ROOT

	if [ ! -f $ROOTFS_PACKAGE ] || [ $(wget_size $ROOTFS_LINK) -ne $(local_size $ROOTFS_PACKAGE) ]
	then
		echo; echo "download root file system package..."
		edo wget $ROOTFS_LINK -O $ROOTFS_PACKAGE
	fi
	edo sudo tar xpf $ROOTFS_PACKAGE -C $TARGET_ROOTFS

	pushd $L4TOUT &> /dev/null
	edo sudo ./apply_binaries.sh
	popd &> /dev/null

	sync
}

function bspsetup()
{
	if [ ! -d $L4TOUT ]
	then
		echo "${red}Linux_for_Tegra is missing."
        echo "plaese run  \"${yel}l4tout_setup${red}\" to setup${normal}"
		return 1;
	fi

	## Toolochain
	mkdir -p $KERNEL_TOOLCHAIN_ROOT
	mkdir -p $BSP_TOOLCHAIN_ROOT
	mkdir -p $KERNEL_ROOT
	mkdir -p $CBOOT_ROOT

	#_toolchain_setup && _sources_setup
	_sources_setup

	_later_check || (echo "${red}_later_check failed, BSP setup failed!${normal}" && return 1)

	echo "${mag}BSP setup successfully!${normal}"; echo
}

echo -e "${red}bspsetup${normal}: \t\tsetup toolchain, kernel source"
echo -e "${red}l4tout_setup${normal}: \t\tsetup Xavier/Linux_for_Tegra"
