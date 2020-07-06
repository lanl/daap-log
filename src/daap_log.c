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

#include "daap_log_internal.h"
#include "daap_log.h"
#include "cJSON.h"

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
/* static int daapSyslogWrite(const char *message, ...) {
    va_list args;

    if (!init_data.transport_type == SYSLOG) {
       return 0;
    }
//    setlogmask (LOG_UPTO (LOG_INFO));
#if defined DEBUG
    va_start(args, message);
    vprintf (message, args);
    va_end(args);
#endif 

    va_start(args, message);
    SYSLOGGER(init_data.level, message, args);
    va_end(args);
    closelog ();

    return 0;
}
*/
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
/*
char *pmix_test_output_prepare(const char *fmt, ... )
{
    static char output[OUTPUT_MAX];
    va_list args;
    va_start( args, fmt );
    memset(output, 0, sizeof(output));
    vsnprintf(output, OUTPUT_MAX - 1, fmt, args);
    va_end(args);
    return output;
}
*/
/*
char *deformat(const char *format_str, ...)
{
    static char output_str[PRINT_MAX];
    va_list args;
    va_start(args, *format_str);
    memset(output_str, 0, sizeof(output_str));
    vsnprintf(output_str, PRINT_MAX - 1, format_str, args);
    va_end(args);
    return output_str;
}
*/

int daapLogWrite(const char *message, ...) {
    /* probably needs to be thread safe; or at least, callees 
     * must be thread safe */
    va_list args;
    char *json_str;
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
    vsnprintf(full_message, msg_len, message, args);
    va_end(args);
    DEBUG_OUTPUT((full_message));

    tstamp = getmillisectime();
    // do some sanity checking on the data here?

    /* create JSON output from the data that's been passed in plus what's
     * already been populated in init_data struct */
    json_str = daapBuildJSON(tstamp, full_message);
    if (json_str == NULL) {
	    goto end;
    }

    DEBUG_OUTPUT(("Complete json string: %s",json_str));

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
      SYSLOGGER(init_data.level, full_message, args);
    } else if (init_data.transport_type == TCP) {
      count = daapTCPLogWrite(json_str, strlen(json_str));
      DEBUG_OUTPUT(("Writing message: %s, written: %d", json_str, count));
    }
    free(json_str);

 end:
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

char *daapBuildJSON(long timestamp, char *message) {
    char *string = NULL;
    cJSON *source_val = NULL;
    cJSON *app_val = NULL;
    cJSON *user_val = NULL;
    cJSON *hostname_val = NULL;
    cJSON *jobid_val = NULL;
    cJSON *jobname_val = NULL;
    cJSON *cpusonnode_val = NULL;
    cJSON *cpuspertask_val = NULL;
    cJSON *clustername_val = NULL;
    cJSON *jobnodes_val = NULL;
    cJSON *jobnodelist_val = NULL;
    cJSON *ntasks_val = NULL;
    cJSON *mpirank_val = NULL;
    cJSON *pid_val = NULL;
    cJSON *taskspernode_val = NULL;
    cJSON *timestamp_val = NULL;
    cJSON *message_val = NULL;
    cJSON *data = cJSON_CreateObject();


    if (data == NULL) {
	goto end;
    }

    /* Build cJSON Object */
    source_val = cJSON_CreateString(DAAP_JSON_VAL);
    if (source_val == NULL) {
	goto end;
    }

    cJSON_AddItemToObject(data, DAAP_JSON_KEY, source_val);
    app_val = cJSON_CreateString(init_data.appname);
    if (app_val == NULL) {
	goto end;
    }

    cJSON_AddItemToObject(data, APP_JSON_KEY, app_val);
    user_val = cJSON_CreateString(init_data.user);
    if (user_val == NULL) {
	goto end;
    }

    cJSON_AddItemToObject(data, USER_JSON_KEY, user_val);
    hostname_val = cJSON_CreateString(init_data.hostname);
    if (hostname_val == NULL) {
	goto end;
    }

    cJSON_AddItemToObject(data, HOST_JSON_KEY, hostname_val);
    jobid_val = cJSON_CreateString(init_data.job_id);
    if (jobid_val == NULL) {
	goto end;
    }

    cJSON_AddItemToObject(data, JOB_ID_JSON_KEY, jobid_val);
    jobname_val = cJSON_CreateString(init_data.job_name);
    if (jobname_val == NULL) {
	goto end;
    }

    cJSON_AddItemToObject(data, JOB_NAME_JSON_KEY, jobname_val);
    clustername_val = cJSON_CreateString(init_data.cluster_name);
    if (jobname_val == NULL) {
	goto end;
    }

    cJSON_AddItemToObject(data, CLUSTER_NAME_JSON_KEY, clustername_val);
    cpusonnode_val = cJSON_CreateNumber(init_data.cpus_on_node);
    if (cpusonnode_val == NULL) {
	goto end;
    }

    cJSON_AddItemToObject(data, CPUS_ON_NODE_JSON_KEY, cpusonnode_val);
    cpuspertask_val = cJSON_CreateString(init_data.cpus_per_task);
    if (cpuspertask_val == NULL) {
	goto end;
    }

    cJSON_AddItemToObject(data, CPUS_PER_TASK_JSON_KEY, cpuspertask_val);
    jobnodes_val = cJSON_CreateString(init_data.job_nodes);
    if (cpuspertask_val == NULL) {
	goto end;
    }

    cJSON_AddItemToObject(data, JOB_NODES_JSON_KEY, jobnodes_val);
    jobnodelist_val = cJSON_CreateString(init_data.job_nodelist);
    if (cpuspertask_val == NULL) {
	goto end;
    }

    cJSON_AddItemToObject(data, JOB_NODELIST_JSON_KEY, jobnodelist_val);
    ntasks_val = cJSON_CreateNumber(init_data.ntasks);
    if (ntasks_val == NULL) {
	goto end;
    }

    cJSON_AddItemToObject(data, NTASKS_JSON_KEY, ntasks_val);
    mpirank_val = cJSON_CreateNumber(init_data.mpi_rank);
    if (mpirank_val == NULL) {
	goto end;
    }

    cJSON_AddItemToObject(data, MPI_RANK_JSON_KEY, mpirank_val);
    pid_val = cJSON_CreateNumber(init_data.task_pid);
    if (mpirank_val == NULL) {
	goto end;
    }

    cJSON_AddItemToObject(data, TASK_PID_JSON_KEY, pid_val);
    taskspernode_val = cJSON_CreateString(init_data.tasks_per_node);
    if (taskspernode_val == NULL) {
	goto end;
    }

    cJSON_AddItemToObject(data, TASKS_PER_NODE_JSON_KEY, taskspernode_val);
    timestamp_val = cJSON_CreateNumber(timestamp);
    if (timestamp_val == NULL) {
	goto end;
    }

    cJSON_AddItemToObject(data, TS_JSON_KEY, timestamp_val);
    message_val = cJSON_CreateString(message);
    if (message_val == NULL) {
	goto end;
    }

    cJSON_AddItemToObject(data, MSG_JSON_KEY, message_val);
    string = cJSON_PrintUnformatted(data);
    if (string == NULL) {
	ERROR_OUTPUT(("Failed to convert json object to string.\n"));
    }

 end:
    cJSON_Delete(data);
    return string;
}
