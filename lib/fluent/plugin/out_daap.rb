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

      #Clean the hostname
      def clean_host(host)
        host = host.gsub(/.localdomain/, '')
        return host
      end

      #Deep copy hash
      def deep_copy(o)
        Marshal.load(Marshal.dump(o))
      end

      #Process each incoming message
      def process(tag, es)
        emit_tag = @tag
        es_out = MultiEventStream.new
        metrics = Array.new
        es.each do |time, record|
          next unless record.key?("metrics")
          jsn = record['metrics']
          #Go through the json and pick out what we want
          jsn.each do |child|
            if not child.has_key?('fields')
              next
            end
            if not child.has_key?('name')
              next
            end
            
            metric_name = child['name']          
            if not ['infiniband','cpu', 'mem', 
                    'daap'].include?(metric_name)
              next
            end

            new_rec = {}
            fields = child['fields']
            #Heartbeat, job start, job end
            if fields.has_key?('message') and (fields['message'] == "running" or fields['message'] == "heartbeat")
              new_rec['metric'] = 'heartbeat'
              new_rec['val'] = 1
            elsif fields.has_key?('message') and fields['message'].index(/job start/) != nil
              new_rec['metric'] = 'job_state'
              new_rec['state'] = 'start'
            elsif fields.has_key?('message') and fields['message'].index(/job end/) != nil 
              new_rec['metric'] = 'job_state'
              new_rec['state'] = 'end'
            end
            #Add common fields
            new_rec['host'] = clean_host(child['tags']['host'])
            new_rec['timestamp'] = child['timestamp']
            #Get jobinfo
            if child['tags'].has_key?('jobinfo')
              if match = child['tags']['jobinfo'].match(/jobid=([^ ]+).*name=([^ ]+).*user=([^ ]+)/i)
                jobid, name, user = match.captures
                if jobid
                  new_rec['jobid'] = jobid
                else
                  new_rec['jobid'] = "0"
                end
                if name
                  new_rec['job_name'] = name
                else
                  new_rec['job_name'] = ""
                end
                if user
                  new_rec['user'] = user
                else
                  new_rec['user'] = ""
                end
              end            
            end
            #Infiniband errors
            if metric_name == 'infiniband'
              new_rec['metric'] = 'infiniband_errors'
              new_rec['device'] = child['tags']['device']
              ["link_downed", "link_error_recovery", 
               "local_link_integrity_errors", "port_rcv_constraint_errors", 
               "port_rcv_errors", "port_xmit_discards", 
               "port_rcv_remote_physical_errors", "port_rcv_switch_relay_errors", 
               "port_xmit_constraint_errors"].each do |item|
                rec = deep_copy(new_rec)
                rec['type'] = item
                rec['val'] = fields[item]
                metrics.push(rec)
              end
            #CPU Usage
            elsif metric_name == 'cpu'
              new_rec['metric'] = 'cpu_usage'
              ["usage_guest", "usage_guest_nice", 
               "usage_idle", "usage_iowait", 
               "usage_irq", "usage_nice", 
               "usage_softirq", "usage_steal", 
               "usage_system", "usage_user"].each do |item|
                rec = deep_copy(new_rec)
                rec['type'] = item.gsub(/usage_/, '')
                rec['val'] = fields[item]
                metrics.push(rec)
              end
            #MEM usage
            elsif metric_name == 'mem'
              new_rec['metric'] = 'mem_usage'
              ["active", "inactive", 
               "vmalloc_total", "vmalloc_used", 
               "used_percent"].each do |item|
                rec = deep_copy(new_rec)
                rec['type'] = item.gsub(/usage_/, '')
                rec['val'] = fields[item]
                metrics.push(rec)
              end
            else
              #Add to queue
              metrics.push(new_rec)
            end
          end
        end

        if metrics.length == 0
          return
        end
        #Send records
        metrics.each do |m|
          ts = m["timestamp"]
          if m['metric'] == 'job_state'
            m["timestamp"] = Time.at(ts).iso8601
          end
          es_out.add(ts, m)
        end

        router.emit_stream(emit_tag, es_out)
      end
    end
  end
end
