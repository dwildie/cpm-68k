#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>

#define REG_SECONDS       0x00
#define REG_MINUTES       0x02
#define REG_HOURS         0x04
#define REG_DAY_OF_WEEK   0x06
#define REG_DAY           0x07
#define REG_MONTH         0x08
#define REG_YEAR          0x09 /* 2 digits */

#define REG_ALARM_SECONDS 0x01
#define REG_ALARM_MINUTES 0x03
#define REG_ALARM_HOURS   0x05

#define REG_CTRL_A        0x0a
#define REG_CTRL_B        0x0b
#define REG_CTRL_C        0x0c
#define REG_CTRL_D        0x0d

#define PORT_ADDR         0x70
#define PORT_DATA         0x71

#define B_SET             0x82
#define B_UNSET           0x02

#define port(x) ((unsigned char *)(0xffff0000 + (x)))

uint16_t readRegister(int reg);
void writeRegister(int reg, int val);
int toBCD(int bin);
int fromBCD(int bcd);

/*-----------------------------------------------------------------------------------------------------
 * Display the current time from the RTC
 * --------------------------------------------------------------------------------------------------*/
void displayTime(int argc, char **argv) {
  writeRegister(REG_CTRL_B, B_SET);

  uint16_t seconds = fromBCD(readRegister(REG_SECONDS));
  uint16_t minutes = fromBCD(readRegister(REG_MINUTES));
  uint16_t hours = fromBCD(readRegister(REG_HOURS));
  uint16_t day = fromBCD(readRegister(REG_DAY));
  uint16_t month = fromBCD(readRegister(REG_MONTH));
  uint16_t year = fromBCD(readRegister(REG_YEAR));
  uint16_t century = 20;

  writeRegister(REG_CTRL_B, B_UNSET);

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

  writeRegister(REG_CTRL_B, B_SET);

  writeRegister(REG_SECONDS, toBCD(seconds));
  writeRegister(REG_MINUTES, toBCD(minutes));
  writeRegister(REG_HOURS, toBCD(hours));
  writeRegister(REG_DAY, toBCD(day));
  writeRegister(REG_MONTH, toBCD(month));
  writeRegister(REG_YEAR, toBCD(year % 100));

  writeRegister(REG_CTRL_B, B_UNSET);
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

/*-----------------------------------------------------------------------------------------------------
 * Convert a binary value to 2 digit BCD
 * --------------------------------------------------------------------------------------------------*/
int toBCD(int bin) {
  return ((bin / 10) << 4) | (bin % 10);
}

/*-----------------------------------------------------------------------------------------------------
 * Convert a 2 digit BCD value to binary
 * --------------------------------------------------------------------------------------------------*/
int fromBCD(int bcd) {
  return ((bcd >> 4) * 10) + (bcd & 0xf);
}
