/*
 * Stdout/Results parser for daap_log library
 */
#include <getopt.h>
#include <linux/limits.h>

#include "daap_log.h"
#include "daap_log_internal.h"

#define LINE_LEN 512
#define MAX_TOKENS 1024
#define MAX_TABLES 10
#define MAX_HEADERS 10
#define MAX_VALS 10

typedef struct {
  char key[LINE_LEN];
  char val[LINE_LEN];
  bool found;
} token_t;

typedef struct {
  char sep[LINE_LEN];
  char val_sep[LINE_LEN];
  int num_headers;
  char header_names[MAX_HEADERS][LINE_LEN];
  int cols;
  int key_col;
  char val_names[MAX_VALS][LINE_LEN];
  int num_vals;
} table_t;

int parseResults(char *key_template_file, char *table_template_file, 
		 char *results_file);
int parseTableTemplate(char *key_template_file, table_t **tables, 
		       int *num_tables);

void usage() {
    printf(
"./stdout_parser (-s || -t) -m -f\n\
   -s: syslog transport \n\
   -t: tcp transport \n\
   -m: key_template file \n\
   -d: table_template file \n\
   -f: stdout/results file\n\n");
    exit(0);
}

int main( int argc, char *argv[] ) {
    int log_level = LOG_NOTICE;
    int ret_val = -1;
    transport transport_type = NONE;
    int options = 0;
    char key_template_file[PATH_MAX];
    char table_template_file[PATH_MAX];
    char results_file[PATH_MAX];
    key_template_file[0] = 0;
    table_template_file[0] = 0;
    results_file[0] = 0;

    while (( options = getopt(argc, argv, "tsm:f:d:")) != -1) {
        switch(options) {
        case 't':
            transport_type = TCP;
            break;
        case 's':
            transport_type = SYSLOG;
            break;
        case 'm':
            snprintf(key_template_file, PATH_MAX, "%s", optarg);
            break;
	case 'd':
            snprintf(table_template_file, PATH_MAX, "%s", optarg);
            break;
        case 'f':
            snprintf(results_file, PATH_MAX, "%s", optarg);
            break;
        default:
            usage();
        }
    }

    if ( transport_type == NONE || key_template_file[0] == 0 || results_file[0] == 0 ) {
        usage();
    }

    if( (ret_val = daapInit("daap_stdout_parser", log_level, 
                            DAAP_AGG_OFF, transport_type)) != 0 ) {
        return ret_val;
    }

    ret_val = parseResults(key_template_file, table_template_file, results_file);
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

int parseTableTemplate(char *table_template_file, table_t **tables, 
		       int *num_tables) {
  char line[LINE_LEN];
  char *template_key;
  int in_table = 0;
  table_t *table;
  int tkey_len = 0;
  FILE *table_template;
  int line_len = 0;
  int i;

  *num_tables = -1;
  table_template = fopen(table_template_file, "r");
  if (!table_template) {
    ERROR_OUTPUT(("Failed to open table template file: %s", table_template_file));
    return -1;
  }

  // build the tables array
  while(fgets(line, LINE_LEN, table_template) != NULL) {
    if (line[0] == 0) {
      continue;
    }

    line_len = strlen(line);
    line[line_len - 1] = '\0'; //string newline
    if (!in_table) {
      template_key = strstr(line, "===table===");
      if( template_key != NULL ) {
	*num_tables++;
	tables[*num_tables] = calloc(1, sizeof(table_t));
	in_table = 1;
      }
      continue;
    }

    table = tables[*num_tables];
    template_key = strstr(line, "table_sep=");
    if ( template_key != NULL ) {
      tkey_len = 10;
      strncpy(table->sep, line+tkey_len, line_len-tkey_len);
      printf("Line: %s\n", line);
    }
    template_key = strstr(line, "header=");
    if ( template_key != NULL && table->num_headers < MAX_HEADERS) {
      tkey_len = 7;
      strncpy(table->header_names[table->num_headers], line+tkey_len, line_len-tkey_len);
      table->num_headers++;
    }
    
    template_key = strstr(line, "val_name=");
    if ( template_key != NULL && table->num_vals < MAX_VALS ) {
      tkey_len = 9;
      strncpy(table->val_names[table->num_vals], line+tkey_len, line_len-tkey_len);
      table->num_vals++;
    }

    template_key = strstr(line, "cols=");
    if ( template_key != NULL ) {
      tkey_len = 5;
      table->cols = atoi(line+tkey_len);
    }

    template_key = strstr(line, "key_col=");
    if ( template_key != NULL ) {
      tkey_len = 8;
      table->key_col = atoi(line+tkey_len);
    }

    template_key = strstr(line, "num_vals=");
    if ( template_key != NULL ) {
      tkey_len = 9;
      table->key_col = atoi(line+tkey_len);
    }

    template_key = strstr(line, "val_sep=");
    if ( template_key != NULL ) {
      tkey_len = 8;
      strncpy(table->val_sep, line+tkey_len, line_len-tkey_len);
    }
    
    if (in_table) {
      template_key = strstr(line, "===end_table===");
      if( template_key != NULL ) {
	in_table = 0;
      }
    }
  }

  printf("sep:%s val_sep:%s num_headers:%d cols:%d key_col:%d num_vals:%d\n", 
	 tables[0]->sep, tables[0]->val_sep, tables[0]->num_headers, 
	 tables[0]->cols, tables[0]->key_col, tables[0]->num_vals);

  for (i=0; i < MAX_VALS; i++) {
    printf("val:%s\n", 
	   tables[0]->val_names[i]);
  }
  fclose(table_template);
  return 0; 
}

int parseResults(char *key_template_file, char *table_template_file, 
		 char *results_file) {
    FILE *key_template, *results;
    char template_buf[LINE_LEN];
    char results_buf[LINE_LEN];
    char converted_buf[LINE_LEN];
    token_t key_val[MAX_TOKENS];
    table_t **tables;
    int num_tables;
    char *key, *val, *token;
    int template_len, results_len, num_tokens, tokens_found;
    int i = 0;
    int ret;
    const char *delimiters = ":*=?\t\n";
    char *word;

    key_template = fopen(key_template_file, "r");
    if (!key_template) {
        ERROR_OUTPUT(("Failed to open template file: %s", key_template_file));
        return -1;
    }

    results = fopen(results_file, "r");
    if (!results) {
        ERROR_OUTPUT(("Failed to open results file: %s", results_file));
        return -1;
    }

    tables = malloc(sizeof(table_t *) * MAX_TABLES);
    ret = parseTableTemplate(table_template_file, tables, &num_tables);
    if (ret < 0) {
        ERROR_OUTPUT(("Failed to table template file: %s", table_template_file));
        return -1;
    }

    // store template file contents in memory;
    // go through each line of results and compare with what's in key array (template file).
    // for now, this only returns the first instance of a match between key and val

    // build the key array
    while(fgets(key_val[i].key, LINE_LEN, key_template) != NULL) {
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

    for (i=0; i < num_tables+1; i++) {
      free(tables[i]);
    }

    free(tables);
    fclose(key_template);
    fclose(results);
    return 0;
}
