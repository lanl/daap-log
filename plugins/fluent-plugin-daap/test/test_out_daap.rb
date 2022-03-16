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


    d.run(default_tag: 'jayenne') do
      d.feed(event_time,
             {'message' => 'jayenne,desc=strong_scaling_8x_particles,host=sn315.localdomain,n_cores=8,n_particles=800000,problem=./experiments/ddmc_rep_hohlraum.inp runtime=333 1638984508000000000\n'})
    end

    assert_equal [
                  [
                   "daap",
                   1638984508,
                   {"desc"=>"strong_scaling_8x_particles",
                     "host"=>"sn315",
                     "metric"=>"jayenne_metrics",
                     "n_cores"=>8,
                     "n_particles"=>800000,
                     "problem"=>"./experiments/ddmc_rep_hohlraum.inp",
                     "runtime"=>333.0,
                     "timestamp"=>"2021-12-08T17:28:28"}
                  ]          
                 ], d.events
  end

##2022-02-10T14:19:01-07:00       appdata {"message":"mcatk app=\"mcatk-parallel-driver\",problem=\"ZEBR8H_CylRZ.pbi\",description=\"mcatk spider plot data\",cpu=\"Intel(R) Xeon(R) CPU E5-2695 v4 @ 2.10GHz\",machine=\"sn-rfe3.lanl.gov\",particles_per_cycle=\"4000\",ppn=32,nodes=1,numpe=32,jobid=\"mcatk-run-32-numpe-2022-18-10-14-02\",total_solve_time=\"0.090000\",env_LCOMPILER=\"gcc\",env_SLURM_MPI_TYPE=\"pmix_v2\",env_LMPI=\"openmpi\",env_MODULEPATH_ROOT=\"/usr/share/modulefiles\",env_OMPI_F77=\"gfortran\",env_OMPI_FC=\"gfortran\",env_QT_ROOT=\"/usr/projects/hpcsoft/toss3/common/qt/4.8.6\",env_LMPIVER=\"3.1.6\",env_MIDDLEMAN_ROOT=\"/yellow/usr/projects/mcatk/dependencies/spack_mcatk_toss3_01-12-2022/spack/opt/spack/linux-rhel7-x86_64/gcc-8.3.0/middleman-3.0.3-rrfarox3fmfczctng5qtrej3bhtsin2d\",env_MPI_NAME=\"openmpi\",env_QWT_ROOT=\"/yellow/usr/projects/mcatk/dependencies/spack_mcatk_toss3_01-12-2022/spack/opt/spack/linux-rhel7-x86_64/gcc-8.3.0/qwt-5.2.2-ejeks4tpxmwo3bypais3ky5omcateu54\",env_F5_CXX_ROOT=\"/yellow/usr/projects/mcatk/dependencies/spack_mcatk_toss3_01-12-2022/spack/opt/spack/linux-rhel7-x86_64/gcc-8.3.0/f5_cxx-1.6.2-rfxyvajy3sxg7c2javn2in5vc24i2trl\",env_MPI_VERSION=\"3.1.6\",env_OMPI_CC=\"gcc\",env_LCOMPILERMAJVER=\"8\",env_MPIHOME=\"/usr/projects/hpcsoft/toss3/snow/openmpi/3.1.6-gcc-8.3.0\",env_MPI_ROOT=\"/usr/projects/hpcsoft/toss3/snow/openmpi/3.1.6-gcc-8.3.0\",env_BOOST_ROOT=\"/yellow/usr/projects/mcatk/dependencies/spack_mcatk_toss3_01-12-2022/spack/opt/spack/linux-rhel7-x86_64/gcc-8.3.0/boost-1.69.0-vluaiqxwikmzichzmo3otfpifjm4h7q6\",env_OMPI_CXX=\"g++\",env_LMPIMAJVER=\"3\",env_LCOMPILERVER=\"8.3.0\",env_CMAKE_PREFIX_PATH=\"/yellow/usr/projects/mcatk/dependencies/spack_mcatk_toss3_01-12-2022/spack/opt/spack/linux-rhel7-x86_64/gcc-8.3.0/qwt-5.2.2-ejeks4tpxmwo3bypais3ky5omcateu54:/usr/projects/hpcsoft/toss3/common/qt/4.8.6:/yellow/usr/projects/mcatk/dependencies/spack_mcatk_toss3_01-12-2022/spack/opt/spack/linux-rhel7-x86_64/gcc-8.3.0/middleman-3.0.3-rrfarox3fmfczctng5qtrej3bhtsin2d:/yellow/usr/projects/mcatk/dependencies/spack_mcatk_toss3_01-12-2022/spack/opt/spack/linux-rhel7-x86_64/gcc-8.3.0/py-scipy-1.5.4-arptjrgulhlqye3pdbnp5lswlp4mqyae:/yellow/usr/projects/mcatk/dependencies/spack_mcatk_toss3_01-12-2022/spack/opt/spack/linux-rhel7-x86_64/gcc-8.3.0/py-pybind11-2.5.0-h3lvujtrrfmpgfclraj6vhudeqqyfx6x:/yellow/usr/projects/mcatk/dependencies/spack_mcatk_toss3_01-12-2022/spack/opt/spack/linux-rhel7-x86_64/gcc-8.3.0/py-matplotlib-3.3.3-jomtacbuxqiidv5a4ltad4w4zothq4sn:/yellow/usr/projects/mcatk/dependencies/spack_mcatk_toss3_01-12-2022/spack/opt/spack/linux-rhel7-x86_64/gcc-8.3.0/py-python-dateutil-2.8.0-tdljsrcl7bjrz7mwx2puxoaz6jbfv3fn:/yellow/usr/projects/mcatk/dependencies/spack_mcatk_toss3_01-12-2022/spack/opt/spack/linux-rhel7-x86_64/gcc-8.3.0/py-pyparsing-2.4.2-ilfjto5ryw4tykyqcket6rzkzwvlgmib:/yellow/usr/projects/mcatk/dependencies/spack_mcatk_toss3_01-12-2022/spack/opt/spack/linux-rhel7-x86_64/gcc-8.3.0/py-pillow-7.2.0-44jydoc7rpwaohsu6f4qjbbwawlxeyhh:/yellow/usr/projects/mcatk/dependencies/spack_mcatk_toss3_01-12-2022/spack/opt/spack/linux-rhel7-x86_64/gcc-8.3.0/libjpeg-turbo-2.0.4-4npcpdor5jqf6buln73mventb5a4ioko:/yellow/usr/projects/mcatk/dependencies/spack_mcatk_toss3_01-12-2022/spack/opt/spack/linux-rhel7-x86_64/gcc-8.3.0/py-kiwisolver-1.1.0-7bchrqkifibkcogkd4y2tzu56q2mxtx2:/yellow/usr/projects/mcatk/dependencies/spack_mcatk_toss3_01-12-2022/spack/opt/spack/linux-rhel7-x86_64/gcc-8.3.0/py-cycler-0.10.0-zmx4xwwyblwlwroa3v3zzfxibarwzh3m:/yellow/usr/projects/mcatk/dependencies/spack_mcatk_toss3_01-12-2022/spack/opt/spack/linux-rhel7-x86_64/gcc-8.3.0/py-h5py-2.10.0-je37mcrshhtjqadc37zax257vv23ayrg:/yellow/usr/projects/mcatk/dependencies/spack_mcatk_toss3_01-12-2022/spack/opt/spack/linux-rhel7-x86_64/gcc-8.3.0/py-six-1.14.0-urcpwosg7pnvo2dpj6x7ptgbfjtwhpef:/yellow/usr/projects/mcatk/dependencies/spack_mcatk_toss3_01-12-2022/spack/opt/spack/linux-rhel7-x86_64/gcc-8.3.0/py-numpy-1.19.4-gujyw2ho3rznmcbezjtnnzpiw2cwyhtf:/yellow/usr/projects/mcatk/dependencies/spack_mcatk_toss3_01-12-2022/spack/opt/spack/linux-rhel7-x86_64/gcc-8.3.0/py-setuptools-50.3.2-ripqbripmna6xr7eo4glj2xo6cgsj3on:/yellow/usr/projects/mcatk/dependencies/spack_mcatk_toss3_01-12-2022/spack/opt/spack/linux-rhel7-x86_64/gcc-8.3.0/mcatk-loki-0.1.7-ybt46pnkinkk455wptvxr4w4t5y5mjnw:/yellow/usr/projects/mcatk/dependencies/spack_mcatk_toss3_01-12-2022/spack/opt/spack/linux-rhel7-x86_64/gcc-8.3.0/meshwriter-1.0.0-rr7xkg33fugicfelkgjyyhzqrb2lt7pn:/yellow/usr/projects/mcatk/dependencies/spack_mcatk_toss3_01-12-2022/spack/opt/spack/linux-rhel7-x86_64/gcc-8.3.0/mpark-variant-1.4.0-65yqgbfomhs5u6tuvxgl7hwbd5ujgiyz:/yellow/usr/projects/mcatk/dependencies/spack_mcatk_toss3_01-12-2022/spack/opt/spack/linux-rhel7-x86_64/gcc-8.3.0/unittest-cpp-1.6.0-vml6lutukzbzabmon5x6eaxchz2nhoi3:/yellow/usr/projects/mcatk/dependencies/spack_mcatk_toss3_01-12-2022/spack/opt/spack/linux-rhel7-x86_64/gcc-8.3.0/ndatk-1.1.1-fotqa6e7fo6rdj7mlvpmlznclb5nk6ts:/yellow/usr/projects/mcatk/dependencies/spack_mcatk_toss3_01-12-2022/spack/opt/spack/linux-rhel7-x86_64/gcc-8.3.0/f5_cxx-1.6.2-rfxyvajy3sxg7c2javn2in5vc24i2trl:/yellow/usr/projects/mcatk/dependencies/spack_mcatk_toss3_01-12-2022/spack/opt/spack/linux-rhel7-x86_64/gcc-8.3.0/hdf5-1.10.7-qlnksh3o33ughir5yxao6ukyjxzyte7w:/yellow/usr/projects/mcatk/dependencies/spack_mcatk_toss3_01-12-2022/spack/opt/spack/linux-rhel7-x86_64/gcc-8.3.0/distributions-0.2.0-aermy4whl3nxwlqvg4qy57ja5ksuowun:/yellow/usr/projects/mcatk/dependencies/spack_mcatk_toss3_01-12-2022/spack/opt/spack/linux-rhel7-x86_64/gcc-8.3.0/trait-2.0.0-yyimddjhzuo6ra5z4ioxg4mgkj7vbf7f:/yellow/usr/projects/mcatk/dependencies/spack_mcatk_toss3_01-12-2022/spack/opt/spack/linux-rhel7-x86_64/gcc-8.3.0/boost-1.69.0-vluaiqxwikmzichzmo3otfpifjm4h7q6:/usr/projects/hpcsoft/toss3/common/x86_64/cmake/3.17.2\",env_CC=\"gcc\",env_NDATK_ROOT=\"/yellow/usr/projects/mcatk/dependencies/spack_mcatk_toss3_01-12-2022/spack/opt/spack/linux-rhel7-x86_64/gcc-8.3.0/ndatk-1.1.1-fotqa6e7fo6rdj7mlvpmlznclb5nk6ts\",env_UNITTEST_ROOT=\"/yellow/usr/projects/mcatk/dependencies/spack_mcatk_toss3_01-12-2022/spack/opt/spack/linux-rhel7-x86_64/gcc-8.3.0/unittest-cpp-1.6.0-vml6lutukzbzabmon5x6eaxchz2nhoi3\",env_LOKI_ROOT=\"/yellow/usr/projects/mcatk/dependencies/spack_mcatk_toss3_01-12-2022/spack/opt/spack/linux-rhel7-x86_64/gcc-8.3.0/mcatk-loki-0.1.7-ybt46pnkinkk455wptvxr4w4t5y5mjnw\" 1644527941000000000\n"}
  def test_daap_mcatk
    d = create_driver %(
      @type daap
      tag daap
      format json
    )

    d.run(default_tag: 'mcatk') do
      d.feed(event_time,
             {"message" => "mcatk app=\"mcatk-parallel-driver\",problem=\"ZEBR8H_CylRZ.pbi\",description=\"mcatk spider plot data\",cpu=\"Intel(R) Xeon(R) CPU E5-2695 v4 @ 2.10GHz\",machine=\"sn-rfe3.lanl.gov\",particles_per_cycle=\"4000\",ppn=32,nodes=1,numpe=32,jobid=\"mcatk-run-32-numpe-2022-18-10-14-02\",total_solve_time=\"0.090000\",env_LCOMPILER=\"gcc\",env_SLURM_MPI_TYPE=\"pmix_v2\",env_LMPI=\"openmpi\",env_MODULEPATH_ROOT=\"/usr/share/modulefiles\",env_OMPI_F77=\"gfortran\",env_OMPI_FC=\"gfortran\",env_QT_ROOT=\"/usr/projects/hpcsoft/toss3/common/qt/4.8.6\",env_LMPIVER=\"3.1.6\",env_MIDDLEMAN_ROOT=\"/yellow/usr/projects/mcatk/dependencies/spack_mcatk_toss3_01-12-2022/spack/opt/spack/linux-rhel7-x86_64/gcc-8.3.0/middleman-3.0.3-rrfarox3fmfczctng5qtrej3bhtsin2d\",env_MPI_NAME=\"openmpi\",env_QWT_ROOT=\"/yellow/usr/projects/mcatk/dependencies/spack_mcatk_toss3_01-12-2022/spack/opt/spack/linux-rhel7-x86_64/gcc-8.3.0/qwt-5.2.2-ejeks4tpxmwo3bypais3ky5omcateu54\",env_F5_CXX_ROOT=\"/yellow/usr/projects/mcatk/dependencies/spack_mcatk_toss3_01-12-2022/spack/opt/spack/linux-rhel7-x86_64/gcc-8.3.0/f5_cxx-1.6.2-rfxyvajy3sxg7c2javn2in5vc24i2trl\",env_MPI_VERSION=\"3.1.6\",env_OMPI_CC=\"gcc\",env_LCOMPILERMAJVER=\"8\",env_MPIHOME=\"/usr/projects/hpcsoft/toss3/snow/openmpi/3.1.6-gcc-8.3.0\",env_MPI_ROOT=\"/usr/projects/hpcsoft/toss3/snow/openmpi/3.1.6-gcc-8.3.0\",env_BOOST_ROOT=\"/yellow/usr/projects/mcatk/dependencies/spack_mcatk_toss3_01-12-2022/spack/opt/spack/linux-rhel7-x86_64/gcc-8.3.0/boost-1.69.0-vluaiqxwikmzichzmo3otfpifjm4h7q6\",env_OMPI_CXX=\"g++\",env_LMPIMAJVER=\"3\",env_LCOMPILERVER=\"8.3.0\",env_CMAKE_PREFIX_PATH=\"/yellow/usr/projects/mcatk/dependencies/spack_mcatk_toss3_01-12-2022/spack/opt/spack/linux-rhel7-x86_64/gcc-8.3.0/qwt-5.2.2-ejeks4tpxmwo3bypais3ky5omcateu54:/usr/projects/hpcsoft/toss3/common/qt/4.8.6:/yellow/usr/projects/mcatk/dependencies/spack_mcatk_toss3_01-12-2022/spack/opt/spack/linux-rhel7-x86_64/gcc-8.3.0/middleman-3.0.3-rrfarox3fmfczctng5qtrej3bhtsin2d:/yellow/usr/projects/mcatk/dependencies/spack_mcatk_toss3_01-12-2022/spack/opt/spack/linux-rhel7-x86_64/gcc-8.3.0/py-scipy-1.5.4-arptjrgulhlqye3pdbnp5lswlp4mqyae:/yellow/usr/projects/mcatk/dependencies/spack_mcatk_toss3_01-12-2022/spack/opt/spack/linux-rhel7-x86_64/gcc-8.3.0/py-pybind11-2.5.0-h3lvujtrrfmpgfclraj6vhudeqqyfx6x:/yellow/usr/projects/mcatk/dependencies/spack_mcatk_toss3_01-12-2022/spack/opt/spack/linux-rhel7-x86_64/gcc-8.3.0/py-matplotlib-3.3.3-jomtacbuxqiidv5a4ltad4w4zothq4sn:/yellow/usr/projects/mcatk/dependencies/spack_mcatk_toss3_01-12-2022/spack/opt/spack/linux-rhel7-x86_64/gcc-8.3.0/py-python-dateutil-2.8.0-tdljsrcl7bjrz7mwx2puxoaz6jbfv3fn:/yellow/usr/projects/mcatk/dependencies/spack_mcatk_toss3_01-12-2022/spack/opt/spack/linux-rhel7-x86_64/gcc-8.3.0/py-pyparsing-2.4.2-ilfjto5ryw4tykyqcket6rzkzwvlgmib:/yellow/usr/projects/mcatk/dependencies/spack_mcatk_toss3_01-12-2022/spack/opt/spack/linux-rhel7-x86_64/gcc-8.3.0/py-pillow-7.2.0-44jydoc7rpwaohsu6f4qjbbwawlxeyhh:/yellow/usr/projects/mcatk/dependencies/spack_mcatk_toss3_01-12-2022/spack/opt/spack/linux-rhel7-x86_64/gcc-8.3.0/libjpeg-turbo-2.0.4-4npcpdor5jqf6buln73mventb5a4ioko:/yellow/usr/projects/mcatk/dependencies/spack_mcatk_toss3_01-12-2022/spack/opt/spack/linux-rhel7-x86_64/gcc-8.3.0/py-kiwisolver-1.1.0-7bchrqkifibkcogkd4y2tzu56q2mxtx2:/yellow/usr/projects/mcatk/dependencies/spack_mcatk_toss3_01-12-2022/spack/opt/spack/linux-rhel7-x86_64/gcc-8.3.0/py-cycler-0.10.0-zmx4xwwyblwlwroa3v3zzfxibarwzh3m:/yellow/usr/projects/mcatk/dependencies/spack_mcatk_toss3_01-12-2022/spack/opt/spack/linux-rhel7-x86_64/gcc-8.3.0/py-h5py-2.10.0-je37mcrshhtjqadc37zax257vv23ayrg:/yellow/usr/projects/mcatk/dependencies/spack_mcatk_toss3_01-12-2022/spack/opt/spack/linux-rhel7-x86_64/gcc-8.3.0/py-six-1.14.0-urcpwosg7pnvo2dpj6x7ptgbfjtwhpef:/yellow/usr/projects/mcatk/dependencies/spack_mcatk_toss3_01-12-2022/spack/opt/spack/linux-rhel7-x86_64/gcc-8.3.0/py-numpy-1.19.4-gujyw2ho3rznmcbezjtnnzpiw2cwyhtf:/yellow/usr/projects/mcatk/dependencies/spack_mcatk_toss3_01-12-2022/spack/opt/spack/linux-rhel7-x86_64/gcc-8.3.0/py-setuptools-50.3.2-ripqbripmna6xr7eo4glj2xo6cgsj3on:/yellow/usr/projects/mcatk/dependencies/spack_mcatk_toss3_01-12-2022/spack/opt/spack/linux-rhel7-x86_64/gcc-8.3.0/mcatk-loki-0.1.7-ybt46pnkinkk455wptvxr4w4t5y5mjnw:/yellow/usr/projects/mcatk/dependencies/spack_mcatk_toss3_01-12-2022/spack/opt/spack/linux-rhel7-x86_64/gcc-8.3.0/meshwriter-1.0.0-rr7xkg33fugicfelkgjyyhzqrb2lt7pn:/yellow/usr/projects/mcatk/dependencies/spack_mcatk_toss3_01-12-2022/spack/opt/spack/linux-rhel7-x86_64/gcc-8.3.0/mpark-variant-1.4.0-65yqgbfomhs5u6tuvxgl7hwbd5ujgiyz:/yellow/usr/projects/mcatk/dependencies/spack_mcatk_toss3_01-12-2022/spack/opt/spack/linux-rhel7-x86_64/gcc-8.3.0/unittest-cpp-1.6.0-vml6lutukzbzabmon5x6eaxchz2nhoi3:/yellow/usr/projects/mcatk/dependencies/spack_mcatk_toss3_01-12-2022/spack/opt/spack/linux-rhel7-x86_64/gcc-8.3.0/ndatk-1.1.1-fotqa6e7fo6rdj7mlvpmlznclb5nk6ts:/yellow/usr/projects/mcatk/dependencies/spack_mcatk_toss3_01-12-2022/spack/opt/spack/linux-rhel7-x86_64/gcc-8.3.0/f5_cxx-1.6.2-rfxyvajy3sxg7c2javn2in5vc24i2trl:/yellow/usr/projects/mcatk/dependencies/spack_mcatk_toss3_01-12-2022/spack/opt/spack/linux-rhel7-x86_64/gcc-8.3.0/hdf5-1.10.7-qlnksh3o33ughir5yxao6ukyjxzyte7w:/yellow/usr/projects/mcatk/dependencies/spack_mcatk_toss3_01-12-2022/spack/opt/spack/linux-rhel7-x86_64/gcc-8.3.0/distributions-0.2.0-aermy4whl3nxwlqvg4qy57ja5ksuowun:/yellow/usr/projects/mcatk/dependencies/spack_mcatk_toss3_01-12-2022/spack/opt/spack/linux-rhel7-x86_64/gcc-8.3.0/trait-2.0.0-yyimddjhzuo6ra5z4ioxg4mgkj7vbf7f:/yellow/usr/projects/mcatk/dependencies/spack_mcatk_toss3_01-12-2022/spack/opt/spack/linux-rhel7-x86_64/gcc-8.3.0/boost-1.69.0-vluaiqxwikmzichzmo3otfpifjm4h7q6:/usr/projects/hpcsoft/toss3/common/x86_64/cmake/3.17.2\",env_CC=\"gcc\",env_NDATK_ROOT=\"/yellow/usr/projects/mcatk/dependencies/spack_mcatk_toss3_01-12-2022/spack/opt/spack/linux-rhel7-x86_64/gcc-8.3.0/ndatk-1.1.1-fotqa6e7fo6rdj7mlvpmlznclb5nk6ts\",env_UNITTEST_ROOT=\"/yellow/usr/projects/mcatk/dependencies/spack_mcatk_toss3_01-12-2022/spack/opt/spack/linux-rhel7-x86_64/gcc-8.3.0/unittest-cpp-1.6.0-vml6lutukzbzabmon5x6eaxchz2nhoi3\",env_LOKI_ROOT=\"/yellow/usr/projects/mcatk/dependencies/spack_mcatk_toss3_01-12-2022/spack/opt/spack/linux-rhel7-x86_64/gcc-8.3.0/mcatk-loki-0.1.7-ybt46pnkinkk455wptvxr4w4t5y5mjnw\" 1644527941000000000\n"})

    end

    assert_equal [
                 ], d.events
  end

  def test_daap_sap
    d = create_driver %(
      @type daap
      tag daap
      format json
    )

    d.run(default_tag: 'sap') do
      d.feed(event_time,
             {"message" => "sap,problem=SAP_PERF_Shape_Charge_spider_plot_symmetry,desc=spider_plot,jobid=5037788 npes=128,nnodes=4,cells=3513600,cpu=\"sn028.localdomain\",version=\"CTS1-intel-openmpi-sgl-no_offload-v17.4.3dev\",cpu_time_per_cell=21.115,runtime_per_cycle=579606.75 1643815974000000000\n"})
    end

    assert_equal [
                 ], d.events
  end

  def test_daap_ristra
    d = create_driver %(
      @type daap
      tag daap
      format json
    )


    d.run(default_tag: 'ristratest') do
      d.feed(event_time,
             {"message" => "poisson-metrics app=\"Ristra-Poisson\",problemname=\"Ristra Poisson Prototype Problem\",description=\"Spider Plot\",cpu=\"TODO\",env=\"snow\",nodes=4,numpe=32,ppn=8,dims=\"5793x5793\",cells=33558849,jobid=\"2022-03-16-02\",cycles=50000,cycle_time=23.24272763 1647430894000000000\n"})

    end

    assert_equal [
                  ["daap",
                   1637115456,
                   {"app"=>"Ristra-Poisson",
                     "cells"=>150994944,
                     "cpu"=>0.0,
                     "cycle_time"=>0.663,
                     "cycles"=>75000,
                     "description"=>"Spider Plot",
                     "dims"=>"12288x12288",
                     "env"=>"snow",
                     "host"=>"sn031",
                     "jobid"=>"TODO",
                     "metric"=>"ristra_metrics",
                     "nodes"=>2,
                     "numpe"=>32,
                     "ppn"=>16,
                     "problemname"=>"Ristra Poisson Prototype Problem",
                     "timestamp"=>"2021-11-17T02:17:36"}]
                 ], d.events
    
  end

  def test_daap_lap_spider
    d = create_driver %(
      @type daap
      tag daap
      format json
    )

    d.run(default_tag: 'laptest') do
      d.feed(event_time,
             {"message" => "lap-metrics,problem=LAP_LH_Spider_Plot,desc=spider_plot,jobid=5122009 problem_name=\"LAP_LH_Spider_Plot\",application_name=\"FLAG\",problem_description=\"LAP_LH_Scaling_ndim80_4PE_per_node\",suite=\"CTS1Ifast\",num_nodes=8,num_tasks_per_node=4,total_number_of_zones=1088000,number_of_cycles-1=20,tot-time_cycles-1=\"2.076E-04\",total_number_of_processors=32,adjusted_runtime=4517.376 1646414836000000000\n"})
    end

    assert_equal [
                  ["daap",
                   1641276764,
                   {"adjusted_runtime"=>30594.56,
                     "application_name"=>"FLAG",
                     "desc"=>"spider_plot",
                     "host"=>"sn035",
                     "jobid"=>"4963086",
                     "metric"=>"lap_metrics",
                     "num_nodes"=>"1",
                     "num_tasks_per_node"=>"4",
                     "number_of_cycles-1"=>20,
                     "problem"=>"LAP_LH_Spider_Plot",
                     "problem_description"=>"LAP_LH_Scaling_ndim80_4PE_per_node",
                     "problem_name"=>"LAP_LH_Spider_Plot",
                     "suite"=>"CTS1Ifast",
                     "timestamp"=>"2022-01-04T06:12:44",
                     "tot-time_cycles-1"=>0.001406,
                     "total_number_of_processors"=>4,
                     "total_number_of_zones"=>1088000}]
                 ], d.events
  end
  def test_daap_xrage
    d = create_driver %(
      @type daap
      tag daap
      format json
    )

    d.run(default_tag: 'test') do
      d.feed(event_time,
             {"message" => "xrage,problem=Asteroid.input,desc=Spider_Plot,num_scm_ids=3,scm_id_0.EH0=9c29c13659d2e995cbd4f22fb8634bc7c5b47b5b,scm_id_0.EB0=master,scm_id_1.EH1=72df37ead555035ba71867782fe6a69b216ff30a,scm_id_1.EB1=master,scm_id_2.EH2=b877a35ac8480f5f05280f760f47e4a43f1b24c3,scm_id_2.EB2=master,run_date=1643837055000000000 job_id=\"2022-02-02-09-35\",cpu=\"Intel(R)Xeon(R)CPUE5-2695v4@2.10GHz\",env=\"SNOW\",numpe=256,nodes=8,scale=0.12,ppn_min=32,ppn_max=32,dims=3,avg_cells_min=6267,avg_cells_avg=8515.70588235294,avg_cells_max=8739,rss_min=3.453,rss_avg=7.6579444444444436,rss_max=8.314,rss_max_min=3.453,rss_max_avg=7.988222222222223,rss_max_max=8.717,cyc_cc_min=0.0,cyc_cc_avg=1051624.705882353,cyc_cc_max=1366600.0,sum_cyc_sec=81463.0,slurm_jobid=5038749,elapsed_s=322.873,n_cycles=160,elapsed_minus_first_s=318.21484375 1643837470000000000\n"})
    end

    assert_equal [
                  ["daap",
                   1641329905,
                   {"avg_cells_avg"=>8515.706,
                     "avg_cells_max"=>8739.0,
                     "avg_cells_min"=>6267.0,
                     "cpu"=>"Intel(R)Xeon(R)CPUE5-2695v4@2.10GHz",
                     "cyc_cc_avg"=>1120288.235,
                     "cyc_cc_max"=>1413200.0,
                     "cyc_cc_min"=>0.0,
                     "cyc_sec_avg"=>0.0,
                     "cyc_sec_max"=>0.0,
                     "cyc_sec_min"=>0.0,
                     "desc"=>"Spider_Plot",
                     "dims"=>3,
                     "elapsed_minus_first_s"=>298.301,
                     "elapsed_s"=>302.733,
                     "env"=>"SNOW",
                     "host"=>"gr-rfe2",
                     "job_id"=>"4963828",
                     "metric"=>"xrage_metrics",
                     "n_cycles"=>160,
                     "nodes"=>8,
                     "num_scm_ids"=>"3",
                     "numpe"=>256,
                     "ppn_max"=>32,
                     "ppn_min"=>32,
                     "problem"=>"Asteroid.input",
                     "rss_avg"=>7.683,
                     "rss_max"=>8.349,
                     "rss_max_avg"=>8.017,
                     "rss_max_max"=>8.739,
                     "rss_max_min"=>3.454,
                     "rss_min"=>3.455,
                     "scale"=>0.12,
                     "scm_id_0.EB0"=>"master",
                     "scm_id_0.EH0"=>"73dc352f32e874fb9030c9f6ab64abb0b358c02b",
                     "scm_id_1.EB1"=>"master",
                     "scm_id_1.EH1"=>"af0259e3ced2bc528b38c58b9be3b5e73432b06e",
                     "scm_id_2.EB2"=>"master",
                     "scm_id_2.EH2"=>"ef8916fd275c8a01dc8485e137389d2f1d74b139",
                     "sum_cyc_sec"=>76365.0,
                     "timestamp"=>"2022-01-04T20:58:25"}]
                 ], d.events
  end


  def test_daap_caliper
    d = create_driver %(
      @type daap
      tag daap
      format json
    )

    d.run(default_tag: 'test') do
      d.feed(event_time,
             {"message" => "sap,problem=SAP_PERF_Shape_Charge_25_mat_spider_plot_refine,desc=caliper,jobid=5071396,cells=14515200 caliper60=\"256     purge                         0.039512      0.042982      0.041023  0.004453    60.281096  \" 1644957198000000000\n"})
      d.feed(event_time,
             {'message' => 'xrage,problem=Asteroid.input,desc=caliper-runtime-report,job_id=4963218,rj_tag=20220104001316 caliper_547=\"      MPI_Win_get_attr                              0.000006      0.000008      0.000007  0.000001 \" 1641408642000000000\n'})
      d.feed(event_time,
             {'message' => 'xrage,desc=caliper-runtime-report,host=sn-rfe2.lanl.gov,job_id=4918945,problem=Asteroid.input,rj_tag=20211215001316 caliper_182=\"            MPI_Win_get_attr                        0.001559      0.001581      0.001571  0.000118 \" 1639555447000000000\n'})
    end

    assert_equal [
                  ["daap",
                   1641997967,
                   {"allocated_mb"=>31.352367,
                     "avg_time"=>147.194426,
                     "caliper_name"=>"caliper2",
                     "desc"=>"caliper",
                     "host"=>"sn053.localdomain",
                     "jobid"=>"4982104",
                     "max_time"=>204.170328,
                     "metric"=>"sap_caliper_metrics",
                     "min_time"=>24.284198,
                     "path"=>"cycler",
                     "path_indent_len"=>0,
                     "path_with_indent"=>"cycler",
                     "problem"=>"SAP_PERF_Shape_Charge_spider_plot_symmetry",
                     "time_percentage"=>5.482492,
                     "timestamp"=>"2022-01-12T14:32:47"}],
                  ["daap",
                   1641408642,
                   {"allocated_mb"=>0.0,
                     "avg_time"=>7.0e-06,
                     "caliper_name"=>"caliper_547",
                     "desc"=>"caliper-runtime-report",
                     "job_id"=>"4963218",
                     "max_time"=>8.0e-06,
                     "metric"=>"xrage_caliper_metrics",
                     "min_time"=>6.0e-06,
                     "path"=>"MPI_Win_get_attr",
                     "path_indent_len"=>6,
                     "path_with_indent"=>"      MPI_Win_get_attr",
                     "problem"=>"Asteroid.input",
                     "rj_tag"=>"20220104001316",
                     "time_percentage"=>1.0e-06,
                     "timestamp"=>"2022-01-05T18:50:42"}],
                  ["daap",
                   1639555447,
                   {"allocated_mb"=>0.0,
                     "avg_time"=>0.001571,
                     "caliper_name"=>"caliper_182",
                     "desc"=>"caliper-runtime-report",
                     "host"=>"sn-rfe2.lanl.gov",
                     "job_id"=>"4918945",
                     "max_time"=>0.001581,
                     "metric"=>"xrage_caliper_metrics",
                     "min_time"=>0.001559,
                     "path"=>"MPI_Win_get_attr",
                     "path_indent_len"=>12,
                     "path_with_indent"=>"            MPI_Win_get_attr",
                     "problem"=>"Asteroid.input",
                     "rj_tag"=>"20211215001316",
                     "time_percentage"=>0.000118,
                     "timestamp"=>"2021-12-15T08:04:07"}]
                 ], d.events
  end

  def test_daap_lap
    d = create_driver %(
      @type daap
      tag daap
      format json
    )

    d.run(default_tag: 'laptest') do
      d.feed(event_time,
             {'message' => '{"metrics":[{"fields":{"VL15_dropped":0,"excessive_buffer_overrun_errors":0,"link_downed":0,"link_error_recovery":0,"local_link_integrity_errors":0,"multicast_rcv_packets":53336060,"multicast_xmit_packets":18,"port_rcv_constraint_errors":0,"port_rcv_data":47687440992044,"port_rcv_errors":0,"port_rcv_packets":148683790195,"port_rcv_remote_physical_errors":0,"port_rcv_switch_relay_errors":0,"port_xmit_constraint_errors":0,"port_xmit_data":47926512257828,"port_xmit_discards":0,"port_xmit_packets":147990216768,"port_xmit_wait":0,"symbol_error":0,"unicast_rcv_packets":0,"unicast_xmit_packets":0},"name":"infiniband","tags":{"device":"hfi1_0","host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood","port":"1"},"timestamp":1644971800},{"fields":{"active":1276289024,"available":129772367872,"available_percent":96.05579431021127,"buffered":0,"cached":2019389440,"commit_limit":132399009792,"committed_as":2438078464,"dirty":0,"free":129778335744,"high_free":0,"high_total":0,"huge_page_size":2097152,"huge_pages_free":0,"huge_pages_total":0,"inactive":1260740608,"low_free":0,"low_total":0,"mapped":87535616,"page_tables":6242304,"shared":955346944,"slab":532307968,"sreclaimable":119709696,"sunreclaim":412598272,"swap_cached":0,"swap_free":0,"swap_total":0,"total":135101030400,"used":3303305216,"used_percent":2.4450629326954414,"vmalloc_chunk":35113269358592,"vmalloc_total":35184372087808,"vmalloc_used":1202470912,"wired":0,"write_back":0,"write_back_tmp":0},"name":"mem","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood"},"timestamp":1644971792},{"fields":{"temp":12},"name":"temp","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood","sensor":"coretemp_core4_input"},"timestamp":1644971792},{"fields":{"temp":12},"name":"temp","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood","sensor":"coretemp_core3_input"},"timestamp":1644971792},{"fields":{"temp":13},"name":"temp","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood","sensor":"coretemp_core2_input"},"timestamp":1644971792},{"fields":{"temp":12},"name":"temp","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood","sensor":"coretemp_core27_input"},"timestamp":1644971792},{"fields":{"temp":14},"name":"temp","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood","sensor":"coretemp_core26_input"},"timestamp":1644971792},{"fields":{"temp":12},"name":"temp","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood","sensor":"coretemp_core25_input"},"timestamp":1644971792},{"fields":{"temp":10},"name":"temp","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood","sensor":"coretemp_core24_input"},"timestamp":1644971792},{"fields":{"temp":12},"name":"temp","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood","sensor":"coretemp_core19_input"},"timestamp":1644971792},{"fields":{"temp":11},"name":"temp","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood","sensor":"coretemp_core18_input"},"timestamp":1644971792},{"fields":{"temp":88},"name":"temp","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood","sensor":"coretemp_packageid1_max"},"timestamp":1644971792},{"fields":{"temp":19},"name":"temp","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood","sensor":"coretemp_packageid1_input"},"timestamp":1644971792},{"fields":{"temp":0},"name":"temp","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood","sensor":"coretemp_packageid1_critalarm"},"timestamp":1644971792},{"fields":{"temp":98},"name":"temp","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood","sensor":"coretemp_packageid1_crit"},"timestamp":1644971792},{"fields":{"temp":12},"name":"temp","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood","sensor":"coretemp_core17_input"},"timestamp":1644971792},{"fields":{"temp":12},"name":"temp","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood","sensor":"coretemp_core16_input"},"timestamp":1644971792},{"fields":{"temp":13},"name":"temp","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood","sensor":"coretemp_core11_input"},"timestamp":1644971792},{"fields":{"temp":13},"name":"temp","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood","sensor":"coretemp_core10_input"},"timestamp":1644971792},{"fields":{"temp":15},"name":"temp","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood","sensor":"coretemp_core9_input"},"timestamp":1644971792},{"fields":{"temp":13},"name":"temp","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood","sensor":"coretemp_core8_input"},"timestamp":1644971792},{"fields":{"temp":88},"name":"temp","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood","sensor":"coretemp_core4_max"},"timestamp":1644971792},{"fields":{"temp":16},"name":"temp","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood","sensor":"coretemp_core4_input"},"timestamp":1644971792},{"fields":{"temp":0},"name":"temp","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood","sensor":"coretemp_core4_critalarm"},"timestamp":1644971792},{"fields":{"temp":98},"name":"temp","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood","sensor":"coretemp_core4_crit"},"timestamp":1644971792},{"fields":{"temp":88},"name":"temp","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood","sensor":"coretemp_core3_max"},"timestamp":1644971792},{"fields":{"temp":15},"name":"temp","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood","sensor":"coretemp_core3_input"},"timestamp":1644971792},{"fields":{"temp":0},"name":"temp","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood","sensor":"coretemp_core3_critalarm"},"timestamp":1644971792},{"fields":{"temp":98},"name":"temp","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood","sensor":"coretemp_core3_crit"},"timestamp":1644971792},{"fields":{"temp":88},"name":"temp","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood","sensor":"coretemp_core2_max"},"timestamp":1644971792},{"fields":{"temp":15},"name":"temp","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood","sensor":"coretemp_core2_input"},"timestamp":1644971792},{"fields":{"temp":0},"name":"temp","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood","sensor":"coretemp_core2_critalarm"},"timestamp":1644971792},{"fields":{"temp":98},"name":"temp","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood","sensor":"coretemp_core2_crit"},"timestamp":1644971792},{"fields":{"temp":88},"name":"temp","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood","sensor":"coretemp_core1_max"},"timestamp":1644971792},{"fields":{"temp":15},"name":"temp","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood","sensor":"coretemp_core1_input"},"timestamp":1644971792},{"fields":{"temp":0},"name":"temp","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood","sensor":"coretemp_core1_critalarm"},"timestamp":1644971792},{"fields":{"temp":98},"name":"temp","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood","sensor":"coretemp_core1_crit"},"timestamp":1644971792},{"fields":{"temp":88},"name":"temp","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood","sensor":"coretemp_core0_max"},"timestamp":1644971792},{"fields":{"temp":14},"name":"temp","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood","sensor":"coretemp_core0_input"},"timestamp":1644971792},{"fields":{"temp":0},"name":"temp","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood","sensor":"coretemp_core0_critalarm"},"timestamp":1644971792},{"fields":{"temp":98},"name":"temp","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood","sensor":"coretemp_core0_crit"},"timestamp":1644971792},{"fields":{"temp":88},"name":"temp","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood","sensor":"coretemp_core27_max"},"timestamp":1644971792},{"fields":{"temp":13},"name":"temp","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood","sensor":"coretemp_core27_input"},"timestamp":1644971792},{"fields":{"temp":0},"name":"temp","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood","sensor":"coretemp_core27_critalarm"},"timestamp":1644971792},{"fields":{"temp":98},"name":"temp","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood","sensor":"coretemp_core27_crit"},"timestamp":1644971792},{"fields":{"temp":88},"name":"temp","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood","sensor":"coretemp_core26_max"},"timestamp":1644971792},{"fields":{"temp":13},"name":"temp","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood","sensor":"coretemp_core26_input"},"timestamp":1644971792},{"fields":{"temp":0},"name":"temp","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood","sensor":"coretemp_core26_critalarm"},"timestamp":1644971792},{"fields":{"temp":98},"name":"temp","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood","sensor":"coretemp_core26_crit"},"timestamp":1644971792},{"fields":{"temp":88},"name":"temp","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood","sensor":"coretemp_core25_max"},"timestamp":1644971792},{"fields":{"temp":15},"name":"temp","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood","sensor":"coretemp_core25_input"},"timestamp":1644971792},{"fields":{"temp":0},"name":"temp","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood","sensor":"coretemp_core25_critalarm"},"timestamp":1644971792},{"fields":{"temp":98},"name":"temp","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood","sensor":"coretemp_core25_crit"},"timestamp":1644971792},{"fields":{"temp":88},"name":"temp","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood","sensor":"coretemp_core24_max"},"timestamp":1644971792},{"fields":{"temp":14},"name":"temp","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood","sensor":"coretemp_core24_input"},"timestamp":1644971792},{"fields":{"temp":0},"name":"temp","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood","sensor":"coretemp_core24_critalarm"},"timestamp":1644971792},{"fields":{"temp":98},"name":"temp","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood","sensor":"coretemp_core24_crit"},"timestamp":1644971792},{"fields":{"temp":88},"name":"temp","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood","sensor":"coretemp_core20_max"},"timestamp":1644971792},{"fields":{"temp":14},"name":"temp","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood","sensor":"coretemp_core20_input"},"timestamp":1644971792},{"fields":{"temp":0},"name":"temp","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood","sensor":"coretemp_core20_critalarm"},"timestamp":1644971792},{"fields":{"temp":98},"name":"temp","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood","sensor":"coretemp_core20_crit"},"timestamp":1644971792},{"fields":{"temp":88},"name":"temp","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood","sensor":"coretemp_core19_max"},"timestamp":1644971792},{"fields":{"temp":13},"name":"temp","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood","sensor":"coretemp_core19_input"},"timestamp":1644971792},{"fields":{"temp":0},"name":"temp","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood","sensor":"coretemp_core19_critalarm"},"timestamp":1644971792},{"fields":{"temp":98},"name":"temp","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood","sensor":"coretemp_core19_crit"},"timestamp":1644971792},{"fields":{"temp":88},"name":"temp","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood","sensor":"coretemp_core18_max"},"timestamp":1644971792},{"fields":{"temp":14},"name":"temp","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood","sensor":"coretemp_core18_input"},"timestamp":1644971792},{"fields":{"temp":0},"name":"temp","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood","sensor":"coretemp_core18_critalarm"},"timestamp":1644971792},{"fields":{"temp":98},"name":"temp","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood","sensor":"coretemp_core18_crit"},"timestamp":1644971792},{"fields":{"temp":88},"name":"temp","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood","sensor":"coretemp_packageid0_max"},"timestamp":1644971792},{"fields":{"temp":23},"name":"temp","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood","sensor":"coretemp_packageid0_input"},"timestamp":1644971792},{"fields":{"temp":0},"name":"temp","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood","sensor":"coretemp_packageid0_critalarm"},"timestamp":1644971792},{"fields":{"temp":98},"name":"temp","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood","sensor":"coretemp_packageid0_crit"},"timestamp":1644971792},{"fields":{"temp":88},"name":"temp","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood","sensor":"coretemp_core17_max"},"timestamp":1644971792},{"fields":{"temp":15},"name":"temp","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood","sensor":"coretemp_core17_input"},"timestamp":1644971792},{"fields":{"temp":0},"name":"temp","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood","sensor":"coretemp_core17_critalarm"},"timestamp":1644971792},{"fields":{"temp":98},"name":"temp","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood","sensor":"coretemp_core17_crit"},"timestamp":1644971792},{"fields":{"temp":88},"name":"temp","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood","sensor":"coretemp_core16_max"},"timestamp":1644971792},{"fields":{"temp":14},"name":"temp","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood","sensor":"coretemp_core16_input"},"timestamp":1644971792},{"fields":{"temp":0},"name":"temp","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood","sensor":"coretemp_core16_critalarm"},"timestamp":1644971792},{"fields":{"temp":98},"name":"temp","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood","sensor":"coretemp_core16_crit"},"timestamp":1644971792},{"fields":{"temp":88},"name":"temp","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood","sensor":"coretemp_core11_max"},"timestamp":1644971792},{"fields":{"temp":16},"name":"temp","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood","sensor":"coretemp_core11_input"},"timestamp":1644971792},{"fields":{"temp":0},"name":"temp","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood","sensor":"coretemp_core11_critalarm"},"timestamp":1644971792},{"fields":{"temp":98},"name":"temp","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood","sensor":"coretemp_core11_crit"},"timestamp":1644971792},{"fields":{"temp":88},"name":"temp","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood","sensor":"coretemp_core10_max"},"timestamp":1644971792},{"fields":{"temp":15},"name":"temp","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood","sensor":"coretemp_core10_input"},"timestamp":1644971792},{"fields":{"temp":0},"name":"temp","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood","sensor":"coretemp_core10_critalarm"},"timestamp":1644971792},{"fields":{"temp":98},"name":"temp","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood","sensor":"coretemp_core10_crit"},"timestamp":1644971792},{"fields":{"temp":88},"name":"temp","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood","sensor":"coretemp_core9_max"},"timestamp":1644971792},{"fields":{"temp":16},"name":"temp","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood","sensor":"coretemp_core9_input"},"timestamp":1644971792},{"fields":{"temp":0},"name":"temp","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood","sensor":"coretemp_core9_critalarm"},"timestamp":1644971792},{"fields":{"temp":98},"name":"temp","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood","sensor":"coretemp_core9_crit"},"timestamp":1644971792},{"fields":{"temp":88},"name":"temp","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood","sensor":"coretemp_core8_max"},"timestamp":1644971792},{"fields":{"temp":16},"name":"temp","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood","sensor":"coretemp_core8_input"},"timestamp":1644971792},{"fields":{"temp":0},"name":"temp","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood","sensor":"coretemp_core8_critalarm"},"timestamp":1644971792},{"fields":{"temp":98},"name":"temp","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood","sensor":"coretemp_core8_crit"},"timestamp":1644971792},{"fields":{"temp":120},"name":"temp","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood","sensor":"i350bb_loc1_max"},"timestamp":1644971792},{"fields":{"temp":37},"name":"temp","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood","sensor":"i350bb_loc1_input"},"timestamp":1644971792},{"fields":{"temp":110},"name":"temp","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood","sensor":"i350bb_loc1_crit"},"timestamp":1644971792},{"fields":{"icmp_inaddrmaskreps":0,"icmp_inaddrmasks":0,"icmp_incsumerrors":0,"icmp_indestunreachs":0,"icmp_inechoreps":0,"icmp_inechos":0,"icmp_inerrors":0,"icmp_inmsgs":0,"icmp_inparmprobs":0,"icmp_inredirects":0,"icmp_insrcquenchs":0,"icmp_intimeexcds":0,"icmp_intimestampreps":0,"icmp_intimestamps":0,"icmp_outaddrmaskreps":0,"icmp_outaddrmasks":0,"icmp_outdestunreachs":0,"icmp_outechoreps":0,"icmp_outechos":0,"icmp_outerrors":0,"icmp_outmsgs":0,"icmp_outparmprobs":0,"icmp_outredirects":0,"icmp_outsrcquenchs":0,"icmp_outtimeexcds":0,"icmp_outtimestampreps":0,"icmp_outtimestamps":0,"ip_defaultttl":64,"ip_forwarding":2,"ip_forwdatagrams":0,"ip_fragcreates":0,"ip_fragfails":0,"ip_fragoks":0,"ip_inaddrerrors":0,"ip_indelivers":8127728,"ip_indiscards":0,"ip_inhdrerrors":0,"ip_inreceives":8127728,"ip_inunknownprotos":0,"ip_outdiscards":0,"ip_outnoroutes":0,"ip_outrequests":4496098,"ip_reasmfails":0,"ip_reasmoks":0,"ip_reasmreqds":0,"ip_reasmtimeout":0,"tcp_activeopens":27853,"tcp_attemptfails":192,"tcp_currestab":6,"tcp_estabresets":5101,"tcp_incsumerrors":0,"tcp_inerrs":13,"tcp_insegs":4478703,"tcp_maxconn":-1,"tcp_outrsts":86,"tcp_outsegs":4512121,"tcp_passiveopens":21613,"tcp_retranssegs":759,"tcp_rtoalgorithm":1,"tcp_rtomax":120000,"tcp_rtomin":200,"udp_incsumerrors":0,"udp_indatagrams":1313,"udp_inerrors":0,"udp_noports":0,"udp_outdatagrams":1313,"udp_rcvbuferrors":0,"udp_sndbuferrors":0,"udplite_incsumerrors":0,"udplite_indatagrams":0,"udplite_inerrors":0,"udplite_noports":0,"udplite_outdatagrams":0,"udplite_rcvbuferrors":0,"udplite_sndbuferrors":0},"name":"net","tags":{"host":"gr0761.localdomain","interface":"all","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood"},"timestamp":1644971792},{"fields":{"bytes_recv":4241977797,"bytes_sent":74175749,"drop_in":0,"drop_out":0,"err_in":0,"err_out":0,"packets_recv":53722789,"packets_sent":346145},"name":"net","tags":{"host":"gr0761.localdomain","interface":"ib0","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood"},"timestamp":1644971792},{"fields":{"bytes_recv":1120068806,"bytes_sent":617646951,"drop_in":0,"drop_out":0,"err_in":0,"err_out":0,"packets_recv":5304473,"packets_sent":3494120},"name":"net","tags":{"host":"gr0761.localdomain","interface":"enp6s0f0","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood"},"timestamp":1644971792},{"fields":{"uptime_format":"13 days,  4:39"},"name":"system","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood"},"timestamp":1644971792},{"fields":{"uptime":1139954},"name":"system","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood"},"timestamp":1644971792},{"fields":{"load1":1.45,"load15":5.78,"load5":9.22,"n_cpus":36,"n_users":0},"name":"system","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood"},"timestamp":1644971792},{"fields":{"blocked":0,"dead":0,"idle":0,"paging":0,"running":0,"sleeping":571,"stopped":0,"total":571,"total_threads":672,"unknown":0,"zombies":0},"name":"processes","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood"},"timestamp":1644971791},{"fields":{"boot_time":1643831837,"context_switches":10654182562,"entropy_avail":3754,"interrupts":50432334993,"processes_forked":1337490},"name":"kernel","tags":{"host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood"},"timestamp":1644971791},{"fields":{"VL15_dropped":0,"excessive_buffer_overrun_errors":0,"link_downed":0,"link_error_recovery":0,"local_link_integrity_errors":0,"multicast_rcv_packets":53335403,"multicast_xmit_packets":18,"port_rcv_constraint_errors":0,"port_rcv_data":47687440980227,"port_rcv_errors":0,"port_rcv_packets":148683789525,"port_rcv_remote_physical_errors":0,"port_rcv_switch_relay_errors":0,"port_xmit_constraint_errors":0,"port_xmit_data":47926512256849,"port_xmit_discards":0,"port_xmit_packets":147990216755,"port_xmit_wait":0,"symbol_error":0,"unicast_rcv_packets":0,"unicast_xmit_packets":0},"name":"infiniband","tags":{"device":"hfi1_0","host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood","port":"1"},"timestamp":1644971791},{"fields":{"usage_guest":0,"usage_guest_nice":0,"usage_idle":99.9745460721792,"usage_iowait":0,"usage_irq":0,"usage_nice":0,"usage_softirq":0,"usage_steal":0,"usage_system":0.016969285592503856,"usage_user":0.008484643133730587},"name":"cpu","tags":{"cpu":"cpu-total","host":"gr0761.localdomain","jobinfo":"jobid=18022696 name=pav_hpcg.base.16,hpcg.daap.16,hpcg.stub.16 user=agood"},"timestamp":1644971790}]}'})
    end

    assert_equal [
     
                 ], d.events
  end
end
