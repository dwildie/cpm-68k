#include <stdio.h>
#include "fat.h"
#include "bios.h"

static fat_bios_entry *fatBios = (fat_bios_entry*)FAT_BIOS_ENTRY;

void* fl_fopen(const char *path, const char *modifiers) {
  return fatBios->fOpenFAT(path, modifiers);
}

int fl_fwrite(const void *data, int size, int count, void *file ) {
  return fatBios->fWriteFAT(size * count, data);
}

int fl_fread(void *data, int size, int count, void *file ) {
  return fatBios->fReadFAT(size * count, data);
}

void fl_fclose(void *file) {
  fatBios->fCloseFAT();
}

void fatTest() {
  void *f = fl_fopen("/test.c", "w");
  fl_fwrite("Hello world", 1, 11, f);
  fl_fclose(f);
}
