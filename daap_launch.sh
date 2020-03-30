#!/bin/bash

#SBATCH --job-name=IOR_DAAP
#SBATCH --output=IOR_DAPP_%j.out
#SBATCH --nodes=2              # Number of nodes
#SBATCH --ntasks=4             # Number of MPI ranks
#SBATCH --ntasks-per-node=2    # Number of MPI ranks per node
#SBATCH --ntasks-per-socket=1  # Number of tasks per processor socket on the node
#SBATCH --time=01:00:00      # Walltime in hh:mm:ss or d-hh:mm:ss

function launch_fluent_bit {
    BASE="/users/hng"
    FLUENT_BIT_EXEC="$BASE/fluent-bit"
    FLUENT_BIT_AMQP="fluent-bit-plugin-amqp"
    SLURM_HOSTS=`/usr/bin/scontrol show hostname "$SLURM_JOB_NODELIST" | tr '\n' "," | sed -e 's/,$//'`
    echo $SLURM_HOSTS
    IFS=',' read -ra host_array <<< "$SLURM_HOSTS"
    host_array_len=${#host_array[@]}
    echo $host_array_len
    num_servers=`echo $host_array_len/4.0 | bc -l | awk '{printf("%d\n",$1 + 0.5)}'`
    servers=()
    echo $num_servers
    for h in "${host_array[@]}"
    do
	echo ${h}
	host_ip=`cat /etc/hosts | grep "[[:space:]]${h}\." | cut -f 1 -d$'\t'`
	echo ${host_ip}
	servers_array_len=${#servers[@]}
	if [ $servers_array_len != $num_servers ]
	then
	    servers[$((servers_array_len))]=${host_ip}
	    #run server fluent bit
            echo "Starting aggregator on: ${h}"
	    ssh ${h} ${FLUENT_BIT_EXEC} -c ${BASE}/${FLUENT_BIT_AMQP}/fluent-bit-aggregator.conf &
	else
	    #get random server
	    index=`awk -v min=0 -v max=$((servers_array_len-1)) 'BEGIN{srand(); print int(min+rand()*(max-min+1))}'`
	    server=${servers[$index]}
	    #run client fluent bit
            echo "Starting client on: ${h}"
	    ssh ${h} ${FLUENT_BIT_EXEC} -c ${BASE}/${FLUENT_BIT_AMQP}/fluent-bit-client.conf -o forward://${server}:7777 &
	fi
    done
}

date;hostname;pwd
#Launch fluent bit on the compute nodes
launch_fluent_bit
#Load modules
module load openmpi/2.1.2

#Run the job
sleep 20 && srun /users/hng/ior-daap/src/ior -t 1m -b 1g
sleep 60
date
