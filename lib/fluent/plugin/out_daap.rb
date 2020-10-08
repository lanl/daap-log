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

      def clean_host(host)
        host = host.gsub(/.localdomain/, '')
        return host
      end

      def process(tag, es)
        emit_tag = @tag
        es_out = MultiEventStream.new
        metrics = Array.new
        es.each do |time, record|
          next unless record.key?("message")
          jsn = JSON.parse(record['message'])
          #Go through the json and pick out what we want
          jsn.each do |child|
            if not child.has_key?('fields')
              next
            end
            if not child.has_key?('name')
              next
            end
            
            name = child['name']          
            if not ['infiniband','cpu', 'mem', 
                    'SNAP_XROADS'].include?(name)
              next
            end

            new_rec = {}
            fields = child['fields']
            #Infiniband errors
            if name == 'infiniband'
              new_rec['metric'] = 'infiniband_errors'
              ["link_downed", "link_error_recovery", 
               "local_link_integrity_errors", "port_rcv_constraint_errors", 
               "port_rcv_errors", "port_xmit_discards", 
               "port_rcv_remote_physical_errors", "port_rcv_switch_relay_errors", 
               "port_xmit_constraint_errors"].each do |item|
                new_rec[item] = fields[item]
              end

              new_rec['device'] = child['tags']['device']
            end
            #CPU Usage
            if name == 'cpu'
              new_rec['metric'] = 'cpu_usage'
              ["usage_guest", "usage_guest_nice", 
               "usage_idle", "usage_iowait", 
               "usage_irq", "usage_nice", 
               "usage_softirq", "usage_steal", 
               "usage_system", "usage_user"].each do |item|
                new_rec[item] = fields[item]
              end
            end
            #MEM usage
            if name == 'mem'
              new_rec['metric'] = 'mem_usage'
              ["active", "inactive", 
               "vmalloc_total", "vmalloc_used", 
               "used_percent"].each do |item|
                new_rec[item] = fields[item]
              end
            end
            #Heartbeat
            if fields.has_key?('message') and fields['message'] = "running"
              new_rec['metric'] = 'heartbeat'
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
          m.delete("timestamp")
          es_out.add(ts, m)
        end

        router.emit_stream(emit_tag, es_out)
      end
    end
  end
end
