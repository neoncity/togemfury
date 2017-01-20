#!/bin/bash

while [[ $# -gt 1 ]]
do
    key="$1"

    case $key in
        -s|--src_root)
            SRC_ROOT="$2"
            shift # past argument
            ;;
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

if [[ -z ${SRC_ROOT} ]]
then
    SRC_ROOT=lib/src
fi

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

# Skip `npm pack` and do the archiving ourselves. Include only the bare minimum and use a flater directory structure so imports will be easy.

## Deep bash magick.
PACKAGE_NAME=$(cat package.json | grep name | head -1 | awk -F: '{ print $2 }' | sed 's/[@",]//g' | sed 's|[/]|-|g' | sed 's/ //g')
PACKAGE_VERSION=$(cat package.json | grep version | head -1 | awk -F: '{ print $2 }' | sed 's/[",]//g' | sed 's/ //g')
PACKAGE="$PACKAGE_NAME-$PACKAGE_VERSION.tgz"

mkdir __work__
cp package.json __work__
cp README.md __work__
cp -r ${SRC_ROOT}/* __work__
cd __work__
tar -cvzf ${PACKAGE} *
cd ..
mv __work__/${PACKAGE} .
rm -rf __work__

curl -s -F package=@${PACKAGE} https://${GEMFURY_API_KEY}@push.fury.io/${GEMFURY_USER}/ > result
if [ -z "$(grep -e ok result)" ]
then
    rm result
    exit 1
fi
rm result
