#!/bin/bash

source $HOME/daap-log/src/tools/daap-launch/telegraf_run_fe.sh
date;hostname;pwd
#Launch telegraf on the frontend node
launch_telegraf
sleep 15 

#Run the pavilion results parser
$HOME/daap-log/src/tools/parse_acceptance_test_results.py -c $HOME/daap_certs -r $HOME/pavilion2/working_dir/results.log
sleep 15
rm -rf ${TELEGRAF_TMP}
kill_telegraf
