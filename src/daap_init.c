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
 * Additional authors: Hugh Greenberg, hng@lanl.gov
 */

#include "daap_log.h"
#include "daap_log_internal.h"

bool daapInit_called = false;
static pthread_mutex_t init_mutex = PTHREAD_MUTEX_INITIALIZER;
static pthread_mutex_t finalize_mutex = PTHREAD_MUTEX_INITIALIZER;

#define NUM_TRIES_FOR_NULL_HOSTNAME 8

/* global declaration of daap_init_t struct init_data, initialized by daapInit(),
 * finalized in daapFinalize(), and accessed by the *Write() functions. */
daap_init_t init_data;

/*
 * This gethostname wrapper does not populate the full-length hostname in
 * those rare cases where it is too long for the buffer. It does, however,
 * guarantee a null-terminated hostname, even if it's
 * truncated. It also tries again in the case where gethostname returns an
 * error because the buffer is initially too short.
 * Note: only call from thread-safe regions).
 */
static int daap_gethostname(char **hostname) {

    size_t count, length = LOCAL_MAXHOSTNAMELEN;
    int ret_val, num_tries = 0;

    char *buf = calloc(length, 1);
    if( buf == NULL ) {
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
            return DAAP_ERROR_IN_ERRNO;
        }

        /*
         * If we get here, it means we want to double the length of
         * the buffer and try again.
         */
        length *= 2;
        buf = realloc(buf, length);
        if( buf == NULL ) {
            return DAAP_ERROR_OUT_OF_MEMORY;
        }
    } /* end while */

    /* If we got here, it means that we tried too many times and are
     * giving up. */
    free(buf);
    return DAAP_ERROR;
}

/* Initializer for library. */
int daapInit(const char *app_name, int msg_level, int agg_val, transport transport_type) {
    /* Assume this needs to be thread safe.
     * All data at present in daapInit structs is specific to a process,
     * not a thread, so only populate struct once per MPI task (thread group).
     */
    pthread_mutex_lock(&init_mutex);
    if( daapInit_called ) {
        pthread_mutex_unlock(&init_mutex);
        return DAAP_SUCCESS;
    }
    //DEBUG_OUTPUT(("Debug output"));
    //PRINT_OUTPUT(stdout, ("Print output"));
    int ret_val = 0;
    size_t envvar_len = 0;

    /* note that app_name is a user-provided value rather than 
     * using the command line value */
    init_data.appname = calloc(strlen(app_name) + 1, 1);
    strcpy(init_data.appname, app_name);
    init_data.agg_val = agg_val;
    init_data.transport_type = transport_type;

    /* get user */ 
    if( getenv("USER") != NULL  ) {
        init_data.user = strdup(getenv("USER"));
    }
    else {
        init_data.user = calloc(1, 1);
    }

    if( getenv("SLURMD_NODENAME") != NULL  ) {
        init_data.hostname = strdup(getenv("SLURMD_NODENAME"));
    }
    else {
        /* allocate memory for and populate init_data.hostname with the 
         * hostname by calling daap_gethostname().*/
        ret_val = daap_gethostname(&init_data.hostname);
        if( ret_val != DAAP_SUCCESS ) {
            // set errno?
            perror("error in call to gethostname, daapInit failed");
            pthread_mutex_unlock(&init_mutex);
            return ret_val;
	}
    }
    /* set daap_hostname[] for purposes of printing output (not part of API) */
    strncpy(daap_hostname, init_data.hostname, LOCAL_MAXHOSTNAMELEN);
    daap_hostname[LOCAL_MAXHOSTNAMELEN - 1] = '\0';
    /* get slurm job id */
    /* this assignment (w/o a malloc) should be ok since buff is a const char* */
    if( getenv("SLURM_JOB_ID") != NULL  ) {
        init_data.job_id = strdup(getenv("SLURM_JOB_ID"));
    }
    else {
        init_data.job_id = calloc(1, 1);
    }
    /* get slurm job name */ 
    if( getenv("SLURM_JOB_NAME") != NULL  ) {
        envvar_len = strlen(getenv("SLURM_JOB_NAME"));
        init_data.job_name = calloc(envvar_len + 1, 1);
        strcpy(init_data.job_name, getenv("SLURM_JOB_NAME"));
    }
    else {
        init_data.job_name = calloc(1, 1);
    }
    /* get cluster name */ 
    if( getenv("SLURM_CLUSTER_NAME") != NULL  ) {
        envvar_len = strlen(getenv("SLURM_CLUSTER_NAME"));
        init_data.cluster_name = calloc(envvar_len + 1, 1);
        strcpy(init_data.cluster_name, getenv("SLURM_CLUSTER_NAME"));
    }
    else {
        init_data.cluster_name = calloc(1, 1);
    }
    /* get cpus on node */ 
    if( getenv("SLURM_CPUS_ON_NODE") != NULL  ) {
        init_data.cpus_on_node = atoi(getenv("SLURM_CPUS_ON_NODE"));
    }
    else {
        init_data.cpus_on_node = 0;
    }
    /* get cpus per task (only populated if --cpus-per-task used w/slurm) */ 
    if( getenv("SLURM_CPUS_PER_TASK") != NULL  ) {
        envvar_len = strlen(getenv("SLURM_CPUS_PER_TASK"));
        init_data.cpus_per_task = calloc(envvar_len + 1, 1);
        strcpy(init_data.cpus_per_task, getenv("SLURM_CPUS_PER_TASK"));
    }
    else {
        init_data.cpus_per_task = calloc(1, 1);
    }
    /* get number of nodes in job allocation */
    if( getenv("SLURM_JOB_NODES") != NULL  ) {
        envvar_len = strlen(getenv("SLURM_JOB_NODES"));
        init_data.job_nodes = calloc(envvar_len + 1, 1);
        strcpy(init_data.job_nodes, getenv("SLURM_JOB_NODES"));
    }
    else {
        init_data.job_nodes = calloc(1, 1);
    }
    /* get node list for job */ 
    if( getenv("SLURM_JOB_NODELIST") != NULL  ) {
        envvar_len = strlen(getenv("SLURM_JOB_NODELIST"));
        init_data.job_nodelist = calloc(envvar_len + 1, 1);
        strcpy(init_data.job_nodelist, getenv("SLURM_JOB_NODELIST"));
    }
    else {
        init_data.job_nodelist = calloc(1, 1);
    }
    /* get number of tasks for job */
    if( getenv("SLURM_NTASKS") != NULL  ) {
	init_data.ntasks = atoi(getenv("SLURM_NTASKS"));
    } else {
	init_data.ntasks = 0;
    }

    /* get MPI rank of this task (SLURM_PROCID == rank) */
    if( getenv("SLURM_PROCID") != NULL  ) {
	init_data.mpi_rank = atoi(getenv("SLURM_PROCID"));
    }
    else {
	init_data.mpi_rank = 0;
    }

    /* get process ID of the task */
    if( getenv("SLURM_TASK_PID") != NULL  ) {
        init_data.task_pid = atoi(getenv("SLURM_TASK_PID"));
    }
    else {
        init_data.task_pid = 0;
    }
    /* get slurm tasks per node */
    if( getenv("SLURM_TASKS_PER_NODE") != NULL  ) {
        envvar_len = strlen(getenv("SLURM_TASKS_PER_NODE"));
        init_data.tasks_per_node = calloc(envvar_len + 1, 1);
        strcpy(init_data.tasks_per_node, getenv("SLURM_TASKS_PER_NODE"));
    }
    else {
        init_data.tasks_per_node = calloc(1, 1);
    }

    /* if we are using syslog, open the log with the user-provided msg_level */
    if ( transport_type == SYSLOG ) {
#   if defined DEBUG
        openlog(init_data.appname, LOG_PERROR | LOG_CONS | LOG_PID | LOG_NDELAY, msg_level);
#   else
	//setlogmask(LOG_UPTO (LOG_NOTICE));
        openlog(init_data.appname, LOG_NDELAY | LOG_PID, LOG_USER);
#   endif
    }
    
    daapInit_called = true;
    pthread_mutex_unlock(&init_mutex);

    if (ret_val < 0) {
	perror("Fatal error");
	exit(1);
    }

    return ret_val;
}

/* Free memory from allocated components of init_data */
int daapFinalize(void) {
    // Likely needs to be thread safe
    int ret_val = 0;

    pthread_mutex_lock(&finalize_mutex);
    free(init_data.hostname);
    free(init_data.appname);
    free(init_data.user);
    free(init_data.job_id);
    free(init_data.job_name);
    free(init_data.cluster_name);
    free(init_data.cpus_per_task);
    free(init_data.job_nodes);
    free(init_data.job_nodelist);
    free(init_data.tasks_per_node);

    pthread_mutex_unlock(&finalize_mutex);
    return DAAP_SUCCESS;
}
