rm -rf build
mkdir build && cd build
cmake -DCUDA_TOOLKIT_ROOT_DIR=/usr/local/cuda-11.6 ..
make -j
# ./cuda_benchmark --benchmark_out=test_details.json
./bgr2nv12 ../test.jpg
