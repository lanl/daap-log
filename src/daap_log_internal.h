/* Header file for includes, functions and structures, 
 * and so on that are *not* part of the API */

#include <stdio.h>
#include <errno.h>
#include <sys/types.h>
#include <stdarg.h>
#include <stdlib.h>

#if defined USE_SYSLOG
#    if defined __APPLE__
#        include <os/log.h>
#        include <pwd.h>
#    else
#        include <syslog.h>
#    endif
#elif defined USE_RABBIT

#elif defined USE_LDMS

#elif defined USE_TCP
# include <sys/socket.h>
# include <arpa/inet.h>
# define PORT 5555
extern struct sockaddr_in servaddr;
extern int sockfd;
#endif

#define NULL_DEVICE "/dev/null"

extern int getmillisectime_as_str(char **time_str);

/* struct initialized by daapInit(),finalized in daapFinalize(), 
 * and accessed by the *Write() functions. */
extern daap_init_t init_data;
