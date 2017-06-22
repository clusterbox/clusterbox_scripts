#!/bin/sh

USER=braddavis

exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>./rclone-trigger.log 2>&1

while getopts u: option
do
 case "${option}"
 in
 u) URL=${OPTARG};;
 esac
done

#echo "URL we're curling $URL"
#echo "Sonarr path $sonarr_episodefile_relativepath"
#echo "Radarr path $radarr_moviefile_relativepath"

#if [[ ${sonarr_episodefile_relativepat}h ]]; then
#    curlCmd="curl -G '$URL' --data-urlencode 'path=$sonarr_episodefile_relativepath'"
#elif [[ ${radarr_moviefile_relativepath} ]]; then
#    curlCmd="curl -G '$URL' --data-urlencode 'path=$radarr_moviefile_relativepath'"
#else
#    curlCmd="curl -G '$URL' --data-urlencode 'path=/blah/blah1'"
#fi



echo "Curling rclone container at $URL"
eval "curl -i $URL"

exit
