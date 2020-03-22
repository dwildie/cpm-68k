CC      = m68k-elf-gcc
AR      = m68k-elf-ar
CFLAGS += -mcpu=68000
CFLAGS += -fno-common -Os
CFLAGS += -ffunction-sections -fdata-sections
CFLAGS += -ffreestanding
CFLAGS += -I../baselibc/include
CFLAGS += -Iinclude

SRC = src/fat_access.c src/fat_cache.c src/fat_filelib.c src/fat_misc.c src/fat_string.c src/fat_table.c src/fat_write.c
OBJ = $(patsubst src/%.c, obj/%.o, $(SRC))

all: target/libfat.a

clean:
	$(RM) -rf obj target
	mkdir -p obj target

target/libfat.a: $(OBJ)
	$(RM) $@
	$(AR) ru $@ $^

obj/%.o: src/%.c
	$(CC) $(CFLAGS) -c -o $@ $<

