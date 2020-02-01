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
 * daapLogWrite(const char *message, int keyval, ...)
 *
 *   Logs <message> (followed by escape/control arguments) to a logfile
 *   (at present, syslog) with priority of <level> that is transmitted
 *   to the remote monitoring system (Tivan at LANL). <app_name> is a 
 *   user-defined string that is prepended to the message - normally this
 *   would be the name of the calling application but it is at the user's
 *   discretion. <keyval> is an integer key-value that may be used later 
 *   when searching through the logs. It is prepended to the message. 
 *
 *   ***Note that daapLogWrite is subject to the same format string
 *   vulnerabilities/attacks as printf() and is not intended to be used by
 *   untrusted callers.
 *
 *****************
 * daapLogRead(int keyval, int time_interval)
 *
 *   Placeholder. Would provide the ability to read messages that 
 *   have been written by the application, **local to the node that is 
 *   calling the function**. Will be further developed if demand exists.
 *
 *****************
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

//static bool volatile first_pass = true;

static pthread_mutex_t gethost_mutex = PTHREAD_MUTEX_INITIALIZER;

#if defined __APPLE__ 
#    define SYSLOGGER(level, args...) os_log(level, args)
#else
#    define SYSLOGGER(level, args...) vsyslog(level, args)
#endif

/* global declaration of init_t struct init_data, initialized by daapInit(),
 * finalized in daapFinalize(), and accessed by the *Write() functions. */
extern daap_init_t init_data;

// This function doesn't buy us much since it will have to be wrapped in
// a preprocessor macro to prevent errors if we aren't using syslog. 
// We might not use this approach. Right now it's not being called.
#if defined USE_SYSLOG
static int daapSyslogWrite(const char *app_name, int level, int keyval, const char *message, ...) {
    /* needs to be thread safe */
    va_list args;
//    setlogmask (LOG_UPTO (LOG_NOTICE));
#if defined DEBUG
    va_start(args, message);
    vprintf (message, args);
    va_end(args);
#endif
    va_start(args, message);
    SYSLOGGER(level, message, args);
    va_end(args);
    closelog ();
    return 0;
}
#endif /* USE_SYSLOG */

/* Function to write out a string to the log. Log can mean syslog or a direct
 * connection to a message broker (RabbitMQ, LDMS Streams, or a point-to-point
 * user process, or we can just aggregate with this and write only when the
 * threshold is reached. The method used is selected at build time by setting the 
 * appropriate macro (an option in CMake). 
 * The string is prepended with some syslog-type info, whether or not
 * syslog is the transport mechanism - application name, message level, and
 * hostname, for instance. */
int daapLogWrite(const char *app_name, int level, int keyval, const char *message, ...) {
    /* probably needs to be thread safe; or at least, callees 
     * must be thread safe */
    va_list args;
//    setlogmask (LOG_UPTO (LOG_NOTICE));
#if defined DEBUG
    va_start(args, message);
    vprintf (message, args);
    va_end(args);
#else
    openlog (app_name, LOG_NDELAY | LOG_PID, LOG_USER);
#endif
    va_start(args, message);
    // get the clocktime and convert this to a string timestamp

    // do some sanity checking on the data

    // create the JSON from the data that's been passed in plus what's
    // already been populated in init_data like hostname and job_id

    // if we are aggregating, just push the data to an internal
    // stack and increment our aggregator until our threshold is reached.

    // else call the appropriate api (depending on macro def) to do the write

#if defined USE_SYSLOG
    SYSLOGGER(level, message, args);

#elif defined USE_RABBIT

#elif defined USE_LDMS

#elif defined USE_P2P

#endif
    va_end(args);
    return 0;
}

/* Placeholder for now. Will only develop if there is interest */
int daapLogRead(int keyval, int time_interval, int max_rows, char **row_array) {

    /* fopen the local log; */
    /* search for keyval and time_interval; */
    /* populate at most max_rows of row_array with results; */
    return 0;
}

