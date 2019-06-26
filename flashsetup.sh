#!/bin/bash

################################################################################
##
## To support:
##  1. Full flash
##  3. Update kernel Image & dtb
##
################################################################################

function remote_sudo()
{
	edo sshpass -p $TARGET_PWD ssh -t -l $TARGET_USER $TARGET_IP "echo ${TARGET_PWD} | sudo -S -s /bin/bash -c \"$@\""
}

function flash()
{
	pushd ${L4TOUT} &> /dev/null
	edo sudo ./flash.sh  $@ `basename ${TARGET_DEV_CONF::-5}` mmcblk0p1;
	popd &> /dev/null
}

function flash_no_rootfs()
{
	if ! is_xavier && ! is_tx2
	then
		return
	fi
	local TARGET_BOARD=$(get_setting_from_conf target_board)
	local FLASH_CONFIG_PATH=$L4TOUT/bootloader/$TARGET_BOARD/cfg
	local FLASH_CONFIG_NAME=$(get_setting_from_conf EMMC_CFG)
	local FLASH_CONFIG=$FLASH_CONFIG_PATH/$FLASH_CONFIG_NAME
	local FLASH_CONFIG_SAVE=$FLASH_CONFIG.save
	local DEV_APP_STRING
	local APP_FILE_STRING

	[ -f $FLASH_CONFIG ] || (echo "$FLASH_CONFIG not found" && return 1)

	edo cp -f $FLASH_CONFIG $FLASH_CONFIG_SAVE
	DEV_APP_STRING=`xmllint --xpath '//partition[@name="APP"]/ancestor::device' $FLASH_CONFIG | head -1`
	APP_FILE_STRING=`xmllint --xpath '//partition[@name="APP"]/filename' $FLASH_CONFIG`
	echo "Add erase=\"false\" to $DEV_APP_STRING"
	sed -i "/$DEV_APP_STRING/s/\([^>]*\)/\1 erase=\"false\"/" $FLASH_CONFIG
	echo "Remove $APP_FILE_STRING"
	sed -i "s,\($APP_FILE_STRING\),<!--\1-->," $FLASH_CONFIG
	flash -r
	edo mv -f $FLASH_CONFIG_SAVE $FLASH_CONFIG
}

function flash_cboot()
{
	if is_xavier
	then
		flash -k cpu-bootloader
	else
		echo "${red}no support for flash_cboot yet${normal}"; echo
	fi
}

function flash_kernel()
{
	flash -k kernel
}

function update_kernel()
{
	local lmd5
	local rmd5
	local HOST_IMAGE=$L4TOUT/kernel/Image
	local TARGET_IMAGE=/boot/Image

	if [ -z "$TARGET_USER" -o -z "$TARGET_PWD" -o -z "$TARGET_IP" ]
	then
		echo "${red}please specify the user@ip and password of device${normal}"; echo
		return 1
	fi

	## Image
	echo "sshpass -p \"$TARGET_PWD\" scp ${HOST_IMAGE} $TARGET_USER@$TARGET_IP:~/"
	sshpass -p "$TARGET_PWD" scp ${HOST_IMAGE} $TARGET_USER@$TARGET_IP:~/
	remote_sudo "mv ~/Image ${TARGET_IMAGE}"
	lmd5=`md5sum ${HOST_IMAGE} | cut -d " " -f 1`
	rmd5=`sshpass -p "$TARGET_PWD" ssh -t -l $TARGET_USER $TARGET_IP "md5sum ${TARGET_IMAGE}" | cut -d " " -f 1`
	if [ "$lmd5" = "$rmd5" ]; then
		echo "Image update successsfully"
	else
		echo "Image update failed"
	fi
}

echo -e "${red}flash${normal}: \t\t\tflash image with options"
if is_xavier || is_tx2
then
	echo -e "${red}flash_no_rootfs${normal}: \tflash all except rootfs"
fi
if is_xavier
then
	echo -e "${red}flash_cboot${normal}: \t\tflash cboot Image"
	echo -e "${red}flash_kernel${normal}: \t\tflash kernel Image"
else
	echo -e "${red}update_kernel${normal}: \t\tupdate kernel Image"
fi
