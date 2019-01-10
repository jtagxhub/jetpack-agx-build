#!/bin/bash

################################################################################
##
## To support:
##  1. Full flash
##  3. Update kernel Image & dtb
##
################################################################################

function flash()
{
	pushd ${L4TOUT} &> /dev/null
	edo sudo ./flash.sh  $@ ${TARGET_DEV,,} mmcblk0p1;
	popd &> /dev/null
}


function flash_no_rootfs()
{
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
	flash -k cpu-bootloader
}

function flash_kernel()
{
	flash -k kernel
}

echo -e "${red}flash${normal}: \t\t\tflash image with options"
echo -e "${red}flash_no_rootfs${normal}: \tflash all except rootfs"
echo -e "${red}flash_cboot${normal}: \t\tflash cboot Image"
echo -e "${red}flash_kernel${normal}: \t\tflash kernel Image"
