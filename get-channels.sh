#!/bin/bash

if [ "$1" = "" ]; then
	echo "Usage $0 IP port dest_dir"
	exit 1
else
	IP=$1
fi

if [ "$2" = "" ]; then
	port=9981
else
	port=$2
fi

if [ "$3" = "" ]; then
	dest_dir="/var/lib/minidlna-tvheadend/services"
else
	dest_dir=$3
fi

tag_count=$(curl -s http://${IP}:${port}'/api/channeltag/grid?limit=0' | jq -r '.total')
uuid_tag_radio=$(curl -s http://${IP}:${port}'/api/channeltag/grid?limit='$tag_count | jq -r '.entries[] | select (.name == "Radio") | .uuid')
uuid_tag_tv=$(curl -s http://${IP}:${port}'/api/channeltag/grid?limit='$tag_count | jq -r '.entries[] | select (.name == "TV channels") | .uuid')

channel_count=$(curl -s http://${IP}:${port}'/api/channel/grid?limit=0' | jq -r '.total')

if [[ -n ${channel_count} ]]; then
	for ((channel=0;channel<${channel_count};channel++)); do
		rx_buf=$(curl -s http://${IP}:${port}'/api/channel/grid?start='${channel}'&limit=1')
		name=$(echo ${rx_buf} | jq -r '.entries[].name')
		uuid=$(echo ${rx_buf} | jq -r '.entries[].uuid')
		tags=$(echo ${rx_buf} | jq -r '.entries[].tags[]')

		# if this is a radio channel
		if $(echo ${tags} | grep -q ${uuid_tag_radio}); then
			if [ ! -f "${dest_dir}/Live TV/${uuid}.url" ]; then
				echo "${name}" > "${dest_dir}/Live Radio/${uuid}.url"
			else
				echo "${dest_dir}/Live Radio/${uuid}.url already exists"
			fi

		# if this is a tv channel
		elif $(echo ${tags} | grep -q ${uuid_tag_tv}); then
			if [ ! -f "${dest_dir}/Live TV/${uuid}.url" ]; then
				echo "${name}" > "${dest_dir}/Live TV/${uuid}.url"
			else
				echo "${dest_dir}/Live TV/${uuid}.url already exists"
			fi
		fi
	done
fi

