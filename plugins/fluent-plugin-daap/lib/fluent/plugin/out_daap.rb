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

      def common_clean(message, code, first_field)
        message.gsub!(/^#{code},/, '')
        message.gsub!(/\.localdomain/, '')
        message.gsub!(/\.lanl\.gov/, '')
        message.gsub!(/\\/, '')
        message.gsub!(/"/, '')
        message.gsub!(/\s+(#{first_field}=)/, ',\1')
        message.gsub!(/^(.*) (\d+).*/, '\1,timestamp=\2')
        return message
      end

      def process(tag, es)
        emit_tag = @tag
        es_out = MultiEventStream.new
        metrics = Array.new
        es.each do |time, record|
          next unless record.key?("metrics") or record.key?("message")
	  if record['message'] and record['message'].include?('fields')
            record = JSON.parse(record['message'])
          end 
#{'message' => 'sap,desc=caliper,host=sn053.localdomain,jobid=4982104,problem=SAP_PERF_Shape_Charge_spider_plot_symmetry caliper2=\"  cycler                         24.284198    204.170328    147.194426  5.482492    31.352367  \" 1641997967000000000\n'})
#           {"message":"xrage,desc=caliper-runtime-r
#eport,host=sn-rfe2.lanl.gov,job_id=4918945,problem=Asteroid.input,rj_tag=2021121
#5001316 caliper_182=\"            MPI_Win_get_attr                        0.0015
#59      0.001581      0.001571  0.000118 \" 1639555447000000000\n"}
	  if !record.has_key?('metrics') and record.has_key?('message') \
            and record['message'].include?(',desc=caliper')
            new_rec = {}
            code = ""
            if match = record['message'].match(/^([a-zA-Z0-9]+),/)
              code = match.captures[0]
            else
              next
            end
            new_rec['metric'] = code + '_caliper_metrics'
            record['message'].gsub!(/^#{code},/, '')
            record['message'].gsub!(/\n$/, '')
            record['message'].gsub!(/\\n$/, '')
            record['message'].gsub!(/[\s]+(\d+)$/, ',timestamp=\1')
            if match = record['message'].match(/\s+(caliper[_]*\d+)=[\\]*["]([^"]+)/)
              caliper_name, caliper_metrics = match.captures
              caliper_metrics.gsub!(/\\/, '')
              path_indent_match = caliper_metrics.match(/([\s]*)(.*)/)
              path_indent, caliper_metrics = path_indent_match.captures
              caliper_metrics.gsub!(/[\s]+/, ' ')
              caliper_pairs = caliper_metrics.split(' ')
              new_rec['caliper_name'] = caliper_name.gsub(/[_]/, '')
              if code == "sap"
                new_rec['numpe'] = caliper_pairs[0]
                new_rec['path'] = caliper_pairs[1]
                new_rec['path_with_indent'] = path_indent + caliper_pairs[1]
                new_rec['path_indent_len'] = path_indent.length
                new_rec['min_time'] = caliper_pairs[2].to_f.round(8)
                new_rec['max_time'] = caliper_pairs[3].to_f.round(8)
                new_rec['avg_time'] = caliper_pairs[4].to_f.round(8)
                new_rec['time_percentage'] = caliper_pairs[5].to_f.round(8)
                new_rec['allocated_mb'] = caliper_pairs[6].to_f.round(8)
              else
              new_rec['path'] = caliper_pairs[0]
              new_rec['path_with_indent'] = path_indent + caliper_pairs[0]
              new_rec['path_indent_len'] = path_indent.length
              new_rec['min_time'] = caliper_pairs[1].to_f.round(8)
              new_rec['max_time'] = caliper_pairs[2].to_f.round(8)
              new_rec['avg_time'] = caliper_pairs[3].to_f.round(8)
              new_rec['time_percentage'] = caliper_pairs[4].to_f.round(8)
              new_rec['allocated_mb'] = caliper_pairs[5].to_f.round(8)
              end
            end
            record['message'].gsub!(/\s+caliper[_]*\d+.*(,timestamp=\d+)$/,'\1')
            kv_pairs = record['message'].split(',')
            kv_pairs.each do | item |
              k, v = item.split('=')
              v.strip!()
              new_rec[k] = v
            end
            if new_rec.has_key?('job_id')
              new_rec['job_id'].gsub!(/-/, '')
            end
            ts = new_rec["timestamp"].to_i/1000000000
            #            new_rec["timestamp"] = Time.at(ts).utc.strftime("%Y-%m-%dT%H:%M:%S")
            new_rec["timestamp"] = ts
            metrics.push(new_rec)
            next
          end

#2021-10-25T12:04:28-06:00       appdata {"message":"sap,desc=spider_plot,host=gr0959.localdomain,problem=SAP_PERF_Shape_Charge_25_mat_spider_plot_refine npes=4,cells=1814400,cpu_time_per_cell=32.003,runtime_per_cycle=14516560.8 1635185068000000000\n"}
#2021-10-25T12:04:28-06:00       appdata {"message":"sap,desc=spider_plot,host=gr0959.localdomain,problem=SAP_PERF_Shape_Charge_25_mat_spider_plot_refine npes=32,cells=1814400,cpu_time_per_cell=46.54,runtime_per_cycle=2638818 1635185068000000000\n"}
#2021-10-25T12:04:28-06:00       appdata {"message":"sap,desc=spider_plot,host=gr0959.localdomain,problem=SAP_PERF_Shape_Charge_25_mat_spider_plot_refine npes=16,cells=1814400,cpu_time_per_cell=37.67,runtime_per_cycle=4271778 1635185068000000000\n"}
#2021-10-25T12:04:33-06:00       appdata {"message":"sap,desc=spider_plot,host=gr0959.localdomain,problem=SAP_PERF_Shape_Charge_25_mat_spider_plot_refine npes=8,cells=1814400,cpu_time_per_cell=31.481,runtime_per_cycle=7139890.800000001 1635185068000000000\n"}
#2021-11-15T07:02:32-07:00       appdata {"message":"lap,desc=spider_plot,host=sn331.localdomain,jobid=4817351,problem=LAP_LH_Spider_Plot_ndim156 problem_name=\"LAP_LH_Spider_Plot_ndim156\",application_name=\"FLAG\",problem_description=\"LAP_LH_Scaling_ndim156_32PE_per_node\",suite=\"CTS1Ifast\",total_number_of_zones=7836192,number_of_cycles-1=33,tot-time_cycles-1=\"2.113E-04\",total_number_of_processors=64,adjusted_runtime=54640.98319680001 1636984949000000000\n"}
#             {"message" => "sap,problem=SAP_PERF_Shape_Charge_spider_plot_symmetry,desc=spider_plot,jobid=5037788 npes=128,nnodes=4,cells=3513600,cpu=\"sn028.localdomain\",version=\"CTS1-intel-openmpi-sgl-no_offload-v17.4.3dev\",cpu_time_per_cell=21.115,runtime_per_cycle=579606.75 1643815974000000000\n"}

	  if !record.has_key?('metrics') and record.has_key?('message') and record['message'].include?('lap,')
            new_rec = {}
            new_rec['metric'] = 'lap_metrics'
            record['message'] = common_clean(record['message'], 'lap', 'problem_name')
            kv_pairs = record['message'].split(',')
            kv_pairs.each do | item |
              k, v = item.split('=')
              v.strip!()
              new_rec[k] = v
            end
            ["tot-time_cycles-1", "adjusted_runtime"].each do |item|
                val = new_rec[item].to_f.round(8)
                new_rec[item] = val
              if item == "tot-time_cycles-1"
                new_rec["tot_time_cycles_1"] = new_rec[item]
                new_rec.delete(item)
              end
            end
            ["total_number_of_zones", 
             "number_of_cycles-1", 
             "total_number_of_processors"].each do |item|
                val = new_rec[item].to_i
                new_rec[item] = val
              if item == "number_of_cycles-1"
                new_rec["number_of_cycles_1"] = new_rec[item]
                new_rec.delete(item)
              end
            end
            ts = new_rec["timestamp"].to_i/1000000000
            #            new_rec["timestamp"] = Time.at(ts).utc.strftime("%Y-%m-%dT%H:%M:%S")
            new_rec["timestamp"] = ts
            metrics.push(new_rec)
            next
          end
# appdata {"message":"poisson-metrics,host=sn031.localdomain app=\"Ristra-Poisson\",problemname=\"Ristra Poisson Prototype Problem\",description=\"Spider Plot\",cpu=\"TODO\",env=\"snow\",nodes=2,numpe=32,ppn=16,dims=\"12288x12288\",cells=150994944,jobid=\"TODO\",cycles=75000,cycle_time=0.6634986572916667 1637115456000000000\n"}
	  if !record.has_key?('metrics') and record.has_key?('message') and record['message'].include?('poisson-metrics,')
            new_rec = {}
            new_rec['metric'] = 'ristra_metrics'
            record['message'] = common_clean(record['message'], 'poisson-metrics', 'app')
            kv_pairs = record['message'].split(',')
            kv_pairs.each do | item |
              k, v = item.split('=')
              v.strip!()
              new_rec[k] = v
            end
            if new_rec.has_key?('jobid')
              new_rec['jobid'].gsub!(/-/, '')
            end
            if record["cpu"] == "TODO"
              record["cpu"] = 0.0
            end
            ["cpu", "cycle_time"].each do |item|
                val = new_rec[item].to_f.round(3)
                new_rec[item] = val
            end
            ["numpe", "cycles", "cells", "nodes", "ppn"].each do |item|
                val = new_rec[item].to_i
                new_rec[item] = val
            end
            ts = new_rec["timestamp"].to_i/1000000000
            #            new_rec["timestamp"] = Time.at(ts).utc.strftime("%Y-%m-%dT%H:%M:%S")
            new_rec["timestamp"] = ts
            metrics.push(new_rec)
            next
          end
#{"message":"jayenne,desc=strong_scaling_8x_particles,host=sn315.localdomain,n_cores=8,n_particles=800000,problem=./experiments/ddmc_rep_hohlraum.inp runtime=333 1638984508000000000\n"}  
	  if !record.has_key?('metrics') and record.has_key?('message') and record['message'].include?('jayenne,')
            new_rec = {}
            new_rec['metric'] = 'jayenne_metrics'
            record['message'] = common_clean(record['message'], 'jayenne', 'runtime')
            kv_pairs = record['message'].split(',')
            kv_pairs.each do | item |
              k, v = item.split('=')
              v.strip!()
              new_rec[k] = v
            end
         
            ["runtime"].each do |item|
                val = new_rec[item].to_f.round(3)
                new_rec[item] = val
            end
            ["n_cores", "n_particles"].each do |item|
                val = new_rec[item].to_i
                new_rec[item] = val
            end
            ts = new_rec["timestamp"].to_i/1000000000
            #            new_rec["timestamp"] = Time.at(ts).utc.strftime("%Y-%m-%dT%H:%M:%S")
            new_rec["timestamp"] = ts
            metrics.push(new_rec)
            next
          end
	  if !record.has_key?('metrics') and record.has_key?('message') and record['message'].include?('sap,')
            new_rec = {}
            new_rec['metric'] = 'sap_metrics'
            record['message'] = common_clean(record['message'], 'sap', 'npes')
            kv_pairs = record['message'].split(',')
            kv_pairs.each do | item |
              k, v = item.split('=')
              v.strip!()
              new_rec[k] = v
            end
            ["cpu_time_per_cell", "runtime_per_cycle"].each do |item|
                val = new_rec[item].to_f.round(3)
                new_rec[item] = val
            end
            ["npes", "cells"].each do |item|
                val = new_rec[item].to_i
                new_rec[item] = val
            end
            ts = new_rec["timestamp"].to_i/1000000000
            #            new_rec["timestamp"] = Time.at(ts).utc.strftime("%Y-%m-%dT%H:%M:%S")
            new_rec["timestamp"] = ts
            metrics.push(new_rec)
            next
          end
	  if !record.has_key?('metrics') and record.has_key?('message')
            if !record['message'].include?('xrage,')
              next
            end
            new_rec = {}
            new_rec['metric'] = 'xrage_metrics'
            record['message'] = common_clean(record['message'], 'xrage', 'job_id')
            #Split into key/value pairs
#'xrage,desc=Spider_Plot,host=gr-rfe2.lanl.gov,num_scm_ids=3,problem=Asteroid.input,scm_id_0.EB0=master,scm_id_0.EH0=73dc352f32e874fb9030c9f6ab64abb0b358c02b,scm_id_1.EB1=master,scm_id_1.EH1=af0259e3ced2bc528b38c58b9be3b5e73432b06e,scm_id_2.EB2=master,scm_id_2.EH2=ef8916fd275c8a01dc8485e137389d2f1d74b139 cpu=\"Intel(R)Xeon(R)CPUE5-2695v4@2.10GHz\",env=\"SNOW\",numpe=256,nodes=8,scale=0.12,ppn_min=32,ppn_max=32,dims=3,avg_cells_min=6267,avg_cells_avg=8515.70588235294,avg_cells_max=8739,rss_min=3.455,rss_avg=7.682944444444445,rss_max=8.349,rss_max_min=3.454,rss_max_avg=8.017000000000003,rss_max_max=8.739,cyc_cc_min=0,cyc_cc_avg=1120288.2352941176,cyc_cc_max=1413200,sum_cyc_sec=76365,job_id=4963828,elapsed_s=302.733,n_cycles=160,elapsed_minus_first_s=298.30078125 1641329905000000000\n'})

#2021-10-28T12:26:59-06:00       appdata {"message":"xrage,desc=Spider_Plot,host=sn-rfe2.lanl.gov,problem=Asteroid.input cpu=\"Intel(R)Xeon(R)CPUE5-2695v4@2.10GHz\",env=\"SNOW\",numpe=64,nodes=2,scale=0.12,ppn_min=32,ppn_max=32,dims=3,avg_cells_min=25071,avg_cells_avg=34250.47619047619,avg_cells_max=35091,rss_min=3.508,rss_avg=10.570272727272727,rss_max=11.441,rss_max_min=3.508,rss_max_avg=11.90059090909091,rss_max_max=12.858,cyc_cc_min=0,cyc_cc_avg=349019.04761904763,cyc_cc_max=394190,sum_cyc_sec=77426,job_id=4756619,elapsed_s=1222.266,n_cycles=200,elapsed_minus_first_s=1209.78125 1635445614000000000\n"}
#{"message":"xrage,problem=Asteroid.input,desc=Spider_Plot,scm_id_0.EH0=9c29c13659d2e995cbd4f22fb8634bc7c5b47b5b,scm_id_0.EB0=master,scm_id_1.EH1=72df37ead555035ba71867782fe6a69b216ff30a,scm_id_1.EB1=master,scm_id_2.EH2=b877a35ac8480f5f05280f760f47e4a43f1b24c3,scm_id_2.EB2=master,num_scm_ids=3,run_date=1644304400000000000 job_id=\"2022-02-08-00-13\",cpu=\"Intel(R)Xeon(R)CPUE5-2695v4@2.10GHz\",env=\"SNOW\",numpe=4,nodes=1,scale=0.015,ppn_min=4,ppn_max=4,dims=3,avg_cells_min=82504,avg_cells_avg=103171.5294117647,avg_cells_max=105560,rss_min=0.353,rss_avg=1.9128333333333332,rss_max=2.138,rss_max_min=0.353,rss_max_avg=2.3774444444444445,rss_max_max=2.643,cyc_cc_min=0.0,cyc_cc_avg=49207.17647058824,cyc_cc_max=56494.0,sum_cyc_sec=5080.2,slurm_jobid=5053371,elapsed_s=1289.843,n_cycles=160,elapsed_minus_first_s=1270.05 1644307585000000000\n"}
            kv_pairs = record['message'].split(',')
            kv_pairs.each do | item |
              k, v = item.split('=')
              v.strip!()
              new_rec[k] = v
            end
            #We have bad data if kv_pairs.length is < 1
            if kv_pairs.length < 1
              next
            end
            if new_rec['metric'].include?('xrage_metrics')
              if new_rec.has_key?('job_id')
                new_rec['job_id'].gsub!(/-/, '')
              end
#scm_id_0.EH0=9c29c13659d2e995cbd4f22fb8634bc7c5b47b5b,scm_id_0.EB0=master,scm_id_1.EH1=72df37ead555035ba71867782fe6a69b216ff30a,scm_id_1.EB1=master,scm_id_2.EH2=b877a35ac8480f5f05280f760f47e4a43f1b24c3,scm_id_2.EB2=master,
              if new_rec.has_key?('scm_id_0.EH0')
                new_rec['scm_id_0_EH0'] = new_rec['scm_id_0.EH0']
                new_rec.delete('scm_id_0.EH0')
              else
                new_rec['scm_id_0_EH0'] = '9c29c13659d2e995cbd4f22fb8634bc7c5b47b5b'
              end
              if new_rec.has_key?('scm_id_0.EB0')
                new_rec['scm_id_0_EB0'] = new_rec['scm_id_0.EB0']
                new_rec.delete('scm_id_0.EB0')
              else
                new_rec['scm_id_0_EB0'] = 'master'
              end
              if new_rec.has_key?('scm_id_1.EB1')
                new_rec['scm_id_1_EB1'] = new_rec['scm_id_1.EB1']
                new_rec.delete('scm_id_1.EB1')
              else
                new_rec['scm_id_1_EB1'] = 'master'
              end
              if new_rec.has_key?('scm_id_1.EH1')
                new_rec['scm_id_1_EH1'] = new_rec['scm_id_1.EH1']
                new_rec.delete('scm_id_1.EH1')
              else
                new_rec['scm_id_1_EH1'] = '72df37ead555035ba71867782fe6a69b216ff30a'
              end
              if new_rec.has_key?('scm_id_2.EH2')
                new_rec['scm_id_2_EH2'] = new_rec['scm_id_2.EH2']
                new_rec.delete('scm_id_2.EH2')
              else
                new_rec['scm_id_2_EH2'] = 'b877a35ac8480f5f05280f760f47e4a43f1b24c3'
              end
              if new_rec.has_key?('scm_id_2.EB2')
                new_rec['scm_id_2_EB2'] = new_rec['scm_id_2.EB2']
                new_rec.delete('scm_id_2.EB2')
              else
                new_rec['scm_id_2_EB2'] = 'master'
              end

              ["numpe", "nodes",
               "ppn_min", "ppn_max", 
               "dims", 
               "n_cycles"].each do |item|
                new_rec[item] = new_rec[item].to_i
              end
              ["scale", "rss_min",
               "rss_avg", "rss_max", "cyc_cc_min", "cyc_cc_avg",
               "cyc_cc_max", "cyc_sec_min", "cyc_sec_avg",
               "cyc_sec_max", "sum_cyc_sec",
               "rss_max_min", "rss_max_avg", "rss_max_max",
               "avg_cells_min", "avg_cells_avg", "avg_cells_max", 
               "elapsed_s", "elapsed_minus_first_s"].each do |item|
                   val = new_rec[item].to_f.round(3)
                   new_rec[item] = val
              end
            else
              ["driver_after_cyclemin", "driver_after_cyclemax",
               "driver_after_cycleavg"].each do |item|
                new_rec[item] = new_rec[item].to_f
              end
            end
            
            ts = new_rec["timestamp"].to_i/1000000000
            #            new_rec["timestamp"] = Time.at(ts).utc.strftime("%Y-%m-%dT%H:%M:%S")
            new_rec["timestamp"] = ts
            metrics.push(new_rec)
            next
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
                if samples % 1 == 0
                  dup_rec = new_rec.clone
                  dup_rec['type'] = item + "_max"
                  dup_rec['val'] = fields[item]
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
          if m.has_key?("metric") and (m["metric"].include? "job_state" \
		or m["metric"].include? "job_duration" \
		or m["metric"].include? "xrage" \
		or m["metric"].include? "sap" \
		or m["metric"].include? "ristra" \
		or m["metric"].include? "lap" \
                or m["metric"].include? "jayenne")
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
