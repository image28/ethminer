#!/bin/bash

CUR=`pwd`
MINERFLAGS="-DBIN_KERN -DETH_ETHASHCL -DUSE_SYS_OPENCL -DBOOST_BIND_GLOBAL_PLACEHOLDERS -DETH_ETHASHCUDA"
CXX="/usr/bin/c++"
CXXFLAGS="-isystem -Wall -Wno-unknown-pragmas -Wextra -Wno-error=parentheses -pedantic -Ofast -ffunction-sections -fdata-sections -std=c++11 -DNDEBUG"
AR="/usr/bin/ar"
RANLIB="/usr/bin/ranlib"
#COPY="/usr/bin/cmake"
NVCC="/opt/cuda/bin/nvcc"
CUDAINC="-I/opt/cuda/include"
HWMON="-I$CUR/../libhwmon/.."
LIBS="../libethcore/libethcore.a ../libpoolprotocols/libpoolprotocols.a ../libdevcore/libdevcore.a libethminer-buildinfo.a /usr/lib/libboost_system.a /usr/lib/libboost_thread.a  ../libethash-cl/libethash-cl.a ../libethash-cuda/libethash-cuda.a ../libhwmon/libhwmon.a /usr/lib/libOpenCL.so /usr/lib/libboost_filesystem.a /usr/lib/libboost_thread.a /opt/cuda/lib64/libcudart_static.a /usr/lib/librt.so ../libdevcore/libdevcore.a /usr/lib/libboost_system.a /usr/lib/libethash.a -lpthread -ldl -ljsoncpp -lethash -lssl -lcrypto"

# Generate buildinfo.h
NAME="ethminer"
VERSION="0.20.0"
SYSTEM=`uname`
ARCH=`uname -m`
COMPILER=`$CXX --version | head -n1 | awk -F'(' '{print $2}'| cut -c1-3`
COMPILER_VER=`$CXX --version | head -n1 | rev | awk -F' ' '{print $1}' | rev`
COMMIT=`git describe --always --long --tags --match=v*`
DIRTY="false"
TYPE="release"
PROJECT_NAME_VER="$PROJECT_NAME.$PROJECT_VERSION"

mkdir -p ethminer
cd $CUR/ethminer
$CXX -o libethminer-buildinfo.o -I../ethminer -DPROJECT_NAME_VERSION="$PROJECT_NAME_VER" -DPROJECT_NAME="$NAME" -DPROJECT_VERSION=0.19.0 -DCOMMIT="$COMMIT" -DSYSTEM_NAME="$SYSTEM" -DSYSTEM_PROCESSOR="$ARCH" -DCOMPILER_ID="$COMPILER" -DCOMPILER_VERSION="$COMPILER_VERSION" -DBUILD_TYPE="$TYPE" -c $CUR/../ethminer/buildinfo.c 
$AR qc libethminer-buildinfo.a libethminer-buildinfo.o

# DEVICE MANAGER CORE
mkdir -p $CUR/libdevcore 
cd $CUR/libdevcore 
$CXX $MINERFLAGS $CXXFLAGS -o CommonData.cpp.o -c $CUR/../libdevcore/CommonData.cpp
$CXX $MINERFLAGS $CXXFLAGS -o FixedHash.cpp.o -c $CUR/../libdevcore/FixedHash.cpp
$CXX $MINERFLAGS $CXXFLAGS -o Log.cpp.o -c $CUR/../libdevcore/Log.cpp
$CXX $MINERFLAGS $CXXFLAGS -o Worker.cpp.o -c $CUR/../libdevcore/Worker.cpp
$AR qc libdevcore.a CommonData.cpp.o FixedHash.cpp.o Log.cpp.o Worker.cpp.o
$RANLIB libdevcore.a

# HARDWARE MONITOR
mkdir -p $CUR/libhwmon 
cd $CUR/libhwmon 
$CXX $MINERFLAGS $HWMON $CUDAINC $CXXFLAGS -o wraphelper.cpp.o -c $CUR/../libhwmon/wraphelper.cpp
$CXX $MINERFLAGS $HWMON $CUDAINC $CXXFLAGS -o wrapnvml.cpp.o -c $CUR/../libhwmon/wrapnvml.cpp
$CXX $MINERFLAGS $HWMON $CUDAINC $CXXFLAGS -o wrapadl.cpp.o -c $CUR/../libhwmon/wrapadl.cpp
$CXX $MINERFLAGS $HWMON $CUDAINC $CXXFLAGS -o wrapamdsysfs.cpp.o -c $CUR/../libhwmon/wrapamdsysfs.cpp
$AR qc libhwmon.a wraphelper.cpp.o wrapnvml.cpp.o wrapadl.cpp.o wrapamdsysfs.cpp.o
$RANLIB libhwmon.a

# POOL MANAGER
mkdir -p $CUR/libpoolprotocols 
mkdir -p $CUR/libpoolprotocols/testing
mkdir -p $CUR/libpoolprotocols/stratum
mkdir -p $CUR/libpoolprotocols/getwork
cd $CUR/libpoolprotocols 
$CXX $MINERFLAGS -I$CUR/../libpoolprotocols/.. -I$CUR $CXXFLAGS -o PoolURI.cpp.o -c $CUR/../libpoolprotocols/PoolURI.cpp
$CXX $MINERFLAGS -I$CUR/../libpoolprotocols/.. -I$CUR $CXXFLAGS -o PoolManager.cpp.o -c $CUR/../libpoolprotocols/PoolManager.cpp 
$CXX $MINERFLAGS -I$CUR/../libpoolprotocols/.. -I$CUR $CXXFLAGS -o testing/SimulateClient.cpp.o -c $CUR/../libpoolprotocols/testing/SimulateClient.cpp
$CXX $MINERFLAGS -I$CUR/../libpoolprotocols/.. -I$CUR $CXXFLAGS -o stratum/EthStratumClient.cpp.o -c $CUR/../libpoolprotocols/stratum/EthStratumClient.cpp
$CXX $MINERFLAGS -I$CUR/../libpoolprotocols/.. -I$CUR $CXXFLAGS -o getwork/EthGetworkClient.cpp.o -c $CUR/../libpoolprotocols/getwork/EthGetworkClient.cpp
$AR qc libpoolprotocols.a PoolURI.cpp.o PoolManager.cpp.o testing/SimulateClient.cpp.o stratum/EthStratumClient.cpp.o getwork/EthGetworkClient.cpp.o
$RANLIB libpoolprotocols.a

# CUDA KERNELS
# -Xptxas "--use_fast_math,--allow-expensive-optimizations,--fmad,--maxrregcount 12288,--warn-on-double-precision-use"
mkdir -p $CUR/libethash-cuda
cd $CUR/libethash-cuda
$NVCC -I/opt/cuda/include -I$CUR/../ -I$CUR/../libethash-cuda --ptxas-options=-v --use_fast_math --disable-warnings -gencode arch=compute_35,code=sm_35 -gencode arch=compute_50,code=sm_50 -gencode arch=compute_52,code=sm_52 -gencode arch=compute_53,code=sm_53 -gencode arch=compute_60,code=sm_60 -gencode arch=compute_61,code=sm_61 -gencode arch=compute_62,code=sm_62 -gencode arch=compute_70,code=sm_70 -gencode arch=compute_75,code=sm_75 --fmad=true --maxrregcount=256 -DNVCC -o ethash-cuda_generated_ethash_cuda_miner_kernel.cu.o -c $CUR/../libethash-cuda/ethash_cuda_miner_kernel.cu
$CXX $MINERFLAGS $CUDAINC -I$CUR/../libethash-cuda -I$CUR/libethash-cuda -I$CUR/.. $CXXFLAGS -o CUDAMiner.cpp.o -c $CUR/../libethash-cuda/CUDAMiner.cpp

$AR qc libethash-cuda.a CUDAMiner.cpp.o ethash-cuda_generated_ethash_cuda_miner_kernel.cu.o
$RANLIB libethash-cuda.a

# OPENCL KERNEL
# Convert ethash.cl to a c header file
# change this to ethash-legacy.cl for legacy kernel
$CUR/cl2h.sh "$CUR/../libethash-cl/kernels/cl/ethash.cl" "ethash_cl" "$CUR/libethash-cl/ethash.h"

mkdir -p $CUR/libethash-cl 
cd $CUR/libethash-cl 
$CXX $MINERFLAGS -I$CUR/../libethash-cl -I$CUR/libethash-cl -I$CUR/.. $CUDAINC $CXXFLAGS -o CLMiner.cpp.o -c $CUR/../libethash-cl/CLMiner.cpp
$AR qc libethash-cl.a CLMiner.cpp.o
$RANLIB libethash-cl.a

# ETHMINER CORE
mkdir -p $CUR/libethcore 
cd $CUR/libethcore 
$CXX $MINERFLAGS -I$CUR/../libethcore -I$CUR/.. $CUDAINC $CXXFLAGS -o EthashAux.cpp.o -c $CUR/../libethcore/EthashAux.cpp 
$CXX $MINERFLAGS -I$CUR/../libethcore -I$CUR/.. $CUDAINC $CXXFLAGS -o Farm.cpp.o -c $CUR/../libethcore/Farm.cpp
$CXX $MINERFLAGS -I$CUR/../libethcore -I$CUR/.. $CUDAINC $CXXFLAGS -o Miner.cpp.o -c $CUR/../libethcore/Miner.cpp
$AR qc libethcore.a EthashAux.cpp.o Farm.cpp.o Miner.cpp.o
$RANLIB libethcore.a

# COMPILE MAIN BINARY AND LINK TO ALL ABOVE STUFF
mkdir -p $CUR/ethminer
cd $CUR/ethminer 
$CXX $MINERFLAGS -I$CUR/../ethminer -I$CUR/.. $CUDAINC -I$CUR $CXXFLAGS -o main.cpp.o -c $CUR/../ethminer/main.cpp

$RANLIB libethminer-buildinfo.a
$CXX $CXXFLAGS -static-libstdc++ main.cpp.o -o ethminer $LIBS
