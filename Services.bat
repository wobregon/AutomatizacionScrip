@echo off
REM Ruta y nombre del archivo log
set "logfile=C:\Scripts\services_status_log.txt"

REM Crear carpeta de Logs si no existe
if not exist "C:\Scripts" mkdir "C:\Scripts"

REM Inicia el monitoreo continuo
:inicio
REM Registrar la fecha y hora de la verificación
echo ================================ >> "%logfile%"
echo Fecha y hora: %date% %time% >> "%logfile%"

REM Array de servicios
set services=servicio1 servicio2 servicio3

REM Recorrer los servicios
for %%s in (%services%) do (
    echo -------------------------------- >> "%logfile%"
    echo Verificando el estado del servicio %%s... >> "%logfile%"

    REM Verificar el estado del servicio
    sc query %%s | findstr /I /C:"STOPPED" >nul
    IF %ERRORLEVEL%==0 (
        REM Si el servicio está detenido, intentar iniciarlo
        echo El servicio %%s está detenido. Intentando iniciarlo... >> "%logfile%"
        sc start %%s >> "%logfile%"
        IF %ERRORLEVEL%==0 (
            echo [EXITO] El servicio %%s se inició correctamente. >> "%logfile%"
            REM Llamar a PowerShell para enviar un correo notificando el reinicio del servicio
            powershell.exe -ExecutionPolicy Bypass -File "C:\Scripts\EnvioCorreo.ps1" -Servicio "%%s" -Estado "Running"
        ) ELSE (
            echo [ERROR] Fallo al intentar iniciar el servicio %%s. >> "%logfile%"
        )
    ) ELSE (
        echo El servicio %%s está en ejecución. >> "%logfile%"
    )
)

REM Final del log
echo ================================ >> "%logfile%"

REM Esperar 5 minutos antes de la próxima verificación
timeout /t 300 /nobreak >nul
goto inicio