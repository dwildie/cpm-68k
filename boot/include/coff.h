typedef struct {
  unsigned short  f_magic;  /* magic number */
  unsigned short  f_nscns;  /* number of sections */
  long    f_timdat;         /* time & date stamp */
  long    f_symptr;         /* file pointer to symtab */
  long    f_nsyms;          /* number of symtab entries */
  unsigned short  f_opthdr; /* sizeof(optional hdr) */
  unsigned short  f_flags;  /* flags */
} coff_filehdr;

typedef struct {
  short magic;      /* see magic.h        */
  short vstamp;     /* version stamp      */
  long  tsize;      /* text size in bytes, padded to FWbdry         */
  long  dsize;      /* initialized data "  "    */
  long  bsize;      /* uninitialized data "   "   */
  long  entry;      /* entry pt.        */
  long  text_start; /* base of text used for this file  */
  long  data_start; /* base of data used for this file  */
} coff_aouthdr;

typedef struct scnhdr {
  char            s_name[8];  /* section name */
  long            s_paddr;    /* physical address */
  long            s_vaddr;    /* virtual address */
  long            s_size;     /* section size */
  long            s_scnptr;   /* file ptr to raw data for section */
  long            s_relptr;   /* file ptr to relocation */
  long            s_lnnoptr;  /* file ptr to line numbers */
  unsigned short  s_nreloc;   /* number of relocation entries */
  unsigned short  s_nlnno;    /* number of line number entries */
  long            s_flags;    /* flags */
} coff_scnhdr;
