#include <stdio.h>
#include <string.h>
#include "cromix-fs.h"

extern int biosReadDriveBlock(long driveId, long lba, unsigned char *buffer, long count);
static int init(int driveId, int offset, int verbose);
static int read_geometry(int driveId, int offset, int verbose);
static int read_fs_block(unsigned int block, unsigned char *buffer);
static cromix_time read_time(unsigned char *data, int offset);
static int read_word(unsigned char *data, int offset);
static int read_dword(unsigned char *data, int offset);
static int read_inode(int inode_number, unsigned char *inode);
static int read_directory(unsigned char *inode);
static int read_file(unsigned char *inode, char *name, unsigned char *destination);
static int extract_file(int size, unsigned char *destination);
static void extractPointerBlock(int ptrBlockNumber, unsigned char *destination, int *offset, int *remaining);
static void extractPointerPointerBlock(int ptrBlockNumber, unsigned char *destination, int *offset, int *remaining);
static void extractPointerPointerPointerBlock(int ptrBlockNumber, unsigned char *destination, int *offset, int *remaining);
static int min(int X, int Y);

static unsigned char block[BLOCK_LENGTH];
static unsigned char dir_inode[INODE_LENGTH];
static unsigned char entry_inode[INODE_LENGTH];
static char types[2] = {'F','D'};

static disk_geometry geometry;
static int first_inode;

/*-----------------------------------------------------------------------------------------------------
 * Display the directory listing for the currently selected drive
 * --------------------------------------------------------------------------------------------------*/
void listCromixDirectory(int driveId, int offset) {
  printf("\r\n");
//  printf("\r\nlistCromixDirectory(0x%x,0x%x)\r\n", driveId, offset);

  init(driveId, offset, 1);
  read_inode(1, dir_inode);
  read_directory(dir_inode);
}

int readCromixFile(int driveId, int offset, char *name, unsigned char *destination) {
  printf("\r\n");
  //printf("\r\nreadCromixFile(0x%x, 0x%x, %s, 0x%x)\r\n", driveId, offset, name, destination);

  init(driveId, offset, 0);
  read_inode(1, dir_inode);
  return read_file(dir_inode, name, destination);
}

/*-----------------------------------------------------------------------------------------------------
 * Read the drive's geometry from the first block and locate the first inode in the filesystem
 * --------------------------------------------------------------------------------------------------*/
static int init(int driveId, int offset, int verbose)
{
  read_geometry(driveId, offset, verbose);
  /* Read the super block */
  read_fs_block(1, block);

  if (block[SUPER_CROMIX_OFFSET + 0] != 'c'
   || block[SUPER_CROMIX_OFFSET + 1] != 'r'
   || block[SUPER_CROMIX_OFFSET + 2] != 'o'
   || block[SUPER_CROMIX_OFFSET + 3] != 'm'
   || block[SUPER_CROMIX_OFFSET + 4] != 'i'
   || block[SUPER_CROMIX_OFFSET + 5] != 'x')
  {
	  printf("Not a cromix filesystem\r\n");
	  printf ("super block id: %c %c %c %c %c %c\r\n",
			  block[SUPER_CROMIX_OFFSET + 0],
			  block[SUPER_CROMIX_OFFSET + 1],
			  block[SUPER_CROMIX_OFFSET + 2],
			  block[SUPER_CROMIX_OFFSET + 3],
			  block[SUPER_CROMIX_OFFSET + 4],
			  block[SUPER_CROMIX_OFFSET + 5]);
	  return 0;
  }

  first_inode = read_word(block, SUPER_INODE_FIRST_OFFSET);
//  printf("Offset to first iNode: %d\r\n", first_inode);
  return 0;
}

static int read_file(unsigned char *inode, char *target, unsigned char *destination)
{
    for (int i = 0; i < 0x10; i++) {
        int blockNumber = read_dword(inode, INODE_PTRS_OFFSET + i * 4);
        if (blockNumber != 0) {
        	read_fs_block(blockNumber, block);

            for (int j = 0; j < 0x10; j++) {
                if (block[j * DIR_ENTRY_LENGTH + 0x1c] == 0x80) {
                    char name[NAME_LENGTH + 1];
                    for (int k = 0; k < 0x18 && block[j * DIR_ENTRY_LENGTH + k] != 0; k++) {
                        name[k] = block[j * DIR_ENTRY_LENGTH + k];
                        name[k + 1] = 0;
                    }

                    if (strcmp(target, name) == 0) {
						int entryInodeNumber = read_word(block, j * DIR_ENTRY_LENGTH + 0x1E);
						read_inode(entryInodeNumber, entry_inode);

						int type = 0xFF & entry_inode[INODE_TYPE_OFFSET];
						if (type == INODE_TYPE_FILE) {

							int size = type == INODE_TYPE_DIR ? read_word(entry_inode, INODE_D_COUNT_OFFSET) : read_dword(entry_inode, INODE_F_SIZE_OFFSET);
							printf("Loading file: %s, %d bytes to address 0x%x\r\n", target, size, (unsigned int)destination);

							int read = extract_file(size, destination);
							printf("Loaded %d bytes\r\n", read);

							return read;
						}
                    }
                }
            }
        }
    }

    return 0;
}

static int extract_file(int size, unsigned char *destination)
{
	int offset = 0;
    int remaining = size;

	// Read first 16 data blocks
	for (int i = 0; i < 0x10 && remaining > 0; i++) {
		int blockNumber = read_dword(entry_inode, INODE_PTRS_OFFSET + i * 4);
		int bytes = min(remaining, BLOCK_LENGTH);
		if (blockNumber != 0) {
        	read_fs_block(blockNumber, &destination[offset]);
		} else {
			for (int i = 0; i < bytes; i++) {
				destination[offset + i] = 0;
			}
		}
		remaining -= bytes;
		offset += bytes;
	}

	if (remaining == 0) {
		return size;
	}

	// 17th pointer
	int blockNumber = read_dword(entry_inode, INODE_PTRS_OFFSET + 0x10 * 4);
	if (blockNumber != 0) {
		extractPointerBlock(blockNumber, destination, &offset, &remaining);
	}

	if (remaining == 0) {
		return size;
	}

	// 18th pointer
	blockNumber = read_dword(entry_inode, INODE_PTRS_OFFSET + 0x11 * 4);
	if (blockNumber != 0) {
		extractPointerPointerBlock(blockNumber, destination, &offset, &remaining);
	}

	if (remaining == 0) {
		return size;
	}

	// 19th pointer
	blockNumber = read_dword(entry_inode, INODE_PTRS_OFFSET + 0x12 * 4);
	if (blockNumber != 0) {
		extractPointerPointerPointerBlock(blockNumber, destination, &offset, &remaining);
	}

	if (remaining != 0) {
		printf("Did not read all bytes, %d remaining\r\n", remaining);
		return 0;
	}

	return size;
}

static void extractPointerBlock(int ptrBlockNumber, unsigned char *destination, int *offset, int *remaining)
{
	read_fs_block(ptrBlockNumber, block);
	for (int i = 0; i < BLOCK_POINTER_COUNT && *remaining > 0; i++) {
		int blockNumber = read_dword(block, i * 4);
		int bytes = min(*remaining, BLOCK_LENGTH);
		if (blockNumber != 0) {
        	read_fs_block(blockNumber, &destination[*offset]);
		} else {
			for (int i = 0; i < bytes; i++) {
				destination[*offset + i] = 0;
			}
		}
		*remaining = *remaining - bytes;
		*offset = *offset + bytes;
	}
}

static void extractPointerPointerBlock(int ptrPtrBlockNumber, unsigned char *destination, int *offset, int *remaining)
{
	unsigned char ptrBlock[BLOCK_LENGTH];
	read_fs_block(ptrPtrBlockNumber, ptrBlock);
    for (int i = 0; i < BLOCK_POINTER_COUNT && *remaining > 0; i++) {
        int ptrBlockNumber = read_dword(ptrBlock, i * 4);
        if (ptrBlockNumber != 0) {
            extractPointerBlock(ptrBlockNumber, destination, offset, remaining);
        }
    }
}

static void extractPointerPointerPointerBlock(int ptrPtrPtrBlockNumber, unsigned char *destination, int *offset, int *remaining)
{
	unsigned char ptrPtrBlock[BLOCK_LENGTH];
	read_fs_block(ptrPtrPtrBlockNumber, ptrPtrBlock);
    for (int i = 0; i < BLOCK_POINTER_COUNT && *remaining > 0; i++) {
        int ptrPtrBlockNumber = read_dword(ptrPtrBlock, i * 4);
        if (ptrPtrBlockNumber != 0) {
            extractPointerPointerBlock(ptrPtrBlockNumber, destination, offset, remaining);
        }
    }
}

static int read_directory(unsigned char *inode)
{
  printf("\r\n");

    for (int i = 0; i < 0x10; i++) {
        int blockNumber = read_dword(inode, INODE_PTRS_OFFSET + i * 4);
        if (blockNumber != 0) {
        	read_fs_block(blockNumber, block);

            for (int j = 0; j < 0x10; j++) {
                if (block[j * DIR_ENTRY_LENGTH + 0x1c] == 0x80) {
                    char name[NAME_LENGTH + 1];
                    for (int k = 0; k < 0x18 && block[j * DIR_ENTRY_LENGTH + k] != 0; k++) {
                        name[k] = block[j * DIR_ENTRY_LENGTH + k];
                        name[k + 1] = 0;
                    }

                    int entryInodeNumber = read_word(block, j * DIR_ENTRY_LENGTH + 0x1E);
                    read_inode(entryInodeNumber, entry_inode);

                    int type = 0xFF & entry_inode[INODE_TYPE_OFFSET];
                    int size = type == INODE_TYPE_DIR ? read_word(entry_inode, INODE_D_COUNT_OFFSET) : read_dword(entry_inode, INODE_F_SIZE_OFFSET);

                    if (type == INODE_TYPE_FILE || type == INODE_TYPE_DIR) {
						cromix_time modified = read_time(entry_inode, INODE_MODIFIED_OFFSET);
                        printf("%9d %c   %02d:%02d:%02d %2d/%02d/%04d  %s\r\n",
                        		size, types[type - INODE_TYPE_FILE],
								modified.hour, modified.minute, modified.second, modified.day, modified.month, (1900 + modified.year),
								name);
                    }
                }
            }
        }
    }

    return 0;
}

static cromix_time read_time(unsigned char *data, int offset)
{
	cromix_time t;
	memcpy((unsigned char *)&t, &data[offset], sizeof(t));
	return t;
}

static int read_inode(int inode_number, unsigned char *inode)
{
  unsigned char scratch[BLOCK_LENGTH];
//  printf("read_inode(%d)\r\n", inode_number);
  int block_number = first_inode + (inode_number - 1) / 4;
  read_fs_block(block_number, scratch);
  int start_inode = ((inode_number - 1) % 4) * INODE_LENGTH;
  memcpy(inode, &scratch[start_inode], INODE_LENGTH);
  return 0;
}

static int read_word(unsigned char *data, int offset)
{
	return ((0xFF & data[offset]) << 8) + (0xFF & data[offset + 1]);
}

static int read_dword(unsigned char *data, int offset)
{
	return ((((((0xFF & data[offset]) << 8) + (0xFF & data[offset + 1])) << 8) + (0xFF & data[offset + 2])) << 8) + (0xFF & data[offset + 3]);
}

static int read_fs_block(unsigned int block_number, unsigned char *buffer)
{
  unsigned int b = geometry.block_0 + block_number;
  return biosReadDriveBlock(geometry.drive_id, b, buffer, 1);
}

static int read_geometry(int drive_id, int offset, int verbose)
{
//  printf("biosReadDriveBlock 0x%x\r\n", offset);
  biosReadDriveBlock(drive_id, offset, block, 1);

  geometry.drive_id         = drive_id;
  geometry.offset           = offset;
  geometry.cylinders        = ((block[0x68] & 0xFF) << 8) + (block[0x69] & 0xFF);
  geometry.track_sectors    = block[0x6d] & 0xFF;
  geometry.surfaces         = block[0x6c] & 0xFF;
  geometry.sector_bytes     = ((block[0x6E] & 0xFF) << 8) + (block[0x6F] & 0xFF);
  geometry.start_cylinder   = ((block[0x72] & 0xFF) << 8) + (block[0x73] & 0xFF);
  geometry.start_part_table = ((block[0x76] & 0xFF) << 8) + (block[0x77] & 0xFF);
  geometry.start_alt_table  = ((block[0x70] & 0xFF) << 8) + (block[0x71] & 0xFF);
  geometry.alt_track_cyl    = ((block[0x74] & 0xFF) << 8) + (block[0x75] & 0xFF);
  geometry.alt_tracks       = ((block[0x6A] & 0xFF) << 8) + (block[0x6B] & 0xFF);
  geometry.block_0          = geometry.offset + geometry.start_cylinder * geometry.surfaces * geometry.track_sectors;

  if (verbose)
  {
    printf("Drive geometry:\r\n");
    printf("  cylinders:      %d\r\n", geometry.cylinders);
    printf("  sectors/track:  %d\r\n", geometry.track_sectors);
    printf("  surfaces:       %d\r\n", geometry.surfaces);
    printf("  bytes/sector:   %d\r\n", geometry.sector_bytes);
    printf("  start cylinder: %d\r\n", geometry.start_cylinder);
    printf("  first fs block: 0x%x\r\n", geometry.block_0);
  }
  return(0);
}

static int min(int X, int Y)
{
	return X < Y ? X : Y;
}


