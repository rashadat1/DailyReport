#!/bin/bash

if [ -z "$1" ]; then
    DATE=$(date +"%Y-%m-%d")
else
    DATE="$1"
fi

FILE_PATH="$PWD/weather_report_$DATE.txt"

if [ ! -f "$FILE_PATH" ]; then
    (
        echo "Subject: Weather Report Failed for $DATE"
        echo "MIME-Version: 1.0"
        echo "Content-Type: text/html; charset=UTF-8"
        echo
        echo "<html><body>"
        echo "<h2 style='color:red;'>Weather Report Failed - $DATE</h2>"
        echo "<p>Please investigate the reason for the failure</p>"
        echo "</body></html>"
    ) | msmtp -a gmail trashada1@gmail.com
    echo "Error: Weather report file for $DATE not found! Daily Email not generated"
    exit 1
fi

(
    echo "Subject: $DATE Weather Report"
    echo "MIME-Version: 1.0"
    echo "Content-Type: text/html; charset=UTF-8"
    echo
    echo "<html><body>"
    echo "<h2>Daily Weather Report for $DATE</h2>"

    inside_forecast=false
    while IFS= read -r line; do
        if [[ "$line" =~ ^### ]]; then
            # built in bash expression so we don't have to use sed
            echo "<h3>${line//###/}</h3>"
            if [[ "$line" =~ "10-Day Forecast" ]]; then
                inside_forecast=true
                # create table here
                echo "<table border='1' cellpadding='5' cellspacing='0' style='border-collapse: collapse;'>"
                echo "<tr style='background-color: lightgray;'>"
                echo "<th>Day</th><th>Date</th><th>Low</th><th>High</th><th>Conditions</th>"
                echo "</tr>"
            fi
        # finds lines that begin with one of these options 
        elif [[ "$line" =~ ^(Location|As Of|Current Temperature|Humidity|Wind Velocity|Wind Chill|Sunrise|Sunset): ]]; then
            # cut with -d lets us chose a delimiter and then index through the 
            # string split with this delimiter
            # -f lets us treat the split string as a list and index through it 
            # -f 1 is the first index 2- means the second and all others concatenated
            field_name=$(echo $line | cut -d : -f 1)
            field_value=$(echo $line | cut -d : -f 2-)
            echo "<p><strong>$field_name</strong>: $field_value</p>"

        elif [[ "$inside_forecast" == true ]]; then
            # check if we have reached the forecast section
            if [[ "$line" =~ ^Day: ]]; then
                # Lines look like this:
                # Day: Sun, Date: 02/03, Low: 6, High: 28, Conditions: Mostly Cloudy
                # -F fs specifies an input field separator
                day=$(echo $line | awk -F ', ' '{print $1}' | awk -F ' ' '{print $2}')
                date=$(echo $line | awk -F ', ' '{print $2}' | awk -F ' ' '{print $2}')
                low=$(echo $line | awk -F ', ' '{print $3}' | awk -F ' ' '{print $2}')
                high=$(echo $line | awk -F ', ' '{print $4}' | awk -F ' ' '{print $2}')
                conditions=$(echo $line | awk -F ', ' '{print $5}' | awk -F ': ' '{print $2}')
                
                echo "<tr>"
                echo "<td>$day</td>"
                echo "<td>$date</td>"
                echo "<td style='color:blue;'>${low}°F</td>"
                echo "<td style='color:red;'>${high}°F</td>"
                echo "<td style='color:green;'>$conditions</td>"
                echo "</tr>"
            fi
        else
            echo "<p>$line</p>"
        fi
    done < $FILE_PATH
    # Close the table tag if we opened it
    if [[ "$inside_forecast" == true ]]; then
        echo "</table>"
    fi
    echo "<br><p>Enjoy your day!</p>"
    echo "</body></html>"
) | msmtp -a gmail trashada1@gmail.com

echo "Email sent successfully!"
