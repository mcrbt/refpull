#!/bin/bash

## refpull - download remote files by hyperlinks from ASCII file
## Copyright (C) 2018 Daniel Haase
##
## This program is free software: you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation, either version 3 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program. If not, see <http://www.gnu.org/licenses/gpl.txt>.

EXEC=$(basename $0)
DIR=$(TZ=Europe/Berlin date +%y%m%d%H%M%S)
RENAME=0
VRBSLVL=2
TAR=0
CLEAN=0
RNCNT=0
FILE=""
CNT=0

function print_usage
{
	echo ""
	echo "usage: $EXEC [-d <dirname>] [-r | -o] [-t] [-e] [-c] [-v | -s | -q] <hyperlink-file>"
	echo "       $EXEC [-h]"; echo ""
	echo "  -d <dirname>"
	echo "    download files to <dirname> (default <dirname> is a date string)"
	echo "  -r | --rename"
	echo "    rename files by increasing numbers (1.jpg, 2.jpg, ...)"
	echo "  -o"
	echo "    rename files by an obfuscation of their original name"
	echo "    (requires program \"obfuscate\")"
	echo "  -t"
	echo "    use tar to archive files after download"
	echo "  -e"
	echo "    encrypt generated tar archive; implies -t"
	echo "  -c"
	echo "    remove single downloaded files after archiving"
	echo "    remove tar archive after encrypting"
	echo "  -v"
	echo "    be verbose (the default)"
	echo "  -s"
	echo "    do not be verbose and only print success message with number of"
	echo "    downloaded files when finished"
	echo "  -q"
	echo "    like --summary but also suppress success message"
	echo "  -h"
	echo "    print this help message and exit"; echo ""
	echo "note:  long options are not supported"
	echo "       if conflicting arguments are given the latter ones take effect"
	echo "       files/directories are never overridden"; echo ""
	exit $1
}

function print_config
{
	echo "VRBSLVL: $VRBSLVL"
	echo "RENAME:  $RENAME"
	echo "TAR:     $TAR"
	echo "CLEAN:   $CLEAN"
	echo "DIR:     $DIR"
	echo "FILE:    $FILE"
	exit 0
}

function parse_args
{
	if [ $# -eq 0 ]; then print_usage 0; fi

	while true; do
		if [ "$1" == "" ]; then break
		elif [ "$1" == "-d" ]; then
			if [ "$2" == "" ]; then print_usage 1
			elif [[ ${2:0:1} == "-"* ]]; then print_usage 1
			else DIR=$2; shift; shift; fi
		elif [[ ${1:0:1} == "-" ]]; then
			if [[ $1 == *"h"* ]]; then print_usage 0; fi
			if [[ $1 == *"r"* ]]; then RENAME=1; fi
			if [[ $1 == *"o"* ]]; then RENAME=2; fi
			if [[ $1 == *"t"* ]]; then TAR=1; fi
			if [[ $1 == *"e"* ]]; then TAR=2; fi
			if [[ $1 == *"c"* ]]; then CLEAN=1; fi
			if [[ $1 == *"v"* ]]; then VRBSLVL=2; fi
			if [[ $1 == *"s"* ]]; then VRBSLVL=1; fi
			if [[ $1 == *"q"* ]]; then VRBSLVL=0; fi
			shift
		else FILE=$1; shift; fi
	done

	if [ "$FILE" == "" ]; then print_usage 1; fi
	#print_config
}

function has_obfuscate
{
	if [ "$(ls . | grep obfuscate)" != "" ]; then echo "1"
	else
		which obfuscate &> /dev/null
		if [ $? -eq 0 ]; then echo "2"
		else echo "0"; fi
	fi
}

function get_cwd_obfuscate_name
{
	if [ "$(ls . | grep obfuscate)" != "" ]; then PROG=$(ls . | grep obfuscate | head -n 1); echo "$PROG"
	else echo ""; fi
}

function obfuscate_filename
{
	NAME=$1
	CON=$(has_obfuscate)

	if [ "$CON" == "0" ]; then echo ""
	else
		obf=""
		if [ "$CON" == "1" ]; then
			OBFEXEC=$(get_cwd_obfuscate_name)
			if [ "$OBFEXEC" != "" ]; then obf=$(perl $OBFEXEC $NAME); fi
		elif [ "$CON" == "2" ]; then obf=$(obfuscate $NAME); fi
		echo "$obf"
	fi
}

parse_args $@
if [ $VRBSLVL -eq 2 ]; then echo "checking required programs..."; fi
which date &> /dev/null
if [ $? -ne 0 ]; then echo "command \"date\" not found on the system"; exit 3; fi
which basename &> /dev/null
if [ $? -ne 0 ]; then echo "command \"basename\" not found on the system"; exit 3; fi
which perl &> /dev/null
if [ $? -ne 0 ]; then echo "command \"perl\" not found on the system"; exit 3; fi
which mkdir &> /dev/null
if [ $? -ne 0 ]; then echo "command \"mkdir\" not found on the system"; exit 3; fi
which wget &> /dev/null
if [ $? -ne 0 ]; then echo "command \"wget\" not found on the system"; exit 3; fi
which ls &> /dev/null
if [ $? -ne 0 ]; then echo "command \"ls\" not found on the system"; exit 3; fi
which wc &> /dev/null
if [ $? -ne 0 ]; then echo "command \"wc\" not found on the system"; exit 3; fi
which rm &> /dev/null
if [ $? -ne 0 ]; then echo "command \"rm\" not found on the system"; exit 3; fi
if [ $TAR -ge 1 ]; then
	which tar &> /dev/null
	if [ $? -ne 0 ]; then echo "command \"tar\" not found on the system"; exit 3; fi
fi
if [ $TAR -eq 2 ]; then
	which gpg &> /dev/null
	if [ $? -ne 0 ]; then echo "command \"gpg\" not found on the system"; exit 3; fi
fi
if [ $RENAME -eq 2 ]; then
	#which obfuscate &> /dev/null
	#if [ $? -ne 0 ]; then echo "command \"obfuscate\" not found on the system"; RENAME=0; fi
	if [ "$(has_obfuscate)" == "0" ]; then echo "no obfuscation program found on the system"; RENAME=0; fi
fi

if [ ! -e $DIR ] || [ ! -d $DIR ]; then mkdir $DIR
else
	TMP=$DIR
	while [ -e $DIR ] && [ -d $DIR ]; do DIR="${TMP}_${RNCNT}"; RNCNT=$((RNCNT + 1)); done
	mkdir $DIR; RNCNT=0
fi

while read LINK; do
	if [[ $LINK != http* ]]; then continue; fi
	NM_ORG=$(echo $LINK | perl -pe 's/.*\/(.*)\s+/\1/' | perl -pe 's/(.+\..+)\?.+/\1/')
	if [ "$NM_ORG" == "" ]; then continue; fi
	EXT="${NM_ORG##*.}"
	if [ ${#EXT} -gt 4 ] || [ ${NM_ORG:0:1} == "?" ]; then continue; fi # echo "skipping \"${NM_ORG}\"..."; continue; fi
	if [ $RENAME -eq 1 ]; then NM_OUT="${CNT}.${EXT}"
	elif [ $RENAME -eq 2 ]; then
		NM_OUT="$(obfuscate_filename $NM_ORG)"
		if [ "$NM_OUT" == "" ]; then NM_OUT="$NM_ORG"; fi
	else NM_OUT="$NM_ORG"; fi
	if [ -e $NM_OUT ] || [ -e "./$DIR/$NM_OUT" ]; then
		STRP=$(echo $NM_ORG | perl -pe 's/(.+)\..+/\1/')
		NM_OUT="${STRP}_${RNCNT}.${EXT}"
		RNCNT=$((RNCNT + 1))
	fi
	CNT=$((CNT + 1))
	if [ $VRBSLVL -eq 2 ]; then echo "downloading file \"${NM_ORG}\"..."; fi
	if [ -e $DIR ] && [ -d $DIR ]; then NM_OUT="./${DIR}/${NM_OUT}"; fi
	wget --quiet --no-dns-cache --no-directories --no-http-keep-alive --no-cookies --output-document=${NM_OUT} ${LINK}
done < "$FILE"

if [ $CNT -eq 0 ]; then
	if [ "$(ls $DIR | wc -l)" == "" ]; then
		if [ $VRBSLVL -eq 2 ]; then echo "removing empty direcotry \"$DIR\"..."; fi
		rmdir $DIR
	fi
fi

if [ $TAR -gt 0 ]; then
	if [ $VRBSLVL -eq 2 ]; then echo "archiving files to $(basename $DIR).txz..."; fi
	tar cJf "$(basename $DIR).txz" $DIR &> /dev/null
	if [ $? -ne 0 ]; then echo "archiving failed"; fi
	if [ $TAR -eq 2 ]; then
		if [ $VRBSLVL -eq 2 ]; then echo "encrypting $(basename $DIR).txz..."; fi
		gpg --cipher-algo AES256 --symmetric $(basename $DIR).txz &> /dev/null
		if [ $? -ne 0 ]; then echo "encryption failed"; fi
	fi

	if [ $CLEAN -eq 1 ]; then
		if [ $TAR -ge 1 ]; then
			if [ -e "$(basename $DIR).txz" ] && [ -f "$(basename $DIR).txz" ]; then
				if [ -e $DIR ] && [ -d $DIR ]; then
					if [ $VRBSLVL -eq 2 ]; then echo "removing $(basename $DIR)..."; fi
					rm -rf $DIR &> /dev/null
					if [ $? -ne 0 ]; then echo "removal of $(basename $DIR) failed"; fi
				fi
			fi
		fi

		if [ $TAR -eq 2 ]; then
			if [ -e "$(basename $DIR).txz.gpg" ] && [ -f "$(basename $DIR).txz.gpg" ]; then
				if [ -e "$(basename $DIR).txz" ] && [ -f "$(basename $DIR).txz" ]; then
					if [ $VRBSLVL -eq 2 ]; then echo "removing $(basename $DIR).txz..."; fi
					rm -f "$(basename $DIR).txz" &> /dev/null
					if [ -$? -ne 0 ]; then echo "removal of $(basename $DIR).txz failed"; fi
				fi
			fi
		fi
	fi
fi

if [ $VRBSLVL -gt 0 ]; then echo "[ ok ] $CNT files downloaded"; fi
exit 0
