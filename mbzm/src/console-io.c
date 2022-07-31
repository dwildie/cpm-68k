#include <stdio.h>
#include "bios.h"

static m68k_bios_entry *bios = (m68k_bios_entry*)M68K_BIOS_ENTRY;

extern size_t writeStrn(const char *bp, size_t n);

size_t io_write(FILE* instance, const char *ptr, size_t n) {
  for (int i = 0; i < n; i++) {
    bios->outChar(*(ptr + i) & 0x7f);
  }
  return n;
}

size_t io_read (FILE* instance, char *bp, size_t n) {
	return n;
}


struct File_methods methods = { &io_write, &io_read };

struct File console = { &methods };

struct File* const stdin  = &console;
struct File* const stdout = &console;
struct File* const stderr = &console;
