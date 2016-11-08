
# The MIT License (MIT)
#
# Copyright (c) 2015-16 Comcast Technology Solutions
#
#     Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require 'linux_stats'

include LinuxStats::OS

CONTAINER_MOUNT_DATA = '
rootfs / rootfs rw 0 0
/dev/mapper/docker-253:4-40803-7fab58c8f0098a1976376c5271ed6540d2edeb636d831db1e6bbe4bfcc266717 / ext4 rw,relatime,barrier=1,stripe=16,data=ordered,discard 0 0
proc /proc proc rw,nosuid,nodev,noexec,relatime 0 0
tmpfs /dev tmpfs rw,nosuid,mode=755 0 0
devpts /dev/pts devpts rw,nosuid,noexec,relatime,gid=5,mode=620,ptmxmode=666 0 0
shm /dev/shm tmpfs rw,nosuid,nodev,noexec,relatime,size=65536k 0 0
mqueue /dev/mqueue mqueue rw,nosuid,nodev,noexec,relatime 0 0
sysfs /sys sysfs rw,nosuid,nodev,noexec,relatime 0 0
/dev/mapper/sysdisk-rootvol /etc/sensu ext3 rw,relatime,errors=continue,user_xattr,acl,barrier=1,data=ordered 0 0
/dev/mapper/sysdisk-rootvol /hostfs ext3 ro,relatime,errors=continue,user_xattr,acl,barrier=1,data=ordered 0 0
devtmpfs /hostfs/dev devtmpfs rw,relatime,size=1948620k,nr_inodes=487155,mode=755 0 0
devpts /hostfs/dev/pts devpts rw,relatime,gid=5,mode=620,ptmxmode=000 0 0
tmpfs /hostfs/dev/shm tmpfs rw,relatime 0 0
proc /hostfs/proc proc rw,relatime 0 0
/proc/bus/usb /hostfs/proc/bus/usb usbfs rw,relatime 0 0
none /hostfs/proc/sys/fs/binfmt_misc binfmt_misc rw,relatime 0 0
sysfs /hostfs/sys sysfs rw,relatime 0 0
/dev/mapper/sysdisk-appvol /hostfs/app ext3 rw,relatime,errors=continue,user_xattr,acl,barrier=1,data=ordered 0 0
/dev/sda1 /hostfs/boot ext3 rw,relatime,errors=continue,user_xattr,acl,barrier=1,data=ordered 0 0
/dev/mapper/sysdisk-homevol /hostfs/home ext3 rw,relatime,errors=continue,user_xattr,acl,barrier=1,data=ordered 0 0
/dev/mapper/sysdisk-tmpvol /hostfs/tmp ext3 rw,relatime,errors=continue,user_xattr,acl,barrier=1,data=ordered 0 0
/dev/mapper/sysdisk-varvol /hostfs/var ext3 rw,relatime,errors=continue,user_xattr,acl,barrier=1,data=ordered 0 0
/dev/mapper/logdisk-logvol /hostfs/var/log ext3 rw,relatime,errors=continue,user_xattr,acl,barrier=1,data=ordered 0 0
/dev/mapper/sysdisk-varvol /hostfs/var/lib/docker/devicemapper ext3 rw,relatime,errors=continue,user_xattr,acl,barrier=1,data=ordered 0 0
/dev/mapper/docker-253:4-40803-7fab58c8f0098a1976376c5271ed6540d2edeb636d831db1e6bbe4bfcc266717 /hostfs/var/lib/docker/devicemapper/mnt/7fab58c8f0098a1976376c5271ed6540d2edeb636d831db1e6bbe4bfcc266717 ext4 rw,relatime,barrier=1,stripe=16,data=ordered,discard 0 0
proc /hostfs/var/lib/docker/devicemapper/mnt/7fab58c8f0098a1976376c5271ed6540d2edeb636d831db1e6bbe4bfcc266717/rootfs/proc proc rw,nosuid,nodev,noexec,relatime 0 0
tmpfs /hostfs/var/lib/docker/devicemapper/mnt/7fab58c8f0098a1976376c5271ed6540d2edeb636d831db1e6bbe4bfcc266717/rootfs/dev tmpfs rw,nosuid,mode=755 0 0
devpts /hostfs/var/lib/docker/devicemapper/mnt/7fab58c8f0098a1976376c5271ed6540d2edeb636d831db1e6bbe4bfcc266717/rootfs/dev/pts devpts rw,nosuid,noexec,relatime,gid=5,mode=620,ptmxmode=666 0 0
shm /hostfs/var/lib/docker/devicemapper/mnt/7fab58c8f0098a1976376c5271ed6540d2edeb636d831db1e6bbe4bfcc266717/rootfs/dev/shm tmpfs rw,nosuid,nodev,noexec,relatime,size=65536k 0 0
mqueue /hostfs/var/lib/docker/devicemapper/mnt/7fab58c8f0098a1976376c5271ed6540d2edeb636d831db1e6bbe4bfcc266717/rootfs/dev/mqueue mqueue rw,nosuid,nodev,noexec,relatime 0 0
sysfs /hostfs/var/lib/docker/devicemapper/mnt/7fab58c8f0098a1976376c5271ed6540d2edeb636d831db1e6bbe4bfcc266717/rootfs/sys sysfs rw,nosuid,nodev,noexec,relatime 0 0
/dev/mapper/sysdisk-rootvol /hostfs/var/lib/docker/devicemapper/mnt/7fab58c8f0098a1976376c5271ed6540d2edeb636d831db1e6bbe4bfcc266717/rootfs/etc/hostMetadata.json ext3 ro,relatime,errors=continue,user_xattr,acl,barrier=1,data=ordered 0 0
/dev/mapper/sysdisk-rootvol /hostfs/var/lib/docker/devicemapper/mnt/7fab58c8f0098a1976376c5271ed6540d2edeb636d831db1e6bbe4bfcc266717/rootfs/etc/localtime ext3 ro,relatime,errors=continue,user_xattr,acl,barrier=1,data=ordered 0 0
/dev/mapper/sysdisk-rootvol /hostfs/var/lib/docker/devicemapper/mnt/7fab58c8f0098a1976376c5271ed6540d2edeb636d831db1e6bbe4bfcc266717/rootfs/etc/sensu ext3 rw,relatime,errors=continue,user_xattr,acl,barrier=1,data=ordered 0 0
cgroup /hostfs/cgroup/blkio cgroup rw,relatime,blkio 0 0
proc /hostproc proc ro,relatime 0 0
/proc/bus/usb /hostproc/bus/usb usbfs rw,relatime 0 0
none /hostproc/sys/fs/binfmt_misc binfmt_misc rw,relatime 0 0
sysfs /hostsys sysfs ro,relatime 0 0
/dev/mapper/sysdisk-rootvol /opt/pl_sensu ext3 rw,relatime,errors=continue,user_xattr,acl,barrier=1,data=ordered 0 0
/dev/mapper/logdisk-logvol /var/log/app ext3 rw,relatime,errors=continue,user_xattr,acl,barrier=1,data=ordered 0 0
/dev/mapper/sysdisk-varvol /etc/resolv.conf ext3 rw,relatime,errors=continue,user_xattr,acl,barrier=1,data=ordered 0 0
'

# mount_list_size =
RAW_HOST_MOUNT_DATA = '
rootfs / rootfs rw 0 0
proc /proc proc rw,relatime 0 0
sysfs /sys sysfs rw,relatime 0 0
devtmpfs /dev devtmpfs rw,relatime,size=1948620k,nr_inodes=487155,mode=755 0 0
devpts /dev/pts devpts rw,relatime,gid=5,mode=620,ptmxmode=000 0 0
tmpfs /dev/shm tmpfs rw,relatime 0 0
/dev/mapper/sysdisk-rootvol / ext3 rw,relatime,errors=continue,user_xattr,acl,barrier=1,data=ordered 0 0
/proc/bus/usb /proc/bus/usb usbfs rw,relatime 0 0
/dev/mapper/sysdisk-appvol /app ext3 rw,relatime,errors=continue,user_xattr,acl,barrier=1,data=ordered 0 0
/dev/sda1 /boot ext3 rw,relatime,errors=continue,user_xattr,acl,barrier=1,data=ordered 0 0
/dev/mapper/sysdisk-homevol /home ext3 rw,relatime,errors=continue,user_xattr,acl,barrier=1,data=ordered 0 0
/dev/mapper/sysdisk-tmpvol /tmp ext3 rw,relatime,errors=continue,user_xattr,acl,barrier=1,data=ordered 0 0
/dev/mapper/sysdisk-varvol /var ext3 rw,relatime,errors=continue,user_xattr,acl,barrier=1,data=ordered 0 0
/dev/mapper/logdisk-logvol /var/log ext3 rw,relatime,errors=continue,user_xattr,acl,barrier=1,data=ordered 0 0
none /proc/sys/fs/binfmt_misc binfmt_misc rw,relatime 0 0
cgroup /cgroup/cpuset cgroup rw,relatime,cpuset 0 0
cgroup /cgroup/cpu cgroup rw,relatime,cpu 0 0
cgroup /cgroup/cpuacct cgroup rw,relatime,cpuacct 0 0
cgroup /cgroup/memory cgroup rw,relatime,memory 0 0
cgroup /cgroup/devices cgroup rw,relatime,devices 0 0
cgroup /cgroup/freezer cgroup rw,relatime,freezer 0 0
cgroup /cgroup/net_cls cgroup rw,relatime,net_cls 0 0
cgroup /cgroup/blkio cgroup rw,relatime,blkio 0 0
'

PROC_DIRECTORY_MAIN = '/proc'
PROC_DIRECTORY_CONTAINER = '/hostproc'
CONTAINER_MOUNT_PREFIX = 'hostfs'

describe 'Partition Report' do
  it 'SENSU-261 -- it should calculate correct disk used percent' do
    reporter = Mounts::Reporter.new
    reporter.report.each do |_, val|
      avail = val[:available_kb].to_f
      total = val[:total_kb].to_f
      # puts("Part: #{key},  Avail: #{avail}, tot: #{total}")
      expect(val[:used_pct]).to eq 100.0 * (1 - avail / total) unless total == 0
    end
  end
end

describe 'module functions' do
  it 'should generate a happy path report' do
    reporter = Mounts::Reporter.new
    data = reporter.report
    expect(data.key? '/').to be true
  end
end

describe 'alternate paths tests' do
  it 'should produce a list with the right number of mounts when not in a container' do
    reporter = Mounts::Reporter.new(PROC_DIRECTORY_MAIN, CONTAINER_MOUNT_PREFIX, RAW_HOST_MOUNT_DATA,
                                    test_mode = true)
    expect(reporter.mount_list_size).to be 50
  end
end
