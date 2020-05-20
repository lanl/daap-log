/* Function: int getmillisectime_as_str(char *) -
 * Takes an unallocated string parameter and populates 
 * it with a millisecond-from-the-epoch value of the
 * present time.
 */

#include <sys/time.h>
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include "timestr.h"

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
    //char *time_str = *buf;
    gettimeofday(&timestruct, NULL);
    timestamp_millisec = (unsigned long)timestruct.tv_sec * 1000 
                         + (unsigned long)timestruct.tv_usec / 1000;

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
    return length;
#else
    fprintf(stderr, "Error in getmillisectime_as_str function: daap_log library must be compiled as C99\n");
    return -1;
#endif /* USE_SNPRINTF */
}
