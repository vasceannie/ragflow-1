#!/bin/bash

# Activate virtual environment
source /opt/venv/bin/activate

# Configure environment variables for cloud deployment
export PORT=${PORT:-9380}
export PYTHONPATH=/app/
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu/

# Create conf directory if it doesn't exist
mkdir -p /app/conf

# Initialize config from template
rm -rf /app/conf/service_conf.yaml
while IFS= read -r line || [[ -n "$line" ]]; do
    eval "echo \"$line\"" >> /app/conf/service_conf.yaml
done < /app/conf/service_conf.yaml.template

# Start nginx if needed
if [ -f "/etc/nginx/nginx.conf" ]; then
    nginx
fi

# Set default worker count
if [[ -z "$WS" || $WS -lt 1 ]]; then
  WS=1
fi

# Function to execute task executor
function task_exe(){
    while true; do
        python rag/svr/task_executor.py $1
        sleep 1
    done
}

# Start task executors
for ((i=0;i<WS;i++)); do
    task_exe $i &
done

# Start main server
while true; do
    python api/ragflow_server.py
    sleep 1
done 