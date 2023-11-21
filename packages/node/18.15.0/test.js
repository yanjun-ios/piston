import { DynamoDB } from "@aws-sdk/client-dynamodb";

const region = "us-west-2";
const client = new DynamoDB({ region });
client.listTables({}, (err, data) => {
    if (err) console.log(err, err.stack);
    else console.log(data);
});

//import AWS from "aws-sdk";
// var AWS = require("aws-sdk");
// const region = "us-west-2";
// const client = new AWS.DynamoDB({ region });
// client.listTables({}, (err, data) => {
//     if (err) console.log(err, err.stack);
//     else console.log(data);
// });
