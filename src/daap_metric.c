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
 * daapMetricCreate(metric_t metric, char *metricName, int numTags, char *tagNames[10])
 *
 *   Initializes the combination of a named metric and a number of named tags
 *   (up to 10). Values for the metric and tags are then specified in each
 *   call to daapMetricWrite().
 *   
 *   By setting up this combination of metric and tags ahead of time, it
 *   reduces the likelihood of many inserts of rows with different tags
 *   (that should actually be the same) into the downstream database.
 *
 * daapMetricWrite(metric_t metric)
 *
 *   Writes out JSON in a format consistent with that necessary
 *   to insert rows into a timeseries database (in the case of LANL, 
 *   this remote TSDB is OpenTSDB on Tivan). Does some checking to 
 *   try to verify that data can be inserted as a valid row in the
 *   database.
 *
 * daapMetricDestroy(void) 
 *
 *   Frees any memory that was allocated by 
 *   daapMetricCreate() and removes the association between the metric_id
 *   and the metric_name.
 ******************
 *
 *   While some format checking will be done, it is ultimately the
 *   responsibility of the caller to ensure that the metric, value, and tags
 *   are useful and well-formatted so that they will successfully insert
 *   into the database and so they can later be queried and visualized. 
 *   Because data must transfer off the cluster and pass through 
 *   a message broker prior to insertion into the database, no immediate
 *   feedback on whether the insertion succeeded or failed shoud be
 *   expected, either now or in the future.
 *   In addition to the user-defined tags, hostname (and possibly cpu ID)
 *   will also be written as tags to each row entry. 
 *   The metric_t type defines a struct that, in addition to metric
 *   information, also contains values for the hostname and cpu ID after
 *   a successful return from daapTsdbCreateMetric.
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

#elif defined USE_TCP

#endif

#include <stdio.h>
#include <errno.h>
#include <unistd.h>
#include <sys/types.h>
#include <stdarg.h>
#include <string.h>

//static bool volatile first_pass = true;

static pthread_mutex_t metric_mutex = PTHREAD_MUTEX_INITIALIZER;

/* global declaration of init_t struct init_data, initialized by daapInit(),
 * finalized in daapFinalize(), and accessed by the *Write() functions. */
extern daap_init_t init_data;

/* Why do we need a separate daapMetricCreate?
 * Logically it's not absolutely necessary; however, it helps the user 
 * to think about each set of metric + tag names as a bundle that can't
 * be modified, so that they aren't messing up the database with changing
 * metrics and tag names in cases where they should really be constant.
 * However, there is also a downside; if there were no daapMetricCreate(),
 * the metric struct would not need to be exposed to the user. 
 * Also, the caller still has to provide values for the metric and each tag 
 * when daapMetricWrite() is called. So whether we have this function or not 
 * is still an open question. */
int daapMetricCreate(metric_t *metric, char *metricName, int numTags, char *tagNames[10]) {
    // It's possible that the best way to do this is not by having the user
    // pass the metric struct, since this could complicate things for them

    // Likely needs to be thread safe 

    int ret_val;

    if( metricName[0] == '\0' ) {
        // set errno?
        // fprintf(stderr, something);
        return DAAP_ERROR;
    }
    // need more error checking here (eg, if metric_name isn't null-terminated)

    else {
        strcpy(metric->metric_name, metricName);
    }
    /* Add logic for setting up different transport layers that isn't already
       covered by daapInit() */

    /* Populate tag_name's in metric.tag_array with the incoming tagNames[]
     * vals, using numTags and checking for improperly terminated values */

    return ret_val;
}


int daapMetricDestroy(metric_t metric) {
    /* needs to be thread safe */
    int ret_val = 0;

    // free memory that was allocated for our metric_struct
    // maybe something else?
    // don't disconnect from our stream or close the log; that is
    // done in daapFinalize().
    return ret_val;
}
int daapMetricWrite(metric_t metric) {
    int ret_val = 0;
    /* needs to be thread safe */

    // get the clocktime and convert this to a string timestamp

    // do some sanity checking on the data

    // create the JSON from the data that's been passed in plus what's
    // already been populated in init_data like hostname and job_id

    // if we are aggregating, just push the data row to an internal
    // stack and increment our aggregator until our threshold is reached.


    // else call the appropriate api (depending on macro def) to do the write

#if defined USE_SYSLOG

#elif defined USE_RABBIT

#elif defined USE_LDMS

#elif defined USE_TCP
    // send record over our already-opened socket

#endif

    return ret_val;
}
