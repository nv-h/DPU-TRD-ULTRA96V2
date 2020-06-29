[Vitis-AI 1.1 Flow for Avnet VITIS Platforms - Part 2](https://www.hackster.io/AlbertaBeef/vitis-ai-1-1-flow-for-avnet-vitis-platforms-part-2-f18be4)の内容をなぞる。これは、一応[Part 1 をなぞった記事](https://qiita.com/nv-h/items/7525c9319087a3f51755)の続きで、ハードウェアは同じものを使えるらしい。


# プリビルドされたSDカードイメージ

FIXME: 自分でつくったものとどう違うのか、要確認

* ultra96v2:  
    + http://avnet.me/Avnet-COMMON-Vitis-AI-1-1-image
    + http://avnet.me/avnet-ultra96v2-vitis-ai-1.1-image
* zcu104: https://www.xilinx.com/bin/public/openDownload?filename=xilinx-zcu104-dpu-v2019.2-v2.img.gz

ultra96用はすでにパッケージなど、いろいろ入れてくれている模様。以下でSDカードに書き込み。

```sh
sudo dd bs=4M if=Avnet-ULTRA96V2-Vitis-AI-1-1-2020-05-15.img of=/dev/sd{X} status=progress conv=fsync
```
`Avnet-COMMON-Vitis-AI-1-1-2020-05-15`のほうは適当なアプリで展開してにBOOTパーテイションにコピー。
起動後、手動で以下の各種インストール作業が必要。

```sh
cd /mnt/runtime/WAYLAND
dpkg -i libdrm-tests_2.4.94-r0_arm64.deb
cd /mnt/runtime/VART
tar -xzvf glog-0.4.0-Linux.tar.gz --strip-components=1 -C /usr
dpkg -i --force-all vitis-ai-runtime-1.1.2/unilog/aarch64/libunilog-1.1.0-Linux-build46.deb
dpkg -i vitis-ai-runtime-1.1.2/XIR/aarch64/libxir-1.1.0-Linux-build46.deb
dpkg -i vitis-ai-runtime-1.1.2/VART/aarch64/libvart-1.1.0-Linux-build48.deb
dpkg -i vitis-ai-runtime-1.1.2/Vitis-AI-Library/aarch64/libvitis_ai_library-1.1.0-Linux-build46.deb
cd /mnt/runtime
dpkg -i vitis_ai_model_ULTRA96V2_2019.2-r1.1.1.deb
```

これで、Vitis AI Libraryの環境は完成。それなりに簡単。ただし、ハードウェアを変えた場合は`xpfm`を作り直しが必要？よくわかっていないが、作り直し方は以下のようなtclでできる。(参考: [Using Xilinx Vitis for Embedded Hardware Acceleration](https://gpanders.com/blog/vitis-for-embedded-hardware-acceleration/))

```tcl
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
```


# トレーニング済みのモデルパッケージ

コンパイル済みのモデルだが、DPU構成が固定と思われる。元記事でいうところのB2304_lr、B4096_hrに合わせたものだが、自分で作ったものとどう違うのかは未確認。モデルのコンパイルでかなり罠があるようなのでこれらを使うのが無難と思われる。

* B2304_lr: B2304 DPU with low RAM usage http://avnet.me/vitis_ai_model_ULTRA96V2_2019.2-r1.1.1.deb
* B4096_hr: B4096 DPU with high RAM usage https://www.xilinx.com/bin/public/openDownload?filename=vitis_ai_model_ZCU104_2019.2-r1.1.0.deb

これらは、ターゲットボードで別途インストールする必要がある。


# VART環境構築

ここ↓も参照しながらVARTの環境を構築する。
https://github.com/Xilinx/Vitis-AI/tree/master/VART

まずは、sysroot環境を作る。

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

そしてライブラリ本体(と思われる)をsysroot環境にインストール。

```sh
# ライブラリをsysrootにインストール
wget -O vitis_ai_2019.2-r1.1.0.tar.gz https://www.xilinx.com/bin/public/openDownload?filename=vitis_ai_2019.2-r1.1.0.tar.gz
tar -xzvf ~/Downloads/vitis_ai_2019.2-r1.1.0.tar.gz  -C ~/work/petalinux_sdk_vai_1_1_vart/sysroots/aarch64-xilinx-linux

# glogをsysrootにインストール、あとでボードにインストールできるように   パッケージ化
curl -Lo glog-v0.4.0.tar.gz https://github.com/google/glog/archive/v0.4.0.tar.gz
tar -zxvf glog-v0.4.0.tar.gz
cd glog-0.4.0
mkdir build_for_petalinux
cd build_for_petalinux
unset LD_LIBRARY_PATH; source ~/work/petalinux_sdk_vai_1_1_vart/environment-setup-aarch64-xilinx-linux
cmake -DCPACK_GENERATOR=TGZ -DBUILD_SHARED_LIBS=on -DCMAKE_INSTALL_PREFIX=$OECORE_TARGET_SYSROOT/usr ..
make && make install
make package
```

そして、VARTのサンプルをビルドしてみる。ソースを見た感じはDNNDKと大差ない。

```sh
# Xilinx/Vitis-AI/VART/samples を適当なところにコピー
mkdir <VART workspace>
cd <VART workspace>
cp -r ~/sources/Vitis-AI/VART/samples/* .

# なにかビルドしてみる(他のものも同じようにビルドできる。)
cd adas_detection
bash -x build.sh
```

# Vitis AI Libraryを使ったアプリの作成

[Vitis-AI/Vitis-AI-Library/overview/samples](https://github.com/Xilinx/Vitis-AI/tree/master/Vitis-AI-Library/overview/samples)以下にサンプルがあるので、これを参考にする。
ただし、サンプルアプリケーションの実装がほとんど[benchmark/include/vitis/ai/demo.hpp](https://github.com/Xilinx/Vitis-AI/blob/master/Vitis-AI-Library/benchmark/include/vitis/ai/demo.hpp)に依存している。マルチスレッドのサンプルとかはC++初心者向けにもっとポータブルなものを置いておいてほしかった。

C++なんてほとんど触ったことがないので、練習もかねて試しにYoloV3のWebカメラでの物体検知を愚直に動かしてみる。

```cpp
/*
 * Copyright 2019 Xilinx Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
#include <iostream>
#include <opencv2/opencv.hpp>
#include <opencv2/core.hpp>
#include <opencv2/highgui.hpp>
#include <opencv2/imgproc.hpp>
#include <vitis/ai/yolov3.hpp>

#define CV_WAITKEY_ESC    27

/*
 *   The color loops every 27 times,
 *    because each channel of RGB loop in sequence of "0, 127, 254"
 */
static cv::Scalar getColor(int label) {
  int c[3];
  for (int i = 1, j = 0; i <= 9; i *= 3, j++) {
    c[j] = ((label / i) % 3) * 127;
  }
  return cv::Scalar(c[2], c[1], c[0]);
}

/*
 * Add bboxes to image
 */
static cv::Mat process_result(cv::Mat &image,
                              const vitis::ai::YOLOv3Result &result) {
  for (const auto bbox : result.bboxes) {
    int label = bbox.label;
    float xmin = bbox.x * image.cols + 1;
    float ymin = bbox.y * image.rows + 1;
    float xmax = xmin + bbox.width * image.cols;
    float ymax = ymin + bbox.height * image.rows;
    float confidence = bbox.score;
    if (xmax > image.cols) xmax = image.cols;
    if (ymax > image.rows) ymax = image.rows;

    cv::rectangle(image, cv::Point(xmin, ymin), cv::Point(xmax, ymax),
                  getColor(label), 1, 1, 0);
  }
  return image;
}

int main(int argc, char *argv[]) {

    cv::VideoCapture cap(std::atoi(argv[2]));
    if (!cap.isOpened()) {
        std::cout << "Could not opened: /dev/video" << argv[2] <<  std::endl;
        return -1;
    }

    auto yolo = vitis::ai::YOLOv3::create(argv[1], true);
    cv::Mat img;
    vitis::ai::YOLOv3Result results;

    while (cap.read(img)) {
        results = yolo->run(img);

        img = process_result(img, results);

        cv::imshow("", img);
        if (cv::waitKey(1) == CV_WAITKEY_ESC) {
            break;
        }
    }

    cap.release();
    cv::destroyAllWindows();
}
```

上記のコードを、**ボード上で**コンパイルする。(横着したが、クロスコンパイルも可能)

```sh
g++ -std=c++11 -I. -o yolov3_test yolov3_test.cpp -lopencv_core -lopencv_video -lopencv_videoio -lopencv_imgproc -lopencv_imgcodecs -lopencv_highgui -lvitis_ai_library-yolov3 -pthread
```

`yolov3_test <model> <video num>` で動くはず。

DNNDKと比較するとかなりコード量は圧縮されるし、モデルをあまり気にしなくてもいいし差し替えも楽。
ただ、Ultra96v2でYolo v3は結構重たくて数fps程度しか性能が出ない。