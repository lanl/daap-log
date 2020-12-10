/*
 * Tester for daap_log library
 */
#include "daap_log.h"
#include <stdio.h>
#include <stdlib.h>
#include <getopt.h>
#include <string.h>

void usage() {
    printf(
    "./test_logger [-s] [-t] \n\
    -s: syslog transport \n\
    -t: tcp transport \n\n\
    ");
    exit(0);
}

int main( int argc, char *argv[] ) {
    int log_level = LOG_NOTICE;
    int ret_val = -1;
    transport transport_type = NONE;
    uid_t uid = getuid();
    int options = 0;

    while (( options = getopt(argc, argv, "ts")) != -1) {
        switch(options) {
        case 't':
            transport_type = TCP;
            break;
        case 's':
            transport_type = SYSLOG;
            break;
        default:
            usage();
        }
    }

    if ( transport_type == NONE ) {
        usage();
    }

    if ( (ret_val = daapInit("logger", log_level, DAAP_AGG_OFF, transport_type)) != 0 ) {
        return ret_val;
    }

    if (strcmp(getenv("DAAP_DECOUPLE"), "1") == 0) {
        if ( (ret_val = daapLogJobStart()) != 0 ) {
            perror("Error in call to daapLogJobStart");
        }
    }

    if ( (ret_val = daapLogHeartbeat()) != 0 ) {
        perror("Error in call to daapLogHeartbeat");
    }


    ret_val = daapLogWrite("daapLogWrite logging correctly, %n user id = %d.", &uid, uid);
    if ( ret_val != 0 ) {
        perror("Error in call to daapLogWrite");
    }


    if (strcmp(getenv("DAAP_DECOUPLE"), "1") == 0) {
        if ( (ret_val = daapLogJobEnd()) != 0 ) {
            perror("Error in call to daapLogJobEnd");
        }
    }

    daapFinalize();
    return 0;
}
