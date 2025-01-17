#!/usr/bin/env bash

############### CONFIGURATION ####################

PASSWORD=''
OUTPUTFOLDER=vault
BW_BINARY=~/.nvm/versions/node/v10.16.0/bin/bw

############ END OF CONFIGURATION ################

# Variables used later in script. Not meant to be changed.
SESSIONS=$($BW_BINARY unlock --raw $PASSWORD)
PARENTS=$($BW_BINARY list items --session $SESSIONS --pretty | jq '.[] | select(.attachments)' | grep -o -P '(?<="id": ").*(?=",)' | sed -n -e '/-/{p;n;}')
ATTACHFOLDER=$OUTPUTFOLDER/attachments/
JSONFILE=$OUTPUTFOLDER/vault.json

# Sync Bitwarden to detect any changes done to the vault before exporting
$BW_BINARY sync --session $SESSIONS

# Backup vault (excluding attachments)
$BW_BINARY export $PASSWORD --format json --session $SESSIONS --output $JSONFILE

# Search for items in the vault that contain attachments, then download all attachments in the vault
for P in $PARENTS; do
	ATTACH=$(echo $P $($BW_BINARY get item $P --pretty --session $SESSIONS | jq .attachments | grep -o -P '(?<="id": ").*(?=",)') | awk '{$1=""; print $0}')
	for A in $ATTACH; do
		$BW_BINARY get attachment $A --itemid $P --session $SESSIONS --output $ATTACHFOLDER
		sleep 1
	done
done
rm -f $OUTPUTFOLDER/bitwarden-backup.zip 
zip -r $OUTPUTFOLDER/bitwarden-backup.zip $OUTPUTFOLDER/*
rm -f $JSONFILE
rm -rf $ATTACHFOLDER
