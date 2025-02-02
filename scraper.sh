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
# today's date
DATE=$(date +"%Y-%m-%d")
FILE_PATH="$PWD/weather_report_$DATE.txt"
get_weather_data() {
    response_json=$(curl --silent --fail --request GET \
        --url "https://yahoo-weather5.p.rapidapi.com/weather?location=$location&format=json&u=$unit" \
        --header "x-rapidapi-host: yahoo-weather5.p.rapidapi.com" \
        --header "x-rapidapi-key: $apiKey")
    echo $response_json | jq 
}
#echo -e "${GREEN}Fetching weather data for $location...${RESET}"

parse_weather_data() {
    weather_data=$(get_weather_data)
    current_observation=$(echo "$weather_data" | jq '.current_observation')
    location_data=$(echo "$weather_data" | jq '.location')
    timestamp=$(echo "$current_observation" | jq '.pubDate')

    echo -e "${BLUE}###Current Weather Conditions###${RESET}"
    echo -n "Location: "
    echo $location_data | jq -r '.city + ", " + .country'
    echo -n "As Of: "
    echo -e "${YELLOW}$(date -r $timestamp +%m/%d\ %H:%M) ${RESET}"
    echo -n "Current Temperature: "
    echo -e "${GREEN}$( echo "$current_observation" | jq '.condition' | jq '.temperature')°F, $( echo $current_observation | jq '.condition' | jq -r '.text') ${RESET}"
    echo -n "Humidity:"
    echo -e "${GREEN} $( echo $current_observation | jq '.atmosphere' | jq '.humidity')%${RESET}"
    echo -n "Wind Velocity:"
    echo -e ${BLUE} $( echo $current_observation | jq -r '.wind | (.speed|tostring) + "mph " + .direction') ${RESET}
    echo -n "Wind Chill:"
    echo -e ${BLUE} $(echo $current_observation | jq -r '.wind | (.chill|tostring) + "°F"') ${RESET}
    echo -n "Sunrise:"
    echo -e ${YELLOW} $( echo $current_observation | jq '.astronomy' | jq -r '.sunrise') ${RESET}
    echo -n "Sunset:"
    echo -e ${YELLOW} $( echo $current_observation | jq '.astronomy' | jq -r '.sunset') ${RESET}
}
parse_forecast_data() {
    echo -e "${BLUE}###10-Day Forecast###${RESET}"
    forecasts=$(echo $(get_weather_data) | jq '.forecasts')
    echo $forecasts | jq -c '.[1:][]' | while read -r item; do
        day=$(echo $item | jq -r '.day')
        date=$(echo $item | jq -r '.date')
        low=$(echo $item | jq -r '.low')
        high=$(echo $item | jq -r '.high')
        weather=$(echo $item | jq -r '.text')
        
        echo -e "Day: ${YELLOW}$day${RESET}, Date: ${YELLOW}$(date -r $date "+%m/%d")${RESET}, Low: ${CYAN}$low"°F"${RESET}, High: ${RED}$high"°F"${RESET}, Conditions: ${GREEN}$weather${RESET}"
    done
}

# Save output to a file
{
    parse_weather_data
    parse_forecast_data
} > "$FILE_PATH"

# Call email weather report script
bash email_weather_report.sh "$DATE"
# additionally remove any weather reports older than a week old
find $PWD -name "weather_report_*.txt" -mtime +7 -exec rm {} \;
