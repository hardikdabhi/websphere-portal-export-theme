#!/bin/bash
########################################
# user variables
########################################
default_themeName="Generated Theme"
default_themeUidStatic="generatedTheme"
default_themeUid="generatedTheme"
default_themeUniqueNamePrefix="com.hardik.generated.theme"
default_staticThemePath="/home/user/tmp/generatedThemeArtifacts/static/"
default_dynamicThemePath="/home/user/tmp/generatedThemeArtifacts/dynamic/"
default_staticLayoutTemplate="1Column"
default_staticSkin="Hidden"

########################################
# common functions
########################################

# $1	file to write
# $2	content
writeToFile(){
	if [ ! -f "$1" ] ; then
		touch "$1"
	fi
	echo "$2" > $1
}

# $1	variable to be assigned with value 
# $2	text to be dispayed to user
# $3	[optional] default value variable
# $4	[optional] true - remove spaces
readInput(){
	local temp
	if [ "$3" = "" ]; then
		echo -n "Enter $2: "
	else 
		echo -n "Enter $2 [$3]: "
	fi 
	read temp
	if [ "$4" != "true" ]; then
		temp=${temp//[[:blank:]]/}
	fi
	export $1="$temp"
	if [ "$temp" = "" ] ; then
		if [ "$3" = "" ] ; then 
			echo "---------------------------------------"
			echo "Invalid $2. Please try again."
			readInput $1 "$2"
		else
			export $1="$3"
		fi
	fi
}

########################################
# specific functions
########################################
validateStaticTheme(){
	if [ ! -f $staticThemePath/metadata.properties ]; then
		echo "---------------------------------------"
		echo "Metadata for Static Theme not found!"
		select option in "Ignore and Porceed" "Re-enter path"
		do
			break
		done
		if [ $REPLY -eq 1 ]; then
			return
		elif [ $REPLY -eq 2 ]; then
			echo "---------------------------------------"
			readInput staticThemePath "Static Theme Path" $default_staticThemePath
			validateStaticTheme
		else
			echo "---------------------------------------"
			echo "Invalid Choice. Please try again."
			validateStaticTheme
		fi
	fi
}
validateDynamicTheme(){
	if [ ! -d $dynamicThemePath/WEB-INF ]; then
		echo "---------------------------------------"
		echo "WEB-INF for Dynamic Theme not found!"
		select option in "Ignore and Porceed" "Re-enter path"
		do
			break
		done
		if [ $REPLY -eq 1 ]; then
			return
		elif [ $REPLY -eq 2 ]; then
			echo "---------------------------------------"
			readInput dynamicThemePath "Dynamic Theme Path" $default_dynamicThemePath
			validateDynamicTheme
		else
			echo "---------------------------------------"
			echo "Invalid Choice. Please try again."
			validateDynamicTheme
		fi
	fi
}
createBaseSdd(){
	local fileData=$(cat $dirPaaData/base-sdd.xml)
	local cFileData=${fileData//__THEME_UID__/$themeUid}
	cFileData=${cFileData//__BUILD_DATE__/`date +%Y-%m-%dT12:00:00`}
	writeToFile $dirTemp/sdd.xml "$cFileData"
}
createComponentSdd(){
	local fileData=$(cat $dirPaaData/component-sdd.xml)
	local cFileData=${fileData//__THEME_UID__/$themeUid}
	cFileData=${cFileData//__BUILD_DATE__/`date +%Y-%m-%dT12:00:00`}
	writeToFile $dirTemp/components/$themeUid/sdd.xml "$cFileData"
}
createVersionCheck(){
	local fileData=$(cat $dirPaaData/version-check.xml)
	local cFileData=${fileData//__THEME_UID__/$themeUid}
	writeToFile $dirTemp/components/$themeUid/config/includes/version-check.xml "$cFileData"
}
createStaticTheme(){
	cd "$dirTemp/components/$themeUid/content/webdav/themes/"
	cp -rf "$staticThemePath" "$themeUidStatic"
	zip -r $themeUidStatic{.zip,}
	rm -rf $themeUidStatic
	cd "$scriptDir"
}
createInstallUninstall(){
	if [ "$themeUniqueNamePrefix" != "" ] ; then
		themeUniqueNamePrefix="$themeUniqueNamePrefix."
	fi
	local tmp=$(echo $themeUid | tr '[:upper:]' '[:lower:]')
	local fileData=$(cat $dirPaaData/installTheme.xml)
	local cFileData=${fileData//__THEME_UID__/$themeUid}
	cFileData=${cFileData//__THEME_UID_STATIC__/$themeUidStatic}
	cFileData=${cFileData//__THEME_UNIQUE_SKINNAME__/"$themeUniqueNamePrefix$tmp.skin"}
	cFileData=${cFileData//__THEME_NAME__/"$themeName"}
	cFileData=${cFileData//__THEME_SKIN__/"$staticSkin"}
	cFileData=${cFileData//__THEME_UNIQUE_THEMENAME__/"$themeUniqueNamePrefix$tmp.theme"}
	cFileData=${cFileData//__THEME_LAYOUT_TEMPLATE__/"$staticLayoutTemplate"}
	writeToFile $dirTemp/components/$themeUid/content/xmlaccess/install/installTheme.xml "$cFileData"
	writeToFile $dirTemp/components/$themeUid/content/xmlaccess/install/order.properties "installTheme.xml"
	
	fileData=$(cat $dirPaaData/uninstallTheme.xml)
	local cFileData=${fileData//__THEME_UNIQUE_SKINNAME__/"$themeUniqueNamePrefix$tmp.skin"}
	cFileData=${cFileData//__THEME_UNIQUE_THEMENAME__/"$themeUniqueNamePrefix$tmp.theme"}
	writeToFile $dirTemp/components/$themeUid/content/xmlaccess/uninstall/uninstallTheme.xml "$cFileData"
	writeToFile $dirTemp/components/$themeUid/content/xmlaccess/uninstall/order.properties "uninstallTheme.xml"
}
createDynamicTheme(){
	mkdir -p $dirTemp/components/$themeUid/installableApps/ear/META-INF
	local fileData=$(cat $dirPaaData/application.xml)
	local cFileData=${fileData//__THEME_UID__/$themeUid}
	writeToFile $dirTemp/components/$themeUid/installableApps/ear/META-INF/application.xml "$cFileData"
	fileData=$(cat $dirPaaData/MANIFEST.MF)
	writeToFile $dirTemp/components/$themeUid/installableApps/ear/META-INF/MANIFEST.MF "$fileData"
	
	cd $dirTemp/components/$themeUid/installableApps/ear/
	rm -rf tmp
	cp -rf $dynamicThemePath tmp
	cd tmp
	zip -r $themeUid"WAR.war" *
	cd ..
	mv tmp/$themeUid"WAR.war" $themeUid"WAR.war"
	rm -rf tmp
	zip -r $themeUid.ear *
	rm -rf {META-INF,$themeUid"WAR.war"}
	
	cd "$scriptDir"
}
createVersionComponent(){
	local fileData=$(cat $dirPaaData/theme.component)
	local cFileData=${fileData//__THEME_UID__/$themeUid}
	cFileData=${cFileData//__BUILD_DATE__/`date +%m-%d-%Y`}
	cFileData=${cFileData//__BUILD_VERSION__/`date +%Y%m%d_1000`}
	writeToFile $dirTemp/components/$themeUid/version/$themeUid.component "$cFileData"
}
packPaa(){
	cd $dirTempRoot
	zip -r $themeUid.paa *
	cd ..
	mv $dirTempRoot/$themeUid.paa $themeUid.paa
	rm -rf $dirTempRoot
	rm -rf $dirPaaData
}
########################################
# script
########################################
dirTempRoot="tmp-theme"
dirPaaData="tmp"
tmpScriptDir=${0}
tmpScriptDir=${tmpScriptDir//${0##*/}/}
cd "$tmpScriptDir"
scriptDir=$(pwd)
echo "*******************************************************************************"
readInput themeName "Theme Display Name" "$default_themeName" "true"
readInput themeUidStatic "Theme Static UID" $default_themeUidStatic
readInput themeUid "Theme UID" $default_themeUid
readInput themeUniqueNamePrefix "Theme Unique Name Prefix" $default_themeUniqueNamePrefix
readInput staticThemePath "Static Theme Path" $default_staticThemePath
readInput dynamicThemePath "Dynamic Theme Path" $default_dynamicThemePath
readInput staticLayoutTemplate "Layout Template" $default_staticLayoutTemplate
readInput staticSkin "Skin" $default_staticSkin
validateStaticTheme
validateDynamicTheme
echo "*******************************************************************************"
mkdir -p $dirPaaData
tar xf ${0##*/}.bin -C $dirPaaData
dirTemp=$dirTempRoot/$themeUid
mkdir -p $dirTemp/{documentation,components/$themeUid}
mkdir -p $dirTemp/components/$themeUid/{config/includes,content,installableApps/ear,version}
mkdir -p $dirTemp/components/$themeUid/content/{webdav,xmlaccess}
mkdir -p $dirTemp/components/$themeUid/content/webdav/{layout-templates,skins,themes}
mkdir -p $dirTemp/components/$themeUid/content/xmlaccess/{install,uninstall}
writeToFile $dirTemp/components/$themeUid/$themeUid.properties
writeToFile $dirTemp/components/$themeUid/config/includes/messages.properties
createBaseSdd
createComponentSdd
createVersionCheck
createStaticTheme
createInstallUninstall
createDynamicTheme
createVersionComponent
packPaa
echo "******************* \"$themeUid.paa\" created successfully! *******************"
