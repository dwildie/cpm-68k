#include "inttypes.h"

#define NAME_LEN 13
#define MAX_IMAGES 4
#define IDE_SECTOR_SIZE 512

typedef struct {
	uint16_t sectors;		/* Number of sectors per track */
	uint16_t sectorBytes;	/* Number of bytes / sector */
	uint16_t offset;      	/* Offset in bytes from start of file */
} track_info;

typedef struct {
	char magic[4];
	uint16_t major;
	uint16_t minor;
	uint16_t cylinders;		/* Number of cylinders, track count = cylinders * heads */
	uint16_t heads;			/* Number of heads, 2 for double sides, 1 for single */
	track_info first;		/* Info for the first track, ie. cylinder 0, head 0 */
	track_info rest;		/* Info for all other tracks */
} vflop_info;

typedef struct {
	char name[NAME_LEN];
	void *fp;
	vflop_info info;
} vflop_image;

