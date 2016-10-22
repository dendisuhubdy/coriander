struct MyStruct {
    float *floats;
    int intvalue;
};

__device__ void foo_dev2(MyStruct *mystruct, float *data);

__device__ void foo_device(MyStruct *mystruct, float *data) {
    data[0] = mystruct[0].floats[0];
}

__global__ void foo(MyStruct *mystruct, float *data) {
    data[0] = mystruct[0].floats[0];
    foo_dev2(mystruct, data);
}

int main(int argc, char *argv[]) {
    int N = 1024;

    CUstream stream;
    cuStreamCreate(&stream, 0);

    float *hostFloats1;
    float *hostFloats2;
    cuMemHostAlloc((void **)&hostFloats1, N * sizeof(float), CU_MEMHOSTALLOC_PORTABLE);
    cuMemHostAlloc((void **)&hostFloats2, N * sizeof(float), CU_MEMHOSTALLOC_PORTABLE);

    CUdeviceptr deviceFloats1;
    CUdeviceptr deviceFloats2;
    cuMemAlloc(&deviceFloats1, N * sizeof(float));
    cuMemAlloc(&deviceFloats2, N * sizeof(float));

    hostFloats1[128] = 123.456f;

    cuMemcpyHtoDAsync(
        (CUdeviceptr)(((float *)deviceFloats1)),
        hostFloats1,
        N * sizeof(float),
        stream
    );
    // cuStreamSynchronize(stream);

    getValue<<<dim3(1,1,1), dim3(32,1,1), 0, stream>>>(((float *)deviceFloats2) + 64, ((float *)deviceFloats1) + 128);

    // now copy back entire buffer
    // hostFloats[64] = 0.0f;
    cuMemcpyDtoHAsync(hostFloats2, deviceFloats2, N * sizeof(float), stream);
    // cuStreamSynchronize(stream);

    // and check the values...
    cout << hostFloats2[64] << endl;

    assert(hostFloats2[64] == 126.456f);

    cuMemFreeHost(hostFloats1);
    cuMemFreeHost(hostFloats2);
    cuMemFree(deviceFloats1);
    cuMemFree(deviceFloats2);
    cuStreamDestroy(stream);

    return 0;
}
