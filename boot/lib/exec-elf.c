#include <stdio.h>
#include <stdint.h>
#include "elf.h"
#include"fat_filelib.h"

typedef int entry_t(int arg, char **argv);

#ifdef ZDEBUG
#define DEBUGF(...)       printf(const char *, ...)
#else
#define DEBUGF(...)
#endif

/*-----------------------------------------------------------------------------------------------------
 * Load the ELF (Executable and Linkable Format) file into memory and execute
 * --------------------------------------------------------------------------------------------------*/
uint32_t executeELF(int argc, char **argv) {
  DEBUGF("\r\nExecute:");
  for (int i = 0; i < argc; i++) {
    DEBUGF(" %s", argv[i]);
  }
  DEBUGF("\r\n");
  char name[strlen(argv[0]) + 2];
  if (argv[0][0] != '/') {
    name[0] = '/';
    strcpy(&name[1], argv[0]);
  } else {
    strcpy(name, argv[0]);
  }
  void *elf = fl_fopen(name, "r");
  if (elf == NULL) {
    printf("File %s not found\r\n", name);
    return 1;
  }

  unsigned char file_header[sizeof(Elf32_Ehdr)];
  Elf32_Ehdr *ehdr = (Elf32_Ehdr *)file_header;

  // Read and validate the magic number
  if (fl_fread(file_header, 1, 4, elf) != 4) {
    puts("Could not read ELF magic number\r");
    goto _exit;
  }

  if (file_header[0] != 0x7f || file_header[1] != 'E' || file_header[2] != 'L' || file_header[3] != 'F') {
    printf("Not an ELF file, invalid magic number: %02x %02x %02x %02x", file_header[0], file_header[1], file_header[2], file_header[3]);
    goto _exit;
  }

  // Read the remainder of the header
  if (fl_fread(&file_header[4], 1, sizeof(Elf32_Ehdr) - 4, elf) != sizeof(Elf32_Ehdr) - 4) {
    puts("Could not read ELF file header\r");
    goto _exit;
  }

  DEBUGF("ELF type %0x, machine %0x, version %0x, entry %0x\r\n", ehdr->e_type, ehdr->e_machine, ehdr->e_version, ehdr->e_entry);

  if (ehdr->e_type != ET_EXEC) {
    puts("Not an executable ELF file\r");
    goto _exit;
  }

  if (ehdr->e_machine != EM_68K) {
    puts("Not a Motorola 68K executable ELF file\r");
    goto _exit;
  }

  Elf32_Shdr shdr;

  // Read each section header
  for (int i = 0; i < ehdr->e_shnum; i++) {
    // Seek to the section header table entry
    fl_fseek(elf, ehdr->e_shoff + i * ehdr->e_shentsize, SEEK_SET);

    if (fl_fread(&shdr, 1, sizeof(Elf32_Shdr), elf) != sizeof(Elf32_Shdr)) {
      printf("Failed to read section header [%d]\r\n");
      goto _exit;
    }
    if (shdr.sh_type != SHT_PROGBITS && shdr.sh_type != SHT_NOBITS || !(shdr.sh_flags & SHF_ALLOC)) {
      DEBUGF("Ignoring section %d, type %02x, flags %02x\r\n", i, shdr.sh_type, shdr.sh_flags);
      continue;
    }

    DEBUGF("Loading  section %d, type %02x, flags %02x, addr %06x, offset %06x, size %06x\r\n", i, shdr.sh_type, shdr.sh_flags, shdr.sh_addr, shdr.sh_offset, shdr.sh_size);

    if (shdr.sh_type != SHT_NOBITS) {
      // Seek to the start of the sections content and read directly into RAM
      fl_fseek(elf, shdr.sh_offset, SEEK_SET);
      if (fl_fread((void*)shdr.sh_addr, 1, shdr.sh_size, elf) != shdr.sh_size) {
        printf("Failed to read section [%d]\r\n", i);
        goto _exit;
      }
    }
  }
  fl_fclose(elf);

  DEBUGF("Starting execution at 0x%06x\r\n", ehdr->e_entry);
  return ((entry_t*)ehdr->e_entry)(argc, argv);

_exit:
  fl_fclose(elf);
  return 0;
}
