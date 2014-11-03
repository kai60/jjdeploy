#!/usr/bin/env bash

VERSION="0.0.1"

### Project Constants

PROJECTDIR="."
APPNAME="##project_name##"
DISPLAY_APPNAME="##app_display_name##"
WORKSPACE="##workspace_name##.xcworkspace"
SCHEME="##scheme_for_archiving##"
PROVPROFILE="##provisioning_profile_for_archiving##"
PLISTFILE="##path_to_info.plist##"
export PUBLISH_PLIST_LINK="##link_to_plist_file##"

### Constants

export COMPANYNAME="##your_company##"
REMOTEPATH="##your_server_remote_path##/${APPNAME}"
TRANSMIT_FAVNAME="##your_transmit_fav##"

SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"
ARCHIVEPATH="$HOME/Desktop/outbox/archive/${APPNAME}"
XCARCHIVEPATH="${ARCHIVEPATH}/${APPNAME}.xcarchive"
IPAARCHIVEPATH="${ARCHIVEPATH}/${APPNAME}.ipa"

TEMPLATE_HTML_FILENAME="index_template.html"
HTML_FILENAME="index.html"
HTMLARCHIVEPATH="$ARCHIVEPATH/$HTML_FILENAME"
CSSARCHIVEPATH="$ARCHIVEPATH/css"
ICONARCHIVEPATH="$ARCHIVEPATH/Icon.png"

redColor='\x1B[0;31m'
endColor='\x1B[0m'

### Functions

function usage
{
    echo "usage: ./archive.sh [ [-v] [-h] [--version] ]"
}

verbose=

while [ "$1" != "" ]; do
	case $1 in
		-v | --verbose )	verbose=1
							;;
		--version )			echo $VERSION
							exit
							;;
		-h | --help )		usage
					  		exit
					  	  	;;
		* )            		usage
							exit 1
	esac
	shift
done

### Commands

#### Build

if [ ! -d "$ARCHIVEPATH" ]; then
	mkdir "$ARCHIVEPATH"
fi

build=$(xcodebuild -workspace "$WORKSPACE" -scheme "$SCHEME" -destination generic/platform=iOS archive -archivePath "$XCARCHIVEPATH")

[ $verbose -neq 1 ] && build=$build" | egrep -A 5 \"(error|warning):\""

eval $build

rm "$IPAARCHIVEPATH"

#### Archive

archive=$(xcodebuild -exportArchive -exportFormat ipa -archivePath "$XCARCHIVEPATH" -exportPath "$IPAARCHIVEPATH" -exportProvisioningProfile "$PROVPROFILE")

[ $verbose -neq 1 ] && archive=$archive" > /dev/null"

eval $archive

rm -rf "$XCARCHIVEPATH"

export CURRENT_TIMESTAMP=`date +"%d.%m.%Y %H:%M"`

export APP_VERSION=`/usr/libexec/PlistBuddy -c Print:CFBundleShortVersionString "$PLISTFILE"`

#### Request changes

CHANGES=`osascript -e "set changes to the text returned of (display dialog \"What has changed?\" default answer \"Fixes\")
return changes"`

export CHANGES

export COMPANYNAME

#### Fill template & generate html file

perl -p -i -e 's/\$\{([^}]+)\}/defined $ENV{$1} ? $ENV{$1} : $&/eg' < "$TEMPLATE_HTML_FILENAME" > "${HTMLARCHIVEPATH}"

if [ -f $HTMLARCHIVEPATH ];
then
	#### Copy css files
	cp -R $SCRIPTPATH/css/ $CSSARCHIVEPATH
	
	#### Find Icon & copy to archive

	iconpath=`find $PROJECTDIR -type d -name '*.appiconset' -print | head -n 1`
	if [ -n "$iconpath" ];
	then
		icon=`find ${iconpath} -type f -print0 | xargs -0 ls -1S | head -n 1`
		if [ -n "$icon" ];
		then
			cp "$icon" "$ICONARCHIVEPATH"
		else
			echo -e "${redColor} Error: Icon file not found. Please check that your image asset contains the app icon.\n${endColor}"
		fi
	else
		echo -e "${redColor} Error: Icon file not found. Image assets are required to display the app icon.\n${endColor}"
	fi
fi

if [ -f $IPAARCHIVEPATH ] && [ -f $HTMLARCHIVEPATH ];
then
	
	#### Commit & push changes
	
	if [ -d "$PROJECTDIR/.git" ]
	then
		git add -A $PROJECTDIR
		git commit -m "$CHANGES"
		git push
	elif [ -d "$PROJECTDIR/.hg" ]
	then
		hg addrem $PROJECTDIR
		hg commit -m "$CHANGES"
		hg push
	fi
	
	#### Upload with Transmit
	
	osascript  -e "
	tell application \"Transmit\"
	set SuppressAppleScriptAlerts to true
	set server to item 1 of (favorites whose name is \"${TRANSMIT_FAVNAME}\")
		tell current tab of (make new document at end)
			connect to server
			tell remote browser
				upload item at path \"${IPAARCHIVEPATH}\" to \"${REMOTEPATH}\" with resume mode overwrite
				upload item at path \"${HTMLARCHIVEPATH}\" to \"${REMOTEPATH}\" with resume mode overwrite
				upload item at path \"${ICONARCHIVEPATH}\" to \"${REMOTEPATH}\" with resume mode overwrite
				upload item at path \"${CSSARCHIVEPATH}\" to \"${REMOTEPATH}\" with resume mode overwrite
			end tell
			close remote browser
		end tell
	end tell"
else
	
	#### Report Error
	
	echo -e "${redColor} Error: no ipa or html file. Run with -v option and check the xcodebuild output. \n${endColor}"
	
	osascript  -e "display alert \"Error archiving ${APPNAME}. No ipa or html file\""
	open $ARCHIVEPATH
fi

tput bel
