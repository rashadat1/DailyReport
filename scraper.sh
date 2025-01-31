#!/bin/bash
if [ -z "$1" ]; then
    echo "Usage: $0 <location>"
    exit 1
fi

location="$1"
apiKey="$WEATHER_API_KEY"
unit="$f"

get_weather_data() {
    response_json=$(curl --request GET \
        --url "https://yahoo-weather5.p.rapidapi.com/weather?location=$location&format=json&u=$unit" \
        --header "x-rapidapi-host: yahoo-weather5.p.rapidapi.com" \
        --header "x-rapidapi-key: $apiKey")
    echo $response_json | jq
}
echo "Getting weather data for $location"
get_weather_data
