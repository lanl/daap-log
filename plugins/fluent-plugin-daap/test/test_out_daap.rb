require 'fluent/test'
require 'fluent/test/driver/output'
require 'test/unit'
require 'fluent/plugin/out_daap'

class DAAPOutputTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
  end

  CONFIG = %().freeze

  def create_driver(conf = CONFIG)
    Fluent::Test::Driver::Output
      .new(Fluent::Plugin::DAAPOutput)
      .configure(conf)
  end

  def event_time
    Time.parse('2017-06-01 00:11:22 UTC').to_i
  end

  def test_daap_default
    d = create_driver %(
      @type daap
      tag daap
      format json
    )

    d.run(default_tag: 'test') do
      d.feed(event_time,
             'message' => '[{"fields":{"blocked":0,"dead":0,"idle":0,"paging":0,"running":0,"sleeping":578,"stopped":0,"total":578,"total_threads":697,"unknown":0,"zombies":0},"name":"processes","tags":{"host":"gr0288.localdomain","jobinfo":"jobid=17158464 partition=debug name=sh user=hng st=r time=11:15 nodes=2 nodelist(reason)=gr[0288-0289]"},"timestamp":1602108602},
{"fields":{"boot_time":1601902870,"context_switches":231238596,"entropy_avail":3754,"interrupts":6284512197,"processes_forked":259115},"name":"kernel","tags":{"host":"gr0288.localdomain","jobinfo":"jobid=17158464 partition=debug name=sh user=hng st=r time=11:15 nodes=2 nodelist(reason)=gr[0288-0289]"},"timestamp":1602108602},
{"fields":{"icmp_inaddrmaskreps":0,"icmp_inaddrmasks":0,"icmp_incsumerrors":0,"icmp_indestunreachs":3,"icmp_inechoreps":0,"icmp_inechos":0,"icmp_inerrors":0,"icmp_inmsgs":3,"icmp_inparmprobs":0,"icmp_inredirects":0,"icmp_insrcquenchs":0,"icmp_intimeexcds":0,"icmp_intimestampreps":0,"icmp_intimestamps":0,"icmp_outaddrmaskreps":0,"icmp_outaddrmasks":0,"icmp_outdestunreachs":3,"icmp_outechoreps":0,"icmp_outechos":0,"icmp_outerrors":0,"icmp_outmsgs":3,"icmp_outparmprobs":0,"icmp_outredirects":0,"icmp_outsrcquenchs":0,"icmp_outtimeexcds":0,"icmp_outtimestampreps":0,"icmp_outtimestamps":0,"icmpmsg_intype3":3,"icmpmsg_outtype3":3,"ip_defaultttl":64,"ip_forwarding":2,"ip_forwdatagrams":0,"ip_fragcreates":0,"ip_fragfails":0,"ip_fragoks":0,"ip_inaddrerrors":0,"ip_indelivers":1500658,"ip_indiscards":0,"ip_inhdrerrors":0,"ip_inreceives":1500658,"ip_inunknownprotos":0,"ip_outdiscards":0,"ip_outnoroutes":60,"ip_outrequests":817022,"ip_reasmfails":0,"ip_reasmoks":0,"ip_reasmreqds":0,"ip_reasmtimeout":0,"tcp_activeopens":11322,"tcp_attemptfails":366,"tcp_currestab":11,"tcp_estabresets":5638,"tcp_incsumerrors":0,"tcp_inerrs":0,"tcp_insegs":841910,"tcp_maxconn":-1,"tcp_outrsts":5109,"tcp_outsegs":831649,"tcp_passiveopens":11768,"tcp_retranssegs":2,"tcp_rtoalgorithm":1,"tcp_rtomax":120000,"tcp_rtomin":200,"udp_incsumerrors":0,"udp_indatagrams":320,"udp_inerrors":0,"udp_noports":3,"udp_outdatagrams":323,"udp_rcvbuferrors":0,"udp_sndbuferrors":0,"udplite_incsumerrors":0,"udplite_indatagrams":0,"udplite_inerrors":0,"udplite_noports":0,"udplite_outdatagrams":0,"udplite_rcvbuferrors":0,"udplite_sndbuferrors":0},"name":"net","tags":{"host":"gr0288.localdomain","interface":"all","jobinfo":"jobid=17158464 partition=debug name=sh user=hng st=r time=11:15 nodes=2 nodelist(reason)=gr[0288-0289]"},"timestamp":1602108601},
{"fields":{"bytes_recv":534111389,"bytes_sent":18083338,"drop_in":0,"drop_out":0,"err_in":0,"err_out":0,"packets_recv":860576,"packets_sent":69679},"name":"net","tags":{"host":"gr0288.localdomain","interface":"ib0","jobinfo":"jobid=17158464 partition=debug name=sh user=hng st=r time=11:15 nodes=2 nodelist(reason)=gr[0288-0289]"},"timestamp":1602108601},
{"fields":{"bytes_recv":373388550,"bytes_sent":132997181,"drop_in":0,"drop_out":0,"err_in":0,"err_out":0,"packets_recv":1073764,"packets_sent":666226},"name":"net","tags":{"host":"gr0288.localdomain","interface":"enp6s0f0","jobinfo":"jobid=17158464 partition=debug name=sh user=hng st=r time=11:15 nodes=2 nodelist(reason)=gr[0288-0289]"},"timestamp":1602108601},
{"fields":{"VL15_dropped":0,"excessive_buffer_overrun_errors":0,"link_downed":0,"link_error_recovery":0,"local_link_integrity_errors":0,"multicast_rcv_packets":760039,"multicast_xmit_packets":36,"port_rcv_constraint_errors":0,"port_rcv_data":3411489449451,"port_rcv_errors":0,"port_rcv_packets":4860767967,"port_rcv_remote_physical_errors":0,"port_rcv_switch_relay_errors":0,"port_xmit_constraint_errors":0,"port_xmit_data":3466783092894,"port_xmit_discards":0,"port_xmit_packets":4916819511,"port_xmit_wait":0,"symbol_error":0,"unicast_rcv_packets":0,"unicast_xmit_packets":0},"name":"infiniband","tags":{"device":"hfi1_0","host":"gr0288.localdomain","jobinfo":"jobid=17158464 partition=debug name=sh user=hng st=r time=11:15 nodes=2 nodelist(reason)=gr[0288-0289]","port":"1"},"timestamp":1602108601},
{"fields":{"usage_guest":0,"usage_guest_nice":0,"usage_idle":99.98283556482713,"usage_iowait":0,"usage_irq":0,"usage_nice":0,"usage_softirq":0,"usage_steal":0,"usage_system":0.011442956858234366,"usage_user":0.005721478302148018},"name":"cpu","tags":{"cpu":"cpu-total","host":"gr0288.localdomain","jobinfo":"jobid=17158464 partition=debug name=sh user=hng st=r time=11:15 nodes=2 nodelist(reason)=gr[0288-0289]"},"timestamp":1602108600},
{"fields":{"active":813150208,"available":130615189504,"available_percent":96.67961631181115,"buffered":0,"cached":1328513024,"commit_limit":132399038464,"committed_as":2210308096,"dirty":0,"free":131010793472,"high_free":0,"high_total":0,"huge_page_size":2097152,"huge_pages_free":0,"huge_pages_total":0,"inactive":789049344,"low_free":0,"low_total":0,"mapped":52629504,"page_tables":6553600,"shared":770461696,"slab":866131968,"sreclaimable":344834048,"sunreclaim":521297920,"swap_cached":0,"swap_free":0,"swap_total":0,"total":135101063168,"used":2761756672,"used_percent":2.044215350522977,"vmalloc_chunk":35113390198784,"vmalloc_total":35184372087808,"vmalloc_used":1199177728,"wired":0,"write_back":0,"write_back_tmp":0},"name":"mem","tags":{"host":"gr0288.localdomain","jobinfo":"jobid=17158464 partition=debug name=sh user=hng st=r time=11:15 nodes=2 nodelist(reason)=gr[0288-0289]"},"timestamp":1602108601},
{"fields":{"cpus_on_node":36,"hostname":"gr0288","job_id":"17158464","message":"running","mpi_rank":0,"ntasks":8,"source":"daap_log","task_pid":5898},"name":"SNAP_XROADS","tags":{"host":"gr0288.localdomain","jobinfo":"jobid=17158464 partition=debug name=sh user=hng st=r time=10:15 nodes=2 nodelist(reason)=gr[0288-0289]"},"timestamp":1602108543}]')
    end

    assert_equal [
                  ["daap",
                   1602108601,
                   {"device"=>"hfi1_0",
                     "host"=>"gr0288",
                     "job_name"=>"sh",
                     "jobid"=>"17158464",
                     "link_downed"=>0,
                     "link_error_recovery"=>0,
                     "local_link_integrity_errors"=>0,
                     "metric"=>"infiniband_errors",
                     "port_rcv_constraint_errors"=>0,
                     "port_rcv_errors"=>0,
                     "port_rcv_remote_physical_errors"=>0,
                     "port_rcv_switch_relay_errors"=>0,
                     "port_xmit_constraint_errors"=>0,
                     "port_xmit_discards"=>0,
                     "user"=>"hng"}],
                  ["daap",
                   1602108600,
                   {"host"=>"gr0288",
                     "job_name"=>"sh",
                     "jobid"=>"17158464",
                     "metric"=>"cpu_usage",
                     "usage_guest"=>0,
                     "usage_guest_nice"=>0,
                     "usage_idle"=>99.98283556482713,
                     "usage_iowait"=>0,
                     "usage_irq"=>0,
                     "usage_nice"=>0,
                     "usage_softirq"=>0,
                     "usage_steal"=>0,
                     "usage_system"=>0.011442956858234366,
                     "usage_user"=>0.005721478302148018,
                     "user"=>"hng"}],
                  ["daap",
                   1602108601,
                   {"active"=>813150208,
                     "host"=>"gr0288",
                     "inactive"=>789049344,
                     "job_name"=>"sh",
                     "jobid"=>"17158464",
                     "metric"=>"mem_usage",
                     "used_percent"=>2.044215350522977,
                     "user"=>"hng",
                     "vmalloc_total"=>35184372087808,
                     "vmalloc_used"=>1199177728}],
                  ["daap",
                   1602108543,
                   {"host"=>"gr0288",
                     "job_name"=>"sh",
                     "jobid"=>"17158464",
                     "metric"=>"heartbeat",
                     "user"=>"hng"}]
                 ], d.events
  end
end
