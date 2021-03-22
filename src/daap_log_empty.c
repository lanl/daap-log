/* 
 * Stubs-like (empty) version of daapLogWrite
 * 
 *****************
 *
 * Copyright (C) 2020 Triad National Security, LLC. All rights reserved.
 * Original author: Charles Shereda, cpshereda@lanl.gov
 * Additional author: Hugh Greenberg, hng@lanl.gov
 */
#include <stdarg.h>

int daapLogWrite(const char *message, ...) {
    va_list args;

    return 0;
}

int daapLogHeartbeat(void) {
    return 0;
}

int daapLogJobStart(void) {
    return 0;
}

int daapLogJobEnd(void) {
    return 0;
}
