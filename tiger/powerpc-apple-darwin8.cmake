# Cross toolchain: GCC 14.2 + MacOSX10.4u SDK targeting Mac OS X Tiger on
# PowerPC (G4). Runs inside ghcr.io/variantxyz/gcc-powerpc-apple-darwin8.
set(CMAKE_SYSTEM_NAME Darwin)
set(CMAKE_SYSTEM_PROCESSOR powerpc)
set(CMAKE_SYSTEM_VERSION 8)

set(CMAKE_C_COMPILER /usr/local/bin/powerpc-apple-darwin8-gcc)
set(CMAKE_CXX_COMPILER /usr/local/bin/powerpc-apple-darwin8-g++)
set(CMAKE_AR /usr/local/bin/powerpc-apple-darwin8-ar CACHE FILEPATH "")
set(CMAKE_RANLIB /usr/local/bin/powerpc-apple-darwin8-ranlib CACHE FILEPATH "")
set(CMAKE_INSTALL_NAME_TOOL /usr/local/bin/powerpc-apple-darwin8-install_name_tool CACHE FILEPATH "")

set(CMAKE_OSX_SYSROOT /usr/local/MacOSX10.4u.sdk)

# Darwin PPC historically gives C _Bool a 4-byte ABI; SDL3's API traffics in
# 1-byte bool. Build every translation unit with the 1-byte bool ABI.
set(CMAKE_C_FLAGS_INIT "-mone-byte-bool")
set(CMAKE_CXX_FLAGS_INIT "-mone-byte-bool")
set(CMAKE_OSX_DEPLOYMENT_TARGET 10.4 CACHE STRING "")

set(CMAKE_FIND_ROOT_PATH /usr/local/MacOSX10.4u.sdk /usr/local/powerpc-apple-darwin8)
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE BOTH)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE BOTH)
set(CMAKE_FIND_FRAMEWORK FIRST)

# The GCC toolchain's own libs (libstdc++, libatomic, libgcc).
set(CMAKE_EXE_LINKER_FLAGS_INIT "-L/usr/local/powerpc-apple-darwin8/lib -static-libstdc++ -static-libgcc")
set(CMAKE_SHARED_LINKER_FLAGS_INIT "-L/usr/local/powerpc-apple-darwin8/lib")

# 32-bit PowerPC lacks native 64-bit atomics; link GCC's libatomic
# statically so the binary is self-contained on the target machine.
set(CMAKE_CXX_STANDARD_LIBRARIES "/usr/local/powerpc-apple-darwin8/lib/libatomic.a")

# No host tools inside the SDK.
set(CMAKE_CROSSCOMPILING TRUE)
