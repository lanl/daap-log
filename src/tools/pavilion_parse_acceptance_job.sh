#!/bin/bash

#SBATCH --job-name=snap_pavilion_parse
#SBATCH --output=PAVILION_PARSE_%j.out
#SBATCH -N 1
#SBATCH --ntasks-per-node=1
#SBATCH --time=00:10:00      # Walltime in hh:mm:ss or d-hh:mm:ss
#SBATCH -p standard

source $HOME/daap-log/src/tools/daap-launch/telegraf_run.sh
date;hostname;pwd
#Launch telegraf on the compute nodes
launch_telegraf
sleep 15 

#Run the pavilion results parser
srun -N1 -n 1 $HOME/daap-log/src/tools/parse_acceptance_test_results.py -c $HOME/daap_certs -r $HOME/pavilion2/working_dir/results.log
sleep 15
rm -rf ${TELEGRAF_TMP}
kill_telegraf
