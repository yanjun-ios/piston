#!/usr/bin/env bash
curl -LO https://golang.org/dl/go1.20.11.linux-amd64.tar.gz
tar -xzf go1.20.11.linux-amd64.tar.gz
rm go1.20.11.linux-amd64.tar.gz

# install aws go SDK
source environment
go mod init example.com/m/v2
go get -u github.com/aws/aws-sdk-go
