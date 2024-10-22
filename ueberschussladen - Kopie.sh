#!/bin/bash

# Define vars

echo $(date) + " ÜBERSCHUSSLADEN - Fronius alle 5 Sekunden abfragen und an den go-E Charger senden"
count=5040
sleep=5


inverter_ip="192.168.0.2"
goe_ip="192.168.178.0.3"

# API endpoint for inverter data
inverter_api_endpoint="/solar_api/v1/GetPowerFlowRealtimeData.fcgi"

# Full URLs to query
inverter_url="http://$inverter_ip$inverter_api_endpoint"


# Use curl to make the request and retrieve JSON data

for ((i=1; i<=count; i++)); do
echo Runde $i von $count
  inverter_response=$(curl -s "$inverter_url")
  pgrid=$(echo "$inverter_response" | jq -r '.Body.Data.Site.P_Grid' | xargs printf "%.0f")
  pload=$(echo "$inverter_response" | jq -r '.Body.Data.Site.P_Load' | xargs printf "%.0f")
  pakku=$(echo "$inverter_response" | jq -r '.Body.Data.Site.P_Akku' | xargs printf "%.0f")
  ppv=$(echo "$inverter_response" | jq -r '.Body.Data.Site.P_PV'| xargs printf "%.0f")
  echo "Grid Power (P_Grid): $pgrid W"
  echo "Load Power (P_Load): $pload W"
  echo "Battery Power (P_Akku): $pakku W"
  echo "Solar Power (P_PV): $ppv W"


  # Construct the JSON payload
  json_payload="{\"pGrid\":$pgrid,\"pPv\":$ppv,\"pAkku\":$pakku}"
  #json_payload="{\"pGrid\":-2000,\"pPv\":0,\"pAkku\":0}"

  # URL encode the JSON payload
  encoded_payload=$(python3 -c "import urllib.parse; print(urllib.parse.quote('''$json_payload'''))")

  # Full URL with the encoded JSON payload
  goewriteurl="http://$goe_ip/api/set?ids=$encoded_payload"
  echo $goewriteurl
  goe_response=$(curl -s -X GET "$goewriteurl")

  # Display the response (JSON output)
  #echo "Response from Fronius Inverter API:"
  #echo "$inverter_response"

  echo "Response from goe API:"
  echo "$goe_response"
  sleep $sleep
done
