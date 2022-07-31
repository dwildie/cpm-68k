#ifndef __FAT_H
#define __FAT_H

int initFat();
void closeFat();

void* fl_fopen(const char *path, const char *modifiers);
int   fl_fwrite(const void * data, int size, int count, void *file );
int   fl_fread(void * data, int size, int count, void *file );
void  fl_fclose(void *file);

void  fatTest();

#endif
