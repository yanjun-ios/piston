#!/bin/bash
curl "https://nodejs.org/dist/v18.15.0/node-v18.15.0-linux-x64.tar.xz" -o node.tar.xz
tar xf node.tar.xz --strip-components=1
rm node.tar.xz

# install aws sdk
source environment

# for sdk v2, support all the services
./bin/npm install aws-sdk --prefix ./

# for sdk v3, current support ec2 s3 lambda dynamodb iam cloudfront ebs
./bin/npm install @aws-sdk/client-ec2 --prefix ./
./bin/npm install @aws-sdk/client-s3 --prefix ./
./bin/npm install @aws-sdk/client-lambda --prefix ./
./bin/npm install @aws-sdk/client-dynamodb --prefix ./
./bin/npm install @aws-sdk/client-iam --prefix ./
./bin/npm install @aws-sdk/client-cloudfront --prefix ./
./bin/npm install @aws-sdk/client-ebs --prefix ./
