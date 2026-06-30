#include <stdio.h>

#define RAM_BASE_ADDR 0xD00000
#define RAM_SIZE 0x800        // bytes
#define TEST_SIZE 0x200       // bytes

int idcVerify() {
  unsigned char* base8 = (unsigned char*)RAM_BASE_ADDR;
  unsigned short* base16 = (unsigned short*)RAM_BASE_ADDR;

  int errors = 0;

  printf("\r\n");
  int n = 0;

  for (n = 0; n < 1000; n++) {
    if ((n % 100) == 0 && n != 0) {
      printf("IDC Verify: %d\r\n", n);
    }
    // write 8bit values
    for (int i = 0; i < TEST_SIZE; i += 1) {
      *(base8 + i) = (i + n) & 0xFF;
    }

    // verify 8bit values
    for (int i = 0; i < TEST_SIZE; i += 1) {
      int val = *(base8 + i);
      if ((val & 0xFF) != ((i + n) & 0xFF)) {
        printf("8bit error %d: n = %d, i = 0x%02X, value = 0x%02X\r\n", ++errors, n + 1, i & 0xF, val & 0xFF);
      }
    }

    // write 16 bit values
    for (int i = 0; i < TEST_SIZE/2; i += 1) {
      *(base16 + i) = ((((i + n) << 8) + i + n) & 0xFFFF);
    }

    // verify 16 bit values
    for (int i = 0; i < TEST_SIZE/2; i += 1) {
      int val = *(base16 + i);
      if ((val & 0xFFFF) != ((((i + n) << 8) + i + n) & 0xFFFF)) {
        printf("16bit error %d: n = %d, i = 0x%04X, value = 0x%04X\r\n", ++errors, n + 1, ((i << 8) + i) & 0xFFFF, val & 0xFFFF);
      }
    }
    if (errors > 100)
      break;
  }
  printf("IDC Verify: %d\r\n", n);
  return errors;
}

int idc8BitTest() {
  unsigned char* base = RAM_BASE_ADDR;

  printf("\r\nIDC 8bit RAM write, start 0X%08X, size 0X%04X", (unsigned)base, RAM_SIZE);

  for (int i = 0; i < TEST_SIZE; i += 1) {
    *(base + i) = (((i % 2) == 0) ? 0x00 : 0xFF);
  }

  return idc8BitRead();
}

int idc8BitRead() {
  unsigned char* base = RAM_BASE_ADDR;

  printf("\r\nIDC 8bit RAM read, start 0X%08X, size 0X%04X", (unsigned)base, RAM_SIZE);

  for (int i = 0; i < (TEST_SIZE / 0x10); i++) {
    printf("\r\n%04X  ", (int)base + i * 0x10);
    for (int j = 0; j < 0x10; j++) {
      int index = i * 0x10 + j;
      printf("%02X ", *(base + index));
    }
  }

  printf("\r\n");
  return 0;
}

int idc16BitTest() {
  unsigned short* base = RAM_BASE_ADDR;

  printf("\r\nIDC 16bit RAM write, start 0X%08X, size 0X%04X", (unsigned)base, RAM_SIZE);

  for (int i = 0; i < TEST_SIZE/2; i += 1) {
    *(base + i) = (((i % 2) == 0) ? 0xFF00 : 0x00FF);
  }

  return idc16BitRead();
}

int idc16BitReadRepeat() {
  int count = 0;

  while(idc16BitRead() == 0) {
    printf("Count: %d\r\n", count);
    int j;
    for (int i = 0; i < 0x10000; i++) {
      j++;
    }
  }
  printf("done\r\n");
}

int idc16BitRead() {
  unsigned short* base = RAM_BASE_ADDR;
  int result = 0;
  printf("\r\nIDC 16bit RAM read, start 0X%08X, size 0X%04X", (unsigned)base, RAM_SIZE);

  for (int i = 0; i < (TEST_SIZE / 0x10); i++) {
    printf("\r\n%04X  ", (int)base + i * 0x10);
    for (int j = 0; j < 0x8; j++) {
      int index = i * 0x8 + j;
      int value = *(base + index);
      printf("%04X ", value);
      if ((index * 2) == 0x1EE && value == 0) {
        result = 1;
        break;
      }
    }
  }

  printf("\r\n");
  return result;
}
