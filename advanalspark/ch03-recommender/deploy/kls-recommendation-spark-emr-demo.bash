#!/bin/bash
# Music Recommendation System EMR/Spark Demo
# ===========================================
# k. steward, 2015-09-15.
# Automatically launch a Spark cluster on AWS, submit recommendation ML,
# make some recommendations, then terminate cluster.
# The Audioscrobbler publicly-available data used as input in the analysis
# (and referenced within th Scala code) lives at s3://audioscrobbler-pds/
# Assumptions;  AWS_SECRET_ACCESS_KEY & AWS_ACCESS_KEY_ID env vars are set
# or configured into your AWS CLI installation.

AMIVERSION=3.9.0
INST_TYPE=c3.4xlarge
INSTANCECORES=16
NUMCORENODES=4
NUMTASKNODES=15
TOTALCORES=`echo "($NUMCORENODES + $NUMTASKNODES) * ($INSTANCECORES - 2)" | bc -l`
BIDPRICE=0.30
AWS_REGION=us-east-1
AWS_ZONE=us-east-1e
NAME='Music Recommender Demo Cluster'
BUCKETNAME=kls-recommendation-spark-emr-demo
BUCKETS3=s3://$BUCKETNAME
BUCKETURL="https://s3.amazonaws.com/$BUCKETNAME"
LOGSURI=$BUCKETS3/logs
KEYPAIR=test-key-1
JARFILE=ch03-recommender-1.0.1-jar-with-dependencies.jar
CLASS=com.cloudera.datascience.recommender.RunRecommender
POLLSECONDS=20

echo ""
echo "Music Recommendation System Demo"
echo "---------------------------------"

# build and package our Scala code if there was a change
cd ..
# For most demos, you will not be interested in rebuilding the Scala code, only
# in deploying it as-is.  If, on the other hand, you want to tweak the Scala code
# ane rebuild the Jar files, then uncomment the following lines.  You will
# need to have Java and Maven installed on the host that you will run this
# script on.
echo "building/packaging application jar (if there were changes) ..."  # uncomment to rebuild the Scala Jar
mvn -q package                      # uncomment to rebuild the Scala Jar

# sync application jar to s3
echo "syncing application code to s3 ..."
aws s3 sync target/ $BUCKETS3/ --exclude "*" --include "*.jar" --quiet

# create the cluster
cd - >/dev/null
msg="Launching Spark cluster $CLUSTNAME with Recommendation System in region $AWS_REGION with $TOTALCORES cores ..."
echo $msg | tee runs.log
aws emr create-default-roles
aws emr create-cluster --name "$NAME" --ami-version $AMIVERSION \
  --applications Name=Spark,Args=["-x"] \
  --ec2-attributes KeyName=$KEYPAIR --log-uri $LOGSURI --instance-groups \
   Name=Master,InstanceGroupType=MASTER,InstanceType=m3.xlarge,InstanceCount=1 \
   Name=Core,InstanceGroupType=CORE,InstanceType=$INST_TYPE,InstanceCount=$NUMCORENODES \
   Name=Task,InstanceGroupType=TASK,InstanceType=$INST_TYPE,InstanceCount=$NUMTASKNODES,BidPrice=$BIDPRICE \
  --steps Type="Spark",Name="Recommender",ActionOnFailure=CONTINUE,Args=["--deploy-mode","cluster","--class","$CLASS","$BUCKETS3/$JARFILE"] | tee cluster_id

# wait for cluster to finish running the analysis step
id=`awk '/ClusterId/{ print $2 }' cluster_id | sed 's/"//g'`
echo "waiting for completion of analysis by cluster $id..."
echo "   (You can monitor progress on your AWS Web Console)"
while true; do
    resp="`aws emr describe-cluster --cluster-id $id`"
    if [ "`echo \"$resp\" | grep 'Waiting after step completed'`" ]; then
	break
    fi
    sleep $POLLSECONDS
done

# terminate the cluster
echo "Processing & analysis has completed.  Terminating cluster ..."
aws emr terminate-clusters --cluster-ids $id
echo "cluster terminated."


