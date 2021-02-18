
/*
 * Common header file for the CMODEM package. See CMODEM.C
 */

/*
 *	The following three defines must be customized by the user:
 */

#define	SPECIAL	'^'-0x40		/* Gets out of terminal mode	*/
#define	CPUCLK 10			/* CPU clock rate, in MHz 	*/

/* 	The rest of the defines need not be modified	*/

#define	SOH 1
#define	EOT 4
#define	ACK 6
#define	BELL 7
#define	CTRL_X	('X' - 0x40)
#define CTRL_Z  ('Z' - 0x40)
#define	ERRORMAX 10
#define	RETRYMAX 10
#define	LF 10
#define	CR 13
#define	SPS 450				/* loops per milli second */
#define	NAK 21
#define	TIMEOUT -1
#define	TBFSIZ (NSECTS*SECSIZ)
#define CRC 'C'

int	crc_flag;
int	sectnum;
int	toterr;
int	checksum;
int	fd;
int	bufctr;

unsigned crc_value;

char	buffer[TBFSIZ];			/* Core buffer for file transfers */
char	sflg;				/* transmit flag		*/

