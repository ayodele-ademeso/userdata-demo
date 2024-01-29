#!/bin/bash

set -e

LOG_FILE="/var/log/userdata.log"

# Function to log and display messages
log_and_display() {
    echo "$(date): $1" | tee -a "$LOG_FILE"
}

log_and_display "Updating the OS"
sudo yum update -y | tee -a "$LOG_FILE"

log_and_display "Installing Java (required for Jenkins)"
sudo yum install fontconfig java -y | tee -a "$LOG_FILE"

log_and_display "Installing Jenkins"
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat/jenkins.repo | tee -a "$LOG_FILE"
sudo rpm --import https://pkg.jenkins.io/redhat/jenkins.io-2023.key | tee -a "$LOG_FILE"

sudo yum install jenkins -y | tee -a "$LOG_FILE"

log_and_display "Starting Jenkins service"
sudo systemctl enable jenkins | tee -a "$LOG_FILE"
sudo systemctl start jenkins | tee -a "$LOG_FILE"

log_and_display "Installing Nginx"
sudo yum install nginx -y | tee -a "$LOG_FILE"

log_and_display "Starting Nginx service"
sudo systemctl enable nginx | tee -a "$LOG_FILE"
sudo systemctl start nginx | tee -a "$LOG_FILE"

log_and_display "Configuring Nginx as a reverse proxy for Jenkins"
sudo tee /etc/nginx/conf.d/jenkins.conf <<\EOF
upstream jenkins {
  keepalive 32; # keepalive connections
  server 127.0.0.1:8080; # jenkins ip and port
}

# Required for Jenkins websocket agents
map $http_upgrade $connection_upgrade {
  default upgrade;
  '' close;
}

server {
  listen          80;

  server_name     _;

  # this is the jenkins web root directory
  # (mentioned in the output of "systemctl cat jenkins")
  root            /var/run/jenkins/war/;

  access_log      /var/log/nginx/jenkins.access.log;
  error_log       /var/log/nginx/jenkins.error.log;

  # pass through headers from Jenkins that Nginx considers invalid
  ignore_invalid_headers off;

  location ~ "^/static/[0-9a-fA-F]{8}\/(.*)$" {
    # rewrite all static files into requests to the root
    # E.g /static/12345678/css/something.css will become /css/something.css
    rewrite "^/static/[0-9a-fA-F]{8}\/(.*)" /$1 last;
  }

  location /userContent {
    # have nginx handle all the static requests to userContent folder
    # note : This is the $JENKINS_HOME dir
    root /var/lib/jenkins/;
    if (!-f $request_filename){
      # this file does not exist, might be a directory or a /**view** url
      rewrite (.*) /$1 last;
      break;
    }
    sendfile on;
  }

  location / {
      sendfile off;
      proxy_pass         http://jenkins;
      proxy_redirect     default;
      proxy_http_version 1.1;

      # Required for Jenkins websocket agents
      proxy_set_header   Connection        $connection_upgrade;
      proxy_set_header   Upgrade           $http_upgrade;

      proxy_set_header   Host              $http_host;
      proxy_set_header   X-Real-IP         $remote_addr;
      proxy_set_header   X-Forwarded-For   $proxy_add_x_forwarded_for;
      proxy_set_header   X-Forwarded-Proto $scheme;
      proxy_max_temp_file_size 0;

      #this is the maximum upload size
      client_max_body_size       10m;
      client_body_buffer_size    128k;

      proxy_connect_timeout      90;
      proxy_send_timeout         90;
      proxy_read_timeout         90;
      proxy_request_buffering    off; # Required for HTTP CLI commands
  }

}
EOF


log_and_display "Reloading Nginx to apply the configuration"
sudo systemctl reload nginx | tee -a "$LOG_FILE"

usermod -aG jenkins nginx | tee -a "$LOG_FILE"

log_and_display "Installation and configuration completed"
