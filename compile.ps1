
$FALLOUT4_DATA = "$env:FALLOUT4_PATH\Data"
$FALLOUT4_SCRIPTS = "$FALLOUT4_DATA\Scripts"
$FALLOUT4_SCRIPTS_SOURCE_USER = "$FALLOUT4_SCRIPTS\Source\User"
$FALLOUT4_SCRIPTS_SOURCE_BASE = "$FALLOUT4_SCRIPTS\Source\Base"
$SCRIPTS_SOURCE = ".\Data\Scripts\Source\User"

$IMPORT_PATH = "$FALLOUT4_SCRIPTS;$FALLOUT4_SCRIPTS_SOURCE_USER;$FALLOUT4_SCRIPTS_SOURCE_BASE;$SCRIPTS_SOURCE"
$BUILD_PATH = "$PSScriptRoot\build\"
$BUILD_PATH_DEBUG = "$BUILD_PATH\debug\Data\Scripts"
$BUILD_PATH_RELEASE = "$BUILD_PATH\release\Data\Scripts"

$INSTITUTE_FLAGS_FILE = "$FALLOUT4_SCRIPTS_SOURCE_BASE\Institute_Papyrus_Flags.flg"

Get-ChildItem $BUILD_PATH_DEBUG | Remove-Item -Recurse -Force
Get-ChildItem $BUILD_PATH_RELEASE | Remove-Item -Recurse -Force

PapyrusCompiler robco-auto-sort.ppj -import="$IMPORT_PATH" -output="$BUILD_PATH_DEBUG" -flags="$INSTITUTE_FLAGS_FILE"
PapyrusCompiler robco-auto-sort.ppj -import="$IMPORT_PATH" -output="$BUILD_PATH_RELEASE" -flags="$INSTITUTE_FLAGS_FILE" -optimize -release -final

Copy-Item -Path "$BUILD_PATH_DEBUG\RobcoAutoSort" -DESTINATION "$FALLOUT4_SCRIPTS" -RECURSE -FORCE