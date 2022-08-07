# DAAP: Data Analytics Application Profiling
## A near real-time logging API for parallel application codes

The DAAP logging API/library provides a consistent interface to parallel user codes to enable output to be sent from compute nodes on a cluster, to an on-node collector (telegraf in LANL's implementation) using SSL, through the message broker assigned to the cluster running the job, and on to a data analytics system, where output messages can be analyzed (in near-real time as a job is still running, if desired). The analytics system can employ Grafana or other graphing tools, or the data can be analyzed over longer periods using tools such as Pyspark to detect anomalies or performance shifts and correlate these shifts to system or application changes.

A variety of messages can be sent from an application, the simplest of these being a ***heartbeat*** indicating a task or node assigned to a job is still making progress. In conjunction with application message data, in a typical setup, system data (such as CPU and memory usage) are also collected and sent, allowing an analyst to identify correlations between application behavior and collected system data.

The general idea with DAAP is that it provides a way to report on application progress, other application metrics, and system metrics without involving MPI, which is far more complicated software than DAAP. When configured to send to an analytics system, DAAP gives multiple communities (support staff, application teams, operations) visibility into an application's behavior and progress, which means DAAP qualifies as DevOps software or a 'silo-breaker'. Prior to DAAP, only application teams would normally have visibility into what their application was doing as it ran, and the data might not be stored long-term in a database, or in a consistent fashion. Other tools exist to do simple *application profiling* such as the LLNL-developed [Caliper](https://software.llnl.gov/Caliper/), but typically those tools were not designed for near-real time instrumentation, they were not developed with the intent of shipping data off-cluster to a centralized data store, and they are more complex and not as lightweight, being oriented toward assisting application developers understand where their code is spending the most time, rather than toward tracking normal application progress in concert with system (node) behavior.

If a management network is available on your cluster (such as a secondary 10GbE network), this can be used by DAAP/Telegraf instead of sending DAAP data through the high speed interconnect.

Because the data is stored long-term in a single location, analytics-type questions can be answered that previously could not, such as:

* How did the performance of this application for equivalent runs change over time?
* Can changes in application performance be correlated with system upgrades or changes?
* If an application run failed unexpectedly, were there unusual system metrics on any nodes leading up to the failure that would allow us to create a predictive capability in the future?

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes.

### Prerequisites

Requires CMake, version >= 3.16.2: 

```
$ ccmake --version
cmake version 3.16.2
CMake suite maintained and supported by Kitware (kitware.com/cmake).
```

Also requires a working version of the transport layer selected during configuration in order to work properly. 

### Installing

We recommend using out-of-source builds to keep the src/ directory clean and the rebuilding process simple. If the build directory doesn't already exist, first create it, then run ccmake and make:

```
mkdir build
cd build
ccmake .. 
make
```

On first launch, ccmake will display an 'EMPTY CACHE' message. Type 'c' to configure, which will then launch a 
screen that shows default configuration options and provides the ability to change these before running the 
actual configure step. 

Once you have selected the options you want, type 'c' to configure, then 'g' to generate the Makefiles and exit.

To see detailed output from make:

```
make VERBOSE=1
```

To install to the directory you chose in the cmake configuration:

```
make install
```

To start fresh after building:
```
rm -rf build/*
cd build
ccmake ..
etc.
```

## Deployment

Deploying in a non-trivial configuration depends on the ability to connect to a message broker from the compute nodes of the cluster where you are running a DAAP-profiled parallel application. In the LANL setup, we use telegraf daemons as on-node collectors and aggregators, and the aggregators send data to a RabbitMQ broker, which forwards the data to an analytics system and a Splunk instance. The scripts to use [telegraf](https://www.influxdata.com/time-series-platform/telegraf/) (which is itself open source) are provided with this software, along with the needed telegraf plugin, which will have to be modified for the specifics of your installation should you choose to use it.

However, an explanation of how to set up your message broker and confirm DAAP messages are being routed correctly is beyond the scope of this document. Please consult your message broker's documentation.

## Intrumenting using DAAP

DAAP is written in C, and Fortran interfaces are also provided. In this example, we assume that your application code is C++.

Let's first assume that you would like to insert a simple heartbeat call, that you want to provide the capability to build your application with or without DAAP, and that you are using a simple Makefile build system.

Let's also assume that you are using a complete installation, with telegraf daemons and a message broker to collect and forward your DAAP messages.

In this case, you can wrap DAAP-related calls and code in `#ifdef`s that check for the environment variable `DAAP_ROOT`.

So the necessary include at the top of your code would look something like this, depending on where you installed DAAP:

```
#ifdef DAAP_ROOT
#include ~/include/daap_log.h
#endif
```

Somewhere near the start of your code, you should call `daapInit()` from all tasks that will be making DAAP calls. For instance:

```
#ifdef DAAP_ROOT
    // Initialize DAAP library
    int ret_val;
    if ( (ret_val = daapInit("daap_pennant", LOG_NOTICE, DAAP_AGG_OFF, TCP)) != 0 ) {
        return ret_val;
    }
#endif
```

After calling `daapInit()`, but also somewhere near the beginning of your job, you should call `daapJobStart()`, only from one rank of your parallel code. This call is a marker to indicate in the analytics system when the job has actually begun:

```
if (mype == 0) {
    cout << "********************" << endl;
    cout << "Running PENNANT v0.9" << endl;
    cout << "********************" << endl;
    cout << endl;
#ifdef DAAP_ROOT
    daapLogJobStart();
#endif
}
```
Now, assuming your code is a typical parallel physics application that has timesteps, you will call `daapHeartbeat()` from all tasks after every timestep, e.g.:

```
// main event loop
while (cycle < cstop && time < tstop) {
    cycle += 1;
    // get timestep
    calcGlobalDt();
    // begin hydro cycle
    hydro->doCycle(dt);
    time += dt;
#ifdef DAAP_ROOT
    // heartbeat from all tasks
    daapLogHeartbeat();
#endif
    ...
    ...
}
```

Somewhere near the end of your code, you should call `daapJobEnd()`, only from one rank of your parallel code. This call is a marker to indicate in the analytics system when the job has completed (note that this call must precede `daapFinalize()`):

```
if (mype == 0) {
    cout << "********************" << endl;
    cout << "PENNANT run complete" << endl;
    cout << "********************" << endl;
    cout << endl;
#ifdef DAAP_ROOT
    daapLogJobEnd();
#endif
}
```


Somewhere near the end of your code and after calling `daapJobEnd()` from rank 0, you must call `daapFinalize()`, but from all DAAP participants. This call cleans up data structures that DAAP used:

```
#ifdef DAAP_ROOT
    // Finalize DAAP library
    daapFinalize();
#endif
```

And that's all the instrumenting you would need to do for a simple heartbeat.

Note that there are more calls available than just the heartbeat. See the `daap_log.h` include file for details.

## Compiling and linking with DAAP

Continuing our above example that assumes a simple Makefile structure, and assuming that you installed DAAP to `~/daap-log`, you might add something like the following to your Makefile:

```
# Comment out below def to disable DAAP (or rely on it being in env var, and remove completely)
DAAP_ROOT ?= $(HOME)/daap-log
ifdef DAAP_ROOT
CXXINCLUDES := -I$(DAAP_ROOT)/include
LIBDIR := $(DAAP_ROOT)/lib
endif
.
.
.
ifdef DAAP_ROOT
LDFLAGS += $(CXXFLAGS_OPENMP) -Wl,-rpath $(LIBDIR) -L $(LIBDIR) -ldaap_log
else
LDFLAGS += $(CXXFLAGS_OPENMP) -Wl,-rpath $(LIBDIR) -L $(LIBDIR)
endif
```
Commenting out the `DAAP_ROOT ?=` line will provide the ability to build without DAAP. Alternatively, you can rely on the environment variable being defined outside the Makefile if you are using DAAP, and eliminate that line entirely.

The above changes then affect your main build rules, which look like this:
```
# begin rules
all : $(BINARY)

$(BINARY) : $(OBJS)
	@echo linking $@
	$(maketargetdir)
	$(LD) -o $@ $^ $(LDFLAGS)

$(BUILDDIR)/%.o : $(SRCDIR)/%.cc
	@echo compiling $<
	$(maketargetdir)
	$(CXX) $(CXXFLAGS) $(CXXINCLUDES) -c -o $@ $<
.
.
.
```
Making using these modifications, with an existing value for DAAP_ROOT would then look like this:
```
cps@ubuntudesktop:/opt/cps/tivan-acceptance-testing/pennant$ echo $DAAP_ROOT
/opt/cps/tivan-acceptance-testing/daap-log
cps@ubuntudesktop:/opt/cps/tivan-acceptance-testing/pennant$ make
.
.
.
compiling src/main.cc
mpicxx -O3 -DUSE_MPI -fopenmp -I/opt/cps/tivan-acceptance-testing/daap-log/include -c -o build/main.o src/main.cc
.
.
.
compiling src/Driver.cc
mpicxx -O3 -DUSE_MPI -fopenmp -I/opt/cps/tivan-acceptance-testing/daap-log/include -c -o build/Driver.o src/Driver.cc
.
.
.
mpicxx -o build/pennant build/ExportGold.o build/Parallel.o build/WriteXY.o build/QCS.o build/TTS.o build/main.o build/Mesh.o build/InputFile.o build/HydroBC.o build/GenMesh.o build/Driver.o build/Hydro.o build/PolyGas.o -L/home/cps/lib -fopenmp -Wl,-rpath /opt/cps/tivan-acceptance-testing/daap-log/lib -L /opt/cps/tivan-acceptance-testing/daap-log/lib -ldaap_log
cps@ubuntudesktop:/opt/cps/tivan-acceptance-testing/pennant$
```

## Running instrumented code

If you are using telegraf, and if you have a message broker set up to collect messages from your telegraf aggregator nodes, we recommend that you use the provided scripts as a starting point for launching telegraf and running a DAAP-instrumented application.

## Included example

A very basic example demonstrating the logging capability (without connecting to a message broker) is included. BUILD_TEST must be enabled in
the initial configure options for it to be built.

After running make install:

```
cd test
./test_logger
```

You can then see what output was written by examining the contents of syslog. The exact location
of syslog is system-dependent; on many Linux systems it is in /var/syslog.

## Original Authors

* **Charles Shereda**
* **Hugh Greenberg**
* **Adam Good**

## License

See LICENSE file in the root directory for details.



