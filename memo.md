ultra96v2向けに良さそうなチュートリアルがあったので多少モディファイしつつ、疑問点を調べつつなぞってみる。

参考にする記事: [Vitis-AI 1.1 Flow for Avnet VITIS Platforms - Part 1](https://www.hackster.io/AlbertaBeef/vitis-ai-1-1-flow-for-avnet-vitis-platforms-part-1-007b0e)

Part 1で低レベルAPIのDNNDKを使い、Part 2ではより抽象化されたVART+Vitis AI libraryを使う。
ひとまずPart 1を実施する。petalinuxの生成物はダウンロードしたものをそのまま使うので、petalinux環境には触れていないが、基本的には[Vitis_Embedded_Platform_Sourceのdpu付きデザイン](https://github.com/Xilinx/Vitis_Embedded_Platform_Source/tree/master/Xilinx_Official_Platforms/zcu104_dpu)のpetalinux環境を踏襲しているっぽい。


[TOC]


# Setup

* Vitis 2019.2 Unified Software Platform
* petalinux 2019.2
* Xilinx Runtime (XRT) 2019.2
* Docker
* Vitis-AI v1.1

Vitis/petalinux 2019.2はダウンロードページ([Vitis 2019.2](https://www.xilinx.com/support/download/index.html/content/xilinx/en/downloadNav/vitis/2019-2.html) / [petalinux 2019.2](https://www.xilinx.com/support/download/index.html/content/xilinx/en/downloadNav/embedded-design-tools/2019-2.html))からダウンロードして適当な場所にインストール。  
XRTは[Installing Xilinx Runtime](https://www.xilinx.com/html_docs/xilinx2019_2/vitis_doc/pjr1542153622642.html)を参考にインストール。日本語を見たい場合は`www`を`japan`にすると良いが日本語版だけリンクが間違ってたりするので注意。  
Dockerは[Vitis AIの中のInstall Docker](https://github.com/Xilinx/Vitis-AI/blob/v1.0/doc/install_docker/README.md)を参照してインストールする。

Vitis-AIはgithubからクローンするが、今回はtagはチェックアウトせず、masterを使用した。今後v1.2などがリリースされた際は注意が必要かもしれない。


```sh
cd ~/sources # 今回はここにクローンする。
git clone https://github.com/Xilinx/Vitis-AI
cd Vitis-AI
# このチュートリアル特有の環境変数を設定。
export VITIS_AI_HOME="$PWD"
```

# Avnet Vitis platforms

Avnetが用意してくれている"ハードウェア"プラットフォーム(HWプラットフォーム)をダウンロード。  

```sh
cd ~/sources
mkdir Avnet
cd Avnet
# 全部は要らないかも
git clone https://github.com/Avnet/bdf
git clone -b 2019.2 https://github.com/Avnet/hdl
git clone -b 2019.2 https://github.com/Avnet/petalinux
git clone https://github.com/Avnet/vitis

# ULTRA96V2_2019_2.tar.xz 3.2GByteあり、日本からは回線が細いので注意
wget http://avnet.me/ultra96v2-vitis-2019.2
cd vitis/platform_repo
tar xvf ULTRA96V2_2019_2.tar.xz # vitis/platform_repoに展開(ULTRA96V2ができる)
# 上記は、以下の操作でも生成できるっぽい
# (petalinuxのインストールディレクトリが決め打ちなのでそこだけ注意)
# cd vitis
# make ultra96v2_oob

# あとの方で実行するVitisのフローのときに、この環境変数が必要らしい
export SDX_PLATFORM=~/sources/Avnet/vitis/platform_repo/ULTRA96V2/ULTRA96V2.xpfm
```

今回はHWプラットフォーム自体の構築は行わないが、以下の内容を参考にするとゼロからHWプラットフォームを構築できる。  
ここで言っているHWプラットフォームとは、いわゆるVivadoプロジェクトのことだが、いつからかVitis(旧SDx)向けの定義を追加できるようになっている。

* クロックとリセットのIP: [Creating the Hardware Component # Adding IP Blocks](https://www.xilinx.com/html_docs/xilinx2019_2/vitis_doc/Chunk373975992.html#vma1570652698630)  
	+ Clocking Wizard IPで適当にクロックを生成して、各クロックにProcesser System Reset IPをくっつける。
	+ ここでベースになるクロック`aclk`と2倍の周波数のクロック`ap_clk2`の組み合わせをいくつか作っておく。  
		これはリソース消費などの関係でタイミングメットしなくなったりちょっと性能を上げたい、などの状況に対応するため。


* クロックのプラットフォームインターフェイス定義: [Configuring Platform Interface Properties # Declaring Clocks](https://www.xilinx.com/html_docs/xilinx2019_2/vitis_doc/Chunk440719349.html#jah1512251513210)  
	`id`なるものでVitisが使うクロックを指定するので`id`と作ったクロックを紐づける必要がある。  
	GUI上でポチポチすることもできるが、以下のようにtclで実行することもできるっぽい。

```tcl
set_property PFM.CLOCK {
PL_CLK0 {id "0" is_default "true" proc_sys_reset "proc_sys_reset_0" status "fixed"}
PL_CLK1 {id "1" is_default "false" proc_sys_reset "proc_sys_reset_1" status "fixed"}
PL_CLK2 {id "2" is_default "false" proc_sys_reset "proc_sys_reset_2" status "fixed"}
PL_CLK3 {id "3" is_default "false" proc_sys_reset "proc_sys_reset_3" status "fixed"}
} [get_bd_cells /zynq_ultra_ps_e_0]
```

* AXIインターコネクトの定義: [Configuring Platform Interface Properties # Declaring AXI Ports](https://www.xilinx.com/html_docs/xilinx2019_2/vitis_doc/Chunk440719349.html#acz1512251511710)  
	こちらもGUI上でポチポチできるが、[Hardware Component Requirements](https://www.xilinx.com/html_docs/xilinx2019_2/vitis_doc/Chunk1408845220.html#itc1511211457306)を参考に、以下のように定義できる。

```tcl
set_property PFM.AXI_PORT {
M_AXI_HPM1_FPD {memport "M_AXI_GP"} 
S_AXI_HPC0_FPD {memport "S_AXI_HPC" sptag "HPC0" memory "ps_e HPC0_DDR_LOW"}  
S_AXI_HPC1_FPD {memport "S_AXI_HPC" sptag "HPC1" memory "ps_e HPC1_DDR_LOW"}  
S_AXI_HP0_FPD {memport "S_AXI_HP" sptag "HP0" memory "ps_e HP0_DDR_LOW"}  
S_AXI_HP1_FPD {memport "S_AXI_HP" sptag "HP1" memory "ps_e HP1_DDR_LOW"}  
S_AXI_HP2_FPD {memport "S_AXI_HP" sptag "HP2" memory "ps_e HP2_DDR_LOW"}
} [get_bd_cells /ps_e]
```

* 割り込みとか: [Platform Add-Ons # Adding Kernel Interrupt Support](https://www.xilinx.com/html_docs/xilinx2019_2/vitis_doc/Chunk760319822.html#ojl1571886923345)  
	割り込み入力を0固定した割り込みコントローラを構築する必要があるっぽい。(Vitisでよろしくやってくれればいいのに)

* その他、以下のような細かい作業が必要だが、上記のリンク先付近を探ればやるべきことがわかる。(が、きちんとまとまってはいない)  
	+ `set_property platform.design_intent.~`が必要
	+ `write_hw_platform`するときはIPとかを中に含めることが必要
	+ `dynamic_postlink.tcl`でなんかの処理が必要
	+ (ほかにもいろいろあるので、後述の通りベースプラットフォームを拾ってきてカスタムするのが楽っぽい)

zcu104のAI向けのベースHWプラットフォームのソースが[githubのXilinx/Vitis_Embedded_Platform_Source](https://github.com/Xilinx/Vitis_Embedded_Platform_Source/tree/master/Xilinx_Official_Platforms/zcu104_dpu)に公開されているのでこれをベースにカスタム、比較するといいかもしれない。  
後述のDPU-TRDを実行するためのpetalinux環境に関してもここに格納されているので、カスタマイズする場合はこれを使えばよい。(デバイスツリーなど考慮するべき内容はいろいろあるが)

とりあえず、ここで作るHWプラットフォームでの、必要になる情報は以下のようなもの。

クロックに関してはidと周波数が分かればよい。今回使用するAvnetの`ULTRA96V2`というHWプラットフォームは以下の定義になっている。今回はid0の150MHzとid1の300MHzを使用する。  
デバイスによってはもっと高い周波数でも大丈夫な模様。

| id |     Frequency     |
|----|-------------------|
|  0 | 150 MHz (default) |
|  1 | 300 MHz           |
|  2 | 75 MHz            |
|  3 | 100 MHz           |
|  4 | 200 MHz           |
|  5 | 400 MHz           |
|  6 | 600 MHz           |


AXIインターコネクトに関しては、一つのDPUの対してキャッシュ付きの`HPC#`が1本とキャッシュ無しの`HP#`が2本必要になる(詳細はよくわかっていない)。ただし、通常のVivadoと同様に共有は可能になっているので重複して指定することも可能らしい。  
Vitisからは`sptag`というものでアクセスする。今回は以下のようになっていると思う。

|      name      | sptag |
|----------------|-------|
| S_AXI_HPC0_FPD | HPC0  |
| S_AXI_HPC1_FPD | HPC1  |
| S_AXI_HP0_FPD  | HP0   |
| S_AXI_HP1_FPD  | HP1   |
| S_AXI_HP2_FPD  | HP2   |
| S_AXI_HP3_FPD  | HP3   |


# Step 1 - Build the Hardware Project

Vitis-AIリポジトリにある、DPU-TRDを改変して利用するらしい。  
もとの記事ではクローンしたVitis-AIリポジトリ内で作業していたが、今回は`~/work`ディレクトリを用意して、ここで作業することにする。

```sh
cd ~/work
mkdir ultra96v2_vitis_flow_tutorial_1 # なんか適当な名前
cd ultra96v2_vitis_flow_tutorial_1
cp -r $VITIS_AI_HOME/DPU-TRD ./DPU-TRD-ULTRA96V2
export TRD_HOME=~/work/ultra96v2_vitis_flow_tutorial_1/DPU-TRD-ULTRA96V2
```


以下2つの設定ファイルを編集する。

* `$TRD_HOME/prj/Vitis/dpu_conf.vh`: DPUの構成を小さいものに変更
* `$TRD_HOME/prj/Vitis/config_file/prj_config`: Vivado(HWプラットフォーム)構成に合わせて修正

```diff
diff --git a/prj/Vitis/config_file/prj_config b/prj/Vitis/config_file/prj_config
index 88cbd02..eae9db2 100644
--- a/prj/Vitis/config_file/prj_config
+++ b/prj/Vitis/config_file/prj_config
@@ -17,22 +17,17 @@
 
 [clock]
 
-freqHz=300000000:dpu_xrt_top_1.aclk
-freqHz=600000000:dpu_xrt_top_1.ap_clk_2
-freqHz=300000000:dpu_xrt_top_2.aclk
-freqHz=600000000:dpu_xrt_top_2.ap_clk_2
+id=0:dpu_xrt_top_1.aclk
+id=1:dpu_xrt_top_1.ap_clk_2
 
 [connectivity]
 
 sp=dpu_xrt_top_1.M_AXI_GP0:HPC0
 sp=dpu_xrt_top_1.M_AXI_HP0:HP0
 sp=dpu_xrt_top_1.M_AXI_HP2:HP1
-sp=dpu_xrt_top_2.M_AXI_GP0:HPC0
-sp=dpu_xrt_top_2.M_AXI_HP0:HP2
-sp=dpu_xrt_top_2.M_AXI_HP2:HP3
 
 
-nk=dpu_xrt_top:2
+nk=dpu_xrt_top:1
 
 [advanced]
 misc=:solution_name=link
diff --git a/prj/Vitis/dpu_conf.vh b/prj/Vitis/dpu_conf.vh
index ec5be48..3105ed2 100644
--- a/prj/Vitis/dpu_conf.vh
+++ b/prj/Vitis/dpu_conf.vh
@@ -39,7 +39,7 @@
 // | `define B4096                 
 // |------------------------------------------------------|
 
-`define B4096 
+`define B2304 
 
 // |------------------------------------------------------|
 // |If the FPGA has Uram. You can define URAM_EN parameter               

```


DPUが有効になっているハードウェアをビルドする。

```sh
cd $TRD_HOME/prj/Vitis
# ここでSDX_PLATFORM環境変数が必要になる。
#   export SDX_PLATFORM=~/sources/Avnet/vitis/platform_repo/ULTRA96V2/ULTRA96V2.xpfm
# また、Vivadoなどのコマンドを実行するので事前にsettings64.shを実行しておく。
#   source /opt/Xilinx/Vitis/2019.2/settings64.sh # インストールパスによる
#   source /opt/xilinx/xrt/setup.sh # こっちも必要(`ERROR: XILINX_XRT is not defined, ...`とか言われる)
make KERNEL=DPU DEVICE=ULTRA96V2 # まぁまぁ時間がかかる
```

完了すると、以下に欲しい物ができている。

```
$ tree binary_container_1/sd_card
binary_container_1/sd_card
├── BOOT.BIN
├── README.txt
├── ULTRA96V2.hwh
├── dpu.xclbin
├── image.ub
└── rootfs.tar.gz
```

# Step 2 - Compile the Models from the Xilinx Model Zoo

事前にXilinxが用意しているモデルをダウンロードしておく。(`Vitis-AI/AI-Model-Zoo.het_model.sh`を使用しても良いが今回は、zipファイルを使い回す予定がありそうなので手動でダウンロードした)

```sh
cd ~/Downloads
wget https://www.xilinx.com/bin/public/openDownload?filename=all_models_1.1.zip
mv openDownload?filename=all_models_1.1.zip all_models_1.1.zip
mkdir all_models_1.1
cd all_models_1.1
unzip ../all_models_1.1.zip
```

Docker環境でコンパイルするが、準備のため`$VITIS_AI_HOME/docker_run.sh`を編集する。ここまでの手順通りやっていると、`~/sources/Vitis-AI/docker_run.sh`に相当する。  
プロンプトや、多少のバグを修正。GPUあり環境で実行するためには、事前に`docker_build_gpu.sh`を実行しておく必要がある。  
変更内容は、上記でさっきダウンロードした`all_models_1.1`を見えるようにするためのもの。


```diff
diff --git a/docker_run.sh b/docker_run.sh
index d792da0..c7810c7 100755
--- a/docker_run.sh
+++ b/docker_run.sh
@@ -1,29 +1,10 @@
 #!/bin/bash
 
-sed -n '1, 5p' ./docker/PROMPT.txt
-read -n 1 -s -r -p "Press any key to continue..." key
-
-sed -n '5, 15p' ./docker/PROMPT.txt
-read -n 1 -s -r -p "Press any key to continue..." key
-
-sed -n '15, 24p' ./docker/PROMPT.txt
-read -n 1 -s -r -p "Press any key to continue..." key
-
-sed -n '24, 53p' ./docker/PROMPT.txt
-read -n 1 -s -r -p "Press any key to continue..." key
-
-sed -n '53, 224p' ./docker/PROMPT.txt
-read -n 1 -s -r -p "Press any key to continue..." key
-
-sed -n '224, 231p' ./docker/PROMPT.txt
-read -n 1 -s -r -p "Press any key to continue..." key
-
-
 confirm() {
   echo -n "Do you agree to the terms and wish to proceed [y/n]? "
   read REPLY
   case $REPLY in
-    [Yy]) break ;;
+    [Yy]) ;;
     [Nn]) exit 0 ;;
     *) confirm ;;
   esac
@@ -85,6 +66,7 @@ elif [[ $IMAGE_NAME == *"gpu"* ]]; then
     $docker_devices \
     -v /opt/xilinx/dsa:/opt/xilinx/dsa \
     -v /opt/xilinx/overlaybins:/opt/xilinx/overlaybins \
+    -v ~/Downloads:/Downloads \
     -e USER=$user -e UID=$uid -e GID=$gid \
     -v $HERE:/workspace \
     -w /workspace \
@@ -99,6 +81,7 @@ else
     $docker_devices \
     -v /opt/xilinx/dsa:/opt/xilinx/dsa \
     -v /opt/xilinx/overlaybins:/opt/xilinx/overlaybins \
+    -v ~/Downloads:/Downloads \
     -e USER=$user -e UID=$uid -e GID=$gid \
     -v $HERE:/workspace \
     -w /workspace \
```

Dockerイメージを起動する。

```sh
cd $TRD_HOME
~/sources/Vitis-AI/docker_run.sh xilinx/vitis-ai-cpu:latest
```

Docker内で、まずは`dlet`というXilinxのツールで`.hwh`ファイルを`.dcf`ファイルに変換する。
(dletについては、[DNNDK User Guide UG1327 (v1.6)](https://www.xilinx.com/support/documentation/sw_manuals/ai_inference/v1_6/ug1327-dnndk-user-guide.pdf)に内容が書いてある)

> DLet is host tool designed to parse and extract various DPU configuration parameters from DPU
> Hardware Handoff file HWH generated by Vivado. It works together with DNNC to support model 
> compilation under various DPU configurations. Also, the DPU IP used in the Vivado project should come
> from Edge AI Targeted Reference Designs (DPU TRD) v3.0 or higher version.

```sh
conda activate vitis-ai-caffe # 以降、プロンプトに`(vitis-ai-caffe)`が追加される
mkdir modelzoo
cd modelzoo
cp ../prj/Vitis/binary_container_1/sd_card/ULTRA96V2.hwh .
dlet -f ULTRA96V2.hwh
mv dpu*.dcf ULTRA96V2.dcf # 名前が日付+時間になり扱いづらいのでリネーム
```

コンパイルするのに必要な`custom.json`ファイルを作成、出力先も作成しておく。

```sh
echo "{\"target\": \"dpuv2\", \"dcf\": \"./ULTRA96V2.dcf\", \"cpu_arch\": \"arm64\"}" > custom.json
mkdir compiled_output
```

コンパイルでは、モデルの場所などをいちいち入力する必要があるので、以下のようなスクリプトで省力化。

```sh
# caffeモデル用
cat <<'EOL' > compile_cf_model.sh
#!/bin/bash

model_name=$1
modelzoo_name=$2
vai_c_caffe \
--prototxt /Downloads/all_models_1.1/${modelzoo_name}/quantized/deploy.prototxt \
--caffemodel /Downloads/all_models_1.1/${modelzoo_name}/quantized/deploy.caffemodel \
--arch ./custom.json \
--output_dir ./compiled_output/${modelzoo_name} \
--net_name ${model_name} \
--options "{'mode': 'normal'}"
EOL

# tensorflowモデル用
cat <<'EOL' > compile_tf_model.sh
#!/bin/bash

model_name=$1
modelzoo_name=$2
vai_c_tensorflow \
--frozen_pb /Downloads/all_models_1.1/${modelzoo_name}/quantized/deploy_model.pb \
--arch ./custom.json \
--output_dir ./compiled_output/${modelzoo_name} \
--net_name ${model_name}
EOL
```

例えば、顔認識であれば以下のようにコンパイルできる。(元記事の例だったので以降はこれですすめる)


```sh
conda activate vitis-ai-caffe
source ./compile_cf_model.sh densebox cf_densebox_wider_360_640_1.11G

# なんとなくtf_yolov3_vocもコンパイルしてみる
conda activate vitis-ai-tensorflow
source ./compile_tf_model.sh tf_yolov3_voc tf_yolov3_voc_416_416_65.63G

# Docker環境でやることは以上で終わりなので、他に用がなければexitやCTRL-Dで抜ける
# ※次のフローからはホスト上で行う。
```

出力は以下のようになる。

```
./modelzoo/
├── ULTRA96V2.dcf
├── ULTRA96V2.hwh
├── compile_cf_model.sh
├── compile_tf_model.sh
├── compiled_output
│   ├── cf_densebox_wider_360_640_1.11G
│   │   ├── densebox_kernel_graph.gv
│   │   └── dpu_densebox.elf
│   └── tf_yolov3_voc_416_416_65.63G
│       ├── dpu_yolov3_voc.elf
│       └── yolov3_voc_kernel_graph.gv
└── custom.json

3 directories, 9 files
```

# Step 3 - Compile the AI Applications (for DNNDK)

今回はDPU向けの低レベルAPIであるDNNDKを使用する。  
高レベルなものは、Vitis-AI RunTime (VART) APIとVitis-AI-Libraryが存在する。

Vitis-AI 1.1 DNNDKに特化した(と思われる)SDK環境をダウンロードして適当な場所に展開、環境変数を設定する。  
多分、petalinuxプロジェクトから吐き出したsysroot環境だと思われる。

```sh
cd ~/Downloads
wget -O sdk.sh https://www.xilinx.com/bin/public/openDownload?filename=sdk.sh
chmod +x sdk.sh
./sdk.sh -d ~/work/petalinux_sdk_vai_1_1_dnndk
unset LD_LIBRARY_PATH
source ~/work/petalinux_sdk_vai_1_1_dnndk/environment-setup-aarch64-xilinx-linux

# 上記sysroot内ににDNNDKをインストール(APIを使えるようにする)
# 推測だが、非開示のDPU情報をOSSのpetalinuxと分けるための措置だと思われる。
wget -O vitis-ai_v1.1_dnndk.tar.gz https://www.xilinx.com/bin/public/openDownload?filename=vitis-ai_v1.1_dnndk.tar.gz
tar -xvzf vitis-ai_v1.1_dnndk.tar.gz
cd vitis-ai_v1.1_dnndk
./install.sh $SDKTARGETSYSROOT

# DNNDKの画像とか動画とかもダウンロードしておく(場所はここでいいか要確認)
wget -O vitis-ai_v1.1_dnndk_sample_img.tar.gz https://www.xilinx.com/bin/public/openDownload?filename=vitis-ai_v1.1_dnndk_sample_img.tar.gz
tar -xvzf vitis-ai_v1.1_dnndk_sample_img.tar.gz # ---> vitis_ai_dnndk_samples
```

DNNDKのサンプルファイルをローカルの開発環境上にコピーする。

```sh
cd $TRD_HOME
cp -r ~/sources/Vitis-AI/mpsoc/vitis_ai_dnndk_samples .
cd vitis_ai_dnndk_samples/face_detection/
mkdir model_for_ULTRA96V2
```

`src/main.cc`ファイルを編集。以下の二行を追加。

```diff
diff --git a/vitis_ai_dnndk_samples/face_detection/src/main.cc b/vitis_ai_dnndk_samples/face_detection/src/main.cc
index eeca404..2d2498d 100755
--- a/vitis_ai_dnndk_samples/face_detection/src/main.cc
+++ b/vitis_ai_dnndk_samples/face_detection/src/main.cc
@@ -207,6 +207,8 @@ void faceDetection(DPUKernel *kernel) {
         cerr << "Open camera error!" << endl;
         exit(-1);
     }
+    camera.set(CV_CAP_PROP_FRAME_WIDTH,640);
+    camera.set(CV_CAP_PROP_FRAME_HEIGHT,480);

     // We create three different threads to do face detection:
     // 1. Reader thread  : Read images from camera and put it to the input queue;
```

make用にモデルディレクトリを作ってビルドする。

```sh
cp -r model_for_ULTRA96V2 model
make
```

`tf_yolov3_voc`は`elf`ファイルを変換して`libdpumodeltf_yolov3_voc.so`にする必要がある。  
この.soファイルのコンパイル方法は、
[Vitis AI User Documentation / DPU Shared Library](https://www.xilinx.com/html_docs/vitis_ai/1_1/sti1576145755426.html?hl=.so)に書いてあった。  
以下でよいと思う。

```sh
cd vitis_ai_dnndk_samples/tf_yolov3_voc_py/
mkdir model_for_ULTRA96V2
# source ~/work/petalinux_sdk_vai_1_1_dnndk/environment-setup-aarch64-xilinx-linux
aarch64-xilinx-linux-gcc --sysroot=$SDKTARGETSYSROOT \
-fPIC -shared ./model_for_ULTRA96V2/dpu_tf_yolov3_voc.elf \
-o ./model_for_ULTRA96V2/libdpumodeltf_yolov3_voc.so
cp ./model_for_ULTRA96V2/libdpumodeltf_yolov3_voc.so .
```


# Step 4 - Create the SD card

各所から必要なものを集めてくる。

```sh
cd $TRD_HOME
mkdir sdcard
cp prj/Vitis/binary_container_1/sd_card/* sdcard/.
cp -r ./vitis_ai_dnndk_samples ./sdcard/.
mkdir sdcard/runtime
cp -r ~/Downloads/vitis-ai_v1.1_dnndk sdcard/runtime/.
```

`sdcard`の中身をSDカードの第一パーティション(vfat)の中にコピー。  
`sdcard/rootfs.tar.gz`の中身を第二パーティション(ext4)の中にコピー。


# Step 5 - Execute the AI applications on hardware

動作確認に必要なもの

* さっき作ったSDカード
* ultra96v2ボードと適当な電源
* [Ultra96 USB-to-JTAG/UART Pod](https://www.avnet.com/shop/japan/products/avnet-engineering-services/aes-acc-u96-jtag-3074457345636446168/)とMicroUSBケーブルとホストPC
* Mini Displayport経由で映るモニタ(今回は適当なVGA変換アダプタを使用; アダプタにより相性があるかもしれない)
* USB Webカメラ(今回はLogicool C615nを使用)
* (USBマウスとUSBキーボード)


上記を全部接続して、電源ボタンを押して起動したらUARTで起動ログなどが表示される。また、ディスプレイにchromiumの画面が表示されているはず。(Matchboxの画面)
ユーザ名`root`、パスワード`root`でログイン。

まずはDNNDKの実行環境などを準備する。今回、rootfsをSDカード上に作成しているのでこの操作は一回だけ実行すればよい。

```sh
cd /run/media/mmcblk0p1 # 自動的にマウントされている。SDカードマウントポイント
cp dpu.xclbin /usr/lib/. # xclbinというPLデータとDPU情報などを格納したファイルを所定の場所へ格納
cd runtime/vitis-ai_v1.1_dnndk # DNNDKの置き場所へ行って、
source ./install.sh            # インストール

# pip3がないとか言われても今回は気にしなくていい
# 再ログインを求められたら、root/rootで再ログイン

dexplorer --whoami # DPU情報を表示(DNNDKの動作確認)
```

顔認識デモを動かしてみる。

```sh
export DISPLAY=:0.0                 # xrandrにディスプレイを認識させるために必要
xrandr --output DP-1 --mode 640x480 # ディスプレイ解像度を変更(顔認識デモに合わせる)

# デモ実行
cd /run/media/mmcblk0p1/vitis_ai_dnndk_samples/face_detection
./face_detection
```

これで動くはず。


一緒に作っておいた`tf_yolov3_voc_py`は固定の画像で動かすものらしい。
[DPU-PYNQのエッジサンプル](https://github.com/Xilinx/DPU-PYNQ/tree/master/pynq_dpu/edge/notebooks)を見るとn2cubeの使い方がなんとなくわかるかも。


