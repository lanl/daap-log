/*
 * Tester for daap_log library
 */
#include "daap_log.h"

int main( int argc, char *argv[] ) {
    int log_level = LOG_NOTICE;
    int key_value = 0;
    uid_t uid = getuid();

    daapLogWrite("logger", log_level, key_value, "daap_log_write logging correctly, %n user id = %d.\n", &uid, uid);
//    daweLogWrite("logger", log_level, key_value, "%08x %08x %08x %08x %08x\n");
    return 0;
}
