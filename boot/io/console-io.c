#include <stdio.h>

extern size_t writeStrn(const char *bp, size_t n);

size_t io_write(FILE* instance, const char *bp, size_t n) {
	return writeStrn(bp,n);
}

size_t io_read (FILE* instance, char *bp, size_t n) {
	return n;
}


struct File_methods methods = { &io_write, &io_read };

struct File console = { &methods };

struct File* const stdin = &console;
struct File* const stdout = &console;
struct File* const stderr = &console;
