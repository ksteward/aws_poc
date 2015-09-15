Music Recommendation System EMR/Spark/Machine Learning Demo
============================================================
author:  Keith Steward, AWS Solutions Architect - EMR
date: 2015-09-04

INTRODUCTION

This software is designed to illustrate some of the capabilities of the AWS EMR
service.  Customers new to AWS or new to EMR will be curious as to how EMR can
be used, and how easily/efficiently it can be used.  This software can be run as
a demonstration to such customers.

The software is a bundle of:
a) music recommendation system written in Scala and designed to run on EMR/Spark
b) a bash script for automated EMR cluster creation, programming, execution, and
   shutdown.

The music recommendation system software comes from Chapter 3 of the Ryza et al
(2015) book titled "Advanced Analytics with Spark", published by O'Reilly.  It
is an example of a machine learning system written in Scala that is designed to
run on Spark.  It processes a publicly-available 24 million+ record set
consisting of anonymised user:artist listenings along with artist
aliases/spelling-variants to support collaborative filtering in order to make
recommendations of artists users might like.


WHAT THE DEMO DOES

This demo:
* puts a music recommendation system code jar into an S3 bucket
* spins up an EMR/Spark cluster with a step to access the code jar from S3
* the code is hard-coded 

PRE-REQUISITES

Before this demo can be run, the following pre-requisites will need to be
addressed:
1) must have an AWS account with room in your EMR/EC2 quota to be able to launch
20 additional EC2 nodes.
2) have the AWS CLI installed on a computer (laptop?) on which the launch script
will run.
3) an S3 bucket that your AWS account can upload files to.
4) a web browser with which to view the EMR cluster status.

If you will be modifying the Scala code and rebuilding the application's Jar
(note: not needed if you simply want to demo deploying the application as-is), you
will also need to have the JDK and Maven installed.


DEPENDENCIES

The music recommendation system, as indicated above, corresponds to Chapter 3 of
the Ryza et al book mentioned above.  The sample code provided for that book is
structured into a bunch of subdirectories, one for each chapter.  Furthermore,
to build the chapter 3 Scala code into a deployable jar a number of dependencies
must be satisfied, including some higher level (book) code contained in the
directory above the ch03 directory.

The Scala code for chapter 3 and the book-level dependencies is built using the
Maven tool and a Project Object Model (pom.xml) file that defines the
dependencies.  The Chapter 3 code has its own pom.xml file, as does parent
directory above the ch03/ directory.

If you do not want to build or rebuild the chapter 3 demo jar, you can use the
jar that has already been built and checked into the repository.  It is located
in the ch03/target/ subdirectory.  The
deploy/kls-recommendation-spark-emr-demo.bash script will automatically find and
upload that jar file to the S3 bucket defined in the script.


