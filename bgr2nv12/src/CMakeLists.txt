# add_subdirectory(bm_lib)

set(SOURCE_FILES main.cu)

# list( APPEND SOURCE_FILES shuffle/shuffle.cc shuffle/shuffle.cu)

cuda_add_executable(bgr2nv12 ${SOURCE_FILES})
target_link_libraries(bgr2nv12 ${OpenCV_LIBS})

install(TARGETS bgr2nv12 RUNTIME)
