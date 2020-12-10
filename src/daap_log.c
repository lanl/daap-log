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
 * API functions in this file:
 *****************
 * daapLogWrite()
 *
 * Writes out a user-specified message, with format specifier capability.
 * Note that this is not a secure function and contains the same format vulnerabilities
 * as calling printf() and should not be used in untrusted environments.
 *
 *****************
 * daapLogHeartbeat()
 * daapLogJobStart()
 * daapLogJobEnd()
 *
 * Each of these calls sends a special message indicating an active job heartbeat, the start
 * of a job, and the end of a job, respectively. daapLogJobStart() and daapLogJobEnd()
 * should only be called by a user if the environment variable DAAP_DECOUPLE is set to a
 * nonzero value.
 * Otherwise, daapLogJobStart() is called automatically by daapInit(), and daapLogJobEnd() by
 * daapFinalize().
 *
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
 * Authors: Charles Shereda, cpshereda@lanl.gov
 *          Hugh Greenberg, hng@lanl.gov
 */

#include <string.h>

#include "daap_log_internal.h"
#include "daap_log.h"

static pthread_mutex_t log_mutex = PTHREAD_MUTEX_INITIALIZER;

#if defined _BSD_SOURCE || _XOPEN_SOURCE >= 500 || _ISOC99_SOURCE || _POSIX_C_SOURCE >= 200112L
#   define USE_SNPRINTF 1
#else
#   define USE_SNPRINTF 0
#endif

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
int daapLogWrite(const char *message, ...) {
    /* probably needs to be thread safe; or at least, callees
     * must be thread safe */
    va_list args;
    char *influx_str;
    char full_message[DAAP_MAX_MSG_LEN+1];
    unsigned long tstamp;
    int agg_threshold = 0;
    FILE *null_device;
    int count, msg_len;
    static bool first_time_in_write = true;

    if (!daapInit_called) {
        errno = EPERM;
        perror("Initialize with daapInit() before calling daapLogWrite()");
        return DAAP_ERROR;
    }

    /* don't have easy way of determining length of full message
     * apart from this hack. */
    va_start(args, message);
    null_device = fopen(NULL_DEVICE, "w");
    msg_len = vfprintf(null_device, message, args);
    fclose(null_device);
    va_end(args);

    if (msg_len > DAAP_MAX_MSG_LEN) {
        ERROR_OUTPUT(("Message is longer than DAAP_MAX_MSG_LEN: %d; truncating.", DAAP_MAX_MSG_LEN));
        msg_len = DAAP_MAX_MSG_LEN;
    }

    va_start(args, message);
    vsnprintf(full_message, msg_len + 1, message, args);
    va_end(args);
    DEBUG_OUTPUT((full_message));

    tstamp = getmillisectime();
    // do some sanity checking on the data here?

    influx_str = daapBuildInflux(tstamp, full_message);
    if (influx_str == NULL) {
        goto end;
    }

    DEBUG_OUTPUT(("Complete influx string: %s", influx_str));

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

    if (init_data.transport_type == SYSLOG) {
        DAAP_SYSLOG(init_data.level, influx_str);
    } else if (init_data.transport_type == TCP) {
        count = daapTCPLogWrite(influx_str, strlen(influx_str));
        DEBUG_OUTPUT(("Writing message: %s, written: %d", influx_str, count));
    }
    free(influx_str);

 end:
    return DAAP_SUCCESS;
}

void daaplogwrite_(char *message, int len) {
    message[len] = '\0';
    daapLogWrite(message);
}

/* Sends a heartbeat message that can then be used in analytics system
   to see status of individual processes that make up a running job and whether
   all are reporting */
int daapLogHeartbeat(void) {
    return daapLogWrite("__daap_heartbeat");
}

/* Sends a message to mark the point of a job's start */
int daapLogJobStart(void) {
    return daapLogWrite("__daap_jobstart");
}

/* Sends a message to mark the point of a job's end */
int daapLogJobEnd(void) {
    return daapLogWrite("__daap_jobend");
}

/* Function to write out an influx message to a log (followed by escape/control args),
 * which will then make its way to an off-cluster data analytics system (Tivan
 * on the turquoise network at LANL).
 * 'Log' can mean syslog or a direct connection to a message broker (RabbitMQ,
 * LDMS Streams, a point-to-point user process, etc), or we can just aggregate
 * and write only when the threshold is reached. The method used is selected
 * at build time by setting the appropriate macro (an option in CMake).
 * The string is prepended with some syslog-type info, whether or not syslog
 * is the transport method - application name and hostname, for instance.
 *
 *   ***Note that daapLogRawWrite is subject to the same format string
 *   vulnerabilities/attacks as printf() and is not intended to be used by
 *   untrusted callers.
 */
int daapLogRawWrite(const char *message, ...) {
    /* probably needs to be thread safe; or at least, callees
     * must be thread safe */
    va_list args;
    char *influx_str;
    char full_message[DAAP_MAX_MSG_LEN+1];
    int agg_threshold = 0;
    FILE *null_device;
    int count, msg_len;
    static bool first_time_in_write = true;

    if (!daapInit_called) {
        errno = EPERM;
        perror("Initialize with daapInit() before calling daapLogRawWrite()");
        return DAAP_ERROR;
    }

    /* don't have easy way of determining length of full message
     * apart from this hack. */
    va_start(args, message);
    null_device = fopen(NULL_DEVICE, "w");
    msg_len = vfprintf(null_device, message, args);
    fclose(null_device);
    va_end(args);

    if (msg_len > DAAP_MAX_MSG_LEN) {
        ERROR_OUTPUT(("Message is longer than DAAP_MAX_MSG_LEN: %d; truncating.", DAAP_MAX_MSG_LEN));
        msg_len = DAAP_MAX_MSG_LEN;
    }

    va_start(args, message);
    vsnprintf(full_message, msg_len + 1, message, args);
    va_end(args);
    DEBUG_OUTPUT((full_message));

    /* create influx output from the data that's been passed in plus what's
     * already been populated in init_data struct */
    influx_str = daapBuildRawInflux(full_message);
    if (influx_str == NULL) {
        goto end;
    }

    DEBUG_OUTPUT(("Complete influx string: %s", influx_str));

    if (init_data.transport_type == SYSLOG) {
        DAAP_SYSLOG(init_data.level, influx_str);
    } else if (init_data.transport_type == TCP) {
        count = daapTCPLogWrite(influx_str, strlen(influx_str));
        DEBUG_OUTPUT(("Writing message: %s, written: %d", influx_str, count));
    }
    free(influx_str);

 end:
    return 0;
}

/* Placeholder for now. Will only develop if there is interest.
 * Would provide the ability to read messages that have been written by
 * the application, **local to the node that is calling the function**.
 * Will be further developed if demand exists. */
int daapLogRead(int key, int time_interval, int max_rows, char **row_array) {

    /* fopen the local log; */
    /* search for key and time_interval; */
    /* populate at most max_rows of row_array with results; */
    return 0;
}

char *daapBuildInflux(long timestamp, char *message) {
    int max_size = 2048;
    char *influx_msg = malloc(max_size);
    long long tstamp = timestamp * 1000000;

    snprintf(influx_msg, max_size,
	    "daap,%s=%s,%s=%s,%s=%s,%s=%d %s=\"%s\" %lld",
	    APP_KEY, init_data.appname,
	    HOST_KEY, init_data.hostname,
	    CLUSTER_NAME_KEY, init_data.cluster_name,
	    MPI_RANK_KEY, init_data.mpi_rank,
	    MSG_KEY, message,
	    tstamp);

    return influx_msg;
}

char *daapBuildRawInflux(char *message) {
    int max_size = 2048;
    char *influx_msg = malloc(max_size);

    snprintf(influx_msg, max_size,
	     "daap,%s",
	     message);

    return influx_msg;
}

