#include <cuda_runtime.h>
#include <stdio.h>

#include <iostream>
#include <opencv2/core.hpp>
#include <opencv2/highgui.hpp>
#include <opencv2/imgcodecs.hpp>
#include <opencv2/imgproc.hpp>
#include <string>

__device__ float pixel(uint8_t* map, int x, int y, int width, int height,
                       int step, int offset) {
  return (float)map[y * (width * step) + x * step + offset];
}

__device__ float Rgb2Y(float r0, float g0, float b0) {
  return (0.257f * r0 + 0.504f * g0 + 0.098f * b0 + 16.0f);
}

__device__ float Rgb2U(float r0, float g0, float b0) {
  return (-0.148f * r0 - 0.291f * g0 + 0.439f * b0 + 128.0f);
}

__device__ float Rgb2V(float r0, float g0, float b0) {
  return (0.439f * r0 - 0.368f * g0 - 0.071f * b0 + 128.0f);
}

__global__ void BGR2NV12(uint8_t* bgr, uint8_t** nv12, int width, int height) {
  int tid = blockIdx.x * blockDim.x + threadIdx.x;
  int x = tid % width;
  int y = tid / width;

  if (tid >= width * height) return;

  /*
   *  focus on left-top value
   *    O X O X O X
   *    X X X X X X
   *    O X O X O X
   *    X X X X X X
   *
   *  calc r00 g00 b00 -> y00, u00, v00
   *       r10 g10 b10 -> y10, u10, v10
   *       r01 g01 b01 -> y01, u01, v01
   *       r11 g11 b11 -> y11, u11, v11
   *
   *       --->  y = sum(Y) / 4
   *       --->  u = sum(U) / 4
   *       --->  v = sum(V) / 4
   *
   *  Standard NV12 |  Standard NV21
   *  YYYY          |  YYYY
   *  YYYY          |  YYYY
   *  UVUV          |  VUVU
   *
   */
  if (y % 2 == 0 && (x) % 2 == 0) {
    float r00 = pixel(bgr, x, y, width, height, 3, 2);
    float g00 = pixel(bgr, x, y, width, height, 3, 1);
    float b00 = pixel(bgr, x, y, width, height, 3, 0);

    float r01 = pixel(bgr, x + 1, y, width, height, 3, 2);
    float g01 = pixel(bgr, x + 1, y, width, height, 3, 1);
    float b01 = pixel(bgr, x + 1, y, width, height, 3, 0);

    float r11 = pixel(bgr, x + 1, y + 1, width, height, 3, 2);
    float g11 = pixel(bgr, x + 1, y + 1, width, height, 3, 1);
    float b11 = pixel(bgr, x + 1, y + 1, width, height, 3, 0);

    float r10 = pixel(bgr, x, y + 1, width, height, 3, 2);
    float g10 = pixel(bgr, x, y + 1, width, height, 3, 1);
    float b10 = pixel(bgr, x, y + 1, width, height, 3, 0);

    float y00 = Rgb2Y(r00, g00, b00);
    float y01 = Rgb2Y(r01, g01, b01);
    float y10 = Rgb2Y(r10, g10, b10);
    float y11 = Rgb2Y(r11, g11, b11);

    float u00 = Rgb2U(r00, g00, b00);
    float u01 = Rgb2U(r01, g01, b01);
    float u10 = Rgb2U(r10, g10, b10);
    float u11 = Rgb2U(r11, g11, b11);

    float v00 = Rgb2V(r00, g00, b00);
    float v01 = Rgb2V(r01, g01, b01);
    float v10 = Rgb2V(r10, g10, b10);
    float v11 = Rgb2V(r11, g11, b11);

    float u0 = (u00 + u01 + u10 + u11) * 0.25f;
    float v0 = (v00 + v01 + v10 + v11) * 0.25f;

    nv12[0][y * width + x] = (unsigned char)(y00 + 0.5f);
    nv12[0][y * width + x + 1] = (unsigned char)(y01 + 0.5f);
    nv12[0][(y + 1) * width + x] = (unsigned char)(y10 + 0.5f);
    nv12[0][(y + 1) * width + x + 1] = (unsigned char)(y11 + 0.5f);

    nv12[1][(y / 2) * width + x] = (unsigned char)(u0 + 0.5f);
    nv12[1][(y / 2) * width + x + 1] = (unsigned char)(v0 + 0.5f);
  }
}

void showNv12(uint8_t** nv12, int width, int height) {
  // Allocate memory on the CPU for the NV12 image
  int size = width * height * 3 / 2;
  uint8_t* nv12_cpu = new uint8_t[size];

  // Copy the NV12 image from the GPU to the CPU
  cudaMemcpy(nv12_cpu, nv12[0], width * height, cudaMemcpyDeviceToHost);
  cudaMemcpy(nv12_cpu + width * height, nv12[1], height * width / 2,
             cudaMemcpyDeviceToHost);

  cv::Mat BGR;
  cv::Mat NV12(height * 3 / 2, width, CV_8UC1, nv12_cpu);

  cv::namedWindow("NV12", cv::WINDOW_NORMAL);
  cv::imshow("NV12", NV12);
  cv::waitKey(0);

  cv::cvtColor(NV12, BGR, cv::COLOR_YUV2BGR_NV12);
  cv::namedWindow("BGR", cv::WINDOW_NORMAL);
  cv::imshow("BGR", BGR);
  cv::waitKey(0);
}

int main(int argc, char* args[]) {
  if (argc < 2) {
    std::cout << "parameter error ,run the program again" << std::endl;
    return 0;
  }

  std::string input(args[1]);

  cv::Mat ORG = cv::imread(input);

  if (ORG.empty()) {
    std::cout << "Can't read image!" << std::endl;
    return -1;
  }

  cv::Size imageSize = ORG.size();
  int width = imageSize.width;
  int height = imageSize.height;
  int channel = ORG.channels();

  uint8_t* src;
  uint8_t** nv12;
  cudaMallocManaged(&nv12, sizeof(uint8_t*) * 2);
  cudaMallocManaged(&src, width * height * 3 * sizeof(uint8_t));
  cudaMallocManaged(&nv12[0], width * height * sizeof(uint8_t));
  cudaMallocManaged(&nv12[1], (height / 2) * width * sizeof(uint8_t));

  cudaMemcpy(src, ORG.data, width * height * 3 * sizeof(uint8_t),
             cudaMemcpyHostToDevice);

  int TPB = 128;
  int blocksize = ((width * height) + TPB - 1) / TPB;
  BGR2NV12<<<blocksize, TPB>>>(src, nv12, width, height);
  cudaDeviceSynchronize();

  cv::namedWindow("ORG", cv::WINDOW_NORMAL);
  cv::imshow("ORG", ORG);
  cv::waitKey(0);

  showNv12(nv12, width, height);

  cv::destroyAllWindows();

  return 1;
}
