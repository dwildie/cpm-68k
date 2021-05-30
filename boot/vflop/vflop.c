#include <string.h>
#include "vflop.h"
#include "fat_filelib.h"

static vflop_image images[MAX_IMAGES];
static int pId;

extern int mediaInit(int driveId, int partitionId);

int vfInit(int driveId, int partitionId) {

	for (int i = 0; i < MAX_IMAGES; i++) {
		images[i].name[0] = 0;
		images[i].fp = NULL;
	}

	return mediaInit(driveId, partitionId) == 0 ? 0 : -1;
}

vflop_image* vfInfo() {
	printf("vfInfo()\r\n");
	return images;
}

void vfList() {
	printf("Virtual floppy mount table\r\n");
	printf("Pos Name         Cylinders Heads\r\n");
	for (int i = 0; i < MAX_IMAGES; i++) {
		vflop_image *image = &images[i];
		if (image->fp == NULL) {
			printf("[%d]\r\n", i);
		} else {
			printf("[%d] %12s       %3d     %d\r\n", i, image->name, image->info.cylinders, image->info.heads);
		}
	}
}

void vfUmount(unsigned int imageIndex) {
	if (imageIndex < MAX_IMAGES) {
		vflop_image *image = &images[imageIndex];
		if (image->fp != NULL) {
			fl_fclose(image->fp);
			image->name[0] = 0;
			image->fp = NULL;
		} else {
			printf("Position %d, is not mounted\r\n", imageIndex);
		}
	}

	vfList();
}

int vfMount(char *name, unsigned int imageIndex) {
	unsigned int result = -1;

	if (imageIndex < MAX_IMAGES) {
		vflop_image *image = &images[imageIndex];
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
				}
			} else {
				printf("Could not read %d bytes from file %s\r\n", sizeof(vflop_info), name);
			}
		} else {
			printf("Could not open file %s\r\n", name);
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

int vfRead(unsigned int dev, unsigned int cylinder, unsigned int head, unsigned int sector, unsigned int bytes, char *address) {
	unsigned int result = -1;

	printf("vfRead dev=%d, cyl=%d, head=%d, sector=%d, bytes=%d\r\n", dev, cylinder, head, sector, bytes);
	if (dev < MAX_IMAGES) {
		vflop_image *image = &images[dev];
		if (image->fp != NULL) {
			track_info *track = (cylinder == 0 && head == 0) ? &(image->info.first) : &(image->info.rest);
			unsigned int offset = track->offset + (cylinder * image->info.heads + head) * (track->sectors * track->sectorBytes) + sector * track->sectorBytes;
			printf("vfRead dev=%d, offset=0x%x\r\n", dev, offset);
			if (fl_fseek(image->fp, offset, SEEK_SET) == 0) {
				int bytesRead = fl_fread(address, 1, bytes, image->fp);
				if (bytesRead == bytes) {
				  result = 0;
				}
			} else {
				printf("vfRead dev=%d, offset=0x%x, seek failed\r\n", dev, offset);
			}
		} else {
			printf("vfRead device %d is not mounted\r\n", dev);
		}
	}

	return result;
}

int vfWrite(unsigned int dev, unsigned int cylinder, unsigned int head, unsigned int sector, unsigned int bytes, char *address) {
	unsigned int result = -1;

	printf("vfWrite dev=%d, cyl=%d, head=%d, sector=%d, bytes=%d\r\n", dev, cylinder, head, sector, bytes);
	if (dev < MAX_IMAGES) {
		vflop_image *image = &images[dev];
		if (image->fp != NULL) {
			track_info *track = (cylinder == 0 && head == 0) ? &(image->info.first) : &(image->info.rest);
			unsigned int offset = track->offset + (cylinder * image->info.heads + head) * (track->sectors * track->sectorBytes) + sector * track->sectorBytes;
			unsigned int sectors = bytes / track->sectorBytes;
			printf("vfWrite dev=%d, offset=0x%x, sectors=%d\r\n", dev, offset, sectors);
			if (fl_fseek(image->fp, offset, SEEK_SET) == 0) {
				int bytesWritten = fl_fwrite(address, track->sectorBytes, sectors, image->fp);
				fl_fflush(image->fp);
        if (bytesWritten == bytes) {
          result = 0;
        }
			} else {
				printf("vfWrite dev=%d, offset=0x%x, sectors=%d, seek failed\r\n", dev, offset, sectors);
			}
		} else {
			printf("vfWrite device %d is not mounted\r\n", dev);
		}
	}

	return result;
}
