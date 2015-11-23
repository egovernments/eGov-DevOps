#!/bin/bash
#Push DB dump to S3 bucket
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source ${DIR}/s3.properties
DATE="$(date +%d%h%y_%H%M)"
CUSTOMER=`echo ${customer_name} | tr '[:lower:]' '[:upper:]'`
subject="[ AWS ${CUSTOMER} ${environment_name} Database ]"
log_file="dumpsync_$(date +%d%h%y).log"
exec &> >(tee -a "$log_file")
olderthan="10 days"
DEBUG=0
####################################
# DO NOT EDIT
####################################
if [ $DEBUG -eq 0 ]
then 
	[[ -z ${environment_name} ]] && ( echo "ENVIRONMENT not set on properties...!" && exit 1 )
	[[ -z ${customer_name} ]] && ( echo "CUSTOMER not set on properties...!" && exit 1 )
	[[ -z ${bucket_path} ]] && ( echo "S3 BUCKET not set on properties...!" && exit 1 )
	[[ -z ${dump_root_path} ]] && ( echo "Backup dump path not set on properties...!" && exit 1 )
	[[ -z ${export_user} ]] && ( echo "Export user not set on properties...!" && exit 1 )
	[[ -z ${database_name} ]] && ( echo "Databse name not set on properties...!" && exit 1 )
	[[ -z ${schema_name} ]] && ( echo "Schame name not set on properties...!" && exit 1 )

	if [ -z ${schema_name} ]
	then
	    echo "SCHEMA not mentioned in property file."
	    exit 1;
	elif [ "${schema_name}" == "all" ]
	then 
	    SCHEMA_LIST=`psql -t -U ${export_user} --no-password -h localhost -d ${database_name} -c "select schema_name from information_schema.schemata;" | sed -e 's/ //g' | tr "\n" " "`
	else
	    SCHEMA_LIST=`echo ${schema_name} | tr "," " "`
	fi
	echo "$(date)  :  Preparing schema list to backup"

	for SCHEMA in ${SCHEMA_LIST}
	do
	    echo "$(date)  :  Archiving the '$SCHEMA' schema to ${dump_root_path}"
	    export SCHEMA_NAME=$SCHEMA && pg_dump -h localhost -U ${export_user} --no-password --no-owner -p 5432 -d ${database_name} -F c -f "${dump_root_path}/${SCHEMA_NAME}_${DATE}.backup" --schema $SCHEMA_NAME
	done

	aws s3 sync ${dump_root_path} s3://${bucket_path}
	[ $? -eq 0 ] && status="success" || status="failed"
	echo | /usr/bin/mutt -e "set content_type=text/html" -s "${subject} - Dump upload ${status}" ${to_list} 
	find ${dump_root_path} -type f -mtime +2 -exec rm {} \;
fi
###########################################################################

s3cmd ls s3://${bucket_path}/ | grep " DIR " -v | grep "\.backup" | while read -r line;
  do
    createDate=`echo $line|awk {'print $1" "$2'}`
    createDate=`date -d"$createDate" +%s`
    olderThan=`date -d"-${olderthan}" +%s`

    if [[ $createDate -lt $olderThan ]]
      then 
        fileName=`echo $line|awk {'print $4'}`
        echo $fileName
        if [[ $fileName != "" ]]
        then
            s3cmd del "$fileName"
        fi
    fi
  done;

