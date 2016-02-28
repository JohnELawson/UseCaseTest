#!/bin/bash
# Database update script
# Written by John Lawson on 27th Feb 2016
echo -e  "\nDatabase Upgrade Script\n"

dbUser="root"
dbPasswd="rootpw"
sqlFiles[0]=""
sqlFileDir=`pwd`
fileDirLen=$((${#sqlFileDir}+1))

#loop files and folders in sql file dir
endPointer=0
minPointer=0
for item in "$sqlFileDir"/*; do
  #if item is a file
  if [ -f "$item" ]; then
    #if file name matches '123.text.sql'
    if [[ $item =~ [0-9]+\.?[a-z]+\.sql$ ]]; then
      #add file name to array
      sqlFiles[$endPointer]=$item
      endPointer=$(($endPointer+1))
    fi
  fi
done

#exit script if no files were found
if [ "$endPointer" = 0 ]; then
 echo -e "\nNo matching sql files found in $sqlFileDir\nExiting."
 exit
fi

#sort sql file array to lowest first
sorted=0
file=0
swap=""
swapped=1
#while not sorted
while [ $sorted = 0 ]; do
  #loop through array
  while [ "$file" -lt "$endPointer" ]; do
    #check weve not reached the end of the array
    if [ "$(($file+1))" -lt "$endPointer" ]; then
      #check if the next element is larger
      if [ "$(echo ${sqlFiles[$file]:$fileDirLen}| egrep -o '[0-9]+')" -gt "$(echo ${sqlFiles[$(($file+1))]:$fileDirLen}| egrep -o '[0-9]+')" ]; then
        #swap them
        swap=${sqlFiles[$file]}
        sqlFiles[$file]=${sqlFiles[$(($file+1))]}
        sqlFiles[$(($file+1))]=$swap
        swapped=1
      fi
    fi
    file=$(($file+1))
  done
  #if none were swapped then array is sorted
  if [ "$swapped" = 0 ]; then
    sorted=1
  fi
  file=0
  swapped=0
done

#print out sql files that can be used in the update
echo "The following sql update files were found in $sqlFileDir:"
for file in "${sqlFiles[@]}"; do
  echo ${file:$fileDirLen}
done

#find current database version 
databaseVersion=`mysql --user=$dbUser --password=$dbPasswd -D"dbversion" -se "SELECT MAX(version) FROM installed"`
echo -e "\nCurrent database version: $databaseVersion"

#loop over sql scripts
updated=0
for file in "${sqlFiles[@]}"; do
  #get script version from name
  scriptVersion=$(echo ${file:$fileDirLen} | egrep -o '[0-9]+')
  #if script version is higher than dv version; execute
  if [ "$scriptVersion" -gt "$databaseVersion" ]; then
    echo "Executing script: $file"
    mysql --user=$dbUser --password=$dbPasswd < $file
    #update db version
    mysql --user=$dbUser --password=$dbPasswd -D"dbversion" -se "INSERT INTO installed (version, date) VALUES ('$scriptVersion', CURRENT_TIMESTAMP)"
    #update script dv versioni
    databaseVersion=`mysql --user=$dbUser --password=$dbPasswd -D"dbversion" -se "SELECT MAX(version) FROM installed"`
    #check if any scripts executed
    updated=1
  fi
done

#if no scripts were executed
if [ $updated = 0 ]; then
  echo -e "\nDatabase is up to date! No scripts were executed. Exiting. "
else
  echo -e "\nThe database version is now: $databaseVersion\nFinished database update script."
fi
