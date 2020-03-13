/*
 * Tester for daap_log library
 */
#include "daap_log.h"
#include <stdio.h>

int main( int argc, char *argv[] ) {
    int log_level = LOG_NOTICE;
    int key_value = 0, ret_val = 0;
    uid_t uid = getuid();
    if( (ret_val = daapInit("logger", log_level, DAAP_AGG_OFF)) != 0 ) {
        return ret_val;
    }

    ret_val = daapLogWrite(key_value, "daapLogWrite logging correctly, %n user id = %d.", &uid, uid);
    if( ret_val != 0 ) {
        perror("Error in call to daapLogWrite");
    }
//    daapLogWrite(key_value, "%08x %08x %08x %08x %08x\n");
    daapFinalize();
    return 0;
}
