#!/bin/bash
##
## refpull - download remote files by hyperlinks from ASCII file
## Copyright (C) 2018, 2020 Daniel Haase
##
## This file is part of refpull.
##
## refpull is free software: you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation, either version 3 of the License, or
## (at your option) any later version.
##
## refpull is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with refpull. If not, see <http://www.gnu.org/licenses/gpl.txt>.
##

TITLE="refpull"
VERSION="0.2.1"
AUTHOR="Daniel Haase"
COPYRIGHT="copyright (c) 2018, 2020 Daniel Haase"

DIR=$(TZ=Europe/Berlin date +%y%m%d%H%M%S)
RENAME=0
VRBSLVL=2
TAR=0
CLEAN=0
FILE=""

APP="$0"
rncnt=0
cnt=0

## print version information
function version
{
	echo "$TITLE version $VERSION"
	echo "$COPYRIGHT"
}

## print GPLv3 license disclaimer
function license
{
	echo ""
	echo "refpull - download remote files by hyperlinks from ASCII file"
	echo "$COPYRIGHT"
	echo ""
	echo "This program is free software: you can redistribute it and/or modify"
	echo "it under the terms of the GNU General Public License as published by"
	echo "the Free Software Foundation, either version 3 of the License, or"
	echo "(at your option) any later version."
	echo ""
	echo "This program is distributed in the hope that it will be useful,"
	echo "but WITHOUT ANY WARRANTY; without even the implied warranty of"
	echo "MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the"
	echo "GNU General Public License for more details."
	echo ""
	echo "You should have received a copy of the GNU General Public License"
	echo "along with this program.  If not, see <https://www.gnu.org/licenses/>."
	echo ""
}

## print usage information and exit with code "$1"
function usage
{
	local code="$1"
	if [ $# -eq 0 ] || [ -z "$code" ]; then code=0; fi

	echo ""
	version
	echo ""
	echo "usage:  $APP [-d <dir>] [-r | -o] [-t] [-e] [-c] [-v | -s | -q] <filename>"
	echo "        $APP [-h | -V | -L | -D]"
	echo ""
	echo "  -d <dir>"
	echo "    download files to directory <dir> (default is a date string)"
	echo ""
	echo "  -r"
	echo "    rename files to consecutive numbers (e.g. \"1.jpg\", \"2.jpg\", ...)"
	echo ""
	echo "  -o"
	echo "    rename files to an obfuscation of their original name"
	echo "    (requires program \"obfuscate\")"
	echo ""
	echo "  -t"
	echo "    use tar command to archive files after download"
	echo ""
	echo "  -e"
	echo "    encrypt generated tar archive (implies -t)"
	echo ""
	echo "  -c"
	echo "    remove downloaded files after archiving and tar archive after encrypting"
	echo ""
	echo "  -v"
	echo "    be verbose (the default)"
	echo ""
	echo "  -s"
	echo "    be silent and only print success message with number of"
	echo "    downloaded files when finished"
	echo ""
	echo "  -q"
	echo "    like -s but also suppress success message"
	echo ""
	echo "  -h"
	echo "    print this help message and exit"
	echo ""
	echo "  -V"
	echo "    print version information"
	echo ""
	echo "  -L"
	echo "    print GPL license disclaimer"
	echo ""
	echo "  -D"
	echo "    print list of dependencies"
	echo ""
	echo "note:  - long options are not supported"
	echo "       - flags (without positional arguments) can be combined"
	echo "         (e.g. \"-oes\" is allowed instead of \"-o -e -s\")"
	echo "       - the order of options is not relevant"
	echo "       - if conflicting arguments are given the latter ones take effect"
	echo "       - files/directories are never overridden"
	echo ""
	exit $code
}

## print list of dependencies
function dependencies
{
	echo "$TITLE depends on the following POSIX tools:"
	echo "  date grep (gpg) head ls mkdir (obfuscate) perl"
	echo "  pwd rm (tar) wc wget (xz)"
}

## print configuration for debugging purposes
function config
{
	echo "VRBSLVL: $VRBSLVL"
	echo "RENAME:  $RENAME"
	echo "TAR:     $TAR"
	echo "CLEAN:   $CLEAN"
	echo "DIR:     $DIR"
	echo "FILE:    $FILE"
	exit 0
}

## test if command "$1" is available on the system (i.e. in "$PATH")
## return 0 on success, 1 on failure
function hascmd
{
	local c="$1"
	if [ $# -eq 0 ] || [ -z "$c" ]; then return 0; fi
	which "$c" &> /dev/null
	if [ $? -eq 0 ]; then return 0; fi
	return 1
}

## test if command "$1" is available on the system (i.e. in "$PATH")
## return 0 on success, exit with code 3 on failure
## see: "hascmd"
function checkcmd
{
	if ! hascmd "$1"; then
		echo "command \"$c\" not found";
		exit 3
	fi

	return 0
}

## exit with code 3 if one dependency in space separated
## list "$@" is not available
## see: "checkcmd"
function checkallcmds
{
	local cmds=("$@")
	if [ ${#cmds[@]} -eq 0 ]; then return 0; fi

	for c in "${cmds[@]}"; do
		if [ -z "$c" ]; then continue; fi
		checkcmd "$c"
	done

	return 0
}

## parse command line arguments
function cmdline
{
	if [ $# -eq 0 ]; then usage 0; fi

	while true; do
		if [ "$1" == "" ]; then break
		elif [ "$1" == "-d" ]; then
			if [ "$2" == "" ]; then usage 1
			elif [ "${2:0:1}" == "-" ]; then usage 1
			else DIR="$2"; shift; shift; fi
		elif [ "${1:0:1}" == "-" ]; then
			if [[ "$1" == *"h"* ]]; then usage 0; fi
			if [[ "$1" == *"V"* ]]; then version; exit 0; fi
			if [[ "$1" == *"L"* ]]; then license; exit 0; fi
			if [[ "$1" == *"D"* ]]; then dependencies; exit 0; fi
			if [[ "$1" == *"r"* ]]; then RENAME=1; fi
			if [[ "$1" == *"o"* ]]; then RENAME=2; fi
			if [[ "$1" == *"t"* ]]; then TAR=1; fi
			if [[ "$1" == *"e"* ]]; then TAR=2; fi
			if [[ "$1" == *"c"* ]]; then CLEAN=1; fi
			if [[ "$1" == *"v"* ]]; then VRBSLVL=2; fi
			if [[ "$1" == *"s"* ]]; then VRBSLVL=1; fi
			if [[ "$1" == *"q"* ]]; then VRBSLVL=0; fi
			shift
		else FILE=$1; shift; fi
	done

	if [ "$FILE" == "" ]; then usage 1; fi
	#config
}

## check if an obfuscation tool is available
## return 1 if tool is in current directory, 2 if tool is in "$PATH"
## and 0 if no such tool was found
function obfuscatable
{
	if [ "$(ls $(pwd) | grep obfuscate)" != "" ]; then echo "1"
	else
		which obfuscate &> /dev/null
		if [ $? -eq 0 ]; then echo "2"
		else echo "0"; fi
	fi
}

## get filename of obfuscation tool in current directory
function obfuscator
{
	echo "$(ls $(pwd) | grep obfuscate | head -n 1)"
}

## execute obfuscation command on filename "$1"
## return new (obfuscated) filename
function obfuscationexec
{
	local name="$1"
	local con=$(obfuscatable)

	if [ "$con" == "0" ]; then echo ""
	else
		local obf=""
		if [ "$con" == "1" ]; then
			local obfexec=$(obfuscator)
			if [ ! -z "$obfexec" ]; then obf="$(perl $obfexec $name)"; fi
		elif [ "$con" == "2" ]; then obf="$(obfuscate $name)"; fi
		echo "$obf"
	fi
}

## format script name iff command "basename" is available
if hascmd "basename"; then APP="$(basename $APP)"; fi

## parse command line arguments
cmdline $@

## checking dependencies
if [ $VRBSLVL -eq 2 ]; then echo "checking required programs..."; fi
DEPS="date grep head ls mkdir perl pwd rm wc wget xz"
checkallcmds $DEPS ## xz is required by tar

## only check commands "tar", "gpg", and "obfuscate" if necessary
if [ $TAR -ge 1 ]; then checkcmd "tar"; fi
if [ $TAR -eq 2 ]; then checkcmd "gpg"; fi
if [ $RENAME -eq 2 ]; then
	if [ "$(obfuscatable)" == "0" ]; then
		echo "no obfuscation tool found on the system"
		RENAME=0 ## skip obfuscation/renaming completely if tool not found
	fi
fi

## savely create target directory
if [ ! -e $DIR ] || [ ! -d $DIR ]; then mkdir -p $DIR
else
	TMP=$DIR
	while [ -e $DIR ] && [ -d $DIR ]; do
		DIR="${TMP}_${rncnt}"
		rncnt=$((rncnt + 1))
	done
	mkdir -p $DIR
	rncnt=0
fi

## process input file
while read href; do
	if [[ "$href" != "http"* ]]; then continue; fi ## skip if not a hyperlink
	orig=$(echo $href | perl -pe 's/.*\/(.*)\s+/\1/' | perl -pe 's/(.+\..+)\?.+/\1/')
	if [ -z "$orig" ]; then continue; fi ## skip on invalid hyperlink
	ext="${orig##*.}" ## extract filename extension

	## assume not a hyperlink to a file on suspicious filename extension
	if [ ${#ext} -gt 4 ] || [ "${orig:0:1}" == "?" ]; then
		#echo "skipping \"${orig}\"..."
		continue
	fi

	## generate new filename
	if [ $RENAME -eq 1 ]; then res="${cnt}.${ext}"
	elif [ $RENAME -eq 2 ]; then
		res="$(obfuscationexec $orig)"
		if [ -z "$res" ]; then res="$orig"; fi
	else res="$orig"; fi

	## fallback to original filename
	if [ -e "$res" ] || [ -e "./$DIR/$res" ]; then
		strp=$(echo $orig | perl -pe 's/(.+)\..+/\1/')
		res="${strp}_${rncnt}.${ext}"
		rncnt=$((rncnt + 1))
	fi

	if [ $VRBSLVL -eq 2 ]; then echo "downloading file \"${orig}\"..."; fi
	if [ -e $DIR ] && [ -d $DIR ]; then res="./${DIR}/${res}"; fi
	wget --quiet --no-dns-cache --no-directories --no-http-keep-alive \
		--no-cookies --output-document="$res" "$href" &> /dev/null
	if [ $? -ne 0 ]; then
		if [ $VRBSLVL -eq 2 ]; then
			echo "failed to download file \"${orig}\""
		fi
	else cnt=$((cnt + 1)); fi ## count successful downloads
done < "$FILE"

## remove created directory if no files had been downloaded
if [ $cnt -eq 0 ]; then
	if [ -z "$(ls $DIR | wc -l)" ]; then
		if [ $VRBSLVL -eq 2 ]; then
			echo "removing empty direcotry \"$DIR\"..."
		fi

		rmdir $DIR &> /dev/null
		if [ $? -ne 0 ]; then
			if [ $VRBSLVL -eq 2 ]; then
				echo "failed to remove empty directory \"$DIR\""
			fi
		fi
	fi
fi

if [ $TAR -gt 0 ]; then
	if [ $VRBSLVL -eq 2 ]; then
		echo "archiving files to \"$(basename $DIR).txz\"..."
	fi

	## create tar archive from directory
	tar cJf "$(basename $DIR).txz" "$DIR" &> /dev/null
	if [ $? -ne 0 ]; then echo "failed to archive files"; fi
	if [ $TAR -eq 2 ]; then
		if [ $VRBSLVL -eq 2 ]; then
			echo "encrypting \"$(basename $DIR).txz\"..."
		fi

		## encrypt tar archive with standard graphical password dialog from gpg
		## TODO: request (repeated) password from user and include in gpg command
		gpg --cipher-algo AES256 --symmetric "$(basename $DIR).txz" &> /dev/null
		if [ $? -ne 0 ]; then echo "failed to encrypt archive"; fi
	fi

	## clean up generated files
	if [ $CLEAN -eq 1 ]; then
		if [ $TAR -ge 1 ]; then
			if [ -e "$(basename $DIR).txz" ] && [ -f "$(basename $DIR).txz" ]; then
				if [ -e "$DIR" ] && [ -d "$DIR" ]; then
					if [ $VRBSLVL -eq 2 ]; then
						echo "removing directory \"$(basename $DIR)\"..."
					fi

					rm -rf "$DIR" &> /dev/null
					if [ $? -ne 0 ]; then
						echo "failed to remove direcotry \"$(basename $DIR)\""; fi
				fi
			fi
		fi

		if [ $TAR -eq 2 ]; then
			if [ -e "$(basename $DIR).txz.gpg" ] && [ -f "$(basename $DIR).txz.gpg" ]; then
				if [ -e "$(basename $DIR).txz" ] && [ -f "$(basename $DIR).txz" ]; then
					if [ $VRBSLVL -eq 2 ]; then
						echo "removing archive \"$(basename $DIR).txz\"..."
					fi

					rm -f "$(basename $DIR).txz" &> /dev/null
					if [ $? -ne 0 ]; then
						echo "failed to remove archive \"$(basename $DIR).txz\""
					fi
				fi
			fi
		fi
	fi
fi

## exit successfully
if [ $VRBSLVL -gt 0 ]; then echo "$cnt files processed"; fi
exit 0
