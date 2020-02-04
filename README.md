# daap_log: Data Analytics Application Profiling - a logging API for parallel application codes

The Daap logging API provides a consistent interface to user codes to enable output to be sent from compute nodes, through the message broker assigned to the cluster running the job, and on to a Data Analytics cluster (Tivan at LANL on the Turquoise network), where output messages can be analyzed, as a job is still running if necessary.

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes.

### Prerequisites

Requires CMake, version >= 3.16.3: 

```
$ ccmake --version
cmake version 3.16.3

CMake suite maintained and supported by Kitware (kitware.com/cmake).
```

Also requires a working version of the transport layer selected during configuration in order to work properly. 

The default transport is syslog. MacOS has broken syslog in later releases; os_log is the MacOS substitute for syslog but does not have the exact same functionality. If you encounter problems with the Mac version, feel free to let us know, but that development is a low priority for us.

### Installing

We recommend using out-of-source builds to keep the src/ directory clean and the rebuilding process simple:

```
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

To install:

```
make install
```

To start afresh after building:
```
rm -rf build/*
cd build
ccmake ..
etc.
```

## Running the example

A simple example demonstrating the logging capability is included. BUILD_TEST must be enabled in
the initial configure options for it to be built.

After running make install:

```
cd test
./test_logger
```

You can then see what output was written by examining the contents of syslog. The exact location
of syslog is system-dependent; on many Linux systems it is in /var/syslog.

## Deployment

Add additional notes about how to deploy this on a live system

## Built With

* [CMake](http://www.cmake.org/)

## Contributing

Please read [CONTRIBUTING.md](https://github.com/daap_log/xxx) for details on our code of conduct, and the process for submitting pull requests to us.

## Versioning

We use [SemVer](http://semver.org/) for versioning. For the versions available, see the [tags on this repository](https://github.com/your/project/tags). 

## Authors

* **Charles Shereda** * - (cpshereda@lanl.gov)
* **Hugh Greenberg**  * - (hgh@lanl.gov)

See also the list of [contributors](https://github.com/daap_log/contributors) who participated in this project.

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details

## Acknowledgments

* Hat tip to anyone whose code was used
* Inspiration
* etc



