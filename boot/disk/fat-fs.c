#include <stdio.h>
#include "fat_filelib.h"

void listFatDirectory(const char *path)
{

	fl_listdirectory(path);

//    FL_DIR dirstat;
//
//    if (fl_opendir(path, &dirstat))
//    {
//        struct fs_dir_ent dirent;
//
//        while (fl_readdir(&dirstat, &dirent) == 0)
//        {
//        }
//	}
}
