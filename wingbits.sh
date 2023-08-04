
function removeContainer(){
    local container_name=$1

    if $hypervisor container inspect "$container_name" >/dev/null 2>&1; then
        echo "Removing container $containerName";
        $hypervisor rm -f $container_name;
    fi
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

function installWingbits() {

    if [ -z "$DEVICEID" ]; then    
        echo "Enter your Wingbits Device ID (your-wingbits-id)"
        DEVICEID=$(prompt_with_default "Winbits ID" "")
    fi


    if ! $hypervisor network inspect adsbnet >/dev/null 2>&1; then 
        $hypervisor network create adsbnet; 
    fi;
    removeContainer ultrafeeder
    removeContainer vector


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
        --network=adsbnet \
        -e READSB_EXTRA_ARGS='--net-connector vector,30099,json_out' \
        ghcr.io/sdr-enthusiasts/docker-adsb-ultrafeeder;


    folder=/mnt/data/wingbits;
    if [ ! -d $folder ]; then mkdir -p $folder; fi;

    response=$(curl -o $folder/vector.toml --write-out "%{http_code}" 'https://gitlab.com/wingbits/config/-/raw/master/vector.toml')
    if [ "$response" -ne 200 ]; then
        echo "can not download from gitlab: HTTP error code $response"
        exit 1
    fi


    sed -i 's/0.0.0.0:30006/0.0.0.0:30099/g' $folder/vector.toml;


    $hypervisor run -d --name vector \
        --restart unless-stopped \
        -e DEVICE_ID="$DEVICEID" \
        --label=com.centurylinklabs.watchtower.enable=true \
        --network=adsbnet \
        -v /mnt/data/wingbits/vector.toml:/etc/vector/vector.toml:ro \
        timberio/vector:latest-alpine;
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
installWingbits
displayQr
echo "finished"
