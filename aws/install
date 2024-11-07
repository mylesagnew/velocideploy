@ECHO OFF

REM Change to the directory of the batch file
cd /D "%~dp0"

REM Install Velociraptor service
echo Installing Velociraptor service...
msiexec /i win-velociraptor.msi /qn
IF %ERRORLEVEL% NEQ 0 (
    echo Error: Failed to install Velociraptor service.
    exit /b %ERRORLEVEL%
)

REM Copy Velociraptor config file
echo Copying Velociraptor config file...
copy /Y Velociraptor.config.yaml "%SYSTEMDRIVE%\Program Files\Velociraptor"
IF %ERRORLEVEL% NEQ 0 (
    echo Error: Failed to copy Velociraptor config file.
    exit /b %ERRORLEVEL%
)

REM Start Velociraptor service
echo Starting Velociraptor service...
net stop Velociraptor >nul 2>&1
net start Velociraptor
IF %ERRORLEVEL% NEQ 0 (
    echo Error: Failed to start Velociraptor service.
    exit /b %ERRORLEVEL%
)

REM Success message
echo Velociraptor service installed and started successfully.
