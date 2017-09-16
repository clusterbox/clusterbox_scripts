#!/bin/bash

exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>/config/logs/rclone-trigger.log 2>&1

while getopts c: option
do
 case "${option}"
 in
 c) CONTAINER=${OPTARG};;
 esac
done


echo "Container we're curling $CONTAINER" >&3
echo "Sonarr sonarr_episodefile_path $sonarr_episodefile_path" >&3
echo "Radarr path $radarr_moviefile_path" >&3


if [ -n "$sonarr_episodefile_path" ]; then
    echo "passing folder to Sonarr:  $sonarr_episodefile_path" >&3

    rootpath="/storage/tv/"
    sonarr_episodefile_path=${sonarr_episodefile_path#${rootpath}}
    sonarr_episodefile_path=$(dirname "${sonarr_episodefile_path}")
    sonarr_episodefile_path=$(printf %q "${sonarr_episodefile_path}")

    echo "stripped folder path to TV Show: $sonarr_episodefile_path" >&3
    curlCmd="curl -G '$CONTAINER' --data-urlencode 'folder=$sonarr_episodefile_path'"
elif [ -n "$radarr_moviefile_path" ]; then
    echo "passing folder to Radarr:  $radarr_moviefile_path" >&3

    rootpath="/storage/movies/"
    radarr_moviefile_path=${radarr_moviefile_path#${rootpath}}
    radarr_moviefile_path=$(dirname "${radarr_moviefile_path}")
    radarr_moviefile_path=$(printf %q "${radarr_moviefile_path}")

    echo "stripped folder path to movie: $radarr_moviefile_path" >&3
    curlCmd="curl -G '$CONTAINER' --data-urlencode 'folder=$radarr_moviefile_path'"
else
    curlCmd="curl -G '$CONTAINER'"
fi

eval "curl -i $curlCmd"

exit
