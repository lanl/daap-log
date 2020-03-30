/* 
 * Data Analytics Application Profiling API
 *
 * Provides a simplifying user code-oriented library that interfaces 
 * with intermediaries so that data can be logged or rows inserted
 * into a database on a remote monitoring cluster 
 * (Tivan at LANL on the unclassified network).
 *
 * Copyright (C) 2020 Triad National Security, LLC. All rights reserved.
 * Original author: Charles Shereda, cpshereda@lanl.gov
 *
 */

#include <pthread.h>

#include <syslog.h>
#include <unistd.h>

/* BEGIN_C_DECLS should be used at the beginning of your declarations,
   so that C++ compilers don't mangle their names.  Use END_C_DECLS at
   the end of C declarations. */
#undef BEGIN_C_DECLS
#undef END_C_DECLS
#ifdef __cplusplus
# define BEGIN_C_DECLS extern "C" {
# define END_C_DECLS }
#else
# define BEGIN_C_DECLS /* empty */
# define END_C_DECLS /* empty */
#endif

/* PARAMS is a macro used to wrap function prototypes, so that
   compilers that don't understand ANSI C prototypes still work,
   and ANSI C compilers can issue warnings about type mismatches. */
#undef PARAMS
#if defined __STDC__ || defined _AIX \
        || (defined __mips && defined _SYSTYPE_SVR4) \
        || defined WIN32 || defined __cplusplus
# define PARAMS(protos) protos
#else
# define PARAMS(protos) ()
#endif

/* Enum for transport types */
typedef enum transports {
  NONE,
  SYSLOG,
  TCP
} transport;

/* Struct type for holding a tag (the combination of tag name and tag value)*/
typedef struct {
    char *tag_name;
    char *tag_val;
} tag_t;

/* Struct type for holding metric-related data */
typedef struct {
    char *metric_name;
    char *metric_value;
    int metric_id; 
    char *hostname;
    char *job_id;
    int cpu_id;
    int num_tags;
    tag_t tag_array[10];
} metric_t;

/* Struct for holding initialization data */
typedef struct {
    char *appname;
    char *hostname;
    char *job_id;
    int level;
    int agg_val;
    int alloc_size;
    transport transport_type;
    char *header_data;
} daap_init_t;

#define DAAP_JSON_KEY_VAL "\"source\":\"daap_log\","
#define APP_JSON_KEY "\"appname\":"
#define HOST_JSON_KEY "\"hostname\":"
#define JOB_ID_JSON_KEY "\"job_id\":"
#define TS_JSON_KEY "\"timestamp\":"
#define MSG_JSON_KEY "\"message\":"

#define DAAP_SUCCESS 0
#define DAAP_ERROR  -1
#define DAAP_ERROR_OUT_OF_MEMORY 1
#define DAAP_ERROR_IN_ERRNO 2

#define DAAP_AGG_OFF       0
#define DAAP_AGG_LOW      10
#define DAAP_AGG_MED     100
#define DAAP_AGG_HIGH   1000
#define DAAP_AGG_SUPER 10000

BEGIN_C_DECLS
/*   Populates some global variables with initialized information
 *   using the function parameters and data specific to the node/job,
 *   like hostname and job_id. */
int daapInit(const char *app_name, int msg_level, int agg_type, transport transport_type);

/*   Cleans up / depopulates / dallocates (as required) structure vars 
 *   populated by daapInit. */
int daapFinalize(void);

/* Function to write a log entry from within an app running on a cluster 
 * compute node. This entry will be transported off-cluster to the data 
 * analytics cluster (Tivan on the open side at LANL). daapInit must be
 * called prior to invoking daapLogWrite. */
int daapLogWrite(int keyval, const char *message, ...);

/* Initializes the combination of a named metric and a number of named tags
 *   (up to 10). Values for the metric and tags are then specified in each
 *   call to daapMetricWrite(). */
int daapMetricCreate(metric_t *metric, char *metricName, int numTags, char *tagNames[10]) ;

/* Deletes/deallocates structure created with daapTsdbCreateMetric() */
int daapMetricDestroy(metric_t metric);

/* Function to create valid JSON data from within an app running on a cluster
 * compute node. This JSON data will be transported off-cluster to the data
 * analytics cluster for insertion into a timeseries database (OpenTSDB on
 * Tivan on the open side at LANL) */
int daapMetricWrite(metric_t metric);

/* TCP Functions for Writing to a TCP Socket */
int daapTCPConnect(void);
int daapTCPClose(int sockfd);
int daapTCPLogWrite(char *buf, int buf_size);

END_C_DECLS
