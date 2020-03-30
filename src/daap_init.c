/* 
 * Data Analytics Application Profiling API
 *
 * Functions in this file:
 *****************
 * daapInit(const char *app_name, int level)
 *   Populates some global variables with initialized information
 *   using the function parameters and data specific to the node/job,
 *   like hostname and job_id. 
 *
 *****************
 * daapFinalize(void)
 *   Cleans up / depopulates / dallocates (as required) structures 
 *   populated by daapInit. 
 * 
 *****************
 *
 * Copyright (C) 2020 Triad National Security, LLC. All rights reserved.
 * Original author: Charles Shereda, cpshereda@lanl.gov
 */

#include <stdio.h>
#include <errno.h>
#include <sys/types.h>
#include <stdarg.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>

#include "daap_log.h"
/* Syslog includes */
#    if defined __APPLE__
#        include <os/log.h>
#        include <pwd.h>
#    else
#        include <syslog.h>
#    endif

/* TCP includes/struct */
# include <sys/socket.h>
# include <arpa/inet.h>
# define PORT 5555

/* socket struct */
struct sockaddr_in servaddr;
int sockfd;

bool daapInit_called = false;
static pthread_mutex_t gethost_mutex = PTHREAD_MUTEX_INITIALIZER;
static pthread_mutex_t init_mutex = PTHREAD_MUTEX_INITIALIZER;

#if defined __APPLE__ 
#    define SYSLOGGER(level, args...) os_log(level, args)
#else
#    define SYSLOGGER(level, args...) vsyslog(level, args)
#endif

#define LOCAL_MAXHOSTNAMELEN 257

#ifndef HOST_NAME_MAX
#define HOST_NAME_MAX 256
#endif

#if (HOST_NAME_MAX > LOCAL_MAXHOSTNAMELEN)
#define LOCAL_MAXHOSTNAMELEN HOST_NAME_MAX
#endif

#define NUM_TRIES_FOR_NULL_HOSTNAME 8

static char daap_hostname[LOCAL_MAXHOSTNAMELEN];

/* global declaration of daap_init_t struct init_data, initialized by daapInit(),
 * finalized in daapFinalize(), and accessed by the *Write() functions. */
daap_init_t init_data;

/*
 * This gethostname wrapper does not populate the full-length hostname in
 * those rare cases where it is too long for the buffer. It does, however,
 * guarantee a null-terminated hostname is place in daap_hostname, even if it's
 * truncated. It also tries again in the case where gethostname returns an
 * error because the buffer is initially too short.
 */
static int daap_gethostname(char **hostname) {

    size_t count, length = LOCAL_MAXHOSTNAMELEN;
    int ret_val, num_tries = 0;

    /* thread safe */
    pthread_mutex_lock(&gethost_mutex);

    char *buf = calloc(length, 1);
    if( buf == NULL ) {
        pthread_mutex_unlock(&gethost_mutex);
        return DAAP_ERROR_OUT_OF_MEMORY;
    }

    while( num_tries < NUM_TRIES_FOR_NULL_HOSTNAME) {
        num_tries++;

        /*
         * Offer all but the last byte of the buffer to gethostname.
         */
        ret_val = gethostname(buf, length - 1);
        /*
         * Terminate the buffer in the last position.
         */
        buf[length - 1] = '\0';
        if( ret_val == 0 ) {
            count = strlen( buf );
            /* The result was not truncated */
            if( count > 0 && count < length - 1 ) {
                /*
                 * If we got a good result, save it.  This value may
                 * be longer than what callers to local_gethostname()
                 * are expecting, so that should be checked by the
                 * caller.
                 */
                *hostname = buf;
                pthread_mutex_unlock(&gethost_mutex);
                return DAAP_SUCCESS;
            }
            /*
             * count = 0: The buffer is empty. In some gethostname
             *             implementations, this can be because the
             *             buffer was too small.
             * count == (length-1): The result *may* be truncated;
             *                      we can't know for sure and 
             *                      should resize the buffer.
             *
             * If it's one of these cases, we'll fall through to
             * increase the length of the buffer and try again.
             *
             * If it's not one of these good cases, it's an error:
             * return.
             */
            else if( !(count == 0 || count == length - 1) ) {
                free(buf);
                pthread_mutex_unlock(&gethost_mutex);
                return DAAP_ERROR;
            }
        }
        /*
         * errno == EINVAL or ENAMETOOLONG: hostname was truncated and
         *              there was an error. Perhaps there is something
         *              in the buffer and perhaps not.
         *
         * If it's one of these cases, we'll fall through to
         * increase the length of the buffer and try again.
         *
         * If it's not one of these good cases, it's an error; return.
         */
        else if( !(errno == EINVAL || errno == ENAMETOOLONG) ) {
            free(buf);
            pthread_mutex_unlock(&gethost_mutex);
            return DAAP_ERROR_IN_ERRNO;
        }

        /*
         * If we get here, it means we want to double the length of
         * the buffer and try again.
         */
        length *= 2;
        buf = realloc(buf, length);
        if( buf == NULL ) {
            pthread_mutex_unlock(&gethost_mutex);
            return DAAP_ERROR_OUT_OF_MEMORY;
        }
    } /* end while */

    /* If we got here, it means that we tried too many times and are
     * giving up. */
    free(buf);
    pthread_mutex_unlock(&gethost_mutex);
    return DAAP_ERROR;
}

/* Initializer for library. */
int daapInit(const char *app_name, int msg_level, int agg_val, transport transport_type) {
    // Might need to be thread safe. What happens if two openmp
    // threads enter this at the same time when we are using a global
    // struct to hold the initialized data?
    pthread_mutex_lock(&init_mutex);

    int ret_val = 0;
    const char *buff;

    /* allocate memory for and populate init_data.hostname with the 
     * hostname by calling daap_gethostname().*/
    ret_val = daap_gethostname(&init_data.hostname);
    if( ret_val != 0 ) {
        // set errno?
        perror("error in call to gethostname, daapInit failed");
	pthread_mutex_unlock(&init_mutex);
        return ret_val;
    }
    /*printf("ret_val = %d, Hostname = %s\n", ret_val, init_data.hostname);*/

    /* note that app_name is a user-provided value rather than 
     * using the command line value */
    init_data.appname = calloc(strlen(app_name), 1);
    strcpy(init_data.appname, app_name);
    init_data.agg_val = agg_val;
    init_data.transport_type = transport_type;

    /* get slurm job id */
    /* this assignment (w/o a malloc) should be ok since buff is a const char* */
    if( (buff = getenv("SLURM_JOB_ID")) != NULL ) {
        init_data.job_id = calloc(strlen(buff), 1);
        strcpy(init_data.job_id, buff);
    }
    else {
        init_data.job_id = calloc(2, 1);
        strcpy(init_data.job_id, "0");
    }

    /* determine and save the amount of mem required for everything in the struct*/
    init_data.alloc_size = 
                 strlen(DAAP_JSON_KEY_VAL) + 2
	       + strlen(APP_JSON_KEY) + 2
	       + strlen(init_data.appname) + 2
	       + strlen(HOST_JSON_KEY) + 2
               + strlen(init_data.hostname) + 2 
	       + strlen(JOB_ID_JSON_KEY) + 2
	       + strlen(init_data.job_id) + 2
	       + strlen(TS_JSON_KEY) + 2
	       + strlen(MSG_JSON_KEY) + 2;
    /* build the first part of the output json string (the part that won't change
     * message to message) */
    init_data.header_data = calloc(init_data.alloc_size, 1);
    init_data.header_data[0] = '{';
    strcat(init_data.header_data, DAAP_JSON_KEY_VAL);
    strcat(init_data.header_data, APP_JSON_KEY);
    strcat(init_data.header_data, "\"");
    strcat(init_data.header_data, init_data.appname);
    strcat(init_data.header_data, "\",");
    strcat(init_data.header_data, HOST_JSON_KEY);
    strcat(init_data.header_data, "\"");
    strcat(init_data.header_data, init_data.hostname);
    strcat(init_data.header_data, "\",");
    strcat(init_data.header_data, JOB_ID_JSON_KEY);
    strcat(init_data.header_data, "\"");
    strcat(init_data.header_data, init_data.job_id);
    strcat(init_data.header_data, "\",");
    strcat(init_data.header_data, TS_JSON_KEY);
    strcat(init_data.header_data, "\"");
    /* if we are using syslog, open the log with the user-provided msg_level */
    if ( transport_type == SYSLOG ) {
#   if defined DEBUG
        openlog(init_data.appname, LOG_PERROR | LOG_CONS | LOG_PID | LOG_NDELAY, msg_level);
#   else
	//setlogmask(LOG_UPTO (LOG_NOTICE));
        openlog(init_data.appname, LOG_NDELAY | LOG_PID, LOG_USER);
#   endif
    } else if ( transport_type == TCP ) {
	/* open a socket for later comms */ 
	
	/* create and verify socket */
	sockfd = socket(AF_INET, SOCK_STREAM, 0);
	ret_val = sockfd;
	if( ret_val < 0 ) {
	    perror("socket creation failed");
	    pthread_mutex_unlock(&init_mutex);
	    return ret_val;
	}
	
	bzero(&servaddr, sizeof(servaddr));
	
	/* assign IP, PORT */
	servaddr.sin_family = AF_INET;
	/* server is always on the local host */
	servaddr.sin_addr.s_addr = inet_addr("127.0.0.1");
	servaddr.sin_port = htons(PORT);
	
	/* connect the client to the server */
	ret_val = connect(sockfd, (struct sockaddr*)&servaddr, sizeof(servaddr));
        printf("Retval from connect: %d\n", ret_val); 
	if( ret_val != 0 ) {
	    perror("connection to the TCP server failed");
	    pthread_mutex_unlock(&init_mutex);
	    return ret_val;
	}
    }
    
    daapInit_called = true;
    pthread_mutex_unlock(&init_mutex);
    return ret_val;
}

/* Free memory from allocated components of init_data */
int daapFinalize(void) {
    // Likely needs to be thread safe
    int ret_val = 0;

    // Close connection if using TCP
    if (init_data.transport_type == TCP) {
	close(sockfd);
    }
	
    free(init_data.hostname);
    free(init_data.appname);
    free(init_data.job_id);
    free(init_data.header_data);

    return ret_val;
}
