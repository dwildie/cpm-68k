#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include "elf.h"
#include "coff.h"
#include"fat_filelib.h"

typedef int entry_t(int arg, char **argv, char *biosTable, char *fatTable);

#ifdef ZDEBUG
#define DEBUGF(...)       printf(const char *, ...)
#else
#define DEBUGF(...)
#endif

uint32_t executeELF(int argc, char **argv, char *biosTable, char *fatTable, void *fp);
uint32_t executeCOFF(int argc, char **argv, char *biosTable, char *fatTable, void *fp);

/*-----------------------------------------------------------------------------------------------------
 * Determine if the file is COFF or ELF
 * --------------------------------------------------------------------------------------------------*/
uint32_t executeCE(int argc, char **argv, char *biosTable, char *fatTable) {
//  printf("\r\nExecute: %d", argc);
//  for (int i = 0; i < argc; i++) {
//    printf(" %s", argv[i]);
//  }
//  printf("\r\n");
//  printf("biosTable 0x%lx, fatTable 0x%lx\r\n", (long)biosTable, (long)fatTable);

  char name[strlen(argv[0]) + 2];
  if (argv[0][0] != '/') {
    name[0] = '/';
    strcpy(&name[1], argv[0]);
  } else {
    strcpy(name, argv[0]);
  }
  void *fp = fl_fopen(name, "r");
  if (fp == NULL) {
    printf("File %s not found\r\n", name);
    return 1;
  }

  unsigned char magic[4];

  // Read and validate the magic number
  if (fl_fread(magic, 1, 4, fp) == 4) {
    // Reset
    fl_fseek(fp, 0, SEEK_SET);

    if (magic[0] == 0x7f && magic[1] == 'E' && magic[2] == 'L' && magic[3] == 'F') {
      return executeELF(argc, argv, biosTable, fatTable, fp);
    }

    if (magic[0] == 0x01 && magic[1] == 0x50) {
      return executeCOFF(argc, argv, biosTable, fatTable, fp);
    }
    printf("Unknown file format, magic number: %02x %02x %02x %02x", magic[0], magic[1], magic[2], magic[3]);
  } else {
    puts("Could not read ELF magic number\r");
  }

  fl_fclose(fp);
  return 0;
}

/*-----------------------------------------------------------------------------------------------------
 * Load the COFF (Common Object File Format) file into memory and execute
 * --------------------------------------------------------------------------------------------------*/
uint32_t executeCOFF(int argc, char **argv, char *biosTable, char *fatTable, void *fp) {
  coff_filehdr chdr;
  coff_aouthdr ahdr;
  coff_scnhdr  shdr;


  // Read the header
  if (fl_fread(&chdr, 1, sizeof(coff_filehdr), fp) == sizeof(coff_filehdr)) {
    if (fl_fread(&ahdr, 1, sizeof(coff_aouthdr), fp) == sizeof(coff_aouthdr)) {
      int sectionStart = sizeof(coff_filehdr) + chdr.f_opthdr;
      // Read each section header
      for (int i = 0; i < chdr.f_nscns; i++) {
        // Seek to the section header table entry
        int offset = sectionStart + i * sizeof(coff_scnhdr);
        int seek = fl_fseek(fp, offset, SEEK_SET);

        // Read the section header
        int size = sizeof(coff_scnhdr);
        int read = fl_fread(&shdr, 1, sizeof(coff_scnhdr), fp);
        if (read != sizeof(coff_scnhdr)) {
          printf("Failed to read COFF section header [%d], %d\r\n", i, read);
          goto _coff_exit;
        }

        if ((shdr.s_flags & 0x80) == 0) {
          // Text or data, seek to the start of the sections content and read directly into RAM
          offset = shdr.s_scnptr;
          seek = fl_fseek(fp, offset, SEEK_SET);
          read = fl_fread((void*)shdr.s_paddr, 1, shdr.s_size, fp);
          if (read != shdr.s_size) {
            goto _coff_exit;
          }
        } else {
          // BSS
          memset((void *)shdr.s_paddr, 0, shdr.s_size);
        }
      }

      printf("Starting execution at 0x%06x\r\n", ahdr.entry);
      return ((entry_t*)ahdr.entry)(argc, argv, biosTable, fatTable);
    } else {
      puts("Could not read COFF aout header\r");
    }
  } else {
    puts("Could not read COFF file header\r");
  }

_coff_exit:
  fl_fclose(fp);
  return 0;
}

/*-----------------------------------------------------------------------------------------------------
 * Load the ELF (Executable and Linkable Format) file into memory and execute
 * --------------------------------------------------------------------------------------------------*/
uint32_t executeELF(int argc, char **argv, char *biosTable, char *fatTable, void *fp) {
  unsigned char file_header[sizeof(Elf32_Ehdr)];
  Elf32_Ehdr *ehdr = (Elf32_Ehdr *)file_header;

  // Read the header
  if (fl_fread(file_header, 1, sizeof(Elf32_Ehdr), fp) != sizeof(Elf32_Ehdr)) {
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

  printf("e_shoff %d, e_shentsize %d\r\n", ehdr->e_shoff, ehdr->e_shentsize);

  // Read each section header
  for (int i = 0; i < ehdr->e_shnum; i++) {
    // Seek to the section header table entry
    printf("Seeking to %d (0x%6x)\r\n", ehdr->e_shoff + i * ehdr->e_shentsize, ehdr->e_shoff + i * ehdr->e_shentsize);
    fl_fseek(fp, ehdr->e_shoff + i * ehdr->e_shentsize, SEEK_SET);

    if (fl_fread(&shdr, 1, sizeof(Elf32_Shdr), fp) != sizeof(Elf32_Shdr)) {
      printf("Failed to read section header [%d]\r\n");
      goto _exit;
    }
    if ((shdr.sh_type != SHT_PROGBITS && shdr.sh_type != SHT_NOBITS) || !(shdr.sh_flags & SHF_ALLOC)) {
      printf("Ignoring section %d, type %02x, flags %02x, addr %06x, offset %06x, size %06x\r\n", i, shdr.sh_type, shdr.sh_flags, shdr.sh_addr, shdr.sh_offset, shdr.sh_size);
      continue;
    }

    printf("Loading  section %d, type %02x, flags %02x, addr %06x, offset %06x, size %06x\r\n", i, shdr.sh_type, shdr.sh_flags, shdr.sh_addr, shdr.sh_offset, shdr.sh_size);

    if (shdr.sh_type != SHT_NOBITS) {
      // Seek to the start of the sections content and read directly into RAM
      fl_fseek(fp, shdr.sh_offset, SEEK_SET);
      if (fl_fread((void*)shdr.sh_addr, 1, shdr.sh_size, fp) != shdr.sh_size) {
        printf("Failed to read section [%d]\r\n", i);
        goto _exit;
      }
    }
  }
  fl_fclose(fp);

  printf("Starting execution at 0x%06x\r\n", ehdr->e_entry);
  return ((entry_t*)ehdr->e_entry)(argc, argv, biosTable, fatTable);

_exit:
  fl_fclose(fp);
  return 0;
}
