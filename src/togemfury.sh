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

SAW_README=0
SAW_PACKAGE=0

rm -rf __work__
mkdir __work__
for f in $($(npm bin)/json -f package.json filesPack | $(npm bin)/json -ka)
do
    ACTION_DEST=$($(npm bin)/json -f package.json filesPack[\"${f}\"])
    ACTION=${ACTION_DEST:0:2}
    DEST=${ACTION_DEST:2}
    if [[ ${ACTION} = f: ]]
    then
        if ! [[ -f ${f} ]]
        then
           echo 'Source with f: is not actually a file'
           exit 1
        fi

        if [[ ${f} = "README.md" ]]
        then
            SAW_README=1
        fi

        if [[ ${f} = "package.json" ]]
        then
            SAW_PACKAGE=1
        fi

        mkdir -p __work__/$(dirname ${DEST})
        cp ${f} __work__/$(dirname ${DEST})
    elif [[ ${ACTION} = c: ]]
    then
        mkdir -p __work__/$(dirname ${DEST})
        cp -r ${f} __work__/$(dirname ${DEST})
    elif [[ ${ACTION} = e: ]]
    then
        if ! [[ -d ${f} ]]
        then
            echo 'Source with e: is not actually a directory'
            exit 1
        fi

        mkdir -p __work__/${DEST}
        cp -r ${f}/* __work__/${DEST}
    fi
done

if [[ ${SAW_README} = 0 ]]
then
    echo 'Here'
    cp README.md __work__
fi

if [[ ${SAW_PACKAGE} = 0 ]]
then
    echo 'THere'
    cp package.json __work__
fi

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
