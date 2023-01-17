# the name of the target operating system
set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR m68k)

# Without that flag CMake is not able to pass test compilation check
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)

set(TOOLCHAIN_PREFIX m68k-elf-)

# which compilers to use for C and C++
set(CMAKE_C_COMPILER   ${TOOLCHAIN_PREFIX}gcc)
set(CMAKE_CXX_COMPILER ${TOOLCHAIN_PREFIX}g++)
set(CMAKE_ASM_COMPILER ${TOOLCHAIN_PREFIX}as)
set(CMAKE_LINKER       ${TOOLCHAIN_PREFIX}ld)
set(CMAKE_C_LINK_EXECUTABLE "<CMAKE_LINKER> <CMAKE_C_LINK_FLAGS> <LINK_FLAGS> <OBJECTS> -o <TARGET> <LINK_LIBRARIES>")

set(CMAKE_C_FLAGS      "-Wall -Werror -Wpedantic -O3 -ffreestanding -nostartfiles -m68010 -Wno-unused-function")
set(CMAKE_ASM_FLAGS    "-m68010 --defsym IS_68030=1")
set(CMAKE_C_LINK_FLAGS "-s --no-relax -Map ${CMAKE_PROJECT_NAME}.map")

# where is the target environment located
#set(CMAKE_FIND_ROOT_PATH  /usr/i586-mingw32msvc
#        /home/alex/mingw-install)

# adjust the default behavior of the FIND_XXX() commands:
# search programs in the host environment
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)

# search headers and libraries in the target environment
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)