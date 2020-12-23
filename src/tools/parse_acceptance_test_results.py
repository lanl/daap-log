#!/usr/bin/python

import json
import sys
import socket
import ssl
import re
import time
import getopt

""" Send the record to telegraf """
def sendRecord(cert_dir, record):
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.settimeout(10)
    ssl_sock = ssl.wrap_socket(sock,keyfile=cert_dir + '/client_key.pem',
                               certfile=cert_dir + '/client_cert.pem')
    
    try:
        ssl_sock.connect(('127.0.0.1', 5555))
    except socket.error as e:
        print("Socket error: %s\n" % str(e))

    try:
        ssl_sock.write(record)
    except socket.error as e:
        print("Error while sending: %s" % str(e))

    ssl_sock.close()

def usage():
    print("Usage: ./parse_acceptance_test_results.py -c cert_dir -r results_file [-h]")
    sys.exit(1)

""" Parse the results.log file and send the records to telegraf """
def main():
    try:
        opts, args = getopt.getopt(sys.argv[1:], "hc:r:", ["help", "cert_dir=", "results_file="])
    except getopt.GetoptError as err:
        usage()

    cert_dir = None
    results_file = None
    for o, a in opts:
        if o == "-c":
            cert_dir = a
        elif o == "-r":
            results_file = a
        elif o in ("-h", "--help"):
            usage()
        else:
            assert False, "unhandled option"

    #Open the results file and go through each line
    results = open(results_file, 'r')
    for line in results:
        #Parse the json obj
        jobj = json.loads(line)
        job_name = jobj["name"]
        job_id = jobj["job_id"]
        job_started = jobj["started"].replace(" ", "T")
        job_ended = jobj["finished"].replace(" ", "T")
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
        #Format the message in influxdb format
        job_info_msg = (",sys_name=%s,job_name=%s,job_id=%s,job_started=%s," + \
                       "job_ended=%s,job_duration=%f,job_result=%s," +\
                       "job_user=%s,job_nodes=%s,job_cpu_total=%s,job_max_mem=%s") %\
                       (sys_name, job_name, job_id, job_started, job_ended, 
                        job_duration, job_result, job_user, job_nodes, 
                        job_cpu_total, job_max_mem)

        #Snap specific fields
        if "snap" in job_name:
            if "execution_time" in jobj:
                execution_time = jobj["execution_time"]
            else:
                execution_time = "0"

            if "grind_time" in jobj:
                grind_time = jobj["grind_time"]
            else:
                grind_time = "0"

            if "allocated_words" in jobj:
                allocated_words = jobj["allocated_words"]
            else:
                allocated_words = "0"

            job_info_msg += (",execution_time=%s,grind_time=%s,allocated_words=%s") %\
                            (execution_time, grind_time, allocated_words)
            job_info_msg = "snap_pavilion_parser" + job_info_msg
        
        job_info_msg += " message=\"daap_pavilion_parser\" " + str(long(time.time()) * 1000000000)
        sendRecord(cert_dir, job_info_msg + "\n\n")

if __name__ == '__main__':
    main()
