/* Header file for includes, functions and structures, 
 * and so on that are *not* part of the API */

#include <stdio.h>
#include <errno.h>
#include <sys/types.h>
#include <stdarg.h>
#include <stdlib.h>
#include <stdbool.h>

#    if defined __APPLE__
#        include <os/log.h>
#        include <pwd.h>
#    else
#        include <syslog.h>
#    endif

# include <sys/socket.h>
# include <arpa/inet.h>
# define PORT 5555

#define NULL_DEVICE "/dev/null"

extern bool daapInit_called;

extern int getmillisectime_as_str(char **time_str);

/* struct initialized by daapInit(),finalized in daapFinalize(), 
 * and accessed by the *Write() functions. */
extern daap_init_t init_data;
