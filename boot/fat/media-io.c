#include <stdio.h>
#include "fat_filelib.h"

int mediaRead(unsigned long sector, unsigned char *buffer, unsigned long sector_count);
int mediaWrite(unsigned long sector, unsigned char *buffer, unsigned long sector_count);

extern unsigned long getPartitionStart(unsigned long currentDriveId, unsigned long currentPartitionId);
extern void rdSectors(unsigned long sector, unsigned char *buffer, unsigned long sectorCount);
extern void wrSectors(unsigned long sector, unsigned char *buffer, unsigned long sectorCount);


static int currentDriveId, currentPartitionId;

int mediaInit(int driveId, int partitionId)
{
	currentDriveId = driveId;
	currentPartitionId = partitionId;

	fl_init();

	if (fl_attach_media(mediaRead, mediaWrite) != FAT_INIT_OK)
	{
		//printf("ERROR: Media attach failed\n");
		return 1;
	}

    return 0;
}

int mediaRead(unsigned long sector, unsigned char *buffer, unsigned long sectorCount)
{
	unsigned long startOffset = getPartitionStart(currentDriveId, currentPartitionId);
	rdSectors(startOffset + sector, buffer, sectorCount);
    return 1;
}

int mediaWrite(unsigned long sector, unsigned char *buffer, unsigned long sectorCount)
{
	unsigned long startOffset = getPartitionStart(currentDriveId, currentPartitionId);
	wrSectors(startOffset + sector, buffer, sectorCount);
    return 1;
}

void mediaClose()
{
	fl_shutdown();
}
