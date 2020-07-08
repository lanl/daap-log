/*
 * Stdout/Results parser for daap_log library
 */
#include <getopt.h>
#include <linux/limits.h>

#include "daap_log.h"
#include "daap_log_internal.h"

#define LINE_LEN 512
#define MAX_TOKENS 1024
typedef struct {
    char key[LINE_LEN];
    char val[LINE_LEN];
    bool found;
} token_t;

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
    template_file[0] = 0;
    results_file[0] = 0;

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

    if ( transport_type == NONE || template_file[0] == 0 || results_file[0] == 0 ) {
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
    free(result);
    return ret_val;
}

/*
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
        // too many strncmps here; instead try strstr
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
*/

int parseResults(char *template_file, char *results_file) {
    FILE *template, *results;
    char template_buf[LINE_LEN];
    char results_buf[LINE_LEN];
    char converted_buf[LINE_LEN];
    token_t key_val[MAX_TOKENS];
    char *key, *val, *token;
    int template_len, results_len, num_tokens, tokens_found;
    int i = 0;
    const char *delimiters = ":*=?\t\n";
    char *word;

    template = fopen(template_file, "r");
    if (!template) {
        ERROR_OUTPUT(("Failed to open template file: %s", template_file));
        return -1;
    }

    results = fopen(results_file, "r");
    if (!results) {
        ERROR_OUTPUT(("Failed to open results file: %s", results_file));
        return -1;
    }

    // instead of this while loop, see below
/*
    while(fgets(template_buf, LINE_LEN, template)) {
        template_len = strlen(template_buf);
        if (template_len == 0) {
            continue;
        }

        key = malloc(template_len);
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
*/
    // Replacement for above that should be faster (but take more memory):
    // store template file contents in memory;
    // go through each line of results and compare with what's in key array (template file).
    // for now, this only returns the first instance of a match between key and val

    // build the key array
    while(fgets(key_val[i].key, LINE_LEN, template) != NULL) {
        if (key_val[i].key[0] == 0) {
            continue;
        }
        key_val[i].found = false;
        token = strtok(key_val[i].key, delimiters); // strip trailing newlines (or other delimiters) 
        ++i;
        if (i == MAX_TOKENS) {
            ERROR_OUTPUT(("Too many tokens in template file. MAX_TOKENS = %d", MAX_TOKENS));
            return -1;
        }
    }
    key_val[i].key[0] = 0;
    num_tokens = i;

    tokens_found = 0;
    // examine each line in results file
    while(fgets(results_buf, LINE_LEN, results)) {
        // find the key - loop over all keys
        for( i = 0; i < num_tokens; ++i) {
            if (key_val[i].found) { // this logic only applies for one instance of a key per output file
                continue;
            }
            key = key_val[i].key;

            word = strstr(results_buf, key);
            //DEBUG_OUTPUT(("key = .%s., results_buf = .%s., word = .%s.\n", key, results_buf, word));
            if( word != NULL ) {
                ++tokens_found;
                key_val[i].found = true;
                // get the first token (the key) - a throwaway since we already have it
                token = strtok(word, delimiters);
                // get the next token (the value(s))
                token = strtok(NULL, delimiters);
                while( token != NULL ) {
                    // remove leading spaces
                    while(token[0] == ' '){
                        ++token;
                    }
                    strncpy(key_val[i].val, token, LINE_LEN-1);
                    key_val[i].val[LINE_LEN-1] = 0;
                    val = key_val[i].val;
                    //DEBUG_OUTPUT(( "val: .%s.\n", val ));
                    // get the other tokens that may be in the line - at present, these are ignored
                    token = strtok(NULL, delimiters);
                }
                // we can either sendResult inside this loop like this, or do it later
                // since all vals are stored inside key_val[].val
                if (val != NULL) {
                    sendResult(key, val);
                    break; // this assumes only one key-value pair per line of results file
                }
            }
        }
        // if no more keys to find, break out of while loop
        if (tokens_found == num_tokens) {
            break;
        }
    } 

    fclose(template);
    fclose(results);
    return 0;
}
