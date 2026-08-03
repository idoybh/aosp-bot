#!/bin/bash

DATA_FILE=/home/ido/aosp-bot/data.txt
CONFIG_FILE=/home/ido/aosp-bot/bot.conf
BOT_TOKEN=$(grep "token = " "${CONFIG_FILE}" | sed 's/token = //')
ALERT_CHAT_IDS_STR=$(grep "alert_chat_ids = " "${CONFIG_FILE}" | sed 's/alert_chat_ids = //')
IFS=',' read -ra ALERT_CHAT_IDS <<< "$ALERT_CHAT_IDS_STR"
MANIFEST_URL="https://android.googlesource.com/platform/manifest"
BUILD_SCRIPT="/home/ido/aosp-bot/build.py"
BUILD_INFO_SCRIPT="/home/ido/aosp-bot/build-info.py"
BULLETIN_SCRIPT="/home/ido/aosp-bot/bulletin.py"
INTERVAL=300

# sends a message in TG
# $1: chat id
# $2: the message
# returns the message ID
send()
{
    local cId=$1
    local MSG
    printf -v MSG '%b' "$2"
    out=$(curl -s -X POST \
        "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
        --data-urlencode "chat_id=${cId}" \
        --data-urlencode "text=${MSG}" \
        --data-urlencode "parse_mode=HTML")
    echo "${out}" | jq -r ".result.message_id"
}

last_tag=$(grep "last_tag=" "${DATA_FILE}" | sed 's/last_tag=//')
last_build=$(grep "last_build=" "${DATA_FILE}" | sed 's/last_build=//')
last_build_info=$(grep "last_build_info=" "${DATA_FILE}" | sed 's/last_build_info=//')
last_bulletin=$(grep "last_bulletin=" "${DATA_FILE}" | sed 's/last_bulletin=//')

cd /home/ido/aosp-bot || exit 1
echo "running"
while true; do

    # AOSP tag
    if [ ! -d "manifest" ]; then
        git clone "${MANIFEST_URL}"
    fi
    pdir=$(pwd)
    cd manifest || exit 1
    git fetch --tags
    tagList=$(git tag --sort=-creatordate)
    cd "$pdir" || exit 1
    newestTag=""
    for tag in $tagList; do
        # of the form android-16.0.0_r1 with only numbers allowed to change
        if [[ $tag =~ ^android-[0-9]+\.[0-9]+\.[0-9]+_r[0-9]+$ ]]; then
            newestTag="$tag"
            break
        fi
    done
    # newer tag detected!
    if [[ $newestTag != "$last_tag" ]] && [[ $newestTag != "" ]]; then
        # notify
        fullVer=$(echo $newestTag | cut -d "-" -f 2)
        ver=$(echo "$fullVer" | cut -d "_" -f 1)
        rev=$(echo "$fullVer" | cut -d "_" -f 2 | sed 's/r//')
        msgTxt="<b>New AOSP tag detected:</b>\n"
        msgTxt="${msgTxt}<code>${newestTag}</code>\n"
        msgTxt="${msgTxt}Ver: <code>${ver}</code>\n"
        msgTxt="${msgTxt}Rev: <code>${rev}</code>\n\n"
        msgTxt="${msgTxt}old: <code>${last_tag}</code>"
        for chat in "${ALERT_CHAT_IDS[@]}"; do
            send "${chat}" "${msgTxt}"
        done
        # save in data
        last_tag="$newestTag"
        sed -i "/^last_tag=/c\\last_tag=${last_tag}" "${DATA_FILE}"
    fi

    # Pixel build
    newestBuild=""
    count=0
    while true; do
        newestBuild=$(python "$BUILD_SCRIPT")
        [[ $count -ge 10 ]] && break
        [[ $newestBuild != "" ]] && break
        (( count++ ))
    done
    # newer build detected!
    if [[ $newestBuild != "$last_build" ]] && [[ $newestBuild != "" ]]; then
        # notify
        oldVer=$(echo "$last_build" | cut -d ";" -f 1)
        oldId=$(echo "$last_build" | cut -d ";" -f 2)
        oldDate=$(echo "$last_build" | cut -d ";" -f 3)
        ver=$(echo "$newestBuild" | cut -d ";" -f 1)
        id=$(echo "$newestBuild" | cut -d ";" -f 2)
        date=$(echo "$newestBuild" | cut -d ";" -f 3)
        link=$(echo "$newestBuild" | cut -d ";" -f 4)
        sha=$(echo "$newestBuild" | cut -d ";" -f 5)
        msgTxt="<b>New husky build detected:</b>\n"
        msgTxt="${msgTxt}<code>${ver}</code> - (<code>${id}</code>, <code>${date}</code>)\n"
        msgTxt="${msgTxt}<a href=\"${link}\">Link</a> (<code>${sha}</code>)\n\n"
        msgTxt="${msgTxt}old: <code>${oldVer}</code> - (<code>${oldId}</code> ; <code>${oldDate}</code>)"
        for chat in "${ALERT_CHAT_IDS[@]}"; do
            send "${chat}" "${msgTxt}"
        done
        # save in data
        last_build="$newestBuild"
        sed -i "/^last_build=/c\\last_build=${last_build}" "${DATA_FILE}"
    fi

    # Build info
    newestBuildInfo=""
    count=0
    while true; do
        newestBuildInfo=$(python "$BUILD_INFO_SCRIPT")
        [[ $count -ge 10 ]] && break
        [[ $newestBuildInfo != "" ]] && break
        (( count++ ))
    done
    # newer build info detected!
    if [[ $newestBuildInfo != "$last_build_info" ]] && [[ $newestBuildInfo != "" ]]; then
        # notify
        oldId=$(echo "$last_build_info" | cut -d ";" -f 1)
        oldTag=$(echo "$last_build_info" | cut -d ";" -f 2)
        oldPatch=$(echo "$last_build_info" | cut -d ";" -f 3)
        id=$(echo "$newestBuildInfo" | cut -d ";" -f 1)
        tag=$(echo "$newestBuildInfo" | cut -d ";" -f 2)
        patch=$(echo "$newestBuildInfo" | cut -d ";" -f 3)
        msgTxt="<b>New build ID detected:</b>\n"
        msgTxt="${msgTxt}<code>${id}</code> - (<code>${tag}</code>, <code>${patch}</code>)\n"
        msgTxt="${msgTxt}old: <code>${oldId}</code> - (<code>${oldTag}</code> ; <code>${oldPatch}</code>)"
        for chat in "${ALERT_CHAT_IDS[@]}"; do
            send "${chat}" "${msgTxt}"
        done
        # save in data
        last_build_info="$newestBuildInfo"
        sed -i "/^last_build_info=/c\\last_build_info=${last_build_info}" "${DATA_FILE}"
    fi

    # Bulletin
    newestBulletin=""
    count=0
    while true; do
        newestBulletin=$(python "$BULLETIN_SCRIPT")
        [[ $count -ge 10 ]] && break
        [[ $newestBulletin != "" ]] && break
        (( count++ ))
    done
    # newer bulletin detected!
    if [[ $newestBulletin != "$last_bulletin" ]] && [[ $newestBulletin != "" ]]; then
        # notify
        oldDate=$(echo "$last_bulletin" | cut -d ";" -f 1)
        oldLink=$(echo "$last_bulletin" | cut -d ";" -f 2)
        date=$(echo "$newestBulletin" | cut -d ";" -f 1)
        link=$(echo "$newestBulletin" | cut -d ";" -f 2)
        msgTxt="<b>New bulletin detected:</b>\n"
        msgTxt="${msgTxt}<a href=\"https://source.android.com${link}\">${date}</a>\n"
        msgTxt="${msgTxt}old: <a href=\"https://source.android.com${oldLink}\">${oldDate}</a>"
        for chat in "${ALERT_CHAT_IDS[@]}"; do
            send "${chat}" "${msgTxt}"
        done
        # save in data
        last_bulletin="$newestBulletin"
        sed -i "/^last_bulletin=/c\\last_bulletin=${last_bulletin}" "${DATA_FILE}"
    fi

    sleep $INTERVAL
done
