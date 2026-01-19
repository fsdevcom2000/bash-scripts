# Useful Bash Scripts

A collection of practical Bash scripts for system management and automation. Each script is located in its own directory with source code and usage instructions.

### Cron Manager Script
A simple interactive Bash script to manage cron jobs. Supports adding, listing, editing, removing tasks, and using predefined templates. Logs all actions.

Repository: https://github.com/fsdevcom2000/bash-scripts/tree/main/cron%20manager

## Mount Manager

This script is an interactive and safe tool for mounting ext4 partitions on Linux and automatically adding them to `/etc/fstab`. It provides a menu-based selection of devices, validates inputs, prevents duplicate `fstab` entries, checks mount point safety, and supports rollback if mounting fails.

Repository: https://github.com/fsdevcom2000/bash-scripts/tree/main/mount-manager

## Systemd Service Manager

This Bash script provides a simple menu-driven interface for managing Systemd services on Linux systems. It allows users to create, delete, restart services, reload Systemd configuration, and enable or disable auto-start for services.

Repository: https://github.com/fsdevcom2000/bash-scripts/tree/main/ssm

## Supervisor-Manager

SUPERVISOR-MANAGER is an interactive Bash script for managing Supervisor (a Linux process control system) configurations through a menu-driven interface. It simplifies the creation and deletion of Supervisor configurations, particularly for users unfamiliar with Supervisor's configuration syntax.

Repository: https://github.com/fsdevcom2000/bash-scripts/tree/main/supervisor

## Automated Installation and Autostart of Xeoma in Graphical Mode on Ubuntu Server 18.04

This project provides a fully automated script for installing and configuring Xeoma to start in graphical mode on Ubuntu Server 18.04 without a desktop environment. The system automatically logs in to the console, launches Xorg with a minimal window manager, and starts the Xeoma client in fullscreen mode.

Repository: https://github.com/fsdevcom2000/bash-scripts/tree/main/xeoma-install
