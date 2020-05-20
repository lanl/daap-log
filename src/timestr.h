
#ifndef _POSIX_C_SOURCE
#   define _POSIX_C_SOURCE 200112L
#endif

#include <sys/time.h>
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>

#if _BSD_SOURCE || _XOPEN_SOURCE >= 500 || _ISOC99_SOURCE || _POSIX_C_SOURCE >= 200112L
#   define USE_SNPRINTF 1
#else   
#   define USE_SNPRINTF 0
#endif

unsigned long getmillisectime();
int getmillisectime_as_str(char **time_str);
