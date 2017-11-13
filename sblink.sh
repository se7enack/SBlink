#!/bin/bash

#Folder in ~ for Blink auth/cred files to be saved
BLINKDIR=".sblink"
#API endpoint
URL="rest.prod.immedia-semi.com"
#Output directory for videos
OUTPUTDIR="clips/"

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
	if [ ! -d ~/${BLINKDIR} ]; then
		mkdir ~/${BLINKDIR}
		echo null > ~/${BLINKDIR}/authcode
		echo Enter your username \(email\):
		read EMAIL
		echo ${EMAIL} > ~/${BLINKDIR}/creds
		echo
		echo Enter your password:
		read -s PASSWORD
		echo ${PASSWORD} >> ~/${BLINKDIR}/creds
	fi
	EMAIL=$(sed -n '1p' ~/${BLINKDIR}/creds)
	PASSWORD=$(sed -n '2p' ~/${BLINKDIR}/creds)
	AUTHCODE=$(cat ~/${BLINKDIR}/authcode)
	AUTHTEST=$(curl -s -H "Host: ${URL}" -H "TOKEN_AUTH: ${AUTHCODE}" --compressed https://${URL}/homescreen | grep -o '\"message\":\".\{0,12\}' | cut -c12-)
	if [ "${AUTHTEST}" == "Unauthorized" ]; then 
		curl -s -H "Host: ${URL}" -H "Content-Type: application/json" --data-binary '{ "password" : "'"${PASSWORD}"'", "client_specifier" : "iPhone 9.2 | 2.2 | 222", "email" : "'"${EMAIL}"'" }' --compressed https://${URL}/login | grep -o '\"authtoken\":\".\{0,22\}' | cut -c14-  > ~/${BLINKDIR}/authcode
		AUTHCODE=$(cat ~/${BLINKDIR}/authcode)
	if [ "${AUTHCODE}" == "" ]; then
		echo "No Authcode received, please check credentials"
		exit
	fi
	fi
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
                rm .sjb* &> /dev/null
                for ((n=0;n<${COUNT};n++)); do
                    curl -s -H "Host: ${URL}" -H "TOKEN_AUTH: ${AUTHCODE}" --compressed https://${URL}//api/v2/videos/page/${n} | sed 's/"/ /g' | sed "s/regexp/\\`echo -e '\n\r'`/g" | tr ' ' '\n' | grep -e mp4 &> .sjb${n}
                done
                for ADDRESS in $( cat .sjb* ); do
                    ADDRESS2=$( echo $ADDRESS | sed 's:.*/::' )
                    PAD=$(echo $ADDRESS | tr -dc '_' | awk '{ print length; }')
                    ADDRESS3=$(echo $ADDRESS2 | cut -d '_' -f $(($PAD-4))-99)
                    DATESTAMP=$(echo $ADDRESS3 | grep -Eo '[0-9]{1,4}' | tr -d '\n' | sed 's/.$//')
                    echo "Downloading ${ADDRESS3} to ${OUTPUTDIR}"
                    ls ${OUTPUTDIR}/${ADDRESS3} &> /dev/null
                    if ! [ $? -eq 0 ]; then
                        curl -s -H "Host: ${URL}" -H "TOKEN_AUTH: ${AUTHCODE}" --compressed https://${URL}/${ADDRESS} > ${OUTPUTDIR}/${ADDRESS3}
                        touch -a -m -t ${DATESTAMP} ${OUTPUTDIR}/${ADDRESS3}
                        tput setaf 2
                        echo "[ ** ${ADDRESS3} is new! ** ]"
                        tput sgr0
                    fi
                done 
                rm .sjb* &> /dev/null 
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
