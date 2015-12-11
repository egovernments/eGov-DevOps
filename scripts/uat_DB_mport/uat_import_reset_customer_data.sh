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

DATABASE="egov_uat_db"
USERNAME="egov_uat"
DUMPDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SOURCE_FILE=$1
if [ ! -d "${HOME}/prod_db_dumps" ]
then
        mkdir ${HOME}/prod_db_dumps
fi

[[ ! -s ${SOURCE_FILE} ]] && ( echo "$(date) :: ERROR :: ${SOURCE_FILE} is empty..!" && exit 1)
cd $DUMPDIR;
ulb_list=`cat $SOURCE_FILE`

while IFS=: read -r schema_name DUMP  || [[ -n "$line" ]]; 
do
        DUMP_FILE=`echo $DUMP | tr -d '[[:space:]]' |tr '\n' ' '`
        if [[ !  -z ${schema_name} && ! -z ${DUMP_FILE} ]]
        then
psql -h localhost -U $USERNAME -d $DATABASE << EOF
set search_path to ${schema_name};
DROP SCHEMA ${schema_name} CASCADE;
CREATE SCHEMA ${schema_name} AUTHORIZATION $USERNAME;
EOF
                pg_restore  ${DUMPDIR}/${DUMP_FILE} | psql -h localhost -U $USERNAME --no-password -p 5432 -d $DATABASE -n ${schema_name}
psql -h localhost -U $USERNAME -d $DATABASE  << EOF
set search_path to ${schema_name};
update ${schema_name}.eg_city set domainurl = '${schema_name}.egovernments.org';
create  table ${schema_name}.eg_user_temp as select * from ${schema_name}.eg_user;
update ${schema_name}.eg_user set mobilenumber = overlay(mobilenumber placing '0000' from 1 for 4) where mobilenumber is not null;
update ${schema_name}.eg_user set emailid = overlay(emailid placing '***' from 1 for 3) where emailid is not null;
EOF
else
        [[  -z ${schema_name} && -z ${DUMP} ]] && echo "ULB name and filename empty";
        [[ -z ${schema_name} && ! -z ${DUMP} ]] && echo "$(date) :: ERROR :: Found empty ULB name for ${DUMP}..! "  ||  ( [[ ! -z ${schema_name} && -z ${DUMP} ]] && echo -e "$(date) :: ERROR :: [ ${schema_name} ] - Found empty DUMP Filename..! "  )
fi
done < "$1"

