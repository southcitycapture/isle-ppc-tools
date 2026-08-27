set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR s390x)

set(CMAKE_C_COMPILER s390x-linux-gnu-gcc)
set(CMAKE_CXX_COMPILER s390x-linux-gnu-g++)

# Debian multiarch: headers are shared in /usr/include, libraries live in
# arch-suffixed dirs. LIBRARY_ARCHITECTURE steers find_library there.
set(CMAKE_LIBRARY_ARCHITECTURE s390x-linux-gnu)

set(CMAKE_FIND_ROOT_PATH /usr/s390x-linux-gnu /usr)
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY BOTH)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE BOTH)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE BOTH)

# Cross pkg-config: only report s390x packages.
set(ENV{PKG_CONFIG_LIBDIR} "/usr/lib/s390x-linux-gnu/pkgconfig:/usr/share/pkgconfig")

# Run cross-compiled test binaries through qemu-user during configure checks.
set(CMAKE_CROSSCOMPILING_EMULATOR /usr/bin/qemu-s390x-static)
