/* Function: int getmillisectime_as_str(char *) -
 * Takes an unallocated string parameter, allocates memory for it,
 * and populates it with a millisecond-from-the-epoch value of the
 * present time as calculated by gettimeofday()
 */

#ifndef _POSIX_C_SOURCE
#   define _POSIX_C_SOURCE 200112L
#endif

#include <sys/time.h>
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include "daap_log_internal.h"
#include "daap_log.h"

/* force asserts to work all the time */
#ifdef NDEBUG
#   undef NDEBUG
#endif

#if _BSD_SOURCE || _XOPEN_SOURCE >= 500 || _ISOC99_SOURCE || _POSIX_C_SOURCE >= 200112L
#   define USE_SNPRINTF 1
#else   
#   define USE_SNPRINTF 0
#endif

unsigned long getmillisectime() {
    struct timeval timestruct;
    unsigned long timestamp_millisec = 0;
    gettimeofday(&timestruct, NULL);
    timestamp_millisec = (unsigned long)timestruct.tv_sec * 1000 
                         + (unsigned long)timestruct.tv_usec / 1000;
    return timestamp_millisec;
}

int getmillisectime_as_str(char **time_str) {
    struct timeval timestruct;
    unsigned long timestamp_millisec = 0;
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
    DEBUG_OUTPUT(("time_str = %s\n", *time_str));
    return length;
#else
    ERROR_OUTPUT(("Error in getmillisectime_as_str function: daap_log library must be compiled as C99\n"));
    return DAAP_ERROR;
#endif /* USE_SNPRINTF */
}
