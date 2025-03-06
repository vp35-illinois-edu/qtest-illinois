@REM Reference: "C:\Users\vp35\Desktop\matlab_signing\SignTool-10.0.22621.6-x64\signtool.exe" sign /v /debug /fd SHA256 /tr "http://timestamp.acs.microsoft.com" /td SHA256 /dlib "C:\Users\vp35\Desktop\matlab_signing\microsoft.trusted.signing.client.1.0.76\bin\x64\Azure.CodeSigning.Dlib.dll" /dmdf "C:\Users\vp35\Desktop\matlab_signing\metadata.json" "C:\Users\vp35\Desktop\matlab_signing\qtest.exe"
@REM unzip azure-cli-2.69.0-x64.zip
@REM unzip SignTool-10.0.22621.6-x64.zip
@REM unzip microsoft.trusted.signing.client.1.0.76.zip

@REM SCRIPT_PATH="$(dirname "$(realpath "$0")")"
@REM ROOT_PATH="$SCRIPT_PATH/../.."
@REM BASE_PATH="$ROOT_PATH/build/windows/win64"

@REM FILES_TO_SIGN=("portamex.mexw64" "portavmex.mexw64")


@echo off

REM Check if environment variables are set
if "%AZURE_CLIENT_ID%"=="" (
    echo Error: AZURE_CLIENT_ID environment variable not set.
    exit /b 1
)
if "%AZURE_CLIENT_SECRET%"=="" (
    echo Error: AZURE_CLIENT_SECRET environment variable not set.
    exit /b 1
)
if "%AZURE_TENANT_ID%"=="" (
    echo Error: AZURE_TENANT_ID environment variable not set.
    exit /b 1
)


REM Define paths
set SCRIPT_PATH=%~dp0
set ROOT_PATH=%SCRIPT_PATH%..\..
set BASE_PATH=%ROOT_PATH%\src

@REM REM Unzip necessary files
@REM echo Unzipping azure-cli-2.69.0-x64.zip
@REM powershell -Command "Expand-Archive -Path '%SCRIPT_PATH%azure-cli-2.69.0-x64.zip' -DestinationPath '%SCRIPT_PATH%azure-cli'"
@REM call :check_command_status "unzip azure-cli-2.69.0-x64.zip"

@REM echo Unzipping SignTool-10.0.22621.6-x64.zip
@REM powershell -Command "Expand-Archive -Path '%SCRIPT_PATH%SignTool-10.0.22621.6-x64.zip' -DestinationPath '%SCRIPT_PATH%SignTool'"
@REM call :check_command_status "unzip SignTool-10.0.22621.6-x64.zip"

@REM echo Unzipping microsoft.trusted.signing.client.1.0.76.zip
@REM powershell -Command "Expand-Archive -Path '%SCRIPT_PATH%microsoft.trusted.signing.client.1.0.76.zip' -DestinationPath '%SCRIPT_PATH%microsoft.trusted.signing.client'"
@REM call :check_command_status "unzip microsoft.trusted.signing.client.1.0.76.zip"


REM Define files to sign
set FILES_TO_SIGN=portamex.mexw64 portavmex.mexw64
@REM set FILES_TO_SIGN=portamex.mexw64

REM Function to check the exit status of commands
:check_command_status
if %errorlevel% neq 0 (
    echo Error: %1 failed.
    exit /b 1
)

REM Sign individual executables
for %%F in (%FILES_TO_SIGN%) do (
    echo Signing %BASE_PATH%\%%F
    "%SCRIPT_PATH%SignTool\signtool.exe" sign /v /fd SHA256 /tr "http://timestamp.acs.microsoft.com" /td SHA256 /dlib "%SCRIPT_PATH%microsoft.trusted.signing.client\bin\x64\Azure.CodeSigning.Dlib.dll" /dmdf "%SCRIPT_PATH%metadata.json" %BASE_PATH%\%%F
    if %errorlevel% neq 0 (
        echo Error: signtool sign for %%F failed.
        exit /b 1
    )
)

echo Code signing completed successfully.
exit /b 0
