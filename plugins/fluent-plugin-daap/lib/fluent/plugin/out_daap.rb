require 'fluent/plugin/output'
require 'fluent/mixin'
require 'fluent/mixin/config_placeholders'
require 'fluent/mixin/rewrite_tag_name'
require 'json'

module Fluent
  module Plugin
    class DAAPOutput < Output
      Fluent::Plugin.register_output('daap', self)

      config_param :tag, :string, default: nil

      include SetTagKeyMixin
      include Fluent::Mixin::ConfigPlaceholders
      include HandleTagNameMixin
      include Fluent::Mixin::RewriteTagName

      helpers :event_emitter

      def multi_workers_ready?
        false
      end

      def configure(conf)
        super
	@jobs = {}
      end

      def deep_copy(o)
        Marshal.load(Marshal.dump(o))
      end

      def clean_host(host)
        host = host.gsub(/.localdomain/, '')
        return host
      end

      def process(tag, es)
        emit_tag = @tag
        es_out = MultiEventStream.new
        metrics = Array.new
        es.each do |time, record|
          next unless record.key?("metrics") or record.key?("message")
	  if !record.has_key?('metrics') and record.has_key?('message')
            if !record['message'].include?('xrage') and !record['message'].include?('caliper')
              next
            end

            record['message'].gsub!(/^.*host=[^ ]+ /, '')
            record['message'].gsub!(/^(.*) (\d+).*/, '\1,timestamp=\2')
            #          puts record
            #Split into key/value pairs
            kv_pairs = msg.split(',')
            new_rec = {}
            kv_pairs.each do | item |
              k, v = item.split('=')
              v.gsub!(/\\\\/, '')
              v.gsub!(/\"/, '')
              v.strip!()
              new_rec[k] = v
            end
            #We have bad data if kv_pairs.length is < 1
            if kv_pairs.length < 1
              next
            end
            if record['message'].include?('xrage')
              new_rec['metric'] = 'xrage_metrics'
              ["numpe", "nodes",
               "ppn_min", "ppn_max", 
               "dims", "cells_min", "cells_avg",
               "cells_max", "cyc_cc_min", "cyc_cc_avg",
               "cyc_cc_max", "cyc_sec_min", "cyc_sec_avg",
               "cyc_sec_max", "elapsed_s"].each do |item|
                new_rec[item] = new_rec[item].to_i
              end
              ["scale", "rss_min",
               "rss_avg", "rss_max",
               "rss_max_min", "rss_max_avg", "rss_max_max"].each do |item|
                new_rec[item] = new_rec[item].to_f
              end
            else
              new_rec['metric'] = 'xrage_caliper'
              ["driver_after_cyclemin", "driver_after_cyclemax",
               "driver_after_cycleavg"].each do |item|
                new_rec[item] = new_rec[item].to_f
              end
            end
              
            ts = new_rec["timestamp"].to_i/1000000
            new_rec["timestamp"] = Time.at(ts).utc.strftime("%Y-%m-%dT%H:%M:%S")
            metrics.push(new_rec)
            puts new_rec
          end

          #Go through the json and pick out what we want
          record["metrics"].each do |child|
            if not child.has_key?('fields')
              next
            end
            if not child.has_key?('name')
              next
            end
            name = child['name']
            if not ['infiniband','cpu', 'mem', 
                    'temp', 'daap', 'snap_pavilion_parser', 
                    'pre_team_pavilion_parser', 'pre_team_pavilion_hpl_parser'].include?(name)
              next
            end

            new_rec = {}
            fields = child['fields']
            prefix = ''
            if child['tags']['jobinfo'].include? "flag_perf_tests_"
              prefix = "flag_daap_"
            end
            #Infiniband errors
            #Heartbeat
            if fields.has_key?('message') and fields['message'] == "__daap_heartbeat"
              new_rec['metric'] = prefix + 'heartbeat'
              new_rec['type'] = 'heartbeat'
              new_rec['val'] = 1
            end
            #Start
            if fields.has_key?('message') and fields['message'] == "__daap_jobstart"
              new_rec['metric'] = prefix + 'job_state'
              new_rec['state'] = 'start'
            end
            if fields.has_key?('message') and fields['message'] == "__daap_jobend"
              new_rec['metric'] = prefix + 'job_state'
              new_rec['state'] = 'end'
            end
            if fields.has_key?('message') and fields['message'].include?  "__daap_jobduration:"
              new_rec['metric'] = prefix + 'job_duration'
              if match = fields['message'].match(/__daap_jobduration: ([^ ]+)/)
                duration = match.captures
                new_rec['duration'] = duration[0].to_i
              end
            end
            if fields.has_key?('message') and fields['message'].include? "mesh" and prefix == "flag_daap_"
              new_rec['metric'] = prefix + 'mesh_info'
              if match = fields['message'].match(/([^ ]+)[ ]+([^ ]+)[ ]+([^ ]+)[ ]+([^ ]+)[ ]+([^ ]+)[ ]+([^ ]+)[ ]+([^ ]+)[ ]+([^ ]+)[ ]+([^ ]+)[ ]+([^ ]+)/)
                name, handle, geom, numpe, points, edges, faces, sides, zones, bandwidth = match.captures
                new_rec['name'] = name
                new_rec['handle'] = handle
                new_rec['geom'] = geom
                new_rec['numpe'] = numpe
                new_rec['points'] = points
                new_rec['edges'] = edges
                new_rec['faces'] = faces
                new_rec['sides'] = sides
                new_rec['zones'] = zones
                new_rec['bandwidth'] = bandwidth 
              end
            end
            #Add common fields
            new_rec['host'] = clean_host(child['tags']['host'])
            new_rec['timestamp'] = child['timestamp']
            #Get jobinfo
            if child['tags'].has_key?('jobinfo')
              if match = child['tags']['jobinfo'].match(/jobid=([^ ]+).*name=([^ ]+).*user=([^ ]+)/i)
                jobid, job_name, user = match.captures
                if jobid
                  new_rec['jobid'] = jobid
                else
                  new_rec['jobid'] = "0"
                end
                if job_name
                  new_rec['job_name'] = job_name
                else
                  new_rec['job_name'] = ""
                end
                if user
                  new_rec['user'] = user
                else
                  new_rec['user'] = ""
                end
              end            
              if match = child['tags']['jobinfo'].match(/jobid=([^ ]+).*name=([^ ]+).*user=([^ ]+).*ranks=([^ ]+)/i)
                jobid, job_name, user, ranks = match.captures
                if jobid
                  new_rec['jobid'] = jobid
                else
                  new_rec['jobid'] = "0"
                end
                if job_name
                  new_rec['job_name'] = job_name
                else
                  new_rec['job_name'] = ""
                end
                if user
                  new_rec['user'] = user
                else
                  new_rec['user'] = ""
                end
                if ranks
                  new_rec['ranks'] = ranks
                else
                  new_rec['ranks'] = "0"
                end
              end            
              if match = child['tags']['jobinfo'].match(/jobid=([^ ]+).*name=([^ ]+).*user=([^ ]+).*ranks=([^ ]+).*version=([^ ]+).*probsize=([^ ]+)/i)
                jobid, job_name, user, ranks, version, probsize = match.captures
                if jobid
                  new_rec['jobid'] = jobid
                else
                  new_rec['jobid'] = "0"
                end
                if job_name
                  new_rec['job_name'] = job_name
                else
                  new_rec['job_name'] = ""
                end
                if user
                  new_rec['user'] = user
                else
                  new_rec['user'] = ""
                end
                if ranks
                  new_rec['ranks'] = ranks
                else
                  new_rec['ranks'] = "0"
                end
                if version 
                  new_rec['version'] = version
                else
                  new_rec['version'] = "0"
                end
                if probsize
                  new_rec['probsize'] = probsize
                else
                  new_rec['probsize'] = "0"
                end
              end            
            end

	    if !new_rec.has_key?('jobid') or !new_rec.has_key?('job_name')
              #puts child
              next
            end
            #Store job info
            job_key = new_rec['jobid'] + "_" + new_rec['job_name']
            
            #Get Rank            
            if child['tags'].has_key?('mpirank')
                  new_rec['mpirank'] = child['tags']['mpirank']
            end
            if fields.has_key?('message') and fields['message'].include? "zones:" and prefix == "flag_daap_"
              new_rec['metric'] = prefix + 'zones'
              if match = fields['message'].match(/[ ]+zones:[ ]+([^ ]+)[ ]+numpes:[ ]+([^ ]+)[ ]+/)
                zones, numpes = match.captures
                new_rec['zones'] = zones
                new_rec['numpes'] = numpes
                jobid = new_rec['jobid']
              end
            end

  	    if prefix == "flag_daap_" and new_rec.has_key?('mpirank') and new_rec['mpirank'] == "0" and new_rec.has_key?('duration')
              jobid = new_rec['jobid']
	      duration =  new_rec['duration'][0]
            end

            if name == 'pre_team_pavilion_parser'
              new_rec['metric'] = 'pre_team'
              ["job_cpu_total", "job_duration", "job_ended", "job_id", "job_max_mem", 
               "job_name", "job_nodes", "job_result", "job_started", "job_user", "sys_name"].each do |item|
                new_rec[item] = child['tags'][item]
              end
            end
            if name == 'pre_team_pavilion_hpl_parser'
              new_rec['metric'] = 'pre_team_hpl'
              ["cpumode","cpuspeed","gflops","job_id","sys_name","valalign",
               "valbcast","valdepth","valequil","vall1","valn","valnb","valnbmin",
               "valndiv","valp","valpfact","valpmap","valq","valrfact","valswap",
		"valu", "node"].each do |item|
                new_rec[item] = child['tags'][item]
              end
            end
            if name == 'infiniband'
              new_rec['metric'] = prefix + 'infiniband_errors'
              ["link_downed", "link_error_recovery", 
               "local_link_integrity_errors", "port_rcv_constraint_errors", 
               "port_rcv_errors", "port_xmit_discards", 
               "port_rcv_remote_physical_errors", "port_rcv_switch_relay_errors", 
               "port_xmit_constraint_errors"].each do |item|
                dup_rec = new_rec.clone
                dup_rec['type'] = item
                dup_rec['val'] = fields[item]
                dup_rec['device'] = child['tags']['device']
                metrics.push(dup_rec)
              end
              new_rec['metric'] = prefix + 'infiniband_metrics'
              ["multicast_rcv_packets", "multicast_xmit_packets", 
               "port_rcv_data", "port_rcv_packets", 
               "port_xmit_data", "port_xmit_packets", 
               "port_xmit_wait", "unicast_rcv_packets", 
		"unicast_xmit_packets"].each do |item|
                dup_rec = new_rec.clone
                dup_rec['type'] = item
                dup_rec['val'] = fields[item]
                dup_rec['device'] = child['tags']['device']
                metrics.push(dup_rec)
              end
              next
            end
            #CPU Usage
            if name == 'cpu'
              new_rec['metric'] = prefix + 'cpu_usage'
              ["usage_guest", "usage_guest_nice", 
               "usage_idle", "usage_iowait", 
               "usage_irq", "usage_nice", 
               "usage_softirq", "usage_steal", 
               "usage_system", "usage_user"].each do |item|
                dup_rec = new_rec.clone
                dup_rec['type'] = item.gsub(/usage_/, '')
                dup_rec['val'] = fields[item]
                metrics.push(dup_rec)
              end
              next
            end
            #MEM usage
            if name == 'mem'
#              puts "Got mem msg"
              new_rec['metric'] = prefix + 'mem_usage'
              ["used_percent"].each do |item|
                if !@jobs.has_key?(job_key)
                  @jobs[job_key] = {'timestamp' => time, 'max_mem' => 0, 'samples' => 0}
                end
                new_mem = fields[item]
                max_mem = @jobs[job_key]['max_mem']
                samples = @jobs[job_key]['samples']
                samples = samples + 1
                if new_mem > max_mem
                  @jobs[job_key] = {'timestamp' => time, 'max_mem' => new_mem, 'samples' => samples}
                else
                  @jobs[job_key] = {'timestamp' => time, 'max_mem' => max_mem, 'samples' => samples}
                end
                if samples % 100 == 0
                  dup_rec = new_rec.clone
                  dup_rec['type'] = item + "_max"
                  dup_rec['val'] = fields[item]
                  #puts job_key, @jobs[job_key], samples
                  metrics.push(dup_rec)
                end
              end
              next
            end
            #Temps
            if name == 'temp'
              new_rec['metric'] = prefix + 'temp'
              new_rec['val'] = fields['temp']
              new_rec['sensor'] = child['tags']['sensor']
            end
            if name == 'snap_pavilion_parser' and fields['message'] == "daap_pavilion_parser"
              new_rec['metric'] = 'snap_pavilion_parser'
              ["job_result", 
               "job_started", "job_ended", "test_node_list"].each do |item|
                new_rec[item] = child['tags'][item]
              end
              ["execution_time", "grind_time", 
               "job_duration"].each do |item|
                new_rec[item] = child['tags'][item].to_f
              end
              ["job_nodes", "job_max_mem",
               "allocated_words", "job_cpu_total"].each do |item|
                new_rec[item] = child['tags'][item].to_i
              end

              new_rec['jobid'] = child['tags']['job_id']
            elsif name == 'snap_pavilion_parser'
              next 
            end

            #Add to queue
            metrics.push(new_rec)
          end
        end

        if metrics.length == 0
          return
        end
        #Send records
        metrics.each do |m|
          ts = m["timestamp"]
          if m.has_key?("metric") and (m["metric"].include? "job_state" or m["metric"].include? "job_duration")
            m["timestamp"] = Time.at(ts).utc.strftime("%Y-%m-%dT%H:%M:%S")
          end
          es_out.add(ts, m)
        end

        router.emit_stream(emit_tag, es_out)
        #clean Jobs Hash
        cur_ts = Time.now.to_i
        max_age = 30 * 60 
	@jobs.each do |k,v|
	  diff = cur_ts - v["timestamp"]
	  if diff > max_age
             @jobs.delete(k)
          end
        end
      end
    end
  end
end
