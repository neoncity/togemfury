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

# Skip standard  `npm pack` and do the archiving ourselves. Include only the bare minimum and use a flater directory structure so imports will be easy.

PACKAGE_NAME=$($(npm bin)/json -f package.json name | sed 's/[@",]//g' | sed 's|[/]|-|g' | sed 's/ //g')
PACKAGE_VERSION=$($(npm bin)/json -f package.json version | sed 's/[", ]//g')
PACKAGE="$PACKAGE_NAME-$PACKAGE_VERSION.tgz"

mkdir __work__
cp package.json __work__
cp README.md __work__
cp -r ${SRC_ROOT}/* __work__
cd __work__
for f in `ls`
do
    ../node_modules/.bin/json -q -I -f package.json -e "this.files.push(\"${f}\")"
done
npm pack
cd ..
mv __work__/${PACKAGE} .
rm -rf __work__

curl -s  -F package=@${PACKAGE} https://${GEMFURY_API_KEY}@push.fury.io/${GEMFURY_USER}/ > result
if [ -z "$(grep -e ok result)" ]
then
    rm ${PACKAGE}
    rm result
    exit 1
fi
rm ${PACKAGE}
rm result
