# Jenkins and Nginx Setup Script

## Overview

This script automates the installation and configuration of Jenkins and Nginx on an Amazon Linux 2023 EC2 instance. It is intended to be used as a userdata script during the provisioning of an EC2 instance.

## Requirements

- **Operating System:** Amazon Linux 2023
- **Permissions:** Ensure that the EC2 instance has the necessary permissions to perform system-level operations and installations.

## Usage

1. **Provision EC2 Instance:**
   Launch an EC2 instance on Amazon Linux 2023 and assign the script as the userdata.

2. **Execute the Script:**
   The script will run during the instance initialization and perform the following tasks:

   - Update the operating system.
   - Install Java (required for Jenkins).
   - Install Jenkins.
   - Start Jenkins service.
   - Install Nginx.
   - Start Nginx service.
   - Configure Nginx as a reverse proxy for Jenkins.
   - Reload Nginx to apply the configuration.
   - Add the 'nginx' user to the 'jenkins' group.

   The progress and logs are recorded in `/var/log/userdata.log`.

## Important Note

- The script is designed for Amazon Linux 2023. Ensure compatibility before using it on other operating systems.

---
