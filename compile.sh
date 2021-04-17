#!/bin/bash

CUR=`pwd`
MINERFLAGS="-DBIN_KERN -DETH_ETHASHCL -DUSE_SYS_OPENCL -DBOOST_BIND_GLOBAL_PLACEHOLDERS" # -DETH_ETHASHCUDA
CXX="/usr/bin/c++"
CXXFLAGS="-isystem -Wall -Wno-unknown-pragmas -Wextra -Wno-error=parentheses -pedantic -Ofast -ffunction-sections -fdata-sections -std=c++11 -DNDEBUG"
AR="/usr/bin/ar"
RANLIB="/usr/bin/ranlib"
COPY="/usr/bin/cmake"
CUDAINC="-I/opt/cuda/include"
HWMON="-I$CUR/../libhwmon/.."
LIBS="../libethcore/libethcore.a ../libpoolprotocols/libpoolprotocols.a ../libdevcore/libdevcore.a libethminer-buildinfo.a /usr/lib/libboost_system.a /usr/lib/libboost_thread.a  ../libethash-cl/libethash-cl.a ../libhwmon/libhwmon.a /usr/lib/libOpenCL.so /usr/lib/libboost_filesystem.a /usr/lib/libboost_thread.a /usr/lib/librt.so ../libdevcore/libdevcore.a /usr/lib/libboost_system.a /usr/lib/libethash.a -lpthread -ldl -ljsoncpp -lethash -lssl -lcrypto" # /opt/cuda/lib64/libcudart_static.a ../libethash-cuda/libethash-cuda.a 

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
#$AR qc libethminer-buildinfo.a libethminer-buildinfo.o

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
# -Xptxas "
# --allow-expensive-optimizations
# --fmad ?
# --maxrregcount 12288 #(48kb of 4 byte registers)
# --warn-on-double-precision-use
# -Xptxas "--use_fast_math,--allow-expensive-optimizations,--fmad,--maxrregcount 12288,--warn-on-double-precision-use"


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

