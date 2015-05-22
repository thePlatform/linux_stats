# pl_procstat

## Overview
pl_procstat is a very lightweight, high-performance report generator for Linux
performance metrics.  It was originally developed to feed regular performance
metrics into Graphite and Sensu.  However, it is a general-purpose tool that
may be used for a variety of purposes.

Two types of reporting are supported

# OS-level statistics
including
  * CPU use
  * Network use
  * Disk use
  * Open Files
  * Memory Use
  * Many more...

# process-level statistics
including
  * memory use
  * threads
  * cpu use
  * process count


Goals:
   * be as fast and lightweight as possible
   * gather all OS-level stats in 10 ms or less
   * no shelling out to existing system tools (sar, vmstat, etc.) since we
     don't want the expense of creating a new process.
   * provide useful statistics in the form of a sensible hash that clients
     can inspect as desired.

Other ruby tools exist for getting CPU os, etc.  Unfortunately they all
seem to rely on shelling out to native system tools as the basis for
retrieving their underlying os.

By going directly to /proc, we have a higher level of control of the type
of data we make available.

## Compatibility
pl_procstat was written specifically targeting Centos 5 & 6.  It's likely to work on other
platforms as well, but those configurations are untested.

Want something? Send us a pull request.

# Note
Mac OS X is not supported.  pl_procstat gets its data by inspecting the
/proc filesystem, which does not exist on macs.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'pl_os_stats'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install pl_os_stats

## Usage

# command line
Example command line tools are provided to examine the output of
the library

 * os_stat
 * pid_stat

Usage:

os_stat's usage is similar to sar
 os_stat [delay_seconds] [iterations]

pit_stat's usage is similar to sar, with the addition of a
regex and friendly_name option
  pid_stat [delay_seconds] [iterations] [regex] [friendly_name]


# client library
An example client for OS-level stats might look like this:
```ruby
#!/usr/bin/env ruby

require 'pl_procstat'
require 'json'

DEFAULT_DELAY_SEC = 0.5
DEFAULT_ITERATIONS = 1
delay_sec = ARGV[0] ? ARGV[0].to_i : DEFAULT_DELAY_SEC
iterations = ARGV[1] ? ARGV[1].to_i : DEFAULT_ITERATIONS
iterations.times do
  sleep(delay_sec)
  report = Procstat::OS.report
  total_time += elapsed_time
  puts JSON.pretty_generate report
end
```
The first call to Procstat::OS.report measures metrics cumulative
from the time the procstat library was loaded. Successive calls to
Procstat::OS.report measure metrics from the time of the previous
call to the current time.

example output:
```
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
    "/dev": {
      "total_kb": 950268,
      "available_kb": 950080,
      "used_pct": 0.019783892544000814
    },
    "/dev/pts": {
      "total_kb": 0,
      "available_kb": 0
    },
    "/dev/shm": {
      "total_kb": 961104,
      "available_kb": 961104,
      "used_pct": 0.0
    },
    "/app": {
      "total_kb": 5225040,
      "available_kb": 4818048,
      "used_pct": 7.789260943456888
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
    "/var": {
      "total_kb": 5225040,
      "available_kb": 4501608,
      "used_pct": 13.845482522621833
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
      "percent_active": 0.0
    },
    "sda": {
      "reads_persec": 13.030159716808111,
      "writes_persec": 0.0,
      "bytes_read_persec": 100071.6266250863,
      "bytes_written_persec": 0.0,
      "percent_active": 41.69651109378596
    },
    "sdc": {
      "reads_persec": 0.0,
      "writes_persec": 0.0,
      "bytes_read_persec": 0.0,
      "bytes_written_persec": 0.0,
      "percent_active": 0.0
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
```

An example client for process-level stats might look like this:
```ruby
#!/usr/bin/env ruby

require 'pl_procstat'
require 'json'

DEFAULT_DELAY_SEC = 2
DEFAULT_ITERATIONS = 3
PROCESS_FRIENDLY_NAME = 'gnome terminal'
PROCESS_REGEX = 'gnome-term'
delay_sec = ARGV[0] ? ARGV[0].to_i : DEFAULT_DELAY_SEC
iterations = ARGV[1] ? ARGV[1].to_i : DEFAULT_ITERATIONS
total_time = 0.0
iterations.times do
  sleep(delay_sec)
  report = Procstat::PID.report(PROCESS_FRIENDLY_NAME, PROCESS_REGEX)
  puts JSON.pretty_generate report
end
```

example output:
```
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
```
