#Unofficial DEFLI installer (supports balena and docker)
#v1.1.1

echo "--------------------------------------"
echo "Wingbits / DEFLI install"
echo "--------------------------------------"

function removeContainer(){
    local container_name=$1

    if $hypervisor container inspect "$container_name" >/dev/null 2>&1; then
        echo "Removing container $containerName";
        $hypervisor rm -f $container_name;
    fi
}

function is_valid_guid() {
  local input=$1
  local guid_pattern='^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
  if [[ $input =~ $guid_pattern ]]; then return 0; else return 1; fi
}

function get_value() {
  local key="$1"
  local value=$(awk -F '=' '/^'"$key"'/ {print $2}' "$deflidatafile")
  echo "$value"
}

function prompt_with_default() {
  local prompt="$1"
  local default_value="$2"
  local user_input

  while true; do
    read -p "$prompt [$default_value]: " user_input

    if [ -z "$user_input" ]; then
      user_input="$default_value"
    fi

    if [ -n "$user_input" ]; then
      break
    else
      echo "Value cannot be empty. Please enter a value."
    fi
  done

  echo "$user_input"
}

function installDefli() {
    #create folders
    folder=/mnt/data/defli;
    if [ ! -d $folder ]; then mkdir -p $folder; fi;


    #Get USB bus and device numbers of the RTL stick
    deviceNameQuery='RTL2838|ADSB_1090'
    line=$(lsusb | grep -E $deviceNameQuery)
    
    if [ -z "$line" ]; then
        echo "No RTL-SDR stick found (searching $deviceNameQuery)"
        exit 1
    fi

    rtlCount=$(echo $line | grep -Ec $deviceNameQuery)
    if [ "$rtlCount" -gt 1 ]; then
        echo "More than one RTL-SDR stick found. Not currently supported by this script."
        exit 2
    fi

    bus_number=$(echo "$line" | cut -d ' ' -f 2)
    device_number=$(echo "$line" | cut -d ' ' -f 4 | cut -d ':' -f 1)
    stationName=""
    stationUuid=""
    latitude=""
    longitude=""
    altitudeMeters=""
    timezone=""

    
    #Get the data files
    deflidatafile="$folder/deflidata.txt"
    if ! [ -f "$deflidatafile" ]; then
        response=$(curl -o "$deflidatafile" --write-out "%{http_code}" 'https://raw.githubusercontent.com/softlion/defli/main/deflidata.txt')
        if [ "$response" -ne 200 ]; then
            echo "can not download deflidata.txt from github: HTTP error code $response"
            exit 3
        fi
    else
        stationName=$(get_value "FEEDER_NAME")
        stationUuid=$(get_value "ULTRAFEEDER_UUID")
        latitude=$(get_value "FEEDER_LAT")
        longitude=$(get_value "FEEDER_LONG")
        altitudeMeters=$(get_value "FEEDER_ALT_M")
        timezone=$(get_value "FEEDER_TZ")
    fi

    zonefile="$folder/zone1970.tab"
    if ! [ -f "$zonefile" ]; then
        response=$(curl -o $zonefile --write-out "%{http_code}" 'https://raw.githubusercontent.com/eggert/tz/main/zone1970.tab')
        if [ "$response" -ne 200 ]; then
            echo "can not download zone1970.tab from github: HTTP error code $response"
            exit 3
        fi
    fi

    #Update the template content with required fields
    echo "Choose a name for this station"
    echo "Do not use special chars"
    stationName=$(prompt_with_default "Station Name" "$stationName")


    echo "Enter the GS ID of this station (get it from your defli wallet)"
    echo "For your first GS, you can find it there: https://defli-wallet.com/gs1"
    echo "(ex: b2b2b2b2-1111-2222-3333-4c4c4c4c4c4c)"
    echo ""
    echo "Warning: Any project can be a SCAM."
    echo "Do your own research."
    echo ""
    echo "Things to find out:"
    echo "- is the company officially registered ?"
    echo "- is the owner profile real ?"
    echo "- have you seen any picture of what you are buying / have baught ?"
    echo ""
    echo "Verify before you buy anything. Otherwise in the end you'll have only your eyes to cry."
    echo "You are warned."
    echo ""
    echo "====================================================="
    echo "WARNING"
    echo "An issue has been detected in the deflidata.txt file"
    echo "which prevents it from sending any data to defli"
    echo ""
    echo "Until Oreo gives better answers, I'm taking down this script"
    echo ""
    echo "You can continue if you want to install wingbits"
    echo "====================================================="
    
    if [ -z "$stationUuid" ]; then
        stationUuid=$(uuidgen)
    fi
    # while true; do
    #     stationUuid=$(prompt_with_default "GD ID" "$stationUuid")
    #     if is_valid_guid "$stationUuid"; then
    #         break;
    #     fi
    #     echo "Invalid GUID. Make sure the format is b2b2b2b2-1111-2222-3333-4c4c4c4c4c4c"
    # done

    echo "Latitude, Longitude and Altitude from sea level of this station in meters"
    echo "can be found on google earth https://earth.google.com/"
    echo "Open Google Earth, center on the location of your antenna."
    echo "The URL will look like @37.13445868,7.96957148,207.72258715a,...."
    echo "The 1st number is the latitude, the 2nd the longitude and the 3rd the altitude from sea level in meters (207.72258715)."

    latitude=$(prompt_with_default "Latitude" "$latitude")
    longitude=$(prompt_with_default "Longitude" "$longitude")
    altitudeMeters=$(prompt_with_default "Altitude (in meters)" "$altitudeMeters")
    altitudeFeet=$(echo "$altitudeMeters * 3.28084" | bc)

    echo "Select your timezone"
    echo "Enter the value of the TZ Identifier column of this table:"
    echo "https://en.wikipedia.org/wiki/List_of_tz_database_time_zones"
    mapfile -t existingTimezones < <(cut -f 3 "$zonefile")
    while true; do
        timezone=$(prompt_with_default "TimeZone" "$timezone")
        if [[ " ${existingTimezones[*]} " == *" $timezone "* ]]; then
            break;
        fi
        echo "Invalid time zone selection. Please choose from the list above."
    done


    #replace data by user value
    sed -i "s/^FEEDER_NAME=.*/FEEDER_NAME=$stationName/" $deflidatafile
    sed -i "s/^ULTRAFEEDER_UUID=.*/ULTRAFEEDER_UUID=$stationUuid/" $deflidatafile
    sed -i "s/^FEEDER_LAT=.*/FEEDER_LAT=$latitude/" $deflidatafile
    sed -i "s/^FEEDER_LONG=.*/FEEDER_LONG=$longitude/" $deflidatafile
    sed -i "s/^FEEDER_ALT_M=.*/FEEDER_ALT_M=$altitudeMeters/" $deflidatafile
    sed -i "s/^FEEDER_ALT_FT=.*/FEEDER_ALT_FT=$altitudeFeet/" $deflidatafile
    sed -i "s|^FEEDER_TZ=.*|FEEDER_TZ=$timezone|" "$deflidatafile"
    sed -i "s|/dev/bus/usb/[0-9]*/[0-9]*|/dev/bus/usb/$bus_number/$device_number|" $deflidatafile

    sed -i "s/^TAR1090_DEFAULTCENTERLAT=.*/TAR1090_DEFAULTCENTERLAT=$latitude/" $deflidatafile
    sed -i "s/^TAR1090_DEFAULTCENTERLON=.*/TAR1090_DEFAULTCENTERLON=$longitude/" $deflidatafile
    sed -i "s/^TAR1090_PAGETITLE=.*/TAR1090_PAGETITLE=$stationName/" $deflidatafile

    sed -i "s/^READSB_LAT=.*/READSB_LAT=$latitude/" $deflidatafile
    sed -i "s/^READSB_LON=.*/READSB_LON=$longitude/" $deflidatafile
    sed -i "s/^READSB_ALT=.*/READSB_ALT=$altitudeMeters/" $deflidatafile

    echo ""
    echo "Summary:"
    echo "Station Name: $stationName"
    echo "Lat/Lon/Alt: $latitude / $longitude / $altitudeMeters"
    echo "TimeZone: $timezone"
    echo "RTL-SDR port: /dev/bus/usb/$bus_number/$device_number"
    echo ""

    #start VM
    removeContainer ultrafeeder
    $hypervisor run -d --name ultrafeeder --hostname ultrafeeder \
        --restart unless-stopped \
        --device-cgroup-rule 'c 189:* rwm' \
        -p 8080:80 \
        --env-file /mnt/data/defli/deflidata.txt \
        -v /mnt/data/defli/ultrafeeder/globe_history:/var/globe_history \
        -v /mnt/data/defli/ultrafeeder/graphs1090:/var/lib/collectd \
        -v /proc/diskstats:/proc/diskstats:ro \
        -v /dev:/dev:ro \
        --tmpfs /run:exec,size=256M \
        --tmpfs /tmp:size=128M \
        --tmpfs /var/log:size=32M \
        --label=com.centurylinklabs.watchtower.enable=true \
        ghcr.io/sdr-enthusiasts/docker-adsb-ultrafeeder
}

function checkBalenaDocker() {

  if command -v balena &>/dev/null; then   balena_installed=1; else   balena_installed=0; fi
  if command -v docker &>/dev/null; then   docker_installed=1; else   docker_installed=0; fi

  if [[ $docker_installed -eq 0 && $balena_installed -eq 0 ]]; then
      echo "Neither Docker nor Balena are installed. Exiting"
      exit 100;
  elif [[ $balena_installed -eq 1 ]]; then
      echo "balena"
  else
      echo "docker"
  fi
}

function displayQr() {
echo "--------------------------------------"
echo "You liked this script ?"
echo "Send me some crypto tokens :)"
echo ""
 echo "█▀▀▀▀▀█ ▀▀▀▀▄█▄▀  ▄▄▀▄▀▀█ █▀▀▀▀▀█  "
 echo "█ ███ █ ▄▄▄▀▀ ▀█▄█▀ ▀▀ █  █ ███ █  "
 echo "█ ▀▀▀ █ ███  █▄▄▀▄ ▀▄  ▀▄ █ ▀▀▀ █  "
 echo "▀▀▀▀▀▀▀ █▄▀ █ █ ▀▄▀▄█▄█▄▀ ▀▀▀▀▀▀▀  "
 echo "▀▄ ▄█▄▀▀▀█▄▀  ▀█▄█▄ ▄▀▄▄▄█▀█▀█▄▄▀  "
 echo "█ ▄ █ ▀▄ █▀▄██▀▀█ ▀  █▀██ ▄ █▀ █   "
 echo " ▄██▄█▀ █▄▀▀▀▀▄ ▀ ▄▄█▀▄▄▄▀▀▄▀ ▄▀▀  "
 echo "████▄█▀▀█▄ █▄▀██▄██ ▀█▀▀ █▀ ▄█▀█   "
 echo "▄ ▀▀  ▀▀ ▄█▄▀█▄▄▀▀▀▀▄▀▄▄▀▀▀█▀▀ ▄█  "
 echo "▀█  ▀▀▀██▄████▄▀▀█▄ ▄▄▀█    █▀ ▀▄  "
 echo "██▄▀▄▄▀▄█▄ █ ▀▄ ▄ ▀▀▀█▀▀▀▄█▀▀ ▄█▀  "
 echo "  ██▀ ▀▄▄ ▄  ▄▀ ▀▄▀ ███▀█ █ ▄  █▄  "
 echo "▀▀  ▀ ▀ ▄▄█  ▀▀█▀█▀▀▄▀▀▄█▀▀▀█▄█▀▀  "
 echo "█▀▀▀▀▀█ ▀ ▄▄█▀██▄ ▀▄██▀ █ ▀ █      "
 echo "█ ███ █ ▀████▀▀ ▀▄▄█▀▀▄ ███▀█▀▄ ▀  "
 echo "█ ▀▀▀ █  ▀   ▀ █▄█ ▄ █ ▀▄█▀▄▀▄▀    "
 echo "▀▀▀▀▀▀▀ ▀▀  ▀      ▀ ▀  ▀▀   ▀  ▀  "
echo "--------------------------------------"
}

hypervisor=$(checkBalenaDocker)
installDefli
displayQr
#echo "Station IP (for use in defli wallet): $(curl -s https://ipinfo.io/ip)"
echo "finished"
