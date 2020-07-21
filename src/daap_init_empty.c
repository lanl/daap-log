/* 
 * Stubs-like (empty) version of Init/Finalize
 * 
 *****************
 *
 * Copyright (C) 2020 Triad National Security, LLC. All rights reserved.
 * Original author: Charles Shereda, cpshereda@lanl.gov
 * Additional author: Hugh Greenberg, hng@lanl.gov
 */

/* Initializer for library. */
int daapInit(const char *app_name, int msg_level, int agg_val, transport transport_type) {
    return DAAP_SUCCESS;
}

/* Free memory from allocated components of init_data */
int daapFinalize(void) {
    return DAAP_SUCCESS;
}
