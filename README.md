# aws_poc
some AWS proof-of-concept code. Nothing proprietary, just some demo code to share with others.

To run this, you first need to create a sym-linked path 
  /tmp/data --> {clickstream directory}
.

Then cd to the {clickstream directory} and executed:
./clicks_analyze

You can then monitor from the AWS console:
a) the uploading of input data files and scripts to s3 inputdata/ folder,
b) the spinning up of the EMR cluster,
c) the completion of the steps
d) the creation of output in the s3 outputdata/ folder.


