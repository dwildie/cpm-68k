/*
 CMODEM.C	v1.6	<Sep 24, 1986>

 Files of this program:	CMODEM.H, CMODEM.C

 Modified for CPM/68K by Damian Wildie, 15/02/2021

 Modified for BDS C v1.6 by Leor Zolman, 10/82, 2/83, 9/86

 A telecommunications program using Ward Christensen's
 "MODEM" File Transfer Protocol.

 Modified by Nigel Harrison and Leor Zolman from XMODEM.C,
 which was written by:  Jack M. Wierda,
 modified by Roderick W. Hart and William D. Earnest

 Added "CRC" file transfer protocol and cancelation via Control-X
 during file xfers. <Stefan Badstuebner	4 Mar 83>

 Compilation & linkage:
 ccm cmodem
 locm cmodem

 Note that the Modem port interfaces are defined in HARDWARE.H,
 which must be configured with the correct values for your system.

 */

#include <stdio.h>
#include "bdsio.h"
#include "hardware.h"
#include "cmodem.h"

extern FILE* fopen();
extern char* malloc();
char* getname();

usage() {
	printf("Usage: cmodem -t filename\n");
	printf("       cmodem -r [-crc] filename");
	exit(1);
}

main(argc, argv)
char **argv;
{
	FILE *fp;

	if (argc < 3) {
		usage();
	}

	crc_flag = FALSE;

	if (strcmp(argv[1], "-t") == 0 || strcmp(argv[1], "-T") == 0) {
		// Transmit file
		if ((fp = fopen(argv[2], "r")) == NULL) {
			printf("Error, cannot open file %s\n", argv[2]);
			usage();
		}
		fclose(fp);
		sendfile(argv[2]);
		exit(0);
	}

	if (strcmp(argv[1], "-r") == 0 || strcmp(argv[1], "-R") == 0) {
		if (strcmp(argv[2], "-crc") == 0 || strcmp(argv[2], "-CRC") == 0) {
			if (argc != 4) {
				usage();
			}
			crc_flag = TRUE;
			rcvfile(argv[3]);
		} else {
			rcvfile(argv[2]);
		}
		exit(0);
	}

	usage();

}



