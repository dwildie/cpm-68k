#include <stdio.h>
#include "bios.h"
#include "zmodem.h"

static m68k_bios_entry *m68kBios = (m68k_bios_entry*)M68K_BIOS_ENTRY;

volatile uint8_t *usbStatus = (uint8_t*)0xFFFF00AA;
volatile uint8_t *usbData   = (uint8_t*)0xFFFF00AC;

volatile inline uint8_t readData() {
  return *usbData;
}

/*
 * Implementation-defined receive character function.
 */
ZRESULT zm_recv() {
  while(1) {
//  for (int j = 0; j < 4; j++) {
    while (m68kBios->hasChar() == 0) {
      // while keyboard chars are available check for an escape
      if ((m68kBios->inChar() & 0xff) == ESC) {
        return CANCELLED;
      }
    }
    for (int i = 0; i < 1000; i++) {
      if ((*usbStatus & 0x80) == 0) {
        return *usbData;
      }
    }
  }
  return TIMEOUT;
}

ZRESULT zm_flush() {
  for (int j = 0; j < 4; j++) {
    while (m68kBios->hasChar() == 0) {
      // while keyboard chars are available check for an escape
      if ((m68kBios->inChar() & 0xff) == ESC) {
        return CANCELLED;
      }
    }
    for (int i = 0; i < 1000; i++) {
      if ((*usbStatus & 0x80) == 0) {
        readData();
      }
    }
  }
  return TIMEOUT;
}

/*
 * Implementation-defined send character function.
 */
ZRESULT zm_send(uint8_t chr) {
  while ((*usbStatus & 0x40) != 0);
  *usbData = chr;
  return OK;
}

bool initCommPort(int argc, char **argv) {
    if (argc != 2) {
        printf("Usage: %s <device file>\r\n", argv[0]);
        return false;
    } else {
      char *fn = argv[1];

      printf("Opening '%s' as comm device\r\n", fn);

    }
    return true;
}

void closeCommPort() {

}
