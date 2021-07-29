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
          next unless record.key?("metrics")
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
                new_rec['duration'] = duration
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
            if fields.has_key?('message') and fields['message'].include? "zones:" and prefix == "flag_daap_"
              new_rec['metric'] = prefix + 'zones'
              if match = fields['message'].match(/[ ]+zones:[ ]+([^ ]+)[ ]+numpes:[ ]+([^ ]+)[ ]+/)
                zones, numpes = match.captures
                new_rec['zones'] = zones
                new_rec['numpes'] = numpes
              end
            end
            #Add common fields
            new_rec['host'] = clean_host(child['tags']['host'])
            new_rec['timestamp'] = child['timestamp']
            #Get jobinfo
            if child['tags'].has_key?('jobinfo')
              if match = child['tags']['jobinfo'].match(/jobid=([^ ]+).*name=([^ ]+).*user=([^ ]+).*/i)
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
            end

            #Get Rank            
            if child['tags'].has_key?('mpirank')
                  new_rec['mpirank'] = child['tags']['mpirank']
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
              new_rec['metric'] = prefix + 'mem_usage'
              ["active", "inactive", 
               "vmalloc_total", "vmalloc_used", 
               "used_percent"].each do |item|
                dup_rec = new_rec.clone
                dup_rec['type'] = item
                dup_rec['val'] = fields[item]
                metrics.push(dup_rec)
              end
              next
            end
            #MEM usage
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
      end
    end
  end
end
