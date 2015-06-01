#!/bin/bash
# Omniture ClickStream Analysis Test 1
# -------------------------------------
# launches EMR cluster on AWS using the AWS cli, uploads data to S3, and then
# runs Pig task to analyse the data.
# author:  Keith Steward
# date:  2015-05-28
SCRIPTPATH=$( cd $(dirname $0) ; pwd -P )

# Vars:
PROJECT='clicks_analyze'
CLUST_NAME=$PROJECT
NUM_MASTER=1
NUM_CORE=4
KEYNAME=test-key-1
if [ -z ${1+x} ]
  then echo "execute as:  $0  <s3 bucket>"
       exit 0
  else BUCKET=$1
fi
LOCAL=$SCRIPTPATH
LLOG=$LOCAL/$CLUST_NAME.log
LOGS=$BUCKET/logs
INPUTDATA=$BUCKET/inputdata
OUTPUTDATA=$BUCKET/outputdata
SCRIPTS=$BUCKET/scripts
HIVESCRIPT1=$SCRIPTS/hiveddl.sql
LDATA=$LOCAL
LSCRIPTS=$LDATA
TAGS=project=$PROJECT

echo "" | tee -a $LLOG
echo "Starting $0 at `date`..." | tee -a $LLOG
echo "using data from $INPUTDATA, scripts from $SCRIPTS, output to $OUTPUTDATA" | tee -a $LLOG 

# sync files to S3...
echo "uploading data and scripts to $BUCKET ..." | tee -a $LLOG
aws s3 sync $LDATA $INPUTDATA/users --exclude "*" --include "users.tsv.gz" | tee -a $LLOG
aws s3 sync $LDATA $INPUTDATA/products --exclude "*" --include "products.tsv.gz" | tee -a $LLOG
aws s3 sync $LDATA $INPUTDATA/clickstreams --exclude "*" --include "Omniture.*.tsv.gz" | tee -a $LLOG
aws s3 sync $LSCRIPTS $SCRIPTS --exclude "*" --include "*.pig" --include "*.sql" | tee -a $LLOG

# clean out any old output
aws s3 rm $OUTPUTDATA/ --recursive | tee -a $LLOG

# spin up the cluster:
aws emr create-default-roles
s="aws emr create-cluster --log-uri $LOGS --name \"$CLUST_NAME\" --ami-version 2.4 \
    --applications Name=Hive Name=Pig \
    --use-default-roles --ec2-attributes KeyName=\"$KEYNAME\" \
    --instance-groups InstanceGroupType=MASTER,InstanceCount=$NUM_MASTER,InstanceType=m3.xlarge \
    InstanceGroupType=CORE,InstanceCount=$NUM_CORE,InstanceType=m3.xlarge \
    --steps Type=HIVE,Name=HiveDDL,ActionOnFailure=CONTINUE,Args=[-f,$HIVESCRIPT1,-d,INPUT=$INPUTDATA,-d,OUTPUT=$OUTPUTDATA] \
    --tags $TAGS"
echo "invoking: $s" | tee -a $LLOG
exec $s | tee -a $LLOG
