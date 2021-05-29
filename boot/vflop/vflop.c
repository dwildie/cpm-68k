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

		char path[255];
		if (name[0] == '/') {
			strcpy(path, name);
		} else {
			path[0] = '/';
			strcpy(&path[1], name);
		}

		image->fp = fl_fopen(path, "r+");
		if (image->fp != NULL) {
			if (fl_fread(&(image->info), sizeof(vflop_info), 1, image->fp) == sizeof(vflop_info)) {
				strncpy(image->name, name, NAME_LEN);
				result = 0;
			} else {
				printf("Could not read %d bytes from file %s\r\n", sizeof(vflop_info), path);
				fl_fclose(image->fp);
				image->fp = NULL;
			}
		} else {
			printf("Could not open file %s\r\n", path);
		}

		if (result == 0) {
			vfList();
		}
	}

	return result;
}

int vfRead(unsigned int imageIndex, unsigned int cylinder, unsigned int head, unsigned int sector, unsigned int count, char *address) {
	unsigned int result = -1;

	if (imageIndex < MAX_IMAGES) {
		vflop_image *image = &images[imageIndex];
		if (image->fp != NULL) {
			track_info *track = (cylinder == 0 && head == 0) ? &(image->info.first) : &(image->info.rest);
			long offset = track->offset + (cylinder * image->info.heads + head) * (track->sectors * track->sectorBytes) + sector * track->sectorBytes;
			if (fl_fseek(image->fp, offset, SEEK_SET) == 0) {
				result = fl_fread(address, track->sectorBytes, count, image->fp);
			}
		}
	}

	return result;
}

int vfWrite(unsigned int imageIndex, unsigned int cylinder, unsigned int head, unsigned int sector, unsigned int count, char *address) {
	unsigned int result = -1;

	if (imageIndex < MAX_IMAGES) {
		vflop_image *image = &images[imageIndex];
		if (image->fp != NULL) {
			track_info *track = NULL;
			if (cylinder == 0 && head == 0) {
				// First track
				track = &(image->info.first);
			} else {
				// All other tracks
				track = &(image->info.rest);
			}
			long offset = track->offset + (cylinder * image->info.heads + head) * (track->sectors * track->sectorBytes) + sector * track->sectorBytes;
			if (fl_fseek(image->fp, offset, SEEK_SET) == 0) {
				result = fl_fwrite(address, track->sectorBytes, count, image->fp);
				fl_fflush(image->fp);
			}
		}
	}

	return result;
}
