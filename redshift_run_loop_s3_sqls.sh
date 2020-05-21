#!/bin/bash
set -e

#################################### OPTIONS ###############################################
## S3 Bucket Configurations
folder=@option.script_folder@
bucket=@option.script_bucket@

## Redshift Configurations 
database=@option.dbase@
host=@option.host@
user=@option.user@
port=@option.port@
password=@option.password@
############################################################################################

## Temporary Directory
temp_dir="$(date +'%H%M%S%N')"

## Create and Change to Temporary Directory
mkdir -p ./$temp_dir
cd ./$temp_dir

## Download S3 files recursive
aws s3 cp s3://$bucket/$folder/ ./ --recursive --include "*.sql"

## Loop Alphanumeric Order
for file in ./*.sql
do
 filefull="$(basename -- $file)"
 filename="${filefull%.*}"
 psql "host=$host user=$user dbname=$database port=$port password=$password" -v ON_ERROR_STOP=1 -f ./$filefull
done

## Back
cd ..

## Remove Temporary Directory
rm -f -R ./$temp_dir
