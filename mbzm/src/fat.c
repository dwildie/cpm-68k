#include <stdio.h>
#include "fat.h"
#include "bios.h"

extern m68k_bios_entry *biosTable;
extern fat_bios_entry *fatTable;
//static fat_bios_entry *fatTable = (fat_bios_entry*)FAT_BIOS_ENTRY;

void* fl_fopen(const char *path, const char *modifiers) {
  return fatTable->fOpenFAT(path, modifiers);
}

int fl_fwrite(const void *data, int size, int count, void *file ) {
  return fatTable->fWriteFAT(size * count, data);
}

int fl_fread(void *data, int size, int count, void *file ) {
  return fatTable->fReadFAT(size * count, data);
}

void fl_fclose(void *file) {
  fatTable->fCloseFAT();
}

void fatTest() {
  void *f = fl_fopen("/test.c", "w");
  fl_fwrite("Hello world", 1, 11, f);
  fl_fclose(f);
}
