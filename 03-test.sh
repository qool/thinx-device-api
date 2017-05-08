#!/bin/bash

# Using API Key 'static-test-key' : e172704e2c4e978782a5aecec4ebca9c88017a2a

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color
API_KEY='e172704e2c4e978782a5aecec4ebca9c88017a2a'

function echo_fail() { # $1 = string
    COLOR=$RED
    NC='\033[0m'
    printf "${COLOR}$1${NC}\n"
}

function echo_ok() { # $1 = string
    COLOR=$GREEN
    NC='\033[0m'
    printf "${COLOR}$1${NC}\n"
}

rm -rf cookies.jar

if [[ -z $HOST ]]; then
	HOST='localhost'
fi

echo
echo "--------------------------------------------------------------------------------"
echo "☢ Testing device registration..."

R=$(curl -s \
-H "Authentication: ${API_KEY}" \
-H 'Origin: device' \
-H "User-Agent: THiNX-Client" \
-H "Content-Type: application/json" \
-d '{ "registration" : { "mac" : "00:00:00:00:00:00", "firmware" : "EAV-App-0.4.0-beta:2017/04/08", "version" : "1.0.0", "hash" : "e58fa9bf7f478442c9d34593f0defc78718c8732", "push" : "dhho4djVGeQ:APA91bFuuZWXDQ8vSR0YKyjWIiwIoTB1ePqcyqZFU3PIxvyZMy9htu9LGPmimfzdrliRfAdci-AtzgLCIV72xmoykk-kHcYRhAFWFOChULOGxrDi00x8GgenORhx_JVxUN_fjtsN5B7T", "alias" : "rabbit", "owner": "test" } }' \
http://$HOST:7442/device/register)

# {"success":false,"status":"authentication"}

SUCCESS=$(echo $R | tr -d "\n" | jq .registration.success)
if [[ $SUCCESS == true ]]; then
	echo_ok "Device registration result: $R"
else
	echo_fail $R
fi

echo
echo "--------------------------------------------------------------------------------"
echo "☢ Assigning device alias..."

R=$(curl -s \
-H "Authentication: ${API_KEY}" \
-H 'Origin: device' \
-H "User-Agent: THiNX-Client" \
-H "Content-Type: application/json" \
-d '{ "changes" : [ { "device_id" : "00:00:00:00:00:00", "alias" : "new-test-alias" } ] }' \
http://$HOST:7442/api/device/edit)

# {"success":true,"status":"updated"}

SUCCESS=$(echo $R | tr -d "\n" | jq .success)
if [[ $SUCCESS == true ]]; then
	echo_ok "Alias assignment result: $R"
else
	echo_fail $R
fi

echo
echo "--------------------------------------------------------------------------------"
echo "☢ Testing device registration for revocation..."

R=$(curl -s \
-H "Authentication: ${API_KEY}" \
-H 'Origin: device' \
-H "User-Agent: THiNX-Client" \
-H "Content-Type: application/json" \
-d '{ "registration" : { "mac" : "FFFFFFFFFFFF", "firmware" : "none", "version" : "0.0.0", "hash" : "hash", "push" : "none", "alias" : "to-be-deleted", "owner": "test" } }' \
http://$HOST:7442/device/register)

# {"success":false,"status":"authentication"}

SUCCESS=$(echo $R | tr -d "\n" | jq .registration.success)
if [[ $SUCCESS == true ]]; then
	STATUS=$(echo $R | jq .status)
	echo_ok "Device registration result: $R"
else
	echo_fail $R
fi

echo
echo "--------------------------------------------------------------------------------"
echo "☢ Testing device revocation..."

R=$(curl -s \
-H "Authentication: ${API_KEY}" \
-H 'Origin: device' \
-H "User-Agent: THiNX-Client" \
-H "Content-Type: application/json" \
-d '{ "device_id" : "FFFFFFFFFFFF" }' \
http://$HOST:7442/device/revoke)

# {"success":false,"status":"authentication"}

SUCCESS=$(echo $R | tr -d "\n" | jq .success)
echo $SUCCESS
if [[ $SUCCESS == true ]]; then
	STATUS=$(echo $R | jq .status)
	echo_ok "Device revocation result: $R"
else
	echo_fail $R
fi

echo
echo "--------------------------------------------------------------------------------"
echo "☢ Testing firmware update (owner test)..."

R=$(curl -s \
-H "Authentication: ${API_KEY}" \
-H 'Origin: device' \
-H "User-Agent: THiNX-Client" \
-H "Content-Type: application/json" \
-d '{ "mac" : "00:00:00:00:00:00", "hash" : "e58fa9bf7f478442c9d34593f0defc78718c8732", "commit" : "e58fa9bf7f478442c9d34593f0defc78718c8732", "checksum" : "02e2436d60c629e2ab6357d0d314dd6fe28bd0331b18ca6b19a25cd6f969d0a8", "owner" : "test"  }' \
http://$HOST:7442/device/firmware)

# {"success":false,"status":"api_key_invalid"}

SUCCESS=$(echo $R | jq .success)
echo $SUCCESS
if [[ $SUCCESS == true ]]; then
	STATUS=$(echo $R | jq .status)
	echo_ok "Firmware update result: $R"
else
	echo_fail $R
fi

echo
echo "--------------------------------------------------------------------------------"
echo "» Testing authentication..."

R=$(curl -s -c cookies.jar \
-H "Origin: rtm.thinx.cloud" \
-H "User-Agent: THiNX-Web" \
-H "Content-Type: application/json" \
-d '{ "username" : "test", "password" : "tset" }' \
http://$HOST:7442/api/login)

# {"redirectURL":"http://rtm.thinx.cloud:80/app"}

SUCCESS=$(echo $R | jq .redirectURL)
echo $SUCCESS
if [[ ! -z $SUCCESS ]]; then
	URL=$(echo $R | jq .redirectURL)
	echo_ok "Redirected to login: $SUCCESS"
else
	echo_fail $R
fi

echo
echo "--------------------------------------------------------------------------------"
echo "» Fetching device catalog..."

R=$(curl -s -b cookies.jar \
-H "Origin: rtm.thinx.cloud" \
-H "User-Agent: THiNX-Web" \
-H "Content-Type: application/json" \
http://$HOST:7442/api/user/devices)

# {"devices":[{"id":"...

SUCCESS=$(echo $R | jq .devices)
# echo $SUCCESS
if [[ ! -z $SUCCESS ]]; then
	DEVICES=$(echo $R | jq .devices)
	echo_ok "Listed devices: $DEVICES"
else
	echo_fail $R
fi

echo
echo "--------------------------------------------------------------------------------"
echo "» Requesting new API Key..."

R=$(curl -s -b cookies.jar \
-H 'Origin: rtm.thinx.cloud' \
-H "User-Agent: THiNX-Web" \
-H "Content-Type: application/json" \
-d '{"alias":"test-key-name"}' \
http://$HOST:7442/api/user/apikey)

# {"success":true,"api_key":"ece10e3effb17650420c280a7d5dce79110dc084","alias":"api-key-name"}

SUCCESS=$(echo $R | jq .success)
echo $SUCCESS
APIKEY="$API_KEY"
if [[ $SUCCESS == true ]]; then
	APIKEY=$(echo $R | jq .api_key)
  HASH=$(echo $R | jq .hash)
	echo_ok "New key to revoke: $APIKEY with hash $HASH"
else
	echo_fail $R
fi

echo
echo "--------------------------------------------------------------------------------"
echo "» Revoking API Key..."

R=$(curl -s -b cookies.jar \
-H 'Origin: rtm.thinx.cloud' \
-H "User-Agent: THiNX-Web" \
-H "Content-Type: application/json" \
-d "{ \"fingerprint\" : \"${HASH}\" }" \
http://$HOST:7442/api/user/apikey/revoke)

# {"success":false,"status":"hash_not_found"}

SUCCESS=$(echo $R | jq .success)
echo $SUCCESS
RKEY=null
if [[ $SUCCESS == true ]]; then
	RKEY=$(echo $R | jq .sources)
	echo_ok "Revoked API key: $APIKEY"
else
	echo_fail $R
fi

echo
echo "--------------------------------------------------------------------------------"
echo "» Fetching API Keys..."

R=$(curl -s -b cookies.jar \
-H "Origin: rtm.thinx.cloud" \
-H "User-Agent: THiNX-Web" \
-H "Content-Type: application/json" \
http://$HOST:7442/api/user/apikey/list)

# {"api_keys":[{"name":"******************************d1343a37e4","hash":"39c1ffb0761038c3eb8fdc067132d90e5561c3ba84847a4e2f1dfb26515b2866","alias":"name"}]}

SUCCESS=$(echo $R | jq .api_keys)
# echo $SUCCESS
if [[ ! -z $SUCCESS ]]; then
	AKEYS=$(echo $R | jq .api_keys)
	echo_ok "Listed API keys: $AKEYS"
else
	echo_fail $R
fi

echo
echo "--------------------------------------------------------------------------------"
echo "» Fetching user sources..."

# {"success":true,"sources":[{"alias":"thinx-firmware-esp8266","url":"https://github.com/suculent/thinx-firmware-esp8266.git","branch":"origin/master"},{"alias":"thinx-firmware-esp8266","url":"https://github.com/suculent/thinx-firmware-esp8266.git","branch":"origin/master"}]}

R=$(curl -s -b cookies.jar \
-H 'Origin: rtm.thinx.cloud' \
-H "User-Agent: THiNX-Web" \
-H "Content-Type: application/json" \
http://$HOST:7442/api/user/sources/list)

SUCCESS=$(echo $R | jq .success)
echo $SUCCESS
SOURCES=null
if [[ $SUCCESS == true ]]; then
	SOURCES=$(echo $R | jq .sources)
	echo_ok "Listing sources: $SOURCES"
else
	echo_fail $R
fi

echo
echo "--------------------------------------------------------------------------------"
echo "» Revoking RSA key..."

# {"revoked":"d3:04:a5:05:a2:11:ff:44:4b:47:15:68:4d:2a:f8:93","success":true}

R=$(curl -s -b cookies.jar \
-H 'Origin: rtm.thinx.cloud' \
-H "User-Agent: THiNX-Web" \
-H "Content-Type: application/json" \
-d '{ "fingerprint" : "d3:04:a5:05:a2:11:ff:44:4b:47:15:68:4d:2a:f8:93" }' \
http://$HOST:7442/api/user/rsakey/revoke)

SUCCESS=$(echo $R | jq .success)
echo $SUCCESS
RPRINT=null
if [[ $SUCCESS == true ]]; then
	RPRINT=$(echo $R | jq .revoked)
	echo_ok "Added RSA key: $RPRINT"
else
	echo_fail $R
fi

echo
echo "--------------------------------------------------------------------------------"
echo "» Pushing RSA key..."

# {"success":true,"fingerprint":"d3:04:a5:05:a2:11:ff:44:4b:47:15:68:4d:2a:f8:93"}

R=$(curl -s -b cookies.jar \
-H 'Origin: rtm.thinx.cloud' \
-H "User-Agent: THiNX-Web" \
-H "Content-Type: application/json" \
-d '{ "alias" : "name", "key" : "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC0PF7uThKgcEwtBga4gRdt7tiPmxzRhJgxUdUrNKj0z4rDhs09gmXyN1EBH3oATJOMwdZ7J19eP/qRFK+bbkOacP6Hh0+eCr54bySpqyNPAeQFFXWzLXJ6t/di/vH0deutYBNH6S5yVz+Df/04IjoVIf+AMDYA8ppJ3WtBm0Qp/1UjYDM3Hc93JtDwr6AUoq/k0oAroP4ikL2gyXnmVjMX0DIkBwEScXhFDi1X6u6PWvFPLeZeB5MWQUo+VnBwFctExOmEt3RWJdwv7s8uRnoaFDA2OxlQ8cMWjCx0Z/aftl8AaV/TwpFTc1Fz/LhZ54Ud3s4usHji9720aAkSXGfD test@thinx.cloud" }' \
http://$HOST:7442/api/user/rsakey)

SUCCESS=$(echo $R | jq .success)
echo $SUCCESS
FPRINT=null
if [[ $SUCCESS == true ]]; then
	FPRINT=$(echo $R | jq .fingerprint)
	echo_ok "Added RSA key: $FPRINT"
else
	echo_fail $R
fi

echo
echo "--------------------------------------------------------------------------------"
echo "» Listing RSA keys..."

# {"rsa_keys":[{"name":"name","fingerprint":"d3:04:a5:05:a2:11:ff:44:4b:47:15:68:4d:2a:f8:93"}]}

R=$(curl -s -b cookies.jar \
-H 'Origin: rtm.thinx.cloud' \
-H "User-Agent: THiNX-Web" \
-H "Content-Type: application/json" \
http://$HOST:7442/api/user/rsakey/list)

SUCCESS=$(echo $R | jq .rsa_keys)
echo $SUCCESS
if [[ ! -z $SUCCESS ]]; then
	KEYS=$(echo $R | jq .rsa_keys)
	echo_ok "Listed RSA keys: $KEYS"
else
	echo_fail $R
fi

echo
echo "--------------------------------------------------------------------------------"
echo "» Testing source add..."

# {"success":true,"source":{"alias":"thinx-firmware-esp8266","url":"https://github.com/suculent/thinx-firmware-esp8266.git","branch":"origin/master"}}

R=$(curl -s -b cookies.jar \
-H 'Origin: rtm.thinx.cloud' \
-H "User-Agent: THiNX-Web" \
-H "Content-Type: application/json" \
-d '{ "url" : "https://github.com/suculent/thinx-firmware-esp8266.git", "alias" : "thinx-firmware-esp8266" }' \
http://$HOST:7442/api/user/source)

SUCCESS=$(echo $R | jq .success)
echo $SUCCESS
SOURCEA=null
if [[ $SUCCESS == true ]]; then
	SOURCEA=$(echo $R | jq .source.alias)
	echo_ok "Added source alias: $SOURCEA"
else
	echo_fail $R
fi

echo
echo "--------------------------------------------------------------------------------"
echo "» Testing source removal..."

# {"success":true,"removed":"thinx-test-repo"}

R=$(curl -s -b cookies.jar \
-H 'Origin: rtm.thinx.cloud' \
-H "User-Agent: THiNX-Web" \
-H "Content-Type: application/json" \
-d '{ "url" : "alias" : "thinx-firmware-esp8266" }' \
http://$HOST:7442/api/user/source/revoke)

SUCCESS=$(echo $R | jq .success)
echo $SUCCESS
RSOURCE=null
if [[ $SUCCESS == true ]]; then
	RSOURCE=$(echo $R | jq .removed)
	echo_ok "Removed source alias: $RSOURCE"
else
	echo_fail $R
fi

echo
echo "--------------------------------------------------------------------------------"
echo "» Testing source detach..."

# {"success":true,"attached":null}

DEVICE_ID="00:00:00:00:00:00"

R=$(curl -s -b cookies.jar \
-H 'Origin: rtm.thinx.cloud' \
-H "User-Agent: THiNX-Web" \
-H "Content-Type: application/json" \
-d '{ "mac" : "${DEVICE_ID}" }' \
http://$HOST:7442/api/device/detach)

SUCCESS=$(echo $R | jq .success)
echo $SUCCESS
if [[ $SUCCESS == true ]]; then
	echo_ok "Detached source from device: $DEVICE_ID"
else
	echo_fail $R
fi

echo
echo "--------------------------------------------------------------------------------"
echo "» Testing source attach..."

# {"success":true,"attached":"thinx-test-repo"}

R=$(curl -s -b cookies.jar \
-H 'Origin: rtm.thinx.cloud' \
-H "User-Agent: THiNX-Web" \
-H "Content-Type: application/json" \
-d '{ "mac" : "00:00:00:00:00:00", "alias" : "thinx-test-repo" }' \
http://$HOST:7442/api/device/attach)

SUCCESS=$(echo $R | jq .success)
echo $SUCCESS
ASOURCE=null
if [[ $SUCCESS == true ]]; then
	ASOURCE=$(echo $R | jq .alias)
	echo_ok "Attached source alias: $ASOURCE"
else
	echo_fail $R
fi

echo
echo "--------------------------------------------------------------------------------"
echo "☢ Testing builder..."

# {"build":{"success":true,"status":"Dry-run started. Build will not be deployed.","id":"85695a10-3015-11e7-9101-a5cf1f2b8f3f"}}r

R=$(curl -s -b cookies.jar \
-H "Origin: rtm.thinx.cloud" \
-H "User-Agent: THiNX-Client" \
-H "Content-Type: application/json" \
-d '{ "build" : { "hash" : "2d5b0e45f791cb3efd828d2a451e0dc64e4aefa3", "source" : "thinx-firmware-esp8266", "dryrun" : true } }' \
http://$HOST:7442/api/build)

SUCCESS=$(echo $R | jq .build.success)
echo $SUCCESS
BUILD_ID=null
if [[ $SUCCESS == true ]]; then
	BUILD_ID=$(echo $R | jq .build.id)
	echo_ok "New build ID: $BUILD_ID"
else
	echo_fail $R
fi

echo
echo "--------------------------------------------------------------------------------"
echo "☢ TODO: Audit log fetch..."

R=$(curl -s -b cookies.jar \
-H "Origin: rtm.thinx.cloud" \
-H "User-Agent: THiNX-Client" \
-H "Content-Type: application/json" \
http://$HOST:7442/api/user/logs/audit)

echo $R

echo
echo "--------------------------------------------------------------------------------"
echo "☢ TODO: Build log list..."

R=$(curl -s -b cookies.jar \
-H "Origin: rtm.thinx.cloud" \
-H "User-Agent: THiNX-Client" \
-H "Content-Type: application/json" \
http://$HOST:7442/api/user/logs/build/list)

echo $R

echo
echo "--------------------------------------------------------------------------------"
echo "☢ TODO: Build log fetch..."

R=$(curl -s -b cookies.jar \
-H "Origin: rtm.thinx.cloud" \
-H "User-Agent: THiNX-Client" \
-H "Content-Type: application/json" \
-d '{ "build_id" : "*"' \
http://$HOST:7442/api/user/logs/build)

echo $R

echo
echo "--------------------------------------------------------------------------------"
echo "☢ TODO: User avatar set..."

R=$(curl -s -b cookies.jar \
-H "Origin: rtm.thinx.cloud" \
-H "User-Agent: THiNX-Client" \
-H "Content-Type: application/json" \
-d '{ "avatar" : "data:image/png;base64,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"}' \
http://$HOST:7442/api/user/profile)

echo $R

echo
echo "--------------------------------------------------------------------------------"
echo "☢ TODO: User info set..."

R=$(curl -s -b cookies.jar \
-H "Origin: rtm.thinx.cloud" \
-H "User-Agent: THiNX-Client" \
-H "Content-Type: application/json" \
-d '{ "info" : { "first_name" : "Custom", "last_name" : "Custom", "mobile_phone" : "+420603861240", "notifications": { "all" : false, "important" : false, "info" : false }, "security" : { "unique_api_keys" : true } } }' \
http://$HOST:7442/api/user/profile)

echo $R

#echo
#echo "☢ Running nyc code coverage..."
#
#HOST="thinx.cloud"
#HOST="localhost"
#
#nyc --reporter=lcov --reporter=text-lcov npm test

#echo
#echo "☢ Running Karma..."

# karma start

exit 0

echo
echo "» Terminating node.js..."

DAEMON="node index.js"
NODEZ=$(ps -ax | grep "$DAEMON")

if [[ $(echo $NODEZ | wc -l) > 1 ]]; then

	echo "${NODEZ}" | while IFS="pts" read A B ; do
		NODE=$($A | tr -d ' ')
		echo "Killing: " $NODE $B
		kill "$NODE"
	done

else
	echo "${NODEZ}"
fi
