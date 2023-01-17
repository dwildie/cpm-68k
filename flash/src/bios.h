/* ----------------------------------------------------------
   Definitions for calling the BIOS routines

   Copyright (C) 2020 Damian Wildie

   -------------------------------------------------------- */

//#define M68K_BIOS_ENTRY 0xF80010

typedef struct {
  int (*initialise)();
  int (*getStatus)();
  int (*readBlock)();
  int (*writeBlock)();
  int (*initConsole)();
  int (*outChar)();
  int (*inChar)();
  int (*hasChar)();     // Return zero if a input char is available, otherwise non-zero
} m68k_bios_entry;

//#define FAT_BIOS_ENTRY 0xF80040

typedef struct {
  void* (*fOpenFAT)(const char *path, const char *modifiers);
  int (*fReadFAT)(int count, void *buffer);
  int (*fWriteFAT)(int count, const void *buffer);
  void (*fCloseFAT)();
} fat_bios_entry;
