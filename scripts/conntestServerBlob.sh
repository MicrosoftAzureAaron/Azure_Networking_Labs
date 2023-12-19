#!/bin/bash

storage_account_name=$1
storage_account_key=$2
container_name=$3
local_folder_path=$4

hname=$(hostname)

mkdir $local_folder_path

curl -o $local_folder_path/conntest https://raw.githubusercontent.com/jimgodden/Azure_Networking_Labs/main/scripts/conntest
chmod +x $local_folder_path/conntest

curl -o $local_folder_path/capture_and_upload_server.sh https://raw.githubusercontent.com/jimgodden/Azure_Networking_Labs/main/scripts/capture_and_upload_server.sh
chmod +x $local_folder_path/capture_and_upload_server.sh

curl -o $local_folder_path/upload_to_blob.py https://raw.githubusercontent.com/jimgodden/Azure_Networking_Labs/main/scripts/upload_to_blob.py
chmod +x $local_folder_path/upload_to_blob.py

apt update -y
sudo apt-get install python3-pip
pip install azure-storage-blob

touch /tmp/test.txt
python3 $local_folder_path/upload_to_blob.py --account-name $storage_account_name --account-key $storage_account_key --container-name $container_name --local-file-path /tmp/test.txt  --blob-name text.txt

nohup $local_folder_path/capture_and_upload_server.sh 5001 $storage_account_name $storage_account_key $container_name $local_folder_path &

nohup /tmp/conntest -s -p 5001 &



