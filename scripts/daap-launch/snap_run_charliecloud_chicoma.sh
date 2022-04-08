#!/bin/bash

#SBATCH --job-name=SNAP_runh0064
#SBATCH --output=SNAP_XROADS_%j.out
#SBATCH -N 2
#SBATCH --ntasks-per-node=4
#SBATCH --time=03:00:00      # Walltime in hh:mm:ss or d-hh:mm:ss
#SBATCH -p standard

source $HOME/telegraf_run_chicoma.sh
date;hostname;pwd
#kill_telegraf
echo $SLURM_JOBID
#Launch fluent bit on the compute nodes
launch_telegraf
#Load modules
module purge
module load charliecloud
#module load openmpi
#module load intel
#module load intel-mpi

sleep 15 
date +%s
# Redirect all output to kickoff.log
#export PYTHONPATH=/yellow/users/hng/pavilion2/lib
#export PAVILION_HOME=/users/hng/pavilion2
#exec >/users/hng/pavilion2/working_dir/test_runs/snap/kickoff.log 2>&1
#export PATH=${PATH}:${PAVILION_HOME}/bin
#export PAV_CONFIG_FILE=${PAVILION_HOME}/config/pavilion.yaml
#export PAV_CONFIG_DIR=${PAVILION_HOME}/config
#mpirun -np 1 ch-run llo-openmpi -- /hello/hello

#Make sure the ssl config of the host is the same as the container
cp /etc/ssl/openssl.cnf $HOME/img/amd64_snap-daap:latest/etc/ssl/
SLURM_HOSTS=`/usr/bin/scontrol show hostname "$SLURM_JOB_NODELIST" | tr '\n' "," | sed -e 's/,$//'`
IFS=',' read -ra host_array <<< "$SLURM_HOSTS"
host_array_len=${#host_array[@]}
for h in "${host_array[@]}"
do
 ssh $h cp -r $HOME/img/amd64_snap-daap:latest /var/tmp/amd64_snap-daap
done
srun --mpi=pmi2 -n 8 -c 1 ch-run --set-env=DAAP_CERTS=/usr/local/src/daap_certs -w --join /var/tmp/amd64_snap-daap -- /usr/local/src/2018-xroads-trinity-snap/snap-src/gsnap /usr/local/src/2018-xroads-trinity-snap/inputs/inh0001t4 /root/output

date +%s
sleep 15
rm -rf ${TELEGRAF_TMP}
kill_telegraf
date
