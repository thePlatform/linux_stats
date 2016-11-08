<a href="http://tpteamcity.corp.theplatform.com/viewType.html?buildTypeId=DevOps_Ruby_LinuxStats">
<img src="http://tpteamcity.corp.theplatform.com/app/rest/builds/buildType:(id:DevOps_Ruby_LinuxStats)/statusIcon"/>
</a>

# Linux Stats

## Overview
linux_stats is a lightweight, high-performance library for reporting on
Linux performance metrics.  It was originally developed to feed data
into Graphite and Sensu at regular intervals.  But since it is
a general-purpose tool, it may be used for a variety of purposes.

Other ruby tools exist for getting similar OS data.  Each one
we reviewed collects its data by shelling out to native system
tools.  This approach has two drawbacks:

 * There is a fairly significant performance penalty incurred
by spawning a new process
 * Using external tools limits the flexibility on which metrics are
collected to whatever is provided by the underlying tool.

By staying in-process and going directly to the /proc filesystem,
linux_stats avoids the performance penalty of shelling out,
and is able to draw upon the rich set of data provided by the Linux
kernel.


## Goals:

 * Be as fast and lightweight as possible
 * Gather all OS-level stats in 10 ms or less
 * Provide useful statistics in the form of a sensibly-structured hash that 
     clients can inspect as desired.

## Report types

linux_stats provides two types of reporting: OS-level, and per-process.


### OS-level statistics
OS level metrics include a broad collection of data points in different
categories.

 * CPU use
 * Network use
 * Disk use
 * Open Files
 * Memory Use
 * Many more...

### Process-level statistics
linux_stats also supports gathering data on individual or groups of
Linux process.  Metrics include information on:

 * Memory use
 * Thread counts
 * CPU use
 * Process counts


## Compatibility
linux_stats was written specifically targeting Centos 5 & 6.  It's likely
to work on other platforms as well, but those configurations are untested.

## Docker Support
We've added convention-based support for linux_stats to collect host information while running 
within a Docker container.  This is accomplished by mounting the host's /proc and /sys to 
/hostproc and /hostsys within the container, as well as mounting the host's root filesystem ('/') to 
/hostfs within the container.

This means that your Docker run command should include the following:
    
    docker run your-container-name:container-version \ 
        --volume /:/hostfs:ro \
        --volume /proc:/hostproc:ro \
        --volume /sys:/hostsys:ro \
        other-flags-and-settings

### Note
Mac OS X is not supported.  linux_stats gets its data by inspecting the
/proc filesystem, which does not exist on macs.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'linux_stats'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install linux_stats

## Usage

### Command line usage
Example command line tools are included in the linux_stats gem.  These
tools show the types of metrics it's possible to collect with the library.
These tools are:

 * os_stats
 * process_stats

Usage:

os_stat's usage is similar to sar, with all arguments being optional.

```
 os_stats [delay_seconds] [iterations]
```

process_stats' usage is similar to sar, with the addition of a regex and
friendly_name option.  As with os_stats, all arguments are optional.

```
  process_stats [delay_seconds] [iterations] [regex] [friendly_name]
```

### Client library usage
An example client for OS-level stats might look like this:

    #!/usr/bin/env ruby

    require 'linux_stats'
    require 'json'

    reporter = LinuxStats::OS::Reporter.new
    DELAY_SEC = 1.5
    ITERATIONS = 3
    ITERATIONS.times do
      sleep(DELAY_SEC)
      report = reporter.report
      puts JSON.pretty_generate report
    end

The first call to LinuxStats::OS.report measures metrics cumulative
from the time the LinuxStats library was loaded. Successive calls to
LinuxStats::OS.report measure metrics from the time of the previous
call to the current time.

example output:

    {
      "memory": {
        "mem_total_kb": 1922208,
        "mem_free_kb": 580464,
        "page_cache_kb": 690612,
        "swap_total_kb": 4194268,
        "swap_free_kb": 4194268,
        "mem_used_pct": 69.80222743844578,
        "swap_used_pct": 0.0,
        "pagein_kb_persec": 97.03810401052468,
        "pageout_kb_persec": 0.0,
        "swapin_kb_persec": 0.0,
        "swapout_kb_persec": 0.0
      },
      "partition_use": {
        "/": {
          "total_kb": 7998920,
          "available_kb": 5398564,
          "used_pct": 32.50883869322359
        },
        "/dev/shm": {
          "total_kb": 961104,
          "available_kb": 961104,
          "used_pct": 0.0
        },
        "/boot": {
          "total_kb": 378252,
          "available_kb": 213912,
          "used_pct": 43.447225659084424
        },
        "/home": {
          "total_kb": 1032088,
          "available_kb": 893912,
          "used_pct": 13.388005673934778
        },
        "/tmp": {
          "total_kb": 1032088,
          "available_kb": 938208,
          "used_pct": 9.09612358636085
        },
        "/var/log": {
          "total_kb": 20158332,
          "available_kb": 18351672,
          "used_pct": 8.962348670514997
        }
      },
      "load_avg": {
        "one": 0.2,
        "five": 0.16,
        "fifteen": 0.16
      },
      "file_descriptor": {
        "used": 928,
        "max": 188192,
        "used_pct": 0.4931134160856997
      },
      "net": {
        "eth0": {
          "tx_bytes_persec": 2771.7967708009137,
          "rx_bytes_persec": 7111.158057658668,
          "errors_rx_persec": 0.0,
          "errors_tx_persec": 0.0
        },
        "tcp_open_conn": 13,
        "tcp_timewait_conn": 6
      },
      "disk_io": {
        "sdb": {
          "reads_persec": 0.0,
          "writes_persec": 0.0,
          "bytes_read_persec": 0.0,
          "bytes_written_persec": 0.0,
          "avg_queue_size": 0.0,
          "avg_request_bytes": 0,
          "percent_active": 0.0
        },
        "sda": {
          "reads_persec": 13.030159716808111,
          "writes_persec": 0.0,
          "bytes_read_persec": 100071.6266250863,
          "bytes_written_persec": 0.0,
          "avg_queue_size": 1.3047762237281717,
          "avg_request_bytes": 7059,
          "percent_active": 41.69651109378596
        }
      },
      "cpu": {
        "all": {
          "idle_pct": 85.15625,
          "iowait_pct": 5.46875,
          "irq_pct": 0.0,
          "nice_pct": 0.0,
          "softirq_pct": 0.0,
          "steal_pct": 0.0,
          "system_pct": 3.125,
          "used_pct": 14.84375,
          "user_pct": 6.25
        },
        "cpu0": {
          "idle_pct": 77.77777777777777,
          "iowait_pct": 9.523809523809524,
          "irq_pct": 0.0,
          "nice_pct": 0.0,
          "softirq_pct": 0.0,
          "steal_pct": 0.0,
          "system_pct": 3.1746031746031744,
          "used_pct": 22.22222222222223,
          "user_pct": 9.523809523809524
        },
        "cpu1": {
          "idle_pct": 96.82539682539682,
          "iowait_pct": 0.0,
          "irq_pct": 0.0,
          "nice_pct": 0.0,
          "softirq_pct": 0.0,
          "steal_pct": 0.0,
          "system_pct": 1.5873015873015872,
          "used_pct": 3.1746031746031775,
          "user_pct": 1.5873015873015872
        }
      },
      "os": {
        "interrupts_persec": 481.86633467677194,
        "ctxt_switches_persec": 401.8168784275362,
        "procs_running": 1,
        "procs_blocked": 0
      }
    }

An example client for process-level stats might look like this:

    #!/usr/bin/env ruby

    require 'linux_stats'
    require 'json'

    reporter = LinuxStats::Process::Reporter.new
    delay_sec = 2
    iterations = 3
    friendly_name = 'gnome terminal'
    proc_regex = 'gnome-term'
    iterations.times do
      sleep(delay_sec)
      report = reporter.report(friendly_name, proc_regex)
      puts JSON.pretty_generate report
    end

example output:

    {
      "gnome terminal": {
        "process_count": 3,
        "age_seconds": 381.8199999332428,
        "threads": 3,
        "mem": {
          "resident_set_bytes": 5550080,
          "virtual_mem_bytes": 332681216
        },
        "cpu_pct": 0.0
      }
    }

## Contributing
Got an idea for a new feature or metric?  Send us a pull request on the 'develop'
branch!

## License
LinuxStats is provided under the MIT License.
