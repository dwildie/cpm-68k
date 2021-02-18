/*
 * This header file contains hardware-dependent definitions for C programs.
 * If the symbol "DIRECT_CURSOR" has been defined at the point this file
 * is included into the program, then the "gotoxy" function
 * and other advanced video-terminal functions will be compiled. THIS FILE
 * MUST BE CUSTOMIZED BY EACH INDIVIDUAL USER AT THE TIME BDS C IS BROUGHT UP.
 */

/*
 * Some console (video) terminal characteristics:
 */

#define TWIDTH	80	/* # of columns	*/
#define TLENGTH	24	/* # of lines	*/
#define CLEARS	"\033E"	/* String to clear screen on console	*/
#define INTOREV	"\033p"	/* String to switch console into reverse video	*/
#define OUTAREV "\033q"	/* String to switch console OUT of reverse video  */
#define CURSOROFF "\033x5"	/* String to turn cursor off	*/
#define CURSORON "\033y5"	/* String to turn cursor on	*/
#define ESC	'\033'	/* Standard ASCII 'escape' character	*/


#ifdef DIRECT_CURSOR		/* if user has enabled advanced	*/
				/* video-terminal functions: 	*/
gotoxy(x,y)
{
	bios(4,ESC);
	bios(4,'Y');
	bios(4, x + ' ');
	bios(4, y + ' ');
}

clear()
{
	bios(4,ESC);
	bios(4,'E');
}

#endif

#define port(x) ((unsigned char *)(0xffff0000 + (x)))
unsigned char inp();
void outp();

/*
	The following definitions provide a portable low-level interface
	for direct I/O to the  console and modem devices. The values
	used here are only for example; be certain to go in and customize
	them for your system! Note that only one of the two sections
	(I/O port vs. memory mapped) will be needed for your system,
	so feel free to edit the unused section out of the file and remove
	the conditional compilation lines around the section you end up
	using.
*/

#define PORT_DATA	0xA3
#define PORT_STAT	0xA1
#define STAT_TBE	0x04
#define STAT_RDA	0x01

/* this section for status-driven I/O only */
#define	MOD_TBE			(inp(PORT_STAT) & STAT_TBE)	/* Modem */
#define MOD_RDA			(inp(PORT_STAT) & STAT_RDA)
#define	MOD_TDATA(byte)	(outp(PORT_DATA, byte))
#define	MOD_RDATA		(inp(PORT_DATA))
#define MOD_CTRL(byte)	(outp(PORT_STAT, byte))
