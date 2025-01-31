#!/bin/bash
if [ -z "$1" ]; then
    echo "Usage: $0 <location>"
    exit 1
fi
# define color codes
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
CYAN="\033[36m"
RESET="\033[0m"
location="$1"
apiKey="$WEATHER_API_KEY"
unit="$f"

get_weather_data() {
    response_json=$(curl --request GET \
        --url "https://yahoo-weather5.p.rapidapi.com/weather?location=$location&format=json&u=$unit" \
        --header "x-rapidapi-host: yahoo-weather5.p.rapidapi.com" \
        --header "x-rapidapi-key: $apiKey")
    echo $response_json
}
echo -e "${GREEN}Fetching weather data for $location...${RESET}"

parse_weather_data() {
    weather_data=$(get_weather_data)
    current_observation=$(echo "$weather_data" | jq '.current_observation')
    location_data=$(echo "$weather_data" | jq '.location')
    timestamp=$(echo "$current_observation" | jq '.pubDate')
    
    echo "$(date -r $timestamp +%m/%d\ %H:%M)"
}
parse_weather_data
