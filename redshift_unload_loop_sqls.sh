#!/bin/bash
set -e

########################## OPTIONS ###########################
## S3 Configurations
folder=@option.script_folder@
bucket=@option.script_bucket@
unload=@option.unload_path@

## Redshift Configurations
database=@option.dbase@
host=@option.host@
user=@option.user@
port=@option.port@
password=@option.password@
credencial_role=@option.iam_role@
##############################################################

## Partition Date
datestring="$(date +'%Y-%m-%d')"

## Temporary Directory
temp_dir="$(date +'%H%M%S%N')"
mkdir -p ./$temp_dir
cd ./$temp_dir

## Download S3 Files
aws s3 cp s3://$bucket/$folder/ ./ --recursive --include "*.sql"

## Loop Alphanumeric Order
for file in ./*.sql
do
 filefull="$(basename -- $file)"
 filename="${filefull%.*}"
 psql "host=$host user=$user dbname=$database port=$port password=$password" -v ON_ERROR_STOP=1 -c "UNLOAD(' $(sed 's/\x27/\x27\x27/g' $filefull) ') TO 's3://$unload/$datestring/$filename' iam_role '$credencial_role' FORMAT AS CSV HEADER PARALLEL OFF ALLOWOVERWRITE"
done

## Create a file when complete
echo "complete"> ./_COMPLETE
aws s3 cp ./_COMPLETE s3://$unload/$datestring/_COMPLETE

# Back and Remove Temporary Folder
cd ..
rm -f -R ./$temp_dir
