#!/bin/bash
# Omniture ClickStream Analysis Test 1
# -------------------------------------
# launches EMR cluster on AWS using the AWS cli, uploads data to S3, and then
# runs Pig task to analyse the data.
# author:  Keith Steward
# date:  2015-05-28


# Vars:
CLUST_NAME='omniture5'
NUM_MASTER=1
NUM_CORE=4
KEYNAME=test-key-1
PIGNAME=omniture_analyze.pig
BUCKET=s3://kls-omniture
LLOG=/tmp/$CLUST_NAME.log
LOGS=$BUCKET/logs
INPUTDATA=$BUCKET/inputdata
OUTPUTDATA=$BUCKET/outputdata
SCRIPTS=$BUCKET/scripts
REFINESCRIPT=$SCRIPTS/refinelog.pig
HIVESCRIPT1=$SCRIPTS/hiveddl.sql
LOCAL=/tmp
LDATA=$LOCAL/data  # symlink /tmp/data -> to location of data & scripts
LSCRIPTS=$LDATA
TAGS=project=omniture_analyze

echo "" >>$LLOG
echo "Starting $0 at `date`..." >>$LLOG
echo "using data from $INPUTDATA, scripts from $SCRIPTS, output to $OUTPUTDATA" >>$LLOG

# sync files to S3...
echo "uploading data to s3 ..." >>$LLOG
aws s3 sync $LDATA $INPUTDATA/users --exclude "*" --include "users.tsv.gz"
aws s3 sync $LDATA $INPUTDATA/products --exclude "*" --include "products.tsv.gz"
aws s3 sync $LDATA $INPUTDATA/clickstreams --exclude "*" --include "Omniture.*.tsv.gz"
aws s3 sync $LSCRIPTS $SCRIPTS --exclude "*" --include "*.pig" --include "*.sql"

# clean out any old output
aws s3 rm $OUTPUTDATA/ --recursive 

# spin up the cluster:
aws emr create-default-roles
s="aws emr create-cluster --log-uri $LOGS --name \"$CLUST_NAME\" --ami-version 2.4 \
    --applications Name=Hive Name=Pig \
    --use-default-roles --ec2-attributes KeyName=\"$KEYNAME\" \
    --instance-groups InstanceGroupType=MASTER,InstanceCount=$NUM_MASTER,InstanceType=m3.xlarge \
    InstanceGroupType=CORE,InstanceCount=$NUM_CORE,InstanceType=m3.xlarge \
    --steps Type=HIVE,Name=HiveDDL,ActionOnFailure=CONTINUE,Args=[-f,$HIVESCRIPT1,-d,INPUT=$INPUTDATA,-d,OUTPUT=$OUTPUTDATA] \
    --tags $TAGS"

echo "invoking: $s" >>$LLOG
exec $s  
