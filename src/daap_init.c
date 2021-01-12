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
bool daapRank_zero = false;

static pthread_mutex_t init_mutex = PTHREAD_MUTEX_INITIALIZER;
static pthread_mutex_t finalize_mutex = PTHREAD_MUTEX_INITIALIZER;

#define NUM_TRIES_FOR_NULL_HOSTNAME 8

/* global declaration of daap_init_t struct init_data, initialized by daapInit(),
 * finalized in daapFinalize(), and accessed by the *Write() functions. */
daap_init_t init_data;

extern int daapInitializeSSL();
extern void daapShutdownSSL();

/*
 * This gethostname wrapper does not populate the full-length hostname in
 * those rare cases where it is too long for the buffer. It does, however,
 * guarantee a null-terminated hostname, even if it's truncated. It also
 * tries again in the case where gethostname returns an error because the
 * buffer is initially too short.
 * Note: only call from thread-safe regions.
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
    int ret_val = DAAP_SUCCESS;
    size_t envvar_len = 0;

    /* note that app_name is a user-provided value rather than
     * using the command line value */
    init_data.appname = calloc(strlen(app_name) + 1, 1);
    strcpy(init_data.appname, app_name);
    init_data.agg_val = agg_val;
    init_data.transport_type = transport_type;

    /* If the local env runs an RM other than SLURM, logic can be
       added below to accomodate that */
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
    /* get cluster name */
    if( getenv("SLURM_CLUSTER_NAME") != NULL  ) {
        envvar_len = strlen(getenv("SLURM_CLUSTER_NAME"));
        init_data.cluster_name = calloc(envvar_len + 1, 1);
        strcpy(init_data.cluster_name, getenv("SLURM_CLUSTER_NAME"));
    }
    else {
        init_data.cluster_name = calloc(1, 1);
    }

    /* if we are using syslog, open the log with the user-provided msg_level */
    if ( transport_type == SYSLOG ) {
#       if defined DEBUG
            openlog(init_data.appname, LOG_PERROR | LOG_CONS | LOG_PID | LOG_NDELAY, msg_level);
#       else
            //setlogmask(LOG_UPTO (LOG_NOTICE));
            openlog(init_data.appname, LOG_NDELAY | LOG_PID, LOG_USER);
#       endif
    }
    else if ( transport_type == TCP) {
        daapInitializeSSL();

    }

    daapInit_called = true;
    pthread_mutex_unlock(&init_mutex);

    if (ret_val < 0) {
        perror("Fatal error");
        exit(1);
    }

    /* Send job start message to message broker/syslog if DAAP_DECOUPLE env var
       not set or set to 0 and the mpi rank is 0 */
    if ( getenv("SLURM_PROCID") != NULL ) {
        if (!(strcmp(getenv("SLURM_PROCID"), "0")) ) {
            daapRank_zero = true;
        }
    }
    else if ( getenv("OMPI_COMM_WORLD_RANK") != NULL ) {
        if (!(strcmp(getenv("OMPI_COMM_WORLD_RANK"), "0")) ) {
            daapRank_zero = true;
        }
    }
    else if ( getenv("PMIX_RANK") != NULL ) {
        if (!(strcmp(getenv("PMIX_RANK"), "0")) ) {
            daapRank_zero = true;
        }
    }
    else if ( getenv("PMI_RANK") != NULL ) {
        if (!(strcmp(getenv("PMI_RANK"), "0")) ) {
            daapRank_zero = true;
        }
    }
    /* add other env variable cases in here for other flavors of MPI */
    /* if we don't have any way to determine rank, but the user is expecting
     * daapInit to handle the job start message, assume we are running serially,
     * but warn with a debug message */
    else if ( (getenv("DAAP_DECOUPLE") == NULL) ||
            !(strcmp(getenv("DAAP_DECOUPLE"), "0")) ) {
        DEBUG_OUTPUT(("DAAP cannot determine which task is rank 0. Assuming serial run."));
        daapRank_zero = true;
    }

    if ( daapRank_zero ) {
        if ( (getenv("DAAP_DECOUPLE") == NULL) ||
           !(strcmp(getenv("DAAP_DECOUPLE"), "0")) ) {
            ret_val += daapLogJobStart();
        }
    }

    return ret_val;
}

void daapinit_(char* app_name, int len) {
    app_name[len] = '\0';
    daapInit(app_name, 0, DAAP_AGG_OFF, TCP);
}

/* Free memory from allocated components of init_data */
int daapFinalize(void) {
    int ret_val;

    pthread_mutex_lock(&finalize_mutex);

    /* Send job end message to message broker/syslog if this is rank 0 and
       DAAP_DECOUPLE env var not set or set to 0. */
    if ( daapRank_zero ) {
        if ( (getenv("DAAP_DECOUPLE") == NULL) ||
           !(strcmp(getenv("DAAP_DECOUPLE"), "0")) ) {
            ret_val = daapLogJobEnd();
        }
    }

    daapShutdownSSL();

    free(init_data.hostname);
    free(init_data.appname);
    free(init_data.cluster_name);

    pthread_mutex_unlock(&finalize_mutex);
    return ret_val;
}

void daapfinalize_(void) {
    daapFinalize();
}
