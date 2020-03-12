#include <stdio.h>
#include "fat_filelib.h"

int mediaRead(unsigned long sector, unsigned char *buffer, unsigned long sector_count);
int mediaWrite(unsigned long sector, unsigned char *buffer, unsigned long sector_count);

extern unsigned long getPartitionStart(unsigned long currentDriveId, unsigned long currentPartitionId);
extern void rdSectors(unsigned long sector, unsigned char *buffer, unsigned long sectorCount);


static int currentDriveId, currentPartitionId;

int mediaInit(int driveId, int partitionId)
{
	currentDriveId = driveId;
	currentPartitionId = partitionId;

	fl_init();

	if (fl_attach_media(mediaRead, mediaWrite) != FAT_INIT_OK)
	{
		printf("ERROR: Media attach failed\n");
		return 1;
	}

    return 0;
}

int mediaRead(unsigned long sector, unsigned char *buffer, unsigned long sectorCount)
{
	//printf("mediaRead(%d,%d)\n", sector, sectorCount);

	unsigned long startOffset = getPartitionStart(currentDriveId, currentPartitionId);

	rdSectors(startOffset + sector, buffer, sectorCount);

    return 1;
}

int mediaWrite(unsigned long sector, unsigned char *buffer, unsigned long sector_count)
{
    unsigned long i;

    for (i=0; i<sector_count; i++)
    {
        // ...
        // Add platform specific sector (512 bytes) write code here
        //..

        sector ++;
        buffer += 512;
    }

    return 0;
}

void mediaClose()
{
	fl_shutdown();
}
