/* Header file for includes, functions and structures, 
 * and so on that are *not* part of the API */

#include <stdio.h>
#include <errno.h>
#include <sys/types.h>
#include <stdarg.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <pthread.h>
#include <sys/time.h>

/* Syslog includes */
#    if defined __APPLE__
#        include <os/log.h>
#        include <pwd.h>
#    else
#        include <syslog.h>
#    endif

#include <sys/socket.h>
#include <arpa/inet.h>

# define PORT 5555

#define NULL_DEVICE "/dev/null"

#if defined __APPLE__ 
#    define SYSLOGGER(level, args...) os_log(level, args)
#else
#    define SYSLOGGER(level, args...) vsyslog(level, args)
#endif

#ifndef DEBUG
#    define DEBUG 0
#endif

extern bool daapInit_called;

extern unsigned long getmillisectime();
extern int getmillisectime_as_str(char **time_str);

#define LOCAL_MAXHOSTNAMELEN 257
#ifndef HOST_NAME_MAX
#define HOST_NAME_MAX 256
#endif

#if (HOST_NAME_MAX > LOCAL_MAXHOSTNAMELEN)
#define LOCAL_MAXHOSTNAMELEN HOST_NAME_MAX
#endif

char daap_hostname[LOCAL_MAXHOSTNAMELEN];

#define FILENAME (strrchr(__FILE__, '/') ? strrchr(__FILE__, '/') + 1 : __FILE__)
#define PRINT_MAX 1024

/* Caution: va_list args from a parent function such as daapLogWrite() cannot be 
 * passed through as a second argument from a parent function */
static inline char *deformat(const char *format_str, ... )
{
    static char output_str[PRINT_MAX];
    va_list args;
    va_start(args, *format_str);
    output_str[0] = '\0';
    vsnprintf(output_str, PRINT_MAX - 1, format_str, args);
    va_end(args);
    return output_str;
} 

/* Note that x must be wrapped in parentheses if it contains multiple components
 * (string with format specifiers plus arguments).
 *
 * Note also that PRINT_OUTPUT (and deformat()) do not allow you to pass through 
 * va_list args from a parent function (such as daapLogWrite, for instance). */
#define PRINT_OUTPUT(file, x) {                  \
    struct timeval tval;                         \
    double timestamp;                            \
    gettimeofday(&tval, NULL);                   \
    timestamp = tval.tv_sec + 1E-6*tval.tv_usec; \
    fprintf(file,"Time: %lf Host: %s %s:%s: %s\n", timestamp, daap_hostname, FILENAME,  __func__, deformat x ); \
    fflush(file);                                \
}

static pthread_mutex_t print_mutex = PTHREAD_MUTEX_INITIALIZER;

#define DEBUG_OUTPUT(x) {    \
    if (DEBUG) {                    \
        pthread_mutex_lock(&print_mutex);   \
        PRINT_OUTPUT(stdout, x);          \
        pthread_mutex_unlock(&print_mutex); \
    } \
}

#define ERROR_OUTPUT(x) {       \
    pthread_mutex_lock(&print_mutex); \
    PRINT_OUTPUT(stderr, x);    \
    pthread_mutex_unlock(&print_mutex); \
}
