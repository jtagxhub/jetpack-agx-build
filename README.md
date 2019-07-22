Jetson AGX Xavier Build Assistant Scripts
===========================================

Background
----------
  After you download lots of files through JetPack-L4T-xxx-linux-x64-yyy.run or sdkmanager, you
still need to download toolchains, kernel source code and other stuffs to setup
the development environment on your Linux Host PC, in addition, you need also
collect some handy commands to build the code, flash the images, etc.
  So, these scripts are to help developer to setup the develop environment and
provide the handy commands.


Introduction
------------
    1. Clone this repo under the top folder downloaded by Jetpack as "build"
        git clone https://github.com/jtagxhub/jetpack-agx-build.git build

    2. The relevant files for this scripts and their layout.

       $TOP
        ├── build                  --> This Build Assistant Scripts
        │   ├── bspsetup.sh
        │   ├── config
        │   ├── envsetup.sh
        │   ├── flashsetup.sh
        │   ├── kernelbuild.sh
        │   ├── README.md
        ├── jetpack_download
        │   ├── Jetson_Linux_XXXX_aarch64.tbz2
        │   ├── sources.tbz2
        │   └── Tegra_Linux_Sample-Root-Filesystem_XXXX_aarch64.tbz2
        ├── out                    --> kernel build output, images will be copied into Linux_for_Tegra for flash
        │   ├── KERNEL
        │   └── MODULES
        ├── prebuilts
        │   └── gcc
        │       ├── bsp            --> toolchain for bsp build
        │       └── kernel         --> toolchain for kernel build
        ├── sources                --> source code
        └── [Xavier|Nano|64_TX2|64_TX1]     --> All images are put under this for flash
            └── Linux_for_Tegra
                ├── apply_binaries.sh
                ├── bootloader
                ├── build_l4t_bup.sh
                ├── flash.sh
                ├── kernel
                └── rootfs

    3. Commands
       3.1 $ . build/envsetup.sh
             > This command must be executed under the TOP folder downloaded by Jetpack
             > This command is to setup some basic env variables, some configurable
             > variables will be saved into $TOP/build/.config
       3.2 $ l4tout_setup
             > re-setup "Linux_for_Tegra"
       3.3 $ bspsetup
             > download and setup the toolchains
             > download and setup kernel source code with git repo
       3.4 $ kbuild
             > build kernel source code, output to $TOP/out/KERNEL, $TOP/out/MODULES
             > Copy the generated Image and dtbs to $OUT/kernel. If "-a" specified, modules will also be copied
       3.5 $ kdefconfig
             > generate .config from defconfig (make xxx_defconfig)
       3.6 $ kmenuconfig
             > generate the menu of kernel config
       3.7 $ ksavedefconfig
             > save the kernel config to $TOP/kernel/arch/arm64/$KERNEL_DEFCONFIG
       3.8 $ flash
             > flash images with passing options to flash.sh
       3.9 $ flash_no_rootfs
             > flash all images excpet rootfs/APP partition, valid for Xavier and TX2
       3.10 $ flash_kernel
             > flash kernel partition, valid for Xavier
       3.11 $ update_kernel
             > update kernel on device by scp, valid for Nano, TX1 and TX2

    4. How to use normally
       4.1 Initial setup
            After download files with Jetpack, run below commands to setup others:
                $ . build/envsetup.sh
                $ l4tout_setup
                $ bspsetup
       4.2 Normally use
                $ . build/envsetup.sh    --> this need to be run in any new shell
                then you can build kernel or flash board with other commands.
