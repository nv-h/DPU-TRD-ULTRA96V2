#!/opt/Xilinx/Vitis/2019.2/bin/xsct

platform create -name ultra96v2_oob_2019_2_ai_pfm \
-hw ./petalinux/ultra96v2_oob_2019_2_ai/project-spec/hw-description/system.xsa \
-proc psu_cortexa53 -os linux -no-boot-bsp -prebuilt -out .

domain config -image ./petalinux/ultra96v2_oob_2019_2_ai/images/linux
# FIXME: 相対パスで指定したい(引数でsh展開とかが必要なのでもう一つスクリプトが必要？)
domain config -sysroot /home/saido/work/petalinux_sdk_vai_1_1_vart/sysroots/aarch64-xilinx-linux
domain config -boot ./petalinux/ultra96v2_oob_2019_2_ai/images/linux
domain config -bif linux.bif

platform generate