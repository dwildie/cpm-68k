#include "inttypes.h"

#define NAME_LEN 12
#define MAX_IMAGES 4
#define IDE_SECTOR_SIZE 512

typedef struct {
	uint16_t sectors;		/* Number of sectors per track */
	uint16_t sectorBytes;	/* Number of bytes / sector */
	uint16_t offset;      	/* Offset in bytes from start of file */
} track_info;

typedef struct {
	char magic[4];
	uint16_t major;     /* Major version number */
	uint16_t minor;     /* Minor version number */
	uint16_t cylinders;	/* Number of cylinders, track count = cylinders * heads */
	uint16_t heads;			/* Number of heads, 2 for double sides, 1 for single */
	track_info first;		/* Info for the first track, ie. cylinder 0, head 0 */
	track_info rest;		/* Info for all other tracks */
} vflop_info;

typedef struct {
	char name[NAME_LEN + 1];
	void *fp;
	vflop_info info;
} vflop_image;

typedef struct {
  char driveLetter;
  uint16_t driveId;
  uint16_t partitionId;
  vflop_image images[MAX_IMAGES];
} vflop_table;
