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

# Skip standard  `npm pack` and do the archiving ourselves. Include only the bare minimum and use a flater directory structure so imports will be easy.

PACKAGE_NAME=$($(npm bin)/json -f package.json name | sed 's/[@",]//g' | sed 's|[/]|-|g' | sed 's/ //g')
PACKAGE_VERSION=$($(npm bin)/json -f package.json version | sed 's/[", ]//g')
PACKAGE="$PACKAGE_NAME-$PACKAGE_VERSION.tgz"

rm -rf __work__
mkdir __work__
for ((i=0; i < $($(npm bin)/json -f package.json files.length); i+=1))
do
    cp $($(npm bin)/json -f package.json files[$i]) __work__
done
cp package.json __work__ # Always copy package.json
cp README.md __work__ # Always copy README.md
cd __work__
../node_modules/.bin/json -q -I -f package.json -e "this.files = []"
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
