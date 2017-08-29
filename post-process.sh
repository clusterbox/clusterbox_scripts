#!/bin/sh

exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>/config/rclone-trigger.log 2>&1

while getopts c: option
do
 case "${option}"
 in
 c) CONTAINER=${OPTARG};;
 esac
done

echo "Container we're curling $CONTAINER"
echo "Sonarr path $sonarr_episodefile_relativepath"
echo "Radarr path $radarr_moviefile_relativepath"

if [ ${sonarr_episodefile_relativepath} ]; then
    curlCmd="curl -G '$CONTAINER' --data-urlencode 'folder=$sonarr_episodefile_relativepath'"
elif [ ${radarr_moviefile_relativepath} ]; then
    curlCmd="curl -G '$CONTAINER' --data-urlencode 'folder=$radarr_moviefile_relativepath'"
else
    curlCmd="curl -G '$CONTAINER'"
fi

eval "curl -i $curlCmd"

exit
