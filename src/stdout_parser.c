/*
 * Stdout/Results parser for daap_log library
 */
#include <getopt.h>
#include <linux/limits.h>
#include <pcre.h>

#include "daap_log.h"
#include "daap_log_internal.h"

#define LINE_LEN 512
#define MAX_TOKENS 1024
#define MAX_TABLES 10
#define MAX_HEADERS 10
#define MAX_COLS 10
#define MAX_VALS 20
#define OVECCOUNT 30
#define MAX_KEY_REGEXES 1000

//table information
typedef struct {
  char sep[LINE_LEN]; //the column separator
  char val_sep[LINE_LEN]; //the value separator
  int num_headers; //the number of headers before the tables tarts
  char header_names[MAX_HEADERS][LINE_LEN]; //the headers of the table
  int cols; //the number of columns
  char val_names[MAX_VALS][LINE_LEN]; //the value names
  int num_vals; //number of values
  int headers_found; //the number of headers found 
} table_t;

//Read through the results file and compare the lines to the table
//template and the key template
int parseResults(char *key_template_file, char *table_template_file, 
		 char *results_file);
//Parse the key template and store the regexps
int parseKeyTemplate(char *key_template_file, pcre **key_regexes,
		     int *num_keys);
//Parse the table template and the tables
int parseTableTemplate(char *table_template_file, table_t **tables, 
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

//Sends the result to the tcp socket or syslog
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
    printf("Sending result: %s\n", result);
    ret_val = daapLogWrite(result);
    if (ret_val != 0) {
        perror("Error in call to daapLogWrite");
    }
    free(result);
    return ret_val;
}

//Parse the key template
int parseKeyTemplate(char *key_template_file, pcre **key_regexes, 
		       int *num_key_regexes) {
  char line[LINE_LEN];
  char *regex_key;
  pcre *key_regex;
  FILE *key_template;
  int line_len = 0;
  int i;
  const char *error;
  int erroffset;
  int ovector[OVECCOUNT];
  int rc;
  pcre *re;

  //stores the number of regexes saved
  *num_key_regexes = -1;
  key_template = fopen(key_template_file, "r");
  if (!key_template) {
    ERROR_OUTPUT(("Failed to open key template file: %s", key_template_file));
    return -1;
  }

  // build the key regexes array
  //Read the file line by line, compile the regex and store
  while(fgets(line, LINE_LEN, key_template) != NULL) {
    if (line[0] == 0) {
      continue;
    }

    line_len = strlen(line);
    //Remove trailing new line
    while(line[line_len-1] == '\n' || line[line_len-1] == '\r') {
      line[line_len - 1] = '\0';
      line_len--;
    }

    /* based off of: 
       https://www.ncbi.nlm.nih.gov/IEB/ToolBox/C_DOC/lxr/source/regexp/
       demo/pcredemo.c */
    //compile the regexp with pcre
    re = pcre_compile(line,              /* the pattern */
		      0,                 /* default options */
		      &error,            /* for error message */
		      &erroffset,        /* for error offset */
		      NULL);             /* use default character tables */

    /* Regex compilation failed */
    if (re == NULL) {
      ERROR_OUTPUT(("Failed to compile regex at offset: %d : %s", erroffset, 
		    error));
      continue;
    }

    *num_key_regexes += 1;
    //save the regexp
    key_regexes[*num_key_regexes] = re;
  }

  fclose(key_template);
  return 0; 
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
  int vals_found = 0;

  //num_tables stores the number of tables found
  *num_tables = -1;
  //open the table template file
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
    //Remove trailing new line and trailing spaces
    while(line[line_len-1] == '\n' || line[line_len-1] == '\r') {
      line[line_len - 1] = '\0';
      line_len--;
    }
    //If we have not found the first ===table===, then we are not in a table def
    if (!in_table) {
      template_key = strstr(line, "===table===");
      //we found the first line in the table def
      if( template_key != NULL ) {
	*num_tables += 1;
	//allocate the table's memory
	tables[*num_tables] = calloc(1, sizeof(table_t));
	in_table = 1;
      }
      continue;
    }

    //get the current table
    table = tables[*num_tables];

    //go through the table template to find all of the information
    //find the table_sep= line for the column seperator (e.g., |)
    template_key = strstr(line, "table_sep=");
    if ( template_key != NULL ) {
      tkey_len = 10;
      strncpy(table->sep, line+tkey_len, line_len-tkey_len);
    }

    //find the header= line for each header in the table
    template_key = strstr(line, "header=");
    if ( template_key != NULL && table->num_headers < MAX_HEADERS) {
      tkey_len = 7;
      strncpy(table->header_names[table->num_headers], line+tkey_len, line_len-tkey_len);
      table->num_headers++;
    }
    
    //find the val_name= line for the name of each column value
    template_key = strstr(line, "val_name=");
    if ( template_key != NULL && vals_found < MAX_VALS ) {
      tkey_len = 9;
      strncpy(table->val_names[vals_found], line+tkey_len, line_len-tkey_len);
      vals_found++;
    }

    //find the cols= line for the number of columns in the table
    template_key = strstr(line, "cols=");
    if ( template_key != NULL ) {
      tkey_len = 5;
      table->cols = atoi(line+tkey_len);
    }

    //find the num_vals= line for the number of column values per row
    template_key = strstr(line, "num_vals=");
    if ( template_key != NULL ) {
      tkey_len = 9;
      table->num_vals = atoi(line+tkey_len);
    }

    //find the val_sep= for the seperator between column values (e.g., space)
    template_key = strstr(line, "val_sep=");
    if ( template_key != NULL ) {
      tkey_len = 8;
      strncpy(table->val_sep, line+tkey_len, line_len-tkey_len);
    }

    if (in_table) {
      //Find the end of the table
      template_key = strstr(line, "===end_table===");
      if( template_key != NULL ) {
	in_table = 0;
      }
    }
  }

  fclose(table_template);
  return 0; 
}

/* Go through each line in the results file. Compare each line in the results
   with the table templates and the key regexes saved */
int parseResults(char *key_template_file, char *table_template_file, 
		 char *results_file) {
  FILE *results; //results file
  char line[LINE_LEN]; //line read
  int line_len; //length of the line
  pcre **key_regexes; //regexes stored and compiled
  pcre *key_regex; //current regex
  table_t **tables; //tables stored
  int num_tables = 0; //num tables stored
  int num_key_regexes = 0; //num regexes stored
  int i = 0, j =0;
  int ret;
  char *columns_token, *val_token; //current column and val token
  char *table_header; //current header of the table being compared
  int in_table; //wether we are in a table
  table_t *table; //current table
  char columns[MAX_COLS][LINE_LEN]; //the column tokens found from the table
  char *key_start; //key start in the regexp
  int key_length; //key length
  char *key_to_send; //key to send to daap transport
  char *val_start; //val start in the regexp
  int val_length; // val length
  char *val_to_send; //val to send to daap transport
  int ovector[OVECCOUNT]; //for the regexp matches
  char *skip; //if _skip in the column value's name, skip the value
  int val_found; //number of column values found in the table
  char *val_name; //the current column value's name

  //open the results file
  results = fopen(results_file, "r");
  if (!results) {
    ERROR_OUTPUT(("Failed to open results file: %s", results_file));
    return -1;
  }
  
  //allocate table and regexes arrays
  tables = malloc(sizeof(table_t *) * MAX_TABLES);
  key_regexes = malloc(sizeof(pcre *) * MAX_KEY_REGEXES);
  //parse the table template and store the results in tables
  ret = parseTableTemplate(table_template_file, tables, &num_tables);
  if (ret < 0) {
    ERROR_OUTPUT(("Failed to parse table template file: %s", table_template_file));
    return -1;
  }
  
  //parse the key template regexes and store the results in key_regexes
  ret = parseKeyTemplate(key_template_file, key_regexes, &num_key_regexes);
  if (ret < 0) {
    ERROR_OUTPUT(("Failed to parse key template file: %s", key_template_file));
    return -1;
  }
  
  in_table = 0;
  table = NULL;
  key_regex = NULL;

  // examine each line in results file
  while(fgets(line, LINE_LEN, results)) {
    //remove new line chars
    while(line[line_len-1] == '\n' || line[line_len-1] == '\r') {
      line[line_len - 1] = '\0';
      line_len--;
    }
    
    /* for each table found in the template, compare the headers with the
      current result file line */
    for (i = 0; i <= num_tables && (!table || 
				    (table && !in_table)); 
	 i++) {
      table = tables[i];
      table_header = NULL;
      table_header = strstr(line, table->header_names[table->headers_found]);
      if (table_header != NULL) {
	table->headers_found++;
	break;
      }
    }
    
    //if we haven't found any headers, then we aren't going through a table
    if (table && table->headers_found == 0) {
      table = NULL;
    }
    
    //if we have matched headers, then we are going through a table
    if (table && !in_table && table->headers_found == table->num_headers) {
      in_table = 1;
      continue;
    }
    
    /*if we have a table saved in the table pointer, but in_table is not 1, 
      then we haven't found all of the headers yet*/
    if (table && !in_table) {
      continue;
    }
    
    columns_token = NULL;
    val_token = NULL;
    //We are reading a table from the results file, so we need to find the values
    if (in_table) {
      //split the table into column tokens by the column seperator
      columns_token = strstr(line, table->sep);
      //if we didn't find a column, then we aren't in a table
      if (!columns_token) {
	in_table = 0;
	table->headers_found = 0;
	table = NULL;
	goto rest;
      }

      //We have columns
      columns_token = strtok(line, table->sep);
      i = 0;
      //iterate through each column
      while ( columns_token != NULL) {
	//copy the column to the columns array
	strcpy(columns[i], columns_token);
	columns[i][strlen(columns_token)-1] = '\0';
	i++;
	columns_token = strtok(NULL, table->sep);
      }

      //now that we have the columns, find the column values for each row
      val_found = 0;
      for (i=0; i < table->cols; i++) {
	//split each column value by the value seperator
	val_token = strstr(columns[i], table->val_sep);
	if (!val_token) {
	  continue;
	}
	
	//get all of the column values per row
	val_token = strtok(columns[i], table->val_sep);
	while (val_token != NULL) {
	  val_name = table->val_names[val_found];
	  //skip this column if "_skip" is in the name
	  skip = strstr(val_name, "_skip");
	  if (skip) {
	    val_found++;
	    //Go to the next value
	    val_token = strtok(NULL, table->val_sep);
	    continue;
	  }
	  
	  //this is a value we want so send it
	  sendResult(val_name, val_token);
	  val_found += 1;
	  val_token = strtok(NULL, table->val_sep);
	}
      }
    }
      
    if (in_table) {
      continue;
    }

  rest:
    /* Loop over key regexps and compare the line to each one
       We do want to compare multiple regexes to each line for the
       case when there are multiple key/value pairs per line */
    for( i = 0; i < num_key_regexes; ++i ) {
      key_regex = key_regexes[i];
      
      ret = pcre_exec(key_regex,                /* the compiled pattern */
		      NULL,                     /* no extra data - we didn't study the pattern */
		      line,                     /* the subject string */
		      (int)strlen(line),        /* the length of the subject */
		      0,                        /* start at offset 0 in the subject */
		      0,                        /* default options */
		      ovector,                  /* output vector for substring information */
		      OVECCOUNT);               /* number of elements in the output vector */
      
      /* Matching failed */
      if ( ret < 0 ) {
	continue;
      }
      
      /* Matching succeded */
      
      /*The output vector wasn't large enough */
      if ( ret == 0 ) {
	ERROR_OUTPUT(("Output vector wasn't large enough for number of matches: %d\n", 
		      OVECCOUNT/3 - 1));
      }
      
      /* Show substrings stored in the output vector */
      for ( j = 0; j < ret; j++ ) {
	//the first match is the whole line, so skip it
	if ( j == 0 ) {
	  continue;
	}
	
	/* We expect a key/value pair. If we don't have a value, but
	   only a key, then continue/quit the loop
	 */
	if ( j+1 >= ret ) {
	  continue;
	}
	
	//Get the key and value matches from the regex
	key_start = line + ovector[2*j];
	key_length = ovector[2*j+1] - ovector[2*j];
	j++;
	val_start = line + ovector[2*j];
	val_length = ovector[2*j+1] - ovector[2*j];
	//allocate and copy the key and value
	key_to_send = calloc(key_length + 1, sizeof(char));
	strncpy(key_to_send, key_start, key_length);
	val_to_send = calloc(val_length + 1, sizeof(char));
	strncpy(val_to_send, val_start, val_length);
	//send the key and value
	sendResult(key_to_send, val_to_send);
	free(key_to_send);
	free(val_to_send);
      }
    }
  }
  
  //cleanup memory
  for (i=0; i < num_key_regexes+1; i++) {
    free(key_regexes[i]);
  }
  
  for (i=0; i < num_tables+1; i++) {
    free(tables[i]);
  }
  
  free(key_regexes);
  free(tables);
  fclose(results);
  return 0;
}
