[Vitis-AI 1.1 Flow for Avnet VITIS Platforms - Part 2](https://www.hackster.io/AlbertaBeef/vitis-ai-1-1-flow-for-avnet-vitis-platforms-part-2-f18be4)

ここもかなり参照することになる。
https://github.com/Xilinx/Vitis-AI/tree/master/VART

bspでpetalinux環境を構築。

```sh
# すでにダウンロード済みの場合は不要
cd ~/Download
wget -O sdk.sh https://www.xilinx.com/bin/public/openDownload?filename=sdk.sh
chmod +x sdk.sh

# DNNDK用の環境と分ける必要があるのか不明だが、とりあえず分けておく
~/Downloads/sdk.sh -d ~/work/petalinux_sdk_vai_1_1_vart
unset LD_LIBRARY_PATH
source ~/work/petalinux_sdk_vai_1_1_vart/environment-setup-aarch64-xilinx-linux
```

```sh
# ライブラリをsysrootにインストール
wget -O vitis_ai_2019.2-r1.1.0.tar.gz https://www.xilinx.com/bin/public/openDownload?filename=vitis_ai_2019.2-r1.1.0.tar.gz
tar -xzvf ~/Downloads/vitis_ai_2019.2-r1.1.0.tar.gz  -C ~/work/petalinux_sdk_vai_1_1_vart/sysroots/aarch64-xilinx-linux

# glogをsysrootにインストール、あとでインストールできるように   パッケージ化
curl -Lo glog-v0.4.0.tar.gz https://github.com/google/glog/archive/v0.4.0.tar.gz
tar -zxvf glog-v0.4.0.tar.gz
cd glog-0.4.0
mkdir build_for_petalinux
cd build_for_petalinux
unset LD_LIBRARY_PATH; source ~/work/petalinux_sdk_vai_1_1_vart/environment-setup-aarch64-xilinx-linux
cmake -DCPACK_GENERATOR=TGZ -DBUILD_SHARED_LIBS=on -DCMAKE_INSTALL_PREFIX=$OECORE_TARGET_SYSROOT/usr ..
make && make install
make package

# Xilinx/Vitis-AI/VART/samples を適当なところにコピー
mkdir <VART workspace>
cd <VART workspace>
cp -r ~/sources/Vitis-AI/VART/samples/* .

# なにかビルドしてみる(他のものも同じようにビルドできる。)
cd adas_detection
bash -x build.sh
```

SDカードイメージ
FIXME: 自分でつくったものとどう違うのか、要確認

* ultra96v2:  
    + http://avnet.me/Avnet-COMMON-Vitis-AI-1-1-image
    + http://avnet.me/avnet-ultra96v2-vitis-ai-1.1-image
* zcu104: https://www.xilinx.com/bin/public/openDownload?filename=xilinx-zcu104-dpu-v2019.2-v2.img.gz

ultra96用はすでにパッケージなど、いろいろ入れてくれている模様。

```sh
sudo dd bs=4M if=Avnet-ULTRA96V2-Vitis-AI-1-1-2020-05-15.img of=/dev/sd{X} status=progress conv=fsync
```

`Avnet-COMMON-Vitis-AI-1-1-2020-05-15`のほうは適当なアプリで展開してにBOOTパーテイションにコピー。

モデルパッケージ
コンパイル済みのモデルだが、DPU構成が固定と思われる。元記事でいうところのB2304_lr、B4096_hrに合わせたものだが、どう違うのか未確認。

* B2304_lr: B2304 DPU with low RAM usage http://avnet.me/vitis_ai_model_ULTRA96V2_2019.2-r1.1.1.deb
* B4096_hr: B4096 DPU with high RAM usage https://www.xilinx.com/bin/public/openDownload?filename=vitis_ai_model_ZCU104_2019.2-r1.1.0.deb

