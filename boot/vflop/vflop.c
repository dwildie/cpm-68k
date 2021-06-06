#include <string.h>
#include "vflop.h"
#include "fat_filelib.h"

static vflop_table table;

extern int mediaInit(int driveId, int partitionId);

int vfInit(int driveId, int partitionId) {

  table.driveLetter = 'A' + driveId;
  table.driveId = driveId;
  table.partitionId = partitionId;

	for (int i = 0; i < MAX_IMAGES; i++) {
	  table.images[i].name[0] = 0;
	  table.images[i].fp = NULL;
	}

	return mediaInit(driveId, partitionId) == 0 ? 0 : -1;
}

vflop_table* vfTable() {
	printf("vfTable()\r\n");
	return &table;
}

void vfList() {
  if (table.driveLetter == 0) {
    printf("Not initialised\r\n");
    return;
  }
	printf("Virtual floppy mount table, using drive %c:%d\r\n", table.driveLetter, table.partitionId);
	printf("Pos Name         Cylinders Heads\r\n");
	for (int i = 0; i < MAX_IMAGES; i++) {
		vflop_image *image = &table.images[i];
		if (image->fp == NULL) {
			printf("[%d]\r\n", i);
		} else {
			printf("[%d] %12s       %3d     %d\r\n", i, image->name, image->info.cylinders, image->info.heads);
		}
	}
}

int vfUmount(unsigned int imageIndex) {
  int result = 0;
	if (imageIndex < MAX_IMAGES) {
		vflop_image *image = &table.images[imageIndex];
		if (image->fp != NULL) {
			fl_fclose(image->fp);
			image->name[0] = 0;
			image->fp = NULL;
		} else {
			printf("Position %d, is not mounted\r\n", imageIndex);
			result = 1;
		}
	}

	vfList();
	return result;
}

int vfMount(char *name, unsigned int imageIndex) {
	unsigned int result = -1;

	if (imageIndex < MAX_IMAGES) {
		vflop_image *image = &table.images[imageIndex];
		// Close the existing image if necessary;
		if (image->fp != NULL) {
			vfUmount(imageIndex);
		}

		char path[NAME_LEN + 2];
		if (name[0] == '/') {
			strncpy(path, name, NAME_LEN);
			path[NAME_LEN] = 0;
		} else {
			path[0] = '/';
			strncpy(&path[1], name, NAME_LEN);
			path[NAME_LEN + 1] = 0;
		}

		image->fp = fl_fopen(path, "r+");
		if (image->fp != NULL) {
			if (fl_fread(&(image->info), sizeof(vflop_info), 1, image->fp) == sizeof(vflop_info)) {
				if (strncmp(image->info.magic, "VFD", 3) == 0) {
					strncpy(image->name, name, NAME_LEN);
					image->name[NAME_LEN] = 0;
					result = 0;
				} else {
					printf("File %s is not a valid VFD image\r\n", name);
					result = 1;
				}
			} else {
				printf("Could not read %d bytes from file %s\r\n", sizeof(vflop_info), name);
        result = 2;
			}
		} else {
			printf("Could not open file %s\r\n", name);
      result = 3;
		}

		if (result == 0) {
			vfList();
		} else if (image->fp != NULL) {
			fl_fclose(image->fp);
			image->fp = NULL;
		}
	}

	return result;
}

int vfRead(unsigned int unit, unsigned int cylinder, unsigned int head, unsigned int sector, unsigned int bytes, char *address) {
	unsigned int result = -1;

	printf("vfRead unit=%d, cyl=0x%x, head=0x%x, sector=0x%x, bytes=0x%x\r\n", unit, cylinder, head, sector, bytes);
	if (unit < MAX_IMAGES) {
		vflop_image *image = &table.images[unit];
		if (image->fp != NULL) {
      track_info *track = NULL;
      unsigned int offset = -1;
      if (cylinder == 0 && head == 0) {
        track = &(image->info.first);
        offset = track->offset + sector * track->sectorBytes;
      } else {
        track = &(image->info.rest);
        offset = track->offset + (cylinder * image->info.heads + head - 1) * (track->sectors * track->sectorBytes) + sector * track->sectorBytes;
      }

			printf("vfRead unit=%d, offset=0x%x\r\n", unit, offset);
			if (fl_fseek(image->fp, offset, SEEK_SET) == 0) {
				int bytesRead = fl_fread(address, 1, bytes, image->fp);
				if (bytesRead == bytes) {
				  result = 0;
				}
			} else {
				printf("vfRead unit=%d, offset=0x%x, seek failed\r\n", unit, offset);
			}
		} else {
			printf("vfRead unit %d is not mounted\r\n", unit);
		}
	}

	return result;
}

int vfWrite(unsigned int unit, unsigned int cylinder, unsigned int head, unsigned int sector, unsigned int bytes, char *address) {
	unsigned int result = -1;

	printf("vfWrite unit=%d, cyl=0x%x, head=0x%x, sector=0x%x, bytes=0x%x\r\n", unit, cylinder, head, sector, bytes);
	if (unit < MAX_IMAGES) {
		vflop_image *image = &table.images[unit];
		if (image->fp != NULL) {
      track_info *track = NULL;
      unsigned int offset = -1;
      if (cylinder == 0 && head == 0) {
        track = &(image->info.first);
        offset = track->offset + sector * track->sectorBytes;
      } else {
        track = &(image->info.rest);
        offset = track->offset + (cylinder * image->info.heads + head - 1) * (track->sectors * track->sectorBytes) + sector * track->sectorBytes;
      }

			printf("vfWrite unit=%d, offset=0x%x\r\n", unit, offset);
			if (fl_fseek(image->fp, offset, SEEK_SET) == 0) {
				int bytesWritten = fl_fwrite(address, 1, bytes, image->fp);
				fl_fflush(image->fp);
        if (bytesWritten == bytes) {
          result = 0;
        }
			} else {
				printf("vfWrite unit=%d, offset=0x%x, seek failed\r\n", unit, offset);
			}
		} else {
			printf("vfWrite unit %d is not mounted\r\n", unit);
		}
	}

	return result;
}
