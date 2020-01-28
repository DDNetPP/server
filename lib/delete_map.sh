#!/bin/bash
# ChillerDraon's map unrelease script

function get_date {
  date "+%F %H:%M:%S"
}

if (( $# != 1 ))
then
    echo "Usage: $0 <SQLPassword>"
    exit
fi

echo "Map will be released now: $(get_date)"
read -rp "MapName: " MapName

echo "Is the input correct and do you really want to add that map? [y/N]"
read -n 1 -rp "" inp
echo ""
if ! [[ $inp =~ ^[Yy]$ ]]
then
    echo "Cancelled map deletion."
    exit
fi

read -rd '' sql << EOF
    DELETE FROM \`record_maps\` WHERE Map = '$MapName';
EOF

echo "$sql" | mysql -u bbnet -p$1 bbnet
./lib/list_maps.sh "$1"

