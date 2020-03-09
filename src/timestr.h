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

static int inline getmillisectime_as_str(char **time_str) {
    struct timeval timestruct;
    unsigned long timestamp_millisec = 0;
    //char *time_str = *buf;
    gettimeofday(&timestruct, NULL);
    timestamp_millisec = (unsigned long)timestruct.tv_sec * 1000 
                         + (unsigned long)timestruct.tv_usec / 1000;
    //timestamp_sec = (unsigned long)timestruct.tv_sec;

#if USE_SNPRINTF
    /* First, use snprintf to get the length before actually 
     * populating time_str so that we're sure how much memory to allocate. */
    const int length = snprintf(NULL, 0, "%lu", timestamp_millisec);
    assert(length > 0);
    time_str[0] = calloc(length+1, 1);
    /* Now, populate time_str */
    int c = snprintf(time_str[0], length+1, "%lu", timestamp_millisec);
    assert(time_str[0][length] == '\0');
    assert(c == length);
#   if defined DEBUG
    printf("time_str = %s\n", *time_str);
#   endif
    //free(timestamp_str);
    return length;
#else
    fprintf(stderr, "Error in gettime_as_str function: daap_log library must be compiled as C99\n");
    return -1;
#endif /* USE_SNPRINTF */
}
