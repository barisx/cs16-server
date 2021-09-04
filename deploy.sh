#!/bin/bash

set -u
set -e

RCON_PASS="$1"
ADMIN="$2"
CNAME="cs16"

RED='\033[0;31m'
NC='\033[0m'

if [[ "$#" -gt "2" ]]
then
    echo "Script only accepts first argument as rcon password and option second argument as the amx admin config to append to users.ini"
    exit -1
fi

for arg in "$@"
do
    if [ "$arg" == "--help" ] || [ "$arg" == "-h" ]
    then
        echo "Script only accepts first argument as rcon password and option second argument as the amx admin config to append to users.ini"
    fi
done

if [[ -z "${RCON_PASS}" ]]
then
    printf "${RED}No RCON password detected or its empty. USING default password, Continuing...\n${NC}"
fi

if [[ ! -z "${ADMIN}" ]]
then
    echo "${ADMIN}" >> users.ini
else
    printf "${RED}No admin config detected. continuing with default users.ini ...\n${NC}"
fi

if [[ $(docker ps -f name=${CNAME} -q | wc -l) -ne "1" ]]
then
    printf "Container named ${CNAME} not found, exiting..."
    exit -1
fi

sed -i "s/rcon_password \"admin\"/rcon_password \"${RCON_PASS}\"/g" server.cfg

docker pull coquinone/counterstrike-1.6:jump && docker stop ${CNAME} && docker rm ${CNAME}

if [[ -f csstats.dat ]]
then
    printf "1"
    docker run -d  --name ${CNAME} --network host -v $(pwd)/users.ini:/home/steam/cs16/cstrike/addons/amxmodx/configs/users.ini -v $(pwd)/server.cfg:/home/steam/cs16/cstrike/server.cfg -v $(pwd)/csstats.dat:/home/steam/cs16/cstrike/addons/amxmodx/data/csstats.dat coquinone/counterstrike-1.6:latest
else
    printf "2"
    docker run -d  --name ${CNAME} --network host -v $(pwd)/users.ini:/home/steam/cs16/cstrike/addons/amxmodx/configs/users.ini -v $(pwd)/server.cfg:/home/steam/cs16/cstrike/server.cfg coquinone/counterstrike-1.6:latest
fi

