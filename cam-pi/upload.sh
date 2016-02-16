#!/bin/bash

# upload.sh
#
# Uploads files to SoftLayer object storage.
#
# If executed with no arguments, presumes uploading in bulk all the locally stored images.
# If executed with 1 or more arguments, presumes it was executed from cam.rb and it is to 
# upload the current weather.jpg.

source ~/.openstack-creds

# Configuration
MEMORY_STORAGE=/var/tmp
RESIDENT_STORAGE=$HOME/weather-cam-tmp

# Main routine
: ${BUCKET=`date +%Y-%j`}
DATE_STAMP=`date +%Y-%m-%d-%H-%M-%S`
mkdir -p $RESIDENT_STORAGE/$BUCKET

if [[ $# -eq 0 ]] ; then

  echo "Upload Mode: Batch"
  sleep 60 # Wait until last photo has been taken and saved locally.
 
  for FILE_PATH in $RESIDENT_STORAGE/$BUCKET/* ; do
    FILE=`basename "$FILE_PATH"`
    echo "Uploading $FILE_PATH to $FILE in $BUCKET"

    until timeout 20s swift upload weather-cam-$BUCKET $FILE_PATH --object-name $FILE --skip-identical; do
      echo "Upload of $FILE failed... Exit code: $?. Retry..."
    done

    rm $FILE_PATH
  done

else

  echo "Upload Mode: weather.jpg"
  FILE=$RESIDENT_STORAGE/$BUCKET/$DATE_STAMP.jpg
  mv $MEMORY_STORAGE/weather-$1.jpg $FILE
  timeout 25s swift upload weather-cam $FILE --object-name weather.jpg &
  
fi