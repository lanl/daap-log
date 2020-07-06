/*
 * Stdout/Results parser for daap_log library
 */
#include <stdio.h>
#include <stdlib.h>
#include <getopt.h>
#include <string.h>
#include <linux/limits.h>

#include "daap_log.h"

#define LINE_LEN 512

int parseResults(char *template_file, char *results_file);

void usage() {
    printf(
"./stdout_parser (-s || -t) -m -f\n\
   -s: syslog transport \n\
   -t: tcp transport \n\
   -m: template file \n\
   -f: stdout/results file\n\n");
    exit(0);
}

int main( int argc, char *argv[] ) {
    int log_level = LOG_NOTICE;
    int ret_val = -1;
    transport transport_type = NONE;
    int options = 0;
    char template_file[PATH_MAX];
    char results_file[PATH_MAX];

    while (( options = getopt(argc, argv, "tsm:f:")) != -1) {
	switch(options) {
	case 't':
	    transport_type = TCP;
	    break;
	case 's':
	    transport_type = SYSLOG;
	    break;
	case 'm':
	    snprintf(template_file, PATH_MAX, "%s", optarg);
	    break;
	case 'f':
	    snprintf(results_file, PATH_MAX, "%s", optarg);
	    break;
	default:
	    usage();
	}
    }

    if ( transport_type == NONE ) {
	usage();
    }

    if( (ret_val = daapInit("daap_stdout_parser", log_level, 
			    DAAP_AGG_OFF, transport_type)) != 0 ) {
        return ret_val;
    }

    ret_val = parseResults(template_file, results_file);
    daapFinalize();

    return 0;
}

int sendResult(char *key, char *val) {
    char *result;
    int res_len;
    int ret_val;

    if (!key || !val) {
	return -1;
    }

    res_len = strlen(key) + strlen(val) + 2;
    result = calloc(res_len, sizeof(char));
    snprintf(result, res_len, "%s=%s", key, val); 
    ret_val = daapLogWrite(result);
    if (ret_val != 0) {
        perror("Error in call to daapLogWrite");
    }

    return ret_val;
}

int validStart(char c) {
    int ret = 1;

    if (c == ' ') {
	ret = 0;
    } else if (c == '\t') {
	ret = 0;
    } else if (c == ':') {
	ret = 0;
    } else if (c == '?') {
	ret = 0;
    } else if (c == '=') {
	ret = 0;
    }

    return ret;
}

int validEnd(char c) {
    int ret = 0;

    if (c == ' ') {
	ret = 1;
    } else if (c == '\t') {
	ret = 1;
    } else if (c == '\n') {
	ret = 1;
    }

    return ret;
}

char *getVal(char *key, char *results_line) {
    int i, j;
    int res_len;
    int key_len;
    int val_start;
    int val_end;
    int val_len;
    char *val;

    if (!key || !results_line) {
	return NULL;
    }

    key_len = strlen(key);
    res_len = strlen(results_line);    
    for (i = 0; i < res_len; i++) {
	if ((strncmp(key, results_line + i, key_len)) != 0) {
	    continue;	    
	}
	val_start = val_end = -1;
	for (j = i + key_len; j < res_len; j++) {
	    if (val_start == -1 && ((validStart(results_line[j])) == 1)) {
		val_start = j;
	    }
	    if (val_start != -1 && ((validEnd(results_line[j])) == 1)) {
		val_end = j-1;
	    }
	}
    }

    val_len = -1;
    if (val_start >= 0 && val_end == -1) {
	val_len = (res_len - val_start) + 1;
    } else if (val_start >= 0 && val_end > 0) {
	val_len = (val_end - val_start) + 1;
    }

    if (val_len < 0) {
	return NULL;
    }

    val = calloc(val_len, sizeof(char));
    strncpy(val, results_line + val_start, val_len);
    return val;
}

int parseResults(char *template_file, char *results_file) {
    FILE *template, *results;
    char template_buf[LINE_LEN];
    char results_buf[LINE_LEN];
    char converted_buf[LINE_LEN];
    char *key, *val;
    int template_len;
    int results_len;

    template = fopen(template_file, "r");
    if (!template) {
	perror("Failed to open template file");
	return -1;
    }

    results = fopen(results_file, "r");
    if (!results) {
	perror("Failed to open results file");
	return -1;
    }

    while(fgets(template_buf, LINE_LEN, template)) {
	template_len = strlen(template_buf);
	if (template_len == 0) {
	    continue;
	}

	key = calloc(template_len, sizeof(char));
	strncpy(key, template_buf, template_len - 1);
	key[template_len - 1] = '\0';
	rewind(results);
	while(fgets(results_buf, LINE_LEN, results)) {
	    results_len = strlen(results_buf);
	    if (results_len == 0) {
		continue;
	    }

	    val = getVal(key, results_buf);
	    if (!val) {
		continue;
	    } else {
		sendResult(key, val);
	    }

	    free(val);
	}

	free(key);
    }

    fclose(template);
    fclose(results);
    return 0;
}
