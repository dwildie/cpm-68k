#include <stdio.h>
#include <stdint.h>

#define REG_SECONDS       0x00
#define REG_MINUTES       0x02
#define REG_HOURS         0x04
#define REG_DAY_OF_WEEK   0x06
#define REG_DAY           0x07
#define REG_MONTH         0x08
#define REG_YEAR          0x09 /* 2 digits */
#define REG_CENTURY       0x32

#define REG_ALARM_SECONDS 0x01
#define REG_ALARM_MINUTES 0x03
#define REG_ALARM_HOURS   0x05

#define REG_CTRL_A        0x0a
#define REG_CTRL_B        0x0b
#define REG_CTRL_C        0x0c
#define REG_CTRL_D        0x0d

#define PORT_ADDR         0x70
#define PORT_DATA         0x71

#define port(x) ((unsigned char *)(0xffff0000 + (x)))

uint16_t readRegister(int reg);
void writeRegister(int reg, int val);

/*-----------------------------------------------------------------------------------------------------
 * Display the current time from the RTC
 * --------------------------------------------------------------------------------------------------*/
uint32_t displayTime(int argc, char **argv) {
  writeRegister(REG_CTRL_B, 0x86);

  uint16_t seconds = readRegister(REG_SECONDS);
  uint16_t minutes = readRegister(REG_MINUTES);
  uint16_t hours = readRegister(REG_HOURS);
  uint16_t day = readRegister(REG_DAY);
  uint16_t month = readRegister(REG_MONTH);
  uint16_t year = readRegister(REG_YEAR);
  uint16_t century = readRegister(REG_CENTURY);

  writeRegister(REG_CTRL_B, 0x06);

  printf("%02d%02d-%02d-%02d %02d:%02d:%02d\r\n", century, year, month, day, hours, minutes, seconds);
}

void setTime(int argc, char **argv) {
  if (argc != 7) {
    printf("Usage: %s YYYY MM DD hh mm ss %d\r\n", argv[0], argc);
    return;
  }

  int year = atoi(argv[1]);
  int month = atoi(argv[2]);
  int day = atoi(argv[3]);

  int hours = atoi(argv[4]);
  int minutes = atoi(argv[5]);
  int seconds = atoi(argv[6]);

  writeRegister(REG_CTRL_B, 0x86);

  writeRegister(REG_SECONDS, seconds);
  writeRegister(REG_MINUTES, minutes);
  writeRegister(REG_HOURS, hours);
  writeRegister(REG_DAY, day);
  writeRegister(REG_MONTH, month);
  writeRegister(REG_YEAR, year % 100);
  writeRegister(REG_CENTURY, year / 100);

  writeRegister(REG_CTRL_B, 0x06);
}

/*-----------------------------------------------------------------------------------------------------
 * Read a RTC register
 * --------------------------------------------------------------------------------------------------*/
uint16_t readRegister(int reg) {
  *port(PORT_ADDR) = reg & 0xff;
  return *port(PORT_DATA);
}

/*-----------------------------------------------------------------------------------------------------
 * Read a RTC register
 * --------------------------------------------------------------------------------------------------*/
void writeRegister(int reg, int val) {
  *port(PORT_ADDR) = reg & 0xff;
  *port(PORT_DATA) = val & 0xff;
}
