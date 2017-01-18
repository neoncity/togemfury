#!/bin/bash

while [[ $# -gt 1 ]]
do
    key="$1"

    case $key in
        -u|--user)
            GEMFURY_USER="$2"
            shift # past argument
            ;;
        -a|--api_key)
            GEMFURY_API_KEY="$2"
            shift # past argument
            ;;
        *)
            # unknown option
            ;;
    esac
    shift # past argument or value
done

if [[ -z ${GEMFURY_USER} ]]
then
    echo 'Need the --user argument'
    exit 1
fi

if [[ -z ${GEMFURY_API_KEY} ]]
then
    echo 'Need the --api_key argument'
    exit 1
fi

npm pack
curl -s -F package=@`ls ${GEMFURY_USER}-*.tgz` https://${GEMFURY_API_KEY}@push.fury.io/${GEMFURY_USER}/ > result
if [ -z "$(grep -e ok result)" ]
then
    rm result
    exit 1
fi
rm result
