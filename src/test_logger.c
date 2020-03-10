/*
 * Tester for daap_log library
 */
#include "daap_log.h"

int main( int argc, char *argv[] ) {
    int log_level = LOG_NOTICE;
    int key_value = 0;
    uid_t uid = getuid();
    daapInit("logger", log_level, DAAP_AGG_OFF);
    daapLogWrite(key_value, "daapLogWrite logging correctly, %n user id = %d.\n", &uid, uid);
//    daapLogWrite(key_value, "%08x %08x %08x %08x %08x\n");
    daapFinalize();
    return 0;
}
