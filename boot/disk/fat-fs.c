#include <stdio.h>
#include "fat_filelib.h"

void listFatDirectory(const char *path)
{
	fl_listdirectory(path);
}

static FL_FILE* file = NULL;

int fOpenFAT(const char *path, const char *modifiers)
{
	char name[255];
	if (path[0] == '/') {
		strcpy(name, path);
	} else {
		name[0] = '/';
		strcpy(&name[1], path);
	}

	file = fl_fopen(name, modifiers);
	return file;
}

int fReadFAT(int count, void *buffer)
{
	return fl_fread(buffer, 1, count, file);
}

int fWriteFAT(int count, void *buffer)
{
  return fl_fwrite(buffer, 1, count, file);
}

void fCloseFAT()
{
	fl_fclose(file);
	file = NULL;
}
