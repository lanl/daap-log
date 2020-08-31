#!/usr/bin/python
import json
import sys
import socket
import ssl
import re
import time

def sendRecord(record):
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.settimeout(10)
    ssl_sock = ssl.wrap_socket(sock,keyfile='/users/hng/daap_certs/client_key.pem',
                               certfile='/users/hng/daap_certs/client_cert.pem')
    
    try:
        ssl_sock.connect(('127.0.0.1', 5555))
    except socket.error as e:
        print("Socket error: %s\n" % str(e))

    try:
        ssl_sock.write(record)
    except socket.error as e:
        print("Error while sending: %s" % str(e))

    ssl_sock.close()

def main(results_file):

    results = open(results_file, 'r')
    for line in results:
        jobj = json.loads(line)
        job_name = jobj["name"]
        job_id = jobj["job_id"]
        job_started = jobj["started"]
        job_ended = jobj["finished"]
        try:
            job_duration = float(jobj["duration"])
        except ValueError as e:
            job_duration = 0.0

        job_user = jobj["user"]
        sys_name = jobj["sys_name"]
        if "alloc_nodes" in jobj["sched"]:
            job_nodes = jobj["sched"]["alloc_nodes"]
        else:
            job_nodes = 0

        if "alloc_cpu_total" in jobj["sched"]:
            job_cpu_total = jobj["sched"]["alloc_cpu_total"]
        else:
            job_cpu_total = 0

        if "alloc_max_mem" in jobj["sched"]:
            job_max_mem = jobj["sched"]["alloc_max_mem"]
        else:
            job_max_mem = 0

        job_result = jobj["result"]
        job_info_msg = ("msg_type=pv_job_info sys_name=%s job_name=%s job_id=%s job_started=\"%s\" " + \
                       "job_ended=\"%s\" job_duration=%f " +\
                       "job_user=%s job_nodes=%s job_cpu_total=%s job_max_mem=%s") %\
                       (sys_name, job_name, job_id, job_started, job_ended, 
                        job_duration, job_user, job_nodes, 
                        job_cpu_total, job_max_mem)
        json_dict = {"message" : job_info_msg, "appname": "daap-pv-jobinfo", "timestamp": 
                     int(time.time())}
        sendRecord(json.dumps(json_dict) + "\n\n")
        if "hpl" in job_name:
            #            print("job_name=%s job_id=%s\n" % (job_name, job_id))
            if "fn" not in jobj:
                continue

            fn_obj = jobj["fn"]
            for key,val in fn_obj.items():
                node_name = key
                hpl_info_msg = ("msg_type=pv_hpl_node_info sys_name=%s job_name=%s job_id=%s node=%s ") %\
                               (sys_name, job_name, job_id, node_name)
                for k,v in val.items():
                    if not v:
                        v = ""
                    if v == "(null)":
                        v = ""
                    
                    v = v.rstrip()
                    v = re.sub(r'\s+', ' ', v)
                    if " " in v:
                        v = '"' + v + '"'

                    hpl_info_msg += k + '=' + v + ' '

                hpl_info_msg = hpl_info_msg[:-1]
                json_dict = {"message" : hpl_info_msg, "appname": "daap-pv-hpljobinfo",
                             "timestamp": int(time.time())}
                sendRecord(json.dumps(json_dict))


def usage():
    print("./parse_pavillion_results.py results_file")
    sys.exit(1)

if __name__ == '__main__':
     # A year and month is required
    if len(sys.argv) != 2:
        usage()

    results_file = sys.argv[1]
    main(results_file)

