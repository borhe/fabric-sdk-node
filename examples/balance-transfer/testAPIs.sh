#!/bin/bash

jq --version > /dev/null 2>&1
if [ $? -ne 0 ]; then
	echo "Please Install 'jq' https://stedolan.github.io/jq/ to execute this script"
	echo
	exit 1
fi
starttime=$(date +%s)

echo "POST request Enroll on Org1  ..."
echo
ORG1_TOKEN=$(curl -s -X POST \
  http://localhost:4000/users \
  -H "cache-control: no-cache" \
  -H "content-type: application/x-www-form-urlencoded" \
  -d 'username=Jim&orgName=org1')
echo $ORG1_TOKEN
ORG1_TOKEN=$(echo $ORG1_TOKEN | jq ".token" | sed "s/\"//g")
echo
echo "ORG1 token is $ORG1_TOKEN"
echo
echo "POST request Enroll on Org2 ..."
echo
ORG2_TOKEN=$(curl -s -X POST \
  http://localhost:4000/users \
  -H "cache-control: no-cache" \
  -H "content-type: application/x-www-form-urlencoded" \
  -d 'username=Barry&orgName=org2')
echo $ORG2_TOKEN
ORG2_TOKEN=$(echo $ORG2_TOKEN | jq ".token" | sed "s/\"//g")
echo
echo "ORG2 token is $ORG2_TOKEN"
echo
echo
echo "POST request Create channel  ..."
echo
curl -s -X POST \
  http://localhost:4000/channels \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "cache-control: no-cache" \
  -H "content-type: application/json" \
  -H "x-access-token: $ORG1_TOKEN" \
  -d '{
	"channelName":"mychannel",
	"channelConfigPath":"../artifacts/channel/mychannel.tx"
}'
echo
echo
sleep 5
echo "POST request Join channel on Org1"
echo
curl -s -X POST \
  http://localhost:4000/channels/mychannel/peers \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "cache-control: no-cache" \
  -H "content-type: application/json" \
  -H "x-access-token: $ORG1_TOKEN" \
  -d '{
	"peers": ["localhost:7051","localhost:7056"]
}'
echo
echo

echo "POST request Join channel on Org2"
echo
curl -s -X POST \
  http://localhost:4000/channels/mychannel/peers \
  -H "authorization: Bearer $ORG2_TOKEN" \
  -H "cache-control: no-cache" \
  -H "content-type: application/json" \
  -H "x-access-token: $ORG2_TOKEN" \
  -d '{
	"peers": ["localhost:8051","localhost:8056"]
}'
echo
echo

echo "POST Install chaincode on Org1"
echo
curl -s -X POST \
  http://localhost:4000/chaincodes \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "cache-control: no-cache" \
  -H "content-type: application/json" \
  -H "x-access-token: $ORG1_TOKEN" \
  -d '{
	"peers": ["localhost:7051","localhost:7056"],
	"chaincodeName":"mycc",
	"chaincodePath":"github.com/example_cc",
	"chaincodeVersion":"v0"
}'
echo
echo


echo "POST Install chaincode on Org2"
echo
curl -s -X POST \
  http://localhost:4000/chaincodes \
  -H "authorization: Bearer $ORG2_TOKEN" \
  -H "cache-control: no-cache" \
  -H "content-type: application/json" \
  -H "x-access-token: $ORG2_TOKEN" \
  -d '{
	"peers": ["localhost:8051","localhost:8056"],
	"chaincodeName":"mycc",
	"chaincodePath":"github.com/example_cc",
	"chaincodeVersion":"v0"
}'
echo
echo

echo "POST instantiate chaincode on peer1 of Org1"
echo
curl -s -X POST \
  http://localhost:4000/channels/mychannel/chaincodes \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "cache-control: no-cache" \
  -H "content-type: application/json" \
  -H "x-access-token: $ORG1_TOKEN" \
  -d '{
	"peers": ["localhost:7051"],
	"chaincodeName":"mycc",
	"chaincodePath":"github.com/example_cc",
	"chaincodeVersion":"v0",
	"functionName":"init",
	"args":["a","100","b","200"]
}'
echo
echo

echo "POST invoke chaincode on peers of Org1"
echo
TRX_ID=$(curl -s -X POST \
  http://localhost:4000/channels/mychannel/chaincodes/mycc \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "cache-control: no-cache" \
  -H "content-type: application/json" \
  -H "x-access-token: $ORG1_TOKEN" \
  -d '{
	"peers": ["localhost:7051", "localhost:7056"],
	"chaincodeVersion":"v0",
	"functionName":"invoke",
	"args":["move","a","b","10"]
}')
echo "Transacton ID is $TRX_ID"
echo
echo

echo "POST invoke chaincode on peers of Org2"
echo
TRX_ID=$(curl -s -X POST \
  http://localhost:4000/channels/mychannel/chaincodes/mycc \
  -H "authorization: Bearer $ORG2_TOKEN" \
  -H "cache-control: no-cache" \
  -H "content-type: application/json" \
  -H "x-access-token: $ORG2_TOKEN" \
  -d '{
	"peers": ["localhost:8051", "localhost:8056"],
	"chaincodeVersion":"v0",
	"functionName":"invoke",
	"args":["move","a","b","10"]
}')
echo "Transacton ID is $TRX_ID"
echo
echo

echo "GET query chaincode on peer1 of Org1"
echo
curl -s -X GET \
  "http://localhost:4000/channels/mychannel/chaincodes/mycc?peer=peer1&args=%5B%22query%22%2C%22a%22%5D&chaincodeVersion=v0" \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "cache-control: no-cache" \
  -H "content-type: application/json" \
  -H "x-access-token: $ORG1_TOKEN"
echo
echo

echo "GET query Block by blockNumber"
echo
curl -s -X GET \
  "http://localhost:4000/channels/mychannel/blocks/1?peer=peer1" \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "cache-control: no-cache" \
  -H "content-type: application/json" \
  -H "x-access-token: $ORG1_TOKEN"
echo
echo

echo "GET query Transaction by TransactionID"
echo
curl -s -X GET http://localhost:4000/channels/mychannel/transactions/$TRX_ID?peer=peer1 \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "cache-control: no-cache" \
  -H "content-type: application/json" \
  -H "x-access-token: $ORG1_TOKEN"
echo
echo

############################################################################
### TODO: What to pass to fetch the Block information
############################################################################
#echo "GET query Block by Hash"
#echo
#hash=????
#curl -s -X GET \
#  "http://localhost:4000/channels/mychannel/blocks?hash=$hash&peer=peer1" \
#  -H "authorization: Bearer $ORG1_TOKEN" \
#  -H "cache-control: no-cache" \
#  -H "content-type: application/json" \
#  -H "x-access-token: $ORG1_TOKEN"
#echo
#echo

echo "GET query ChainInfo"
echo
curl -s -X GET \
  "http://localhost:4000/channels/mychannel?peer=peer1" \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "cache-control: no-cache" \
  -H "content-type: application/json" \
  -H "x-access-token: $ORG1_TOKEN"
echo
echo

echo "GET query Installed chaincodes"
echo
curl -s -X GET \
  "http://localhost:4000/chaincodes?peer=peer1&type=installed" \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "cache-control: no-cache" \
  -H "content-type: application/json" \
  -H "x-access-token: $ORG1_TOKEN"
echo
echo

echo "GET query Instantiated chaincodes"
echo
curl -s -X GET \
  "http://localhost:4000/chaincodes?peer=peer1&type=instantiated" \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "cache-control: no-cache" \
  -H "content-type: application/json" \
  -H "x-access-token: $ORG1_TOKEN"
echo
echo

echo "GET query Channels"
echo
curl -s -X GET \
  "http://localhost:4000/channels?peer=peer1" \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "cache-control: no-cache" \
  -H "content-type: application/json" \
  -H "x-access-token: $ORG1_TOKEN"
echo
echo


echo "Total execution time : $(($(date +%s)-starttime)) secs ..."
