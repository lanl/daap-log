function modify_config {
    CONF_FILE="$1"
    sed -i.bkup -e "s/job_id = \"1\"/job_id = \"${SLURM_JOBID}\"/" "${CONF_FILE}"
    sed -i.bkup -e "s/job_name = \"\"/job_name = \"${SLURM_JOB_NAME}\"/" "${CONF_FILE}"
    sed -i.bkup -e "s/job_user = \"\"/job_user = \"${SLURM_JOB_USER}\"/" "${CONF_FILE}"
}

function launch_telegraf {
    # NOTE: If we can gaurantee that telegraf base will be in $HOME/telegraf this can be simplified
    #       Else, pass telegraf's root directory as argument 1
    if [ $# -ne 0 ]; then
      BASE=$1
      TELEGRAF_BASE="$BASE"
    else
      BASE=$HOME
      TELEGRAF_BASE="$BASE/telegraf"
    fi
    date=`date +%s`
    rand_num=$((1 + RANDOM % 100))

    # Allow for TELEBRAF_WORKING_DIR to be an env var
    if [[ -z "${TELEGRAF_WORKING_DIR}" ]]; then
        TELEGRAF_WORKING_DIR="$HOME/telegraf_tmp"
    fi
    TELEGRAF_TMP="$TELEGRAF_WORKING_DIR/telegraf-$date-$rand_num"
    mkdir -p "$TELEGRAF_TMP"
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
    echo $num_servers
    if [ $num_servers == 0 ]
    then
      num_servers=1
    fi

    echo $num_servers
	if [ $servers_array_len != $num_servers ]
	then
	    servers[$((servers_array_len))]=${host_ip}
	    #run server fluent bit
        CONF_FILE="${TELEGRAF_TMP}/telegraf-agg-0.conf"
        if [ ! -f "${CONF_FILE}" ]
        then
          cp -f ${TELEGRAF_BASE}/telegraf-agg.conf ${CONF_FILE}
	  modify_config "${CONF_FILE}"
          rm -f ${TELEGRAF_TMP}/telegraf-agg-0.conf.bkup*
        fi
        echo "Starting aggregator on: ${h}"
	    ssh ${h} ${TELEGRAF_EXEC} --config "$TELEGRAF_TMP/telegraf-agg-0.conf" &
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
        CONF_FILE="${TELEGRAF_TMP}/telegraf-client-${index}.conf"
        if [ ! -f "${CONF_FILE}" ]
        then
            cp -f ${TELEGRAF_BASE}/telegraf-client.conf "${CONF_FILE}"
            sed -i.bkup -e "s/1\.1\.1\.1/${server}/" ${CONF_FILE}
	    modify_config "${CONF_FILE}"
            rm -f ${TELEGRAF_TMP}/telegraf-client-${index}.conf.bkup*
        fi
        echo "Starting client on: ${h}"
	    ssh ${h} ${TELEGRAF_EXEC} --config "${TELEGRAF_TMP}/telegraf-client-${index}.conf" &
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

    rm -rf ${TELEGRAF_TMP}
    if [ -d ${TELEGRAF_WORKING_DIR} ] && [ -z "$(ls -A ${TELEGRAF_WORKING_DIR})" ]
    then
        rmdir ${TELEGRAF_WORKING_DIR}
    fi 
}
