#!/bin/bash

#Folder in ~ for Blink auth/cred files to be saved
BLINKDIR=".sblink"
#API endpoint
URL="rest.prod.immedia-semi.com"
URL_SUBDOMAIN="prod"
TIMEZONE=":US/Pacific"
#Output directory for videos
OUTPUTDIR="/tmp/"

preReq () {
    if ! [ -x "$(command -v jq)" ]; then
        clear
        echo
        echo "Error: jq package not detected..."
        echo
        echo "     Please install the jq package for your system:"
        echo "           https://stedolan.github.io/jq/ " 
        echo
        exit
    fi
}

banner () {
    echo '                                                                '
    echo '                                                                '
    echo '  .--.--.       ,---,.   ,--,                              ,-.  '
    echo ' /  /    `.   ,`  .`  \,--.`|     ,--,                 ,--/ /|  '
    echo '|  :  /`. / ,---.` .` ||  | :   ,--.`|         ,---, ,--. :/ |  '
    echo ';  |  |--`  |   |  |: |:  : `   |  |,      ,-+-. /  |:  : ` /   '
    echo '|  :  ;_    :   :  :  /|  ` |   `--`_     ,--.`|`   ||  `  /    '
    echo ' \  \    `. :   |    ; `  | |   ,` ,`|   |   |  ,`` |`  |  :    '
    echo '  `----.   \|   :     \|  | :   `  | |   |   | /  | ||  |   \   '
    echo '  __ \  \  ||   |   . |`  : |__ |  | :   |   | |  | |`  : |. \  '
    echo ' /  /`--`  /`   :  `; ||  | `.`|`  : |__ |   | |  |/ |  | ` \ \ '
    echo '`--`.     / |   |  | ; ;  :    ;|  | `.`||   | |--`  `  : |--`  '
    echo '  `--`---`  |   :   /  |  ,   / ;  :    ;|   |/      ;  |,`     '
    echo '            |   | ,`    ---`-`  |  ,   / `---`       `--`       '
    echo '            `----`               ---`-`                         '
    echo '                                                                '  
}

credGet () {
    # Read the cached URL
    URL2=$(cat ~/${BLINKDIR}/url 2>/dev/null)
    if [ ! "${URL2}" == "" ]; then 
        URL=${URL2}
    fi

    # Read the cached auth code
    AUTHCODE=$(cat ~/${BLINKDIR}/authcode 2>/dev/null) 
    AUTHTEST=$(curl -s -H "Host: ${URL}" -H "TOKEN_AUTH: ${AUTHCODE}" --compressed https://${URL}/homescreen | grep -o '\"message\":\".\{0,12\}' | cut -c12-)
    if [ "${AUTHTEST}" == "Unauthorized" ]; then 
        # Create the temp dir if nothing is cached yet
        if [ ! -d ~/${BLINKDIR} ]; then
            mkdir ~/${BLINKDIR}
        fi

        # Enter the creds
        echo null > ~/${BLINKDIR}/authcode
        echo Enter your username \(email\):
        read EMAIL
        echo
        echo Enter your password:
        read -s PASSWORD

        # Auth the creds and cache the authcode
        AUTH=$(curl -s -H "Host: ${URL}" -H "Content-Type: application/json" --data-binary '{ "password" : "'"${PASSWORD}"'", "client_specifier" : "iPhone 9.2 | 2.2 | 222", "email" : "'"${EMAIL}"'" }' --compressed https://${URL}/login )
        # Read the authcode
        AUTHCODE=$(echo $AUTH | grep -o '\"authtoken\":\".\{0,22\}' | cut -c14-)
        echo $AUTHCODE > ~/${BLINKDIR}/authcode
        if [ "${AUTHCODE}" == "" ]; then
            echo "No Authcode received, please check credentials"
            exit
        fi

        # Read the domain, adjust and cache the URL
        SUBDOMAIN=$(echo $AUTH | grep -o '\"region\":{"[^"]\+"' | cut -c12- | grep -o '[[:alnum:]]*')
        URL=${URL/.${URL_SUBDOMAIN}./.${SUBDOMAIN}.}
        echo $URL > ~/${BLINKDIR}/url
    fi

    # Query the network ID
    NETWORKID=$(curl -s -H "Host: ${URL}" -H "TOKEN_AUTH: ${AUTHCODE}" --compressed https://${URL}/networks | grep -o '\"summary\":{\".\{0,6\}' | cut -c13- | grep -o '[[:digit:]]*')
    echo Network ID: ${NETWORKID}
}

theMenu () {
    PS3='What do you want to do? : '
    options=("Download all videos" "Get network information" "Get Sync Module information" \
        "Arm network" "Disarm network" "Get homescreen information" \
        "Get events for network" "Capture a new thumbnail" "Capture a new video" \
        "Get a total on the number of videos" "Get paginated video information" \
        "Unwatched video list" "Get a list of all cameras" "Get camera information" "Get camera sensor information" \
        "Enable motion detection" "Disable motion detection" "Get information about connected devices" \
        "Get information about supported regions" "Get information about system health" "Get information about programs" "Quit")
    select opt in "${options[@]}"
    do
        case $opt in
            "Download all videos")
                echo;echo "Download all videos"
                echo "AUTHCODE = ${AUTHCODE}"
                echo "URL = ${URL}"
                COUNT=$(curl -s -H "Host: ${URL}" -H "TOKEN_AUTH: ${AUTHCODE}" --compressed https://${URL}//api/v2/videos/count | sed -n 's/\"count"\://p' | tr -d '{}')
                echo "Total clips = ${COUNT}"
                COUNT=$(((${COUNT} / 10)+2))
for ((n=0;n<${COUNT};n++)); do
                    VIDEOS=$(curl -s -H "Host: ${URL}" -H "TOKEN_AUTH: ${AUTHCODE}" --compressed https://${URL}//api/v2/videos/page/${n} | jq -c '.[] | { address: .address, id: .id }')
                    for VIDEO in $VIDEOS; do
                        ADDRESS=$(echo $VIDEO | jq -r '.address')
                        ID=$(echo $VIDEO | jq -r '.id')
                        ADDRESS2=$( echo $ADDRESS | sed 's:.*/::' )
                        PAD=$(echo $ADDRESS | tr -dc '_' | awk '{ print length; }')
                        ADDRESS3=$(echo $ADDRESS2 | cut -d '_' -f $(($PAD-4))-99)
                        CAMERA=$(dirname $ADDRESS | xargs basename)
                        DATESTAMP=$(echo $ADDRESS3 | grep -Eo '[0-9]{1,4}' | tr -d '\n' | sed 's/.$//')
                        DATESTAMP2=$( TZ=${TIMEZONE} date -j -f %Y%m%d%H%M%z ${DATESTAMP}+0000 +%Y%m%d%H%M )
                        ADDRESS3_FILENAME="${ADDRESS3%.*}"
                        ADDRESS3_EXTENSION="${ADDRESS3##*.}"
                        ADDRESS4=${ADDRESS3_FILENAME}-${CAMERA}
                        ADDRESS5=${ADDRESS4}-${ID}.${ADDRESS3_EXTENSION}
                        
                        ls ${OUTPUTDIR}/${ADDRESS5} &> /dev/null
                        if ! [ $? -eq 0 ]; then
                            echo "Downloading ${ADDRESS5} to ${OUTPUTDIR} with timestamp ${DATESTAMP}"
                            # download the file
                            curl -s -H "Host: ${URL}" -H "TOKEN_AUTH: ${AUTHCODE}" --compressed https://${URL}/${ADDRESS} > ${OUTPUTDIR}/${ADDRESS5}
                            # touch the file so it appears with the right datestamp
                            TZ=UTC touch -a -m -t ${DATESTAMP2} ${OUTPUTDIR}/${ADDRESS5}
                            # Print in green
                            tput setaf 2
                            echo "[ ** ${ADDRESS5} is new! ** ]"
                            # Print back in black
                            tput sgr0
                        fi
                    done 
                done
                echo "Download complete. Your videos can be found here: ${OUTPUTDIR}"
                exit
                ;;
            "Get network information")
                echo;echo "Get network information"
                CALL="/networks"
                SWITCH=""
                JQ=true
                break
                ;;
            "Get Sync Module information")
                echo;echo "Get Sync Module information"
                CALL="/network/${NETWORKID}/syncmodules"
                SWITCH=""
                JQ=true
                break
                ;;
            "Arm network")
                echo;echo "Arm network ${NETWORKID}"
                CALL="/network/${NETWORKID}/arm"
                SWITCH="--data-binary"
                JQ=true
                break
                ;;
            "Disarm network")
                echo;echo "Disarm network ${NETWORKID}"
                CALL="/network/${NETWORKID}/disarm"
                SWITCH="--data-binary"
                JQ=true
                break
                ;;
            "Get homescreen information")
                echo;echo "Get homescreen information"
                CALL="/homescreen"
                SWITCH=""
                JQ=true
                break
                ;;
            "Get events for network")
                echo;echo "Get events for network ${NETWORKID}"
                CALL="/events/network/${NETWORKID}"
                SWITCH=""
                JQ=true
                break
                ;;
            "Capture a new thumbnail")
                curl -s -H "Host: ${URL}" -H "TOKEN_AUTH: ${AUTHCODE}" --compressed https://${URL}/network/${NETWORKID}/cameras | jq '.' | grep -E '"name"|"id"'
                echo "Please enter the camera's ID number:"
                read CAMERAID
                echo "Capture a new thumbnail from camera ${CAMERAID}"
                CALL="/network/${NETWORKID}/camera/${CAMERAID}/thumbnail"
                SWITCH="--data-binary"
                JQ=true
                break
                ;;
            "Capture a new video")
                curl -s -H "Host: ${URL}" -H "TOKEN_AUTH: ${AUTHCODE}" --compressed https://${URL}/network/${NETWORKID}/cameras | jq '.' | grep -E '"name"|"id"'
                echo "Please enter the camera's ID number:"
                read CAMERAID
                echo "Capture a new video from camera ${CAMERAID}"
                CALL="/network/${NETWORKID}/camera/${CAMERAID}/clip"
                SWITCH="--data-binary"
                JQ=true
                break
                ;;
            "Get a total on the number of videos")
                echo;echo "Get a total on the number of videos"
                CALL="/api/v2/videos/count"
                SWITCH=""
                JQ=true
                break
                ;;
            "Get paginated video information")
                echo;echo "Get paginated video information"
                COUNT=$(curl -s -H "Host: ${URL}" -H "TOKEN_AUTH: ${AUTHCODE}" --compressed https://${URL}//api/v2/videos/count | sed -n 's/\"count"\://p' | tr -d '{}')
                COUNT=$(((${COUNT} / 10)+2))
                for ((n=0;n<${COUNT};n++)); do
                    curl -s -H "Host: ${URL}" -H "TOKEN_AUTH: ${AUTHCODE}" --compressed https://${URL}//api/v2/videos/page/${n} | jq -C
                done
                exit
                ;;
            "Unwatched video list")
                echo;echo "Get a list of unwatched videos"
                CALL="/api/v2/videos/unwatched"
                SWITCH=""
                JQ=true
                break
                ;;
            "Get a list of all cameras")
                echo;echo "Get a list of all cameras"
                CALL="/network/${NETWORKID}/cameras"
                SWITCH=""
                JQ=true
                break
                ;;
            "Get camera information")
                curl -s -H "Host: ${URL}" -H "TOKEN_AUTH: ${AUTHCODE}" --compressed https://${URL}/network/${NETWORKID}/cameras | jq '.' | grep -E '"name"|"id"'
                echo "Please enter the camera's ID number:"
                read CAMERAID
                echo "Get information for camera ${CAMERAID}"
                CALL="/network/${NETWORKID}/camera/${CAMERAID}"
                SWITCH=""
                JQ=true
                break
                ;;
            "Get camera sensor information")
                curl -s -H "Host: ${URL}" -H "TOKEN_AUTH: ${AUTHCODE}" --compressed https://${URL}/network/${NETWORKID}/cameras | jq '.' | grep -E '"name"|"id"'
                echo "Please enter the camera's ID number:"
                read CAMERAID
                echo "Get camera sensor information for camera ${CAMERAID}"
                CALL="/network/${NETWORKID}/camera/${CAMERAID}/signals"
                SWITCH=""
                JQ=true
                break
                ;;
            "Enable motion detection")
                curl -s -H "Host: ${URL}" -H "TOKEN_AUTH: ${AUTHCODE}" --compressed https://${URL}/network/${NETWORKID}/cameras | jq '.' | grep -E '"name"|"id"'
                echo "Please enter the camera's ID number:"
                read CAMERAID
                echo "Enable motion detection for camera ${CAMERAID}"
                CALL="/network/${NETWORKID}/camera/${CAMERAID}/enable"
                SWITCH="--data-binary"
                JQ=true
                break
                ;;
            "Disable motion detection")
                curl -s -H "Host: ${URL}" -H "TOKEN_AUTH: ${AUTHCODE}" --compressed https://${URL}/network/${NETWORKID}/cameras | jq '.' | grep -E '"name"|"id"'
                echo "Please enter the camera's ID number:"
                read CAMERAID
                echo "Disable motion detection for camera ${CAMERAID}"
                CALL="/network/${NETWORKID}/camera/${CAMERAID}/disable"
                SWITCH="--data-binary"
                JQ=true
                break
                ;;
            "Get information about connected devices")
                echo;echo "Get information about connected devices"
                CALL="/account/clients"
                SWITCH=""
                JQ=true
                break
                ;;
            "Get information about supported regions")
                echo;echo "Get information about supported regions"
                CALL="/regions"
                SWITCH=""
                JQ=true
                break
                ;;
            "Get information about system health")
                echo;echo "Get information about system health"
                CALL="/health"
                SWITCH=""
                JQ=false
                break
                ;;
            "Get information about programs")
                echo;echo "Get information about programs"
                CALL="/api/v1/networks/${NETWORKID}/programs"
                SWITCH=""
                JQ=true
                break
                ;;
            "Quit")
                exit
                ;;
            *) echo invalid option;;
        esac
    done
}

while [ true ]; do

    preReq;credGet;banner;theMenu

    if [ ${JQ} == true ]; then
        clear
        echo
        curl -s -H "Host: ${URL}" -H "TOKEN_AUTH: ${AUTHCODE}" ${SWITCH} --compressed https://${URL}${CALL} | jq -C
        echo
        echo
    else 
        clear
        echo
        curl -s -H "Host: ${URL}" -H "TOKEN_AUTH: ${AUTHCODE}" ${SWITCH} --compressed https://${URL}${CALL}
        echo
        echo
    fi

    read -p "Press any key..."
    clear

done
