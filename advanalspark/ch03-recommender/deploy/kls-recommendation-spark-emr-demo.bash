#!/bin/bash
# Automatically launch a Spark cluster on AWS, submit recommendation ML,
# make some recommendations, then terminate cluster.
# Assumptions;  AWS_SECRET_ACCESS_KEY & AWS_ACCESS_KEY_ID env vars are set.
#
# TODO:  speed up 10-fold by:
#  a) increasing NUM_NODES to 15
#  b) increasing instance-type from m1.large to c3.2xlarge (15 Gb RAM, 8 cores, SSD)
AMIVERSION=3.9.0
INST_TYPE=c3.4xlarge
INSTANCECORES=16
NUMCORENODES=4
NUMTASKNODES=15
TOTALCORES=`echo "($NUMCORENODES + $NUMTASKNODES) * ($INSTANCECORES - 2)" | bc -l`
BIDPRICE=0.30
AWS_REGION=us-east-1
AWS_ZONE=us-east-1e
NAME='Music Recommender Cluster'
BUCKETNAME=kls-recommendation-spark-emr-demo
BUCKETS3=s3://$BUCKETNAME
BUCKETURL="https://s3.amazonaws.com/$BUCKETNAME"
LOGSURI=$BUCKETS3/logs
KEYPAIR=test-key-1
AUTH="-k $KEYPAIR -i $KEYPAIR.pem"
OPTS="--copy-aws-credentials --region=$AWS_REGION --zone=$AWS_ZONE $AUTH -t $INST_TYPE  --no-ganglia"
JARFILE=ch03-recommender-1.0.1-jar-with-dependencies.jar
CLASS=com.cloudera.datascience.recommender.RunRecommender

echo ""
echo "Music Recommendation System Demo"
echo "---------------------------------"

# package our scala code
cd ..
echo "packaging application code ..."
mvn -q package

# sync it to s3
echo "syncing application code to s3 ..."
aws s3 sync target/ $BUCKETS3/ --exclude "*" --include "*.jar" --quiet
aws s3 cp deploy/sparkconfig.json $BUCKETS3/

# create the cluster
cd -
msg="Launching Spark cluster $CLUSTNAME in region $AWS_REGION with $TOTALCORES cores ..."
echo $msg
echo $msg >>runs.log
aws emr create-default-roles
cmd=<<EOC
aws emr create-cluster --name "$NAME" --ami-version $AMIVERSION \
  --applications Name=Spark,Args=["-x"] \
  --ec2-attributes KeyName=$KEYPAIR --log-uri $LOGSURI --instance-groups \
   Name=Master,InstanceGroupType=MASTER,InstanceType=m3.xlarge,InstanceCount=1 \
   Name=Core,InstanceGroupType=CORE,InstanceType=$INST_TYPE,InstanceCount=$NUMCORENODES \
   Name=Task,InstanceGroupType=TASK,InstanceType=$INST_TYPE,InstanceCount=$NUMTASKNODES,BidPrice=$BIDPRICE \
  --steps Type="Spark",Name="Recommender",ActionOnFailure=CONTINUE,Args=["--deploy-mode","cluster","--class","com.cloudera.datascience.recommender.RunRecommender","$BUCKETS3/ch03-recommender-1.0.1-jar-with-dependencies.jar"]
EOC
echo "executing:"
echo " $cmd"
RESULT=`$cmd`
echo $RESULT


#"--conf","spark.dynamicAllocation.enabled=true","--conf","spark.executor.memory=2G","--conf","spark.executor.cores=10",


#"--total-executor-cores","$TOTALCORES",

# terminate the cluster ?