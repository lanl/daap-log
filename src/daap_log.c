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
 * The actual means by which log messages (or database rows) make it off
 * the compute cluster and into the external analytics system are hidden 
 * from the user by this library. 
 *
 * Functions in this file:
 *****************
 * daapLogWrite()
 *
 *****************
 * daapLogRead()
 *
 *   Placeholder. Would provide the ability to read messages that 
 *   have been written by the application, **local to the node that is 
 *   calling the function**. Will be further developed if demand exists.
 *
 *****************
 * Copyright (C) 2020 Triad National Security, LLC. All rights reserved.
 * Original author: Charles Shereda, cpshereda@lanl.gov
 */

#include <string.h>

#include "daap_log.h"
#include "daap_log_internal.h"

//static bool volatile first_pass = true;

static pthread_mutex_t log_mutex = PTHREAD_MUTEX_INITIALIZER;

#if defined __APPLE__ 
#    define SYSLOGGER(level, args...) os_log(level, args)
#else
#    define SYSLOGGER(level, args...) vsyslog(level, args)
#endif

#if defined _BSD_SOURCE || _XOPEN_SOURCE >= 500 || _ISOC99_SOURCE || _POSIX_C_SOURCE >= 200112L
#   define USE_SNPRINTF 1
#else
#   define USE_SNPRINTF 0
#endif

// This function doesn't buy us much since it has to be wrapped in
// a preprocessor macro to prevent errors if we aren't using syslog. 
// We might not use this approach. Right now it's not being called.
static int daapSyslogWrite(int keyval, const char *message, ...) {
#if defined USE_SYSLOG
    /* needs to be thread safe */
    va_list args;
//    setlogmask (LOG_UPTO (LOG_INFO));
#if defined DEBUG
    va_start(args, message);
    vprintf (message, args);
    va_end(args);
#endif /* DEBUG */
    va_start(args, message);
    SYSLOGGER(init_data.level, message, args);
    va_end(args);
    closelog ();
#endif /* USE_SYSLOG */
    return 0;
}

/* Function to write out a message to a log (followed by escape/control args),
 * which will then make its way to an off-cluster data analytics system (Tivan
 * on the turquoise network at LANL).
 * 'Log' can mean syslog or a direct connection to a message broker (RabbitMQ,
 * LDMS Streams, a point-to-point user process, etc), or we can just aggregate 
 * and write only when the threshold is reached. The method used is selected 
 * at build time by setting the appropriate macro (an option in CMake). 
 * The string is prepended with some syslog-type info, whether or not syslog 
 * is the transport method - application name and hostname, for instance.
 *
 *   ***Note that daapLogWrite is subject to the same format string
 *   vulnerabilities/attacks as printf() and is not intended to be used by
 *   untrusted callers.
 */
int daapLogWrite(int keyval, const char *message, ...) {
    /* probably needs to be thread safe; or at least, callees 
     * must be thread safe */
    va_list args;
    struct timeval timestruct;
    unsigned long timestamp_millisec;
    char *timestamp_str, *buff, *full_message;
    int ts_len, msg_len, buff_sz, agg_threshold = 0;
    FILE *null_device;

#if defined DEBUG
    va_start(args, message);
    vprintf (message, args);
    va_end(args);
#endif
    /* don't have easy way of determining length of full message
     * apart from this hack */
    va_start(args, message);
    null_device = fopen(NULL_DEVICE, "w");
    msg_len = vfprintf(null_device, message, args);
    fclose(null_device);
    va_end(args);

    va_start(args, message);
    full_message = calloc(msg_len + 1, 1);
    vsprintf(full_message, message, args);
    va_end(args);
    /* get the wall clock time and convert this to a string timestamp -
     * this call allocates the memory for the input string, which must be freed
     * outside the call (at the end of this block). */
    ts_len = getmillisectime_as_str(&timestamp_str);
#if defined DEBUG
    printf("length = %d, timestamp_str = %s\n", ts_len, timestamp_str);
#endif
    // do some sanity checking on the data

    /* create JSON output from the data that's been passed in plus what's
     * already been populated in init_data struct */
    buff_sz = init_data.alloc_size
               + ts_len + 2 
	       + msg_len + 2;
    buff = calloc(buff_sz, 1);

    strcpy(buff, init_data.header_data);
    strcat(buff, timestamp_str);
    strcat(buff, "\",");
    strcat(buff, MSG_JSON_KEY);
    strcat(buff, "\"");
    strcat(buff, full_message);
    strcat(buff, "\"}");
    printf("complete json string = %s\n",buff);
    free(full_message);

    // if we are aggregating, just put the data in an internal buffer
    // and increment our aggregator until our threshold is reached;
    // else call the appropriate api (depending on macro def) to do the write

    /* Note: need to do this differently, can't be a stack that's popped
     * because it has to be FIFO. Commented out for now. *
    if( init_data.agg_val > 0 ) {
        if( agg_threshold < init_data.agg_val ) {
	    ret_val = push_message_stack(buff);
            agg_threshold++;
	    return ret_val;
	}
	else {
	    ret_val = transmit_message_stack;
	    agg_threshold = 0;
	    return ret_val;
	}
    }
    */
 
#if defined USE_SYSLOG
    va_start(args, message);
    SYSLOGGER(init_data.level, message, args);
    va_end(args);

#elif defined USE_RABBIT
    
#elif defined USE_LDMS

#elif defined USE_TCP
    /* send log message over socket opened with daapInit */
    write(sockfd, buff, buff_sz);

#endif
    free(timestamp_str);
    return 0;
}

/* Placeholder for now. Will only develop if there is interest.
 * Would provide the ability to read messages that have been written by 
 * the application, **local to the node that is calling the function**. 
 * Will be further developed if demand exists. */
int daapLogRead(int keyval, int time_interval, int max_rows, char **row_array) {

    /* fopen the local log; */
    /* search for keyval and time_interval; */
    /* populate at most max_rows of row_array with results; */
    return 0;
}

