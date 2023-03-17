# Syslog Module

This module contains a script called `configure-syslog` that allows you to configure rate limiting and log rotation
settings for syslog.

Note that this module currently only supports:

* **Operating systems:**
  * Amazon Linux 2
  * Amazon Linux
  * Ubuntu
  * CentOS / Red Hat Linux

* **Syslog flavors:** rsyslog

## What is syslog and rsyslog?

[syslog](https://en.wikipedia.org/wiki/Syslog) is the standard logging system on Linux. Many Linux distributions,
including Ubuntu, CentOS, and Amazon Linux, come with [rsyslog](http://www.rsyslog.com/) installed, which is a 
replacement for syslog that uses the same configuration and API, but has more advanced features (see [this StackOverflow
thread](http://serverfault.com/a/692329/326638) for a discussion of the various syslog libraries).

With syslog, you can log things using the `logger` command (e.g. `echo "hi" | logger`) and find the log files under
`/var/log/syslog` (most Linux flavors) or `/var/log/messages` (Amazon Linux).

## Example

See the [syslog example](/examples/syslog) for an example of how to use this module.

## How do you use this module?

#### Installation

To use this module, you just need to run the `configure-syslog` script on your servers. The easiest way to install and
run the `configure-syslog` script on your servers is to create a [Packer](https://www.packer.io/) template
for your servers and to run the [Gruntwork Installer](https://github.com/gruntwork-io/gruntwork-installer) in that
template:

```
gruntwork-install --module-name logs/syslog --repo https://github.com/gruntwork-io/module-aws-monitoring --tag v0.0.9
```

#### Rate limiting

By default, rsyslog has a [rate limit](http://www.rsyslog.com/tag/rate-limiting/) that will start dropping log messages
if it sees more than 200 messages over a 5 second interval. This may be too small of a rate limit for many high traffic
web services, so this module allows you to configure a higher limit so you don't lose log messages whenever traffic
increases.

This module increases the rate limit to 5,000 messages over a 5-second interval. You can use the `--rate-limit-interval`
and `--rate-limit-burst` flags to configure an even higher limit, or disable rate limiting entirely by setting
`--rate-limit-interval` to 0. Note: disabling rate limiting carries a small amount of risk, as logging can take up a
lot of CPU and disk space.

For example, to set the rate limit to 2,500 messages over a 3-second interval, you could use the following command:

```
gruntwork-install --module-name logs/syslog --repo https://github.com/gruntwork-io/module-aws-monitoring --tag v0.0.9 --rate-limit-interval 3 --rate-limit-burst 2500
```

#### Log rotation

By default, all syslog messages go to `/var/log/syslog` (most Linux flavors) or `/var/log/messages` (Amazon Linux). If
this went on indefinitely, that log file would become enormous, making it hard to search and read. Moreover, you could
end up with so much log data that you run out of disk space.

Therefore, most Linux systems run a command called [logrotate](http://www.linuxcommand.org/man_pages/logrotate8.html)
as a daily and weekly CRON job. `logrotate` "rotates" your log files, archiving the current log file by renaming it
(e.g. `/var/log/syslog` gets renamed to `/var/log/syslog-05-06-2016.log`) and deleting old archived files.

This module configures reasonable defaults for log rotation:

* Run logrotate hourly
* Rotate log files once per day
* Rotate log files if they are over 1GB in size
* Keep at most 7 log files

It also allows you to provide a custom `logrotate` config file using the `--logrotate-config-path` variable to set up a
custom log rotation configuration.
