#!/bin/bash
#import wcms dump
if [ $# -ne 1 ]
then
        echo "Usage : $0 '<format-file-name.txt>'"
        exit 1;
fi
if [[ ! -f $1 ]]
then
        echo "$(date) :: ERROR :: $1 file does not exists...!";
        echo "$(date) :: ERROR :: Please verify, you have given correct file..."
        exit 1;
fi

PREFIX="wcms_"
DATABASE="egov_uat_db"
USERNAME="egov_uat"
DUMPDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SOURCE_FILE=$1
if [ ! -d "${HOME}/pg_backup" ]
then
        mkdir ${HOME}/pg_backup
fi

[[ ! -s ${SOURCE_FILE} ]] && ( echo "$(date) :: ERROR :: ${SOURCE_FILE} is empty..!" && exit 1)
cd $DUMPDIR;
ulb_list=`cat $SOURCE_FILE`

while IFS=: read -r schema_name DUMP  || [[ -n "$line" ]]; 
do
        DUMP_FILE=`echo $DUMP | tr -d '[[:space:]]' |tr '\n' ' '`
        if [[ !  -z ${schema_name} && ! -z ${DUMP_FILE} ]]
        then
                echo "$(date) ::  Backing up exixting  schema' ${PREFIX}${schema_name}' ...!!!"
                export WCMS_SCHEMA_NAME=${PREFIX}${schema_name} && pg_dump -h localhost -U postgres --no-password --no-owner -p 5432 -d $DATABASE -F c -f "${HOME}/pg_backup/${WCMS_SCHEMA_NAME}_$(date +%d%h%y_%H%M).backup" --schema $WCMS_SCHEMA_NAME
                echo "$(date) :: Preparing to import for '${PREFIX}${schema_name}' from $DUMP ...!!!"
psql -h localhost -U postgres -d $DATABASE << EOF
set search_path to ${PREFIX}${schema_name};
DROP SCHEMA ${PREFIX}${schema_name} CASCADE;
CREATE SCHEMA ${PREFIX}${schema_name} AUTHORIZATION $USERNAME;
EOF
                pg_restore  ${DUMPDIR}/${DUMP_FILE} | sed -e "s/public/${PREFIX}${schema_name}/g" | psql -h localhost -U $USERNAME --no-password -p 5432 -d $DATABASE -n ${PREFIX}${schema_name}
else
        [[  -z ${schema_name} && -z ${DUMP} ]] && echo "ULB name and filename empty";
        [[ -z ${schema_name} && ! -z ${DUMP} ]] && echo "$(date) :: ERROR :: Found empty ULB name for ${DUMP}..! "  ||  ( [[ ! -z ${schema_name} && -z ${DUMP} ]] && echo -e "$(date) :: ERROR :: [ ${schema_name} ] - Found empty DUMP Filename..! "  )
fi
done < "$1"

