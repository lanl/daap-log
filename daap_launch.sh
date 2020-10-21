#!/bin/bash

#SBATCH --job-name=SNAP_XROADS_4nodes_8tasks
#SBATCH --output=SNAP_XROADS_%j.out
#SBATCH --nodes=4              # Number of nodes
#SBATCH --ntasks=8             # Number of MPI ranks
#SBATCH --ntasks-per-node=2    # Number of MPI ranks per node
#SBATCH --ntasks-per-socket=1  # Number of tasks per processor socket on the node
#SBATCH --time=00:20:00      # Walltime in hh:mm:ss or d-hh:mm:ss

function modify_config {
    CONF_FILE="$1"
    sed -i.bkup -e "s/job_id = \"1\"/job_id = \"${SLURM_JOBID}\"/" "${CONF_FILE}"
    sed -i.bkup -e "s/job_name = \"\"/job_name = \"${SLURM_JOB_NAME}\"/" "${CONF_FILE}"
    sed -i.bkup -e "s/job_user = \"\"/job_user = \"${SLURM_JOB_USER}\"/" "${CONF_FILE}"
}

function launch_telegraf {
    BASE="/users/hng"
    TELEGRAF_BASE="$BASE/telegraf"
    TELEGRAF_EXEC="$TELEGRAF_BASE/telegraf"
    SLURM_HOSTS=`/usr/bin/scontrol show hostname "$SLURM_JOB_NODELIST" | tr '\n' "," | sed -e 's/,$//'`
    rm -f ${TELEGRAF_BASE}/telegraf-agg-*.conf
    rm -f ${TELEGRAF_BASE}/telegraf-client-*.conf
    echo $SLURM_HOSTS
    IFS=',' read -ra host_array <<< "$SLURM_HOSTS"
    host_array_len=${#host_array[@]}
    num_servers=`echo $host_array_len/4.0 | bc -l | awk '{printf("%d\n",$1 + 0.5)}'`
    servers=()
    FIRST_CLIENT=0
    for h in "${host_array[@]}"
    do
	host_ip=`cat /etc/hosts | grep "[[:space:]]${h}\." | cut -f 1 -d$'\t'`
	servers_array_len=${#servers[@]}
	if [ $servers_array_len != $num_servers ]
	then
	    servers[$((servers_array_len))]=${host_ip}
	    #run server fluent bit
        CONF_FILE="${TELEGRAF_BASE}/telegraf-agg-0.conf"
        if [ ! -f "${CONF_FILE}" ]
        then
          cp -f ${TELEGRAF_BASE}/telegraf-agg.conf ${CONF_FILE}
	  modify_config "${CONF_FILE}"
          rm -f ${TELEGRAF_BASE}/telegraf-agg-0.conf.bkup*
        fi
        echo "Starting aggregator on: ${h}"
	    ssh ${h} ${TELEGRAF_EXEC} --config "$TELEGRAF_BASE/telegraf-agg-0.conf" --debug &
	else
            if [ $FIRST_CLIENT -eq 0 ]
            then
               sleep 5
               FIRST_CLIENT=$((FIRST_CLIENT+1))
            fi
	    #get random server
	    index=`awk -v min=0 -v max=$((servers_array_len-1)) 'BEGIN{srand(); print int(min+rand()*(max-min+1))}'`
	    server=${servers[$index]}
	    #run client fluent bit
        CONF_FILE="${TELEGRAF_BASE}/telegraf-client-${index}.conf"
        if [ ! -f "${CONF_FILE}" ]
        then
            cp -f ${TELEGRAF_BASE}/telegraf-client.conf "${CONF_FILE}"
            sed -i.bkup -e "s/1\.1\.1\.1/${server}/" ${CONF_FILE}
	    modify_config "${CONF_FILE}" 
            rm -f ${TELEGRAF_BASE}/telegraf-client-${index}.conf.bkup* 
        fi
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
echo $SLURM_JOBID
#Launch fluent bit on the compute nodes
launch_telegraf
#Load modules
module load intel
module load intel-mpi

sleep 20 && srun -N 4 -n 8 -c 16 $BASE/2018-xroads-trinity-snap/snap-src/isnap /users/hng/2018-xroads-trinity-snap/inputs/inh0001t4 /users/hng/2018-xroads-trinity-snap/output
sleep 60
rm -f ${TELEGRAF_BASE}/telegraf-agg-*.conf
rm -f ${TELEGRAF_BASE}/telegraf-client-*.conf
kill_telegraf
date
