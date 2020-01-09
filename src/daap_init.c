/* 
 * Data Analytics Application Profiling API
 *
 * A simplifying and abstracting usercode-oriented library that 
 * provides the means for codes running on HPC cluster compute nodes
 * to log messages to a logfile on an external system -
 * at LANL this is the Tivan Data Analytics system.
 * From the external system, logs can be analyzed (to see if a code is 
 * still progressing normally, for instance).
 *
 * The API provided here does not do the transfer to the Analytics system
 * itself; instead it communicates with the thing (message broker, syslog, 
 * LDMSD, point-to-point communicator, or whatever else) that does the 
 * transfer off the cluster and then gets the data to a place where it
 * can be accessed from the Data Analytics system.
 *
 * Also provides a function to create formatted JSON for a later insert
 * as a row in a remote timeseries database
 * (in the LANL case, OpeTSDB, and again, residing on Tivan) 
 * assuming the row is correctly formatted. This data can then 
 * be visualized using Grafana on the Analytics system. 
 *
 * Users should be made aware that if the row is *not* correctly 
 * formatted or if there is some other problem with the data,
 * the failure to insert may be a silent one. This is because the 
 * attempt to insert into the database is an independent process 
 * that happens after data has moved off of compute nodes, with no
 * link back to the user process that created the data using this library.
 * 
 * The actual means by which log messages (or database rows) make it off
 * the compute cluster and into the external analytics system are hidden 
 * from the user by this library. 
 *
 * Header file: daap_log.h
 * Shared library: libdaap_log.so
 * Static library: libdaap_log.a
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

#include "daap_log.h"

#if defined USE_SYSLOG
#    if defined __APPLE__
#        include <os/log.h>
#        include <pwd.h>
#    else
#        include <syslog.h>
#    endif
#elif defined USE_RABBIT

#elif defined USE_LDMS

#elif defined USE_P2P

#endif

#include <stdio.h>
#include <errno.h>
#include <unistd.h>
#include <sys/types.h>
#include <stdarg.h>
#include <stdlib.h>
#include <string.h>

//static bool volatile first_pass = true;

static pthread_mutex_t gethost_mutex = PTHREAD_MUTEX_INITIALIZER;

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
static int daap_gethostname(char *hostname) {

    size_t count, length = LOCAL_MAXHOSTNAMELEN;
    int ret_val, num_tries = 0;

    /* thread safe */
    pthread_mutex_lock(&gethost_mutex);

    char *buf = calloc( 1, length );
    if( buf == NULL ) {
        pthread_mutex_unlock(&gethost_mutex);
        return DAAP_ERROR_OUT_OF_MEMORY;
    }

    while( num_tries < NUM_TRIES_FOR_NULL_HOSTNAME) {
        num_tries++;

        /*
         * Offer all but the last byte of the buffer to gethostname.
         */
        ret_val = gethostname( buf, length - 1 );
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
                hostname = buf;
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
int daapInit(const char *app_name, int msg_level, int agg_type) {
    // Might need to be thread safe. What happens if two openmp
    // threads enter this at the same time when we are using a global
    // struct to hold the initialized data?

    int ret_val = 0;

    /* allocate memory for and populate init_data.hostname with the 
     * hostname by calling daap_gethostname().*/
    ret_val = daap_gethostname(init_data.hostname);
    if( ret_val != 0 ) {
        // set errno?
        // fprintf(stderr, something); Depending on debug level??
        return ret_val;
    }
 
    /* copy the user-provided name of the app into init_data */
    strcpy(init_data.appname, app_name);

    /* if we are using syslog, open the log with the user-provided msg_level */
#if defined USE_SYSLOG
#   if defined DEBUG
        openlog(init_data.appname, LOG_PERROR | LOG_CONS | LOG_PID | LOG_NDELAY, msg_level);
#   else
        openlog(app_name, LOG_NDELAY | LOG_PID, LOG_USER);
#   endif

#elif defined USE_RABBIT

#elif defined USE_LDMS

#elif defined USE_P2P

#endif
    return ret_val;
}

/* Free memory from allocated components of init_data */
int daapFinalize(void) {
    // Likely needs to be thread safe
    int ret_val = 0;
    free(init_data.hostname);
    free(init_data.appname);
    // other stuff here such as closing the logfile or connection
    return ret_val;
}
