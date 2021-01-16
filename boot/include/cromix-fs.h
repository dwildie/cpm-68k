typedef struct {
  int drive_id;
  unsigned int offset;
  unsigned int block_0;
  unsigned int cylinders;
  unsigned int track_sectors;
  unsigned int surfaces;
  unsigned int sector_bytes;
  unsigned int start_cylinder;
  unsigned int start_part_table;
  unsigned int start_alt_table;
  unsigned int alt_track_cyl;
  unsigned int alt_tracks;
  unsigned char identifier[3];
} disk_geometry;

typedef	struct	{
	unsigned char	year;		/* year 0 .. 99		*/
	unsigned char	month;		/* month 1 .. 12	*/
	unsigned char	day;		/* day 1 .. 31		*/
	unsigned char	hour;		/* hour 0 .. 23		*/
	unsigned char	minute;		/* minute 0 .. 59	*/
	unsigned char	second;		/* second 0 .. 59	*/
} cromix_time;


#define SUPER_INODE_FIRST_OFFSET	0x08
#define SUPER_INODE_COUNT_OFFSET	0x0a
#define SUPER_CROMIX_OFFSET			0x02

#define BLOCK_LENGTH				0x200
#define INODE_LENGTH				0x80

#define INODE_OWNER_OFFSET     		0x00
#define INODE_GROUP_OFFSET      	0x02
#define INODE_TYPE_OFFSET       	0x07
#define INODE_F_SIZE_OFFSET     	0x0A
#define INODE_D_COUNT_OFFSET    	0x12
#define INODE_CREATED_OFFSET   		0x18
#define INODE_MODIFIED_OFFSET  		0x1E
#define INODE_PTRS_OFFSET      		0x30

#define DIR_ENTRY_LENGTH			0x20
#define NAME_LENGTH					0x18

#define INODE_TYPE_FILE				0x80
#define INODE_TYPE_DIR				0x81

#define BLOCK_POINTER_COUNT 		0x80
