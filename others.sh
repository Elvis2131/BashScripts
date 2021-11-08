# sleep 30 &
# process_id=$!
# echo "PID: $process_id"
# wait $process_id
# echo "Exit status: $?"


##### Installing Docker ######
sudo curl -L "https://github.com/docker/compose/releases/download/2.1.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose