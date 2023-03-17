# Syslog Module Example

This is an example of how to use the [logs/syslog module](/modules/logs/syslog) to configure rate
limiting and log rotation for syslog. The example contains a [Packer](https://www.packer.io/) template that creates
Ubuntu, CentOS, and Amazon Linux AMIs with syslog configured using the `configure-syslog` module.

## Quick start

To build the AMIs:

1. Install [Packer](https://www.packer.io/)
1. Set your [GitHub access token](https://help.github.com/articles/creating-an-access-token-for-command-line-use/) as
   the environment variable `GITHUB_OAUTH_TOKEN`.
1. Run `packer build syslog-example.json`
