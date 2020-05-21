#!/bin/bash

#SBATCH --job-name=IOR_DAAP
#SBATCH --output=IOR_DAPP_%j.out
#SBATCH --nodes=4              # Number of nodes
#SBATCH --ntasks=4             # Number of MPI ranks
#SBATCH --ntasks-per-node=1    # Number of MPI ranks per node
#SBATCH --ntasks-per-socket=1  # Number of tasks per processor socket on the node
#SBATCH --time=01:00:00      # Walltime in hh:mm:ss or d-hh:mm:ss

function launch_telegraf {
    BASE="$HOME"
    TELEGRAF_BASE="$BASE/telegraf"
    TELEGRAF_EXEC="$TELEGRAF_BASE/telegraf"
    SLURM_HOSTS=`/usr/bin/scontrol show hostname "$SLURM_JOB_NODELIST" | tr '\n' "," | sed -e 's/,$//'`
    echo $SLURM_HOSTS
    IFS=',' read -ra host_array <<< "$SLURM_HOSTS"
    host_array_len=${#host_array[@]}
    num_servers=`echo $host_array_len/4.0 | bc -l | awk '{printf("%d\n",$1 + 0.5)}'`
    servers=()
    for h in "${host_array[@]}"
    do
	host_ip=`cat /etc/hosts | grep "[[:space:]]${h}\." | cut -f 1 -d$'\t'`
	servers_array_len=${#servers[@]}
	if [ $servers_array_len != $num_servers ]
	then
	    servers[$((servers_array_len))]=${host_ip}
	    #run server fluent bit
            echo "Starting aggregator on: ${h}"
	    ssh ${h} ${TELEGRAF_EXEC} --config "$TELEGRAF_BASE/telegraf-agg.conf" --debug &
	else
	    #get random server
	    index=`awk -v min=0 -v max=$((servers_array_len-1)) 'BEGIN{srand(); print int(min+rand()*(max-min+1))}'`
	    server=${servers[$index]}
	    #run client fluent bit
            cp ${TELEGRAF_BASE}/telegraf-client.conf ${TELEGRAF_BASE}/telegraf-client-${index}.conf
            sed -i.bkup -e "s/1\.1\.1\.1/${server}/" ${TELEGRAF_BASE}/telegraf-client-${index}.conf 
            rm -f ${TELEGRAF_BASE}/telegraf-client-${index}.conf.bkup 
            echo "Starting client on: ${h}"
	    ssh ${h} ${TELEGRAF_EXEC} --config ${TELEGRAF_BASE}/telegraf-client-${index}.conf &
	fi
    done
}

function kill_telegraf {
    SLURM_HOSTS=`/usr/bin/scontrol show hostname "$SLURM_JOB_NODELIST" | tr '\n' "," | sed -e 's/,$//'`
    echo $SLURM_HOSTS
    IFS=',' read -ra host_array <<< "$SLURM_HOSTS"
    host_array_len=${#host_array[@]}
    num_servers=`echo $host_array_len/4.0 | bc -l | awk '{printf("%d\n",$1 + 0.5)}'`
    servers=()
    for h in "${host_array[@]}"
    do
	host_ip=`cat /etc/hosts | grep "[[:space:]]${h}\." | cut -f 1 -d$'\t'`
	servers_array_len=${#servers[@]}
        ssh ${h} killall -9 telegraf > /dev/null 2>&1
    done
}

date;hostname;pwd
kill_telegraf
#Launch fluent bit on the compute nodes
launch_telegraf
#Load modules
module load openmpi/2.1.2

#Run the job
sleep 20 && srun /users/hng/ior-daap/src/ior -t 1m -b 1g -o /lustre/scratch3/yellow/hng/testFile -i 10
sleep 60
rm -f ${TELEGRAF_BASE}/telegraf-client-*.conf
kill_telegraf
date
