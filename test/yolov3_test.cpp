#include <iostream>
#include <opencv2/opencv.hpp>
#include <opencv2/core.hpp>
#include <opencv2/highgui.hpp>
#include <opencv2/imgproc.hpp>
#include <vitis/ai/yolov3.hpp>


#define CV_WAITKEY_SPACE  32
#define CV_WAITKEY_ESC    27
#define CV_WAITKEY_TAB     9
#define CV_WAITKEY_ENTER  13


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