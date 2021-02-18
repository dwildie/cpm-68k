/* stdio.h 	for BDS C v1.6  2/85 */

#define BDSC

#define ERROR -1	/* General "on error" return value */
#define OK 0		/* General purpose "no error" return value */
#define JBUFSIZE 6	/* Length of setjump/longjump buffer	*/
#define CPMEOF 0x1a	/* CP/M End-of-text-file marker (sometimes!)  */
#define SECSIZ 128	/* Sector size for CP/M read/write calls */
#define MAXLINE	150	/* For compatibility */

#define NSECTS 8	/* Number of sectors to buffer up in ram */

#define _READ 1		/* only one of these two may be active at a time */
#define _WRITE 2

#define _EOF 4		/* EOF has occurred on input */
#define _TEXT 8		/* convert ^Z to EOF on input, write ^Z on output */
#define _ERR 16		/* error occurred writing data out to a file */

#define stdlst 2
#define stdrdr 3
#define stdpun 3

