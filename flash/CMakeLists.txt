cmake_minimum_required(VERSION 3.24)

set( CMAKE_TOOLCHAIN_FILE ${CMAKE_CURRENT_SOURCE_DIR}/m68.cmake )
set( CMAKE_VERBOSE_MAKEFILE ON CACHE BOOL "ON" FORCE)

project( flash VERSION 0.4 LANGUAGES C ASM )

set( CMAKE_C_STANDARD 17 )

FILE( GLOB C_SOURCES src/*.c )

set( BASELIBC_DIR /home/dwildie/m68000/gnu/cpm-68k/baselibc )
set( LINKER_SCRIPT ${CMAKE_CURRENT_SOURCE_DIR}/flash-elf.lnk )
set( CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -T ${LINKER_SCRIPT}")

configure_file(src/config.h.in config.h)

add_executable(flash src/crt0.s ${C_SOURCES})

add_custom_command ( OUTPUT ${CMAKE_PROJECT_NAME}.srec
        COMMAND objcopy -O srec ${CMAKE_PROJECT_NAME} ${CMAKE_PROJECT_NAME}.srec
        WORKING_DIRECTORY ${PROJECT_BINARY_DIR}/)

add_custom_target(
        srec ALL
        DEPENDS ${CMAKE_PROJECT_NAME}.srec
)
add_dependencies(srec flash)

target_include_directories(flash PUBLIC
        "${BASELIBC_DIR}/include"
        "${PROJECT_BINARY_DIR}"
        )
target_link_directories(flash PUBLIC
        "/usr/local/lib/gcc/m68k-elf/12.1.0/m68000"
        "${BASELIBC_DIR}/target")

target_link_libraries(flash PUBLIC c gcc)