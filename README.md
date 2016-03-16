# Websphere Portal Export Theme PAA
Shell script to export Websphere Portal theme to a PAA application file, which can be installed on different Websphere Portal(s).

## How to use
1. Download and copy ```export-theme.sh``` and ```export-theme.sh.bin``` in same directory.
2. Copy content of theme static resources from portal webdav to local directory and note the path of this directory. The structure of your local static directory should look something like below.
```
|--- local_static_directory
    |--- contributions
    |--- css
    |--- images
    |--- js
        .
        .
    |--- theme.html
```
> Note: It is important to copy static resources to local directory, as script does not connect to webdav.

3. Copy content of theme dynamic resources to local directory (different than above static local directory) and note the path of this directory. The structure of your local dynamic directory should look something like below.
```
|--- local_dynamic_directory
    |--- META-INF
    |--- skins
    |--- themes
    |--- WEB-INF
```
> Note: This is the content of dynamic theme WAR.
4. Run ```./export-theme.sh```. (refer to perameter information provided below).
5. ```theme-application-name.paa``` will be exported in the directory from which the script was executed.
6. Transfer and install PAA to required target portal. Installation instructions are as follows.

## PAA Installation
1. Change to ```ConfigEngine``` directory of portal. Like ```cd /opt/IBM/WebSphere/ConfigEngine```.
2. Run ```./ConfigEngine.sh install-paa -DPAALocation='{paa-directory-path}' -DWasPassword={was_password} -DPortalAdminPwd={portal_admin_password}```.
3. Run ```./ConfigEngine.sh deploy-paa -DappName={paa_application_name} -DWasPassword={was_password} -DPortalAdminPwd={portal_admin_password}```.

## Parameter Information
* themeName - Name of exported theme
* themeUidStatic - Unique ID given to static theme
* themeUid - Unique ID given to theme, this also becomes ```paa_application_name``` used while deploying paa (step 2 in paa installation).
* themeUniqueNamePrefix - Unique ID prefix given to theme
* staticThemePath - Path of local directory created in step 2 of how to use.
* dynamicThemePath - Path of local directory created in step 3 of how to use.
* staticLayoutTemplate - Default layout template for theme
* staticSkin - Default skin for theme
> Note: Either of above parameters can be left blank. In that case default parameter will be used.

## Versions Supported
Websphere Portal v8.x