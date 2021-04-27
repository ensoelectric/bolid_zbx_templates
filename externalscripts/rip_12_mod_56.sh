#!/bin/bash
# rip_12_mod_56.sh

# $1 - protocol://host:port
# $2 - Modbus UID
# $3 - Status register
# $4 - Offset (0 - 6)

# Example of requesting statuses:       ./rip_12_mod_56.sh enc://127.0.0.1:4001 1 40000
# Example value request:                        ./rip_12_mod_56.sh enc://127.0.0.1:4001 1 40000 3

(($# < 3)) && { printf '%s\n' "You have given little data. Command exited with non-zero"; exit 1; }

lockfile=$(echo "$1" | awk -F "://" '{print $2}')

setzone()
{
        modpoll -m $1 -a $4 -r 46181 -0 -1 -c 1 -p $3 $2 $5> /dev/null 2>&1

    (($? != 0)) && { printf '%s\n' "Command exited with non-zero"; exit 1; }

    sleep 0.15
}

getvalue ()
{
        value=$(modpoll -m $1 -a $4 -r 46328 -0 -1 -c 1 -t 4:hex -p $3 $2 |grep ]: |awk '{print $2}')
        printf "%d" $value
}

getstatus ()
{
        status=$(modpoll -m $1 -a $4 -r $5 -1 -c 7 -t 4:hex -p $3 $2 | grep ]: | awk -F "0x" 'BEGIN { printf"["} NR!=7{printf "\""$2"\","} NR==7 {printf "\""$2"\""} END { printf "]"}')
    echo "{ \"status\": $status }"
}

(
        flock -e 200

        protocol=$(echo $1 | awk -F "://" '{print $1}');
        host=$(echo $1 | awk -F "://" '{print $2}' | awk -F ":" '{print $1}')
        port=$(echo $1 | awk -F "://" '{print $2}' | awk -F ":" '{print $2}')
        register=$(($3+1))

        if (($# >= 4)); then
                zone=$(($register+$4-40000))

                setzone $protocol $host $port $2 $zone

                echo $(getvalue $protocol $host $port $2)

                sleep 0.15

                exit 0
        fi

        echo $(getstatus $protocol $host $port $2 $register)

        sleep 0.15;

) 200> /tmp/$lockfile