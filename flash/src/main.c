/*
 * ------------------------------------------------------------
 */

#include <stdio.h>
#include "config.h"

#define FALSE                   0
#define TRUE                    1

#define SST_ID                  0xBF      /* SST Manufacturer's ID code   */
#define SST_39SF010             0xB5      /* SST 39SF040 device code      */
#define SST_39SF020             0xB6      /* SST 39SF040 device code      */
#define SST_39SF040             0xB7      /* SST 39SF040 device code      */
#define DEV_UNKNOWN             0x00      /* Unknown device               */

#define SECTOR_SIZE             0x1000    /* Must be 4096 bytes for 39SF040 */
#define BASE_ADDRESS            0xF80000

typedef unsigned char BYTE;

extern long biosTable, fatTable;

void delay25milliSeconds() {
    for (int i = 0; i < 5000; i++) {
        volatile BYTE a = *(BYTE *) (0x10000);
        *(BYTE *) (0x10000) = a;
    }
}

char *deviceName(BYTE id) {
    if (id == SST_39SF010) {
        return "SST39SF010";
    }
    if (id == SST_39SF020) {
        return "SST39SF020";
    }
    if (id == SST_39SF040) {
        return "SST39SF040";
    }
    return "Unknown";
}

char *manufacturerName(BYTE id) {
    if (id == SST_ID) {
        return "SST";
    }
    return "Unknown";
}

int getSSTDeviceId(long base) {
    /*  Issue the Software Product ID code to 39SF040  */
    *(volatile BYTE *) (base + 0x5555) = 0xAA;                   /* write data 0xAA to 0x5555 */
    *(volatile BYTE *) (base + 0x2AAA) = 0x55;                   /* write data 0x55 to 0x2AAA */
    *(volatile BYTE *) (base + 0x5555) = 0x90;                   /* write data 0x90 to 0x5555 */

    /* Read the product ID from 39SF040 */
    BYTE manId = *(volatile BYTE *) (base + 0x0000);             /* get first ID byte */
    BYTE devId = *(volatile BYTE *) (base + 0x0001);             /* get first ID byte */

    /* Issue the Software Product ID Exit code thus returning the 39SF040  to the read operating mode */
    *(volatile BYTE *) (base + 0x5555) = 0xAA;                   /* write data 0xAA to 0x5555 */
    *(volatile BYTE *) (base + 0x2AAA) = 0x55;                   /* write data 0x55 to 0x2AAA */
    *(volatile BYTE *) (base + 0x5555) = 0xF0;                   /* write data 0xF0 to 0x5555 */

    printf("Manufacturer's ID %s (0x%02x), Device ID %s (0x%02x)\r\n",
           manufacturerName(manId), manId,
           deviceName(devId), devId);

    return (manId == SST_ID) ? devId : DEV_UNKNOWN;
}

void eraseSector(long base, long sector) {
    /*  Issue the Sector Erase command to 39SF040   */
    *(volatile BYTE *) (base + 0x5555) = 0xAA;                   /* write data 0xAA to 0x5555 */
    *(volatile BYTE *) (base + 0x2AAA) = 0x55;                   /* write data 0x55 to 0x2AAA */
    *(volatile BYTE *) (base + 0x5555) = 0x80;                   /* write data 0x80 to 0x5555 */
    *(volatile BYTE *) (base + 0x5555) = 0xAA;                   /* write data 0xAA to 0x5555 */
    *(volatile BYTE *) (base + 0x2AAA) = 0x55;                   /* write data 0x55 to 0x2AAA */
    *(volatile BYTE *) (base + sector) = 0x30;                   /* write data 0x30 to the sector address */

    delay25milliSeconds();
}

int checkToggleReady(const volatile BYTE *target) {
    unsigned long timeOut = 0;

    BYTE preData = *target & 0x40;

    while ((timeOut < 0x07FFFFFF)) {
        BYTE currData = *target & 0x40;
        if (preData == currData)
            return TRUE;
        preData = currData;
        timeOut++;
    }

    return FALSE;
}

int writeSector(long base, long sector, const BYTE *src) {
    eraseSector(base, sector);          /* erase the sector first */

    for (int i = 0; i < SECTOR_SIZE; i++) {
        *(volatile BYTE *) (base + 0x5555) = 0xAA;             /* write data 0xAA to the address */
        *(volatile BYTE *) (base + 0x2AAA) = 0x55;             /* write data 0x55 to the address */
        *(volatile BYTE *) (base + 0x5555) = 0xA0;             /* write data 0xA0 to the address */
        *(volatile BYTE *) (base + sector + i) = *(src + i);   /* transfer data from source to destination */
        if (!checkToggleReady((BYTE *)(base + sector + i))) {
            return i + 1;
        }
    }

    return SECTOR_SIZE;
}

int writeSectorAll(long base, long sector, BYTE value) {
    eraseSector(base, sector);          /* erase the sector first */

    for (int i = 0; i < SECTOR_SIZE; i++) {
        *(volatile BYTE *) (base + 0x5555) = 0xAA;             /* write data 0xAA to the address */
        *(volatile BYTE *) (base + 0x2AAA) = 0x55;             /* write data 0x55 to the address */
        *(volatile BYTE *) (base + 0x5555) = 0xA0;             /* write data 0xA0 to the address */
        *(volatile BYTE *) (base + sector + i) = value;        /* transfer data from source to destination */
        if (!checkToggleReady((BYTE *)(base + sector + i))) {
            return i + 1;
        }
    }

    return SECTOR_SIZE;
}

int main(int argc, char **argv) {
    printf("68030 flash, Damian Wildie, 10/01/2023 V%d.%d\r\n", VERSION_MAJOR, VERSION_MINOR);

    int devId = getSSTDeviceId(BASE_ADDRESS);
    printf("devId = %s (0x%02x)\r\n", deviceName(devId), devId);

    long sector = 0xd000;

    eraseSector(BASE_ADDRESS, sector);

    int bytes = writeSectorAll(BASE_ADDRESS, sector, 0xAA);
    printf("%d bytes written to sector starting at 0x%04lx\r\n", bytes, sector);

    return 0;
}

