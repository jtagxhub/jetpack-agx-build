#!/bin/bash

red=$'\e[31m'
grn=$'\e[32m'
yel=$'\e[33m'
blu=$'\e[34m'
mag=$'\e[35m'
cyn=$'\e[36m'
normal=$'\e[0m'


BUILD_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
export TOP=`dirname $BUILD_DIR`

TARGET_DEV_ARRAY=()
TARGET_RELEASE_ARRAY=()

CONFIG_DIR=$BUILD_DIR/config

source $TOP/build/.config &> /dev/null

function edo()
{
	echo "${cyn}$@${normal}"
	$@
}

function choose_target()
{
	if [ ! -z "$TARGET_DEV" ]
	then
		return 0
	fi

	local index=0
	local v
	for v in ${TARGET_DEV_ARRAY[@]}
	do
		echo "     $index. $v"
		index=$(($index+1))
	done

	local ANSWER
	while [ -z "$TARGET_DEV" ]
	do
		echo -n "Which device would you choose? [$DEFAULT_TARGET_DEV] "
		read ANSWER

		if [ -z "$ANSWER" ] ; then
			export TARGET_DEV=$DEFAULT_TARGET_DEV
		else
			if [ $ANSWER -lt ${#TARGET_DEV_ARRAY[@]} ]
			then
				export TARGET_DEV=${TARGET_DEV_ARRAY[$ANSWER]}
			else
				echo "** Not a valid device option: $ANSWER"
			fi
		fi
	done
}

function choose_release()
{
	if [ ! -z "$TARGET_RELEASE" ]
	then
		return 0
	fi

	local index=0
	local v
	for v in ${TARGET_RELEASE_ARRAY[@]}
	do
		echo "     $index. $v"
		index=$(($index+1))
	done

	local ANSWER
	while [ -z "$TARGET_RELEASE" ]
	do
		echo -n "Which release would you choose? [$DEFAULT_TARGET_RELEASE] "
		read ANSWER

		if [ -z "$ANSWER" ] ; then
			export TARGET_RELEASE=$DEFAULT_TARGET_RELEASE
		else
			if [ $ANSWER -lt ${#TARGET_RELEASE_ARRAY[@]} ]
			then
				export TARGET_RELEASE=${TARGET_RELEASE_ARRAY[$ANSWER]}
			else
				echo "** Not a valid release option: $ANSWER"
			fi
		fi
	done
}

function set_target_user()
{
	if [ ! -z "$TARGET_USER" ]
	then
		return 0
	fi

	local ANSWER
	while [ -z "$TARGET_USER" ]
	do
		echo -n "Login user of target device? [nvidia] "
		read ANSWER

		if [ -z "$ANSWER" ] ; then
			export TARGET_USER=nvidia
		else
			export TARGET_USER=$ANSWER
		fi
	done
}

function set_target_pwd()
{
	if [ ! -z "$TARGET_PWD" ]
	then
		return 0
	fi

	local ANSWER
	while [ -z "$TARGET_PWD" ]
	do
		echo -n "Login password of target device? [nvidia] "
		read ANSWER

		if [ -z "$ANSWER" ] ; then
			export TARGET_PWD=nvidia
		else
			export TARGET_PWD=$ANSWER
		fi
	done
}

function set_target_ip()
{
	if [ ! -z "$TARGET_IP" ]
	then
		return 0
	fi

	local ANSWER
	while [ -z "$TARGET_IP" ]
	do
		echo -n "IP address of target device? "
		read ANSWER

		if [ -z "$ANSWER" ] ; then
			break;
		else
			export TARGET_IP=$ANSWER
			break;
		fi
	done
}

function is_nano()
{
	[ "Xjetson-nano" == "X${TARGET_DEV,,}" ]
}

function is_tx1()
{
	[ "Xjetson-tx1" == "X${TARGET_DEV,,}" ]
}

function is_tx2()
{
	[ "Xjetson-tx2" == "X${TARGET_DEV,,}" ]
}

function is_xavier()
{
	[ "Xjetson-xavier" == "X${TARGET_DEV,,}" ]
}

function _getnumcpus()
{
	NUMCPUS=2
	NUMCPUS=`cat /proc/cpuinfo | grep processor | wc -l`
}

function rm_pwd()
{
    sshpass -p "$TARGET_PWD" ssh -t -l ${TARGET_USER} ${TARGET_IP} \
        "sudo sed -i 's/^%sudo.*:ALL[)]/& NOPASSWD: NOPASSWD:/g' /etc/sudoers"

    sshpass -p "$TARGET_PWD" ssh -t -l ${TARGET_USER} ${TARGET_IP} \
        "ssh-keygen -f ~/.ssh/id_rsa -t rsa -N ''"
    sshpass -p "${TARGET_PWD}" scp ~/.ssh/id_rsa.pub \
        ${TARGET_USER}@${TARGET_IP}:~/.ssh/tmp_authorized_keys > /dev/null
    sshpass -p "${TARGET_PWD}" ssh -t -l ${TARGET_USER} ${TARGET_IP} \
        "cat ~/.ssh/tmp_authorized_keys >> ~/.ssh/authorized_keys; \
         rm ~/.ssh/tmp_authorized_keys" > /dev/null
}

for f in `find $CONFIG_DIR -maxdepth 1 -type f`
do
	f=`basename $f`
	arr=(${f//-/ })
	if [[ ! " ${TARGET_DEV_ARRAY[@]} " =~ " Jetson-${arr[0]} " ]]; then
		TARGET_DEV_ARRAY+=(Jetson-${arr[0]})
	fi
done

DEFAULT_TARGET_DEV=${TARGET_DEV_ARRAY[0]}

choose_target

# ${TARGET_DEV:7} removes Jetson-
for f in `ls $CONFIG_DIR/${TARGET_DEV:7}-*`
do
	f=`basename $f`
	arr=(${f//-/ })
	if [[ ! " ${TARGET_RELEASE_ARRAY[@]} " =~ " ${arr[1]} " ]]; then
		TARGET_RELEASE_ARRAY+=(${arr[1]})
	fi
done

DEFAULT_TARGET_RELEASE=${TARGET_RELEASE_ARRAY[0]}

choose_release
set_target_user
set_target_pwd
set_target_ip
echo
echo "${TARGET_DEV_ARRAY[@]}" | grep -w "$TARGET_DEV" 2>&1 >/dev/null || (echo "invalid target device" && return 1)
echo "${TARGET_RELEASE_ARRAY[@]}" | grep -w "$TARGET_RELEASE" 2>&1 >/dev/null || (echo "invalid target release" && return 1)

echo "${yel}Please confirm below configuration:${normal}"
echo "${grn}"
echo "TARGET_DEV                : $TARGET_DEV"
echo "TARGET_RELEASE            : $TARGET_RELEASE"
echo "Target device login user     : $TARGET_USER"
echo "Target device login password : $TARGET_PWD"
echo "Target device IP             : $TARGET_IP"
echo
echo -n "${yel}Are these right? [n/y] "
read ANSWER
if [ "$ANSWER"x = "n"x ]
then
	edo rm -f $TOP/build/.config
	export TARGET_DEV=
	export TARGET_RELEASE=
	export TARGET_USER=
	export TARGET_PWD=
	export TARGET_IP=
	echo "please re-configure with $ . build/envsetup.sh"
	echo "${normal}"
	return 1
fi
echo "${normal}"

## re-write build/.config
echo "TARGET_DEV=$TARGET_DEV" >$TOP/build/.config
echo "TARGET_RELEASE=$TARGET_RELEASE" >>$TOP/build/.config
echo "TARGET_USER=$TARGET_USER" >>$TOP/build/.config
echo "TARGET_PWD=$TARGET_PWD" >>$TOP/build/.config
echo "TARGET_IP=$TARGET_IP" >>$TOP/build/.config

# Toolchain
TOOLCHAIN_ROOT=$TOP/prebuilts/gcc
KERNEL_TOOLCHAIN_ROOT=$TOOLCHAIN_ROOT/kernel
BSP_TOOLCHAIN_ROOT=$TOOLCHAIN_ROOT/bsp

# DOWNLOAD
DOANLOAD_ROOT=$TOP/jetpack_download

# SOURCE
SOURCE_PACKAGE=$DOANLOAD_ROOT/sources.tbz2
SOURCE_UNPACK=$DOANLOAD_ROOT/public_sources
SOURCE_ROOT=$TOP/sources

OUT=$TOP/out

# Kernel
KERNEL_PACKAGE=$SOURCE_UNPACK/kernel_src.tbz2
KERNEL_ROOT=$SOURCE_ROOT/kernel
KERNEL_OUT=$OUT/KERNEL
INSTALL_KERNEL_MODULES_PATH=$OUT/MODULES

# C-boot
CBOOT_PACKAGE=$SOURCE_UNPACK/cboot_src_t19x.tbz2
CBOOT_ROOT=$SOURCE_ROOT/cboot
CBOOT_OUT=$OUT/CBOOT

# Tmp
TMP_ROOT=$TOP/.tmp

TARGET_CUDA_INSTALL_SAMPLE_PATH="~/"
TARGET_VISIONWORKS_INSTALL_SAMPLE_PATH="~/"

source $CONFIG_DIR/${TARGET_DEV:7}-${TARGET_RELEASE}

# OUT_ROOT and KERNEL_VERSION defined in build/config/* file, so put them after source
L4TOUT=$OUT_ROOT/Linux_for_Tegra
TARGET_ROOTFS=$L4TOUT/rootfs/
KERNEL_PATH=$KERNEL_ROOT/kernel/kernel-${KERNEL_VERSION}
MM_API_SDK_PATH=$OUT_ROOT/tegra_multimedia_api


function wget_size()
{
	wget --spider $@ 2>&1 | grep Length: | awk '{print $2}'
}

function local_size()
{
	stat -c%s $@
}

echo "C O M M A N D S:"
echo -e "${red}rm_pwd${normal}: \t\tauth ssh connection without password"
source $TOP/build/bspsetup.sh
source $TOP/build/cbootbuild.sh
source $TOP/build/kernelbuild.sh
source $TOP/build/flashsetup.sh
echo
