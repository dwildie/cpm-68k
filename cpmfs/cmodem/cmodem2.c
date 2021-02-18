/*
 *	Modem7 protocol drivers for CMODEM package. See CMODEM.C.
 *
 *	Added:	"CRC" mode, Abort via Control-X
 *		Stefan Badstuebner	4 Mar 83
 */

#include <stdio.h>
#include "bdsio.h"
#include "hardware.h"
#include "cmodem.h"

shocrt(sec, try, tot)
	int sec, try, tot; {
	if (sflg)
		printf("Sending #%d (Try=%d Errs=%d)  \r", sec, try, tot);
	else
		printf("Awaiting #%d (Try=%d, Errs=%d)  \r", sec, try, tot);

	if (try && tot)
		putchar('\n');
}

/* send char to modem */
send(data)
char data;
{
	while (!MOD_TBE)
		;
	MOD_TDATA(data);
}

unsigned char receive(seconds)
int seconds;
{
	unsigned char data;
	int lpc, seccnt, mscnt;

	/*printf("\n%d rx", seconds);*/
	for (lpc = 0; lpc < seconds; lpc++) {
		/*printf(".");*/
		/* One second loop */
		for (mscnt = 0; mscnt < 100; mscnt++) {
			/* Ten milli second loop */
			for (seccnt = 0; seccnt < SPS; seccnt++) {
				if (MOD_RDA) {
					data = MOD_RDATA;
					/*printf(" %x", data & 0xFF);*/
					return (data);
				}
			}
		}
	}
	/*printf("z\n");*/
	return (TIMEOUT);
}

purgeline() {
	while (MOD_RDA)
		MOD_RDATA; /* purge the receive register	*/
}

rcvfile(file)
	char *file; {
	int total;
	int j, firstchar, sectcurr, sectcomp, errors;
	int errorflag;
	int rcvd_char;
	int good_record;

	sflg = FALSE;
	fd = creat(file);

	if (fd == -1) {
		printf("CMODEM: cannot create %s\n", file);
		exit(1);
	}

	printf("\nReady to receive %s\n", file);
	sectnum = 0;
	errors = 0;
	toterr = 0;
	bufctr = 0;
	purgeline();

	/*
	 *	Since the Modem protocol implies that
	 *	the Receiver starts the Xfer process;
	 *	The following code was added. <sb>
	 */
	if (crc_flag)
		send(CRC);
	else
		send(NAK);

	shocrt(0, 0, 0);
	do {
		errorflag = FALSE;
		do
			firstchar = receive(10);
		while (firstchar != SOH && firstchar != EOT && firstchar != TIMEOUT);

		if (firstchar == TIMEOUT)
			errorflag = TRUE;
		if (firstchar == SOH) {
			sectcurr = receive(5);
			sectcomp = receive(5);

			if ((sectcurr + sectcomp) == 255) {
				/*printf("sector number valid %d\n", sectcurr);*/
				if (sectcurr == ((sectnum + 1) & 0xFF)) {
					/*printf("sector number is expected %d\n", sectcurr);*/
					checksum = 0;
					crc_value = 0;
					for (j = bufctr; j < (bufctr + SECSIZ); j++) {
						buffer[j] = receive(5);
						checksum = (checksum + buffer[j]) & 0xff;
						calc_crc(&crc_value, buffer[j]);
					}
					rcvd_char = receive(5);
					calc_crc(&crc_value, rcvd_char);
					if (crc_flag) {
						rcvd_char = receive(5);
						calc_crc(&crc_value, rcvd_char);
					}

					if (crc_flag)
						good_record = (crc_value == 0);
					else {
						good_record = (checksum == rcvd_char);
					}

					if (good_record) {
						/*printf("Valid cksum: calculated 0x%x, received 0x%x\n", checksum, rcvd_char);*/
						errors = 0;
						sectnum = sectcurr;
						bufctr = bufctr + SECSIZ;
						total += SECSIZ;
						if (bufctr == TBFSIZ) {
							bufctr = 0;
							write(fd, buffer, NSECTS * SECSIZ);
						}
						shocrt(sectnum, errors, toterr);
						send(ACK);
					} else {
						if (crc_flag) {
							printf("Invalid crc: calculated 0x%x\n", crc_value);
						} else {
							printf("Invalid cksum: calculated 0x%x, received 0x%x\n", checksum & 0xff, rcvd_char & 0xff);
						}
						errorflag = TRUE;
					}
				} else if (sectcurr == sectnum) {
					printf("sector number is previous %d\n", sectcurr);
					do
						; while (receive(1) != TIMEOUT);
					send(ACK);
				} else {
					printf("sector number %d expected %d\n", sectcurr, sectnum + 1);
					errorflag = TRUE;
				}
			} else {
				printf("sector number invalid %d - %d\n", sectcurr, sectcomp);
				errorflag = TRUE;
			}
		}
		if (errorflag == TRUE) {
			errors++;
			if (sectnum)
				toterr++;
			while (receive(1) != TIMEOUT)
				;
			shocrt(sectnum, errors, toterr);
			if (crc_flag)
				send(CRC);
			else
				send(NAK);
		}
	} while (firstchar != EOT && errors != ERRORMAX);

	if ((firstchar == EOT) && (errors < ERRORMAX)) {
		send(ACK);
		bufctr = (bufctr + SECSIZ - 1) / SECSIZ;
		write(fd, buffer, bufctr * SECSIZ);
		close(fd);
		printf("\nDone %d bytes received\n", total);
	} else
		printf("\n\Aborting\n\n");
}

sendfile(file)
	char *file;
{
	char *npnt;
	int rqst;
	int j, bytes, attempts;
	int total;

	sflg = TRUE;
	fd = open(file, 0);

	if (fd == -1) {
		printf("\nCMODEM: %s not found\n", file);
		return;
	}

	purgeline();
	attempts = 0;
	toterr = 0;
	crc_flag = FALSE;

	printf("\nAwaiting Initial Request...");

	do {
		rqst = receive(6);
	} while (rqst != NAK && rqst != CRC && ++attempts < 10);

	if (attempts == 10) {
		printf("\nNo Response, Aborting...\n");
		return;
	}

	if (rqst == CRC) {
		printf("\nReceived 'C': CRC Transfer Requested\n");
		crc_flag = TRUE;
	} else {
		crc_flag = FALSE;
		printf("\nReceived NAK: Checksum Transfer Requested\n");
	}

	putchar('\n');

	attempts = 0;
	sectnum = 1;

	while ((bytes = read(fd, buffer, NSECTS * SECSIZ)) && (attempts != RETRYMAX)) {
		/*printf("\nRead %d bytes, %d sectors\n", bytes, bytes/SECSIZ);*/
		if (bytes == -1) {
			printf("\nFile read error.\n");
			break;
		} else {
			bufctr = 0;
			do {
				attempts = 0;
				do {
					shocrt(sectnum, attempts, toterr);
					send(SOH);
					send(sectnum);
					send(-sectnum - 1);
					checksum = 0;
					crc_value = 0;
					if (bytes < SECSIZ) {
						/* This will be the last packet, stuff the unused buffer with CTRL-Z chars */
						for (j = bytes; j < SECSIZ; j++) {
							buffer[bufctr + j] = CTRL_Z;
						}
					}
					for (j = bufctr; j < (bufctr + SECSIZ); j++) {
						send(buffer[j]);
						checksum = (checksum + buffer[j]) & 0xff;
						calc_crc(&crc_value, buffer[j]);
					}
					if (crc_flag) {
						calc_crc(&crc_value, 0);
						calc_crc(&crc_value, 0);
						send(crc_value >> 8);
						send(crc_value);
					} else
						send(checksum);

					attempts++;
					toterr++;
				} while ((receive(10) != ACK) && (attempts != RETRYMAX));

				total += SECSIZ;
				bufctr = bufctr + SECSIZ;
				sectnum++;
				bytes -= SECSIZ;
				toterr--;
			} while ((bytes > 0) && (attempts != RETRYMAX));
		}
	}
	if (attempts == RETRYMAX)
		printf("\nNo ACK on sector, aborting\n");
	else {
		attempts = 0;
		do {
			printf("\nEnd of file, sending EOT\n");
			send(EOT);
			attempts++;
		} while ((receive(10) != ACK) && (attempts != RETRYMAX));
		if (attempts == RETRYMAX)
			printf("\nNo ACK on EOT, aborting\n");
	}
	close(fd);
	printf("\nDone %d bytes sent\n", total);
}

/*
 * Calculate the CCITT CRC polynomial X^16 + X^12 + X^5 + 1
 *
 *	Adapted by Stefan Badstuebner from the assembly language
 *	version of CRCSUBS ver. 1.20 by Paul Hansknecht JUN '81
 */

calc_crc(crc, a_byte)
	unsigned *crc;int a_byte; {
	int carry, i, mask;

	mask = 0x80;

	for (i = 0; i < 8; i++) {
		carry = *crc & 0x8000; /* Preserve MSB state */

		*crc <<= 1;

		*crc |= (a_byte & mask ? 1 : 0);

		if (carry)
			*crc ^= 0x1021;

		mask >>= 1;
	}
}

unsigned char inp(p)
	int p; {
	return *port(p);
}

void outp(p, ch)
	int p;char ch; {
	*port(p) = ch;
}

