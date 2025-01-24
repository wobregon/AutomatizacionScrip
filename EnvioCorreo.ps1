param (
    [string]$Servicio,
    [string]$Estado
)

# Configuracion del servidor SMTP
$smtpServer = "smg-smtp-01.tudominio.corp"
$smtpPort = 25
$smtpFrom = "notificacion@tudominio.com"
# No se requiere autenticacion segun la configuracion proporcionada
# Si es necesario anadir la autenticacion, se puede hacer en el siguiente formato:
# $smtpUser = "notificacion@tudominio.com"
# $smtpPassword = "Pass1234.."

# Lista de correos destinatarios, el ultimo correo no lleva , (coma)
$smtpTo = @(
    "correo1@tudominio.com.co"
)

# Informacion sobre el servidor
$servidor = "Servidor1"
$ip = "165.45.24.1"
$ambiente = "Desarrollo, Certificacion o produccion"

# Funcion para enviar correo
function Send-Email {
    param (
        [string]$asunto,
        [string]$cuerpo
    )
    $mailmessage = New-Object system.net.mail.mailmessage
    $mailmessage.from = ($smtpFrom)

    foreach ($destinatario in $smtpTo) {
        $mailmessage.To.Add($destinatario)
    }

    $mailmessage.Subject = $asunto
    $mailmessage.Body = $cuerpo
    $mailmessage.IsBodyHtml = $true  # Habilitar formato HTML en el cuerpo del correo

    # Establecer las credenciales y configuracion SMTP
    $SMTPClient = New-Object Net.Mail.SmtpClient($smtpServer, $smtpPort)
    $SMTPClient.EnableSsl = $false  # Deshabilitar SSL porque esta configurado en "FALSE"

    # Intentar enviar el correo
    try {
        $SMTPClient.Send($mailmessage)
        Write-Host "Correo enviado con exito."
    } catch {
        Write-Host "Error al enviar el correo: $_"
    }

    # Limpiar los objetos de mensaje y cliente SMTP
    $mailmessage.Dispose()
    $SMTPClient.Dispose()
}

# Lista de servicios a verificar
$servicios = @("servicio1", "servicio2", "servicio3")
$estadoPrevio = @{}

foreach ($servicio in $servicios) {
    # Verificar el estado actual del servicio
    $estadoServicio = Get-Service -Name $servicio | Select-Object -ExpandProperty Status

    # Si el servicio ya fue verificado y el estado no ha cambiado, no enviamos correo
    if ($estadoPrevio[$servicio] -eq $estadoServicio) {
        continue
    }

    # Guardar el estado previo para comparar en la siguiente iteracion
    $estadoPrevio[$servicio] = $estadoServicio

    # Comprobar si el servicio esta detenido
    if ($estadoServicio -eq "Stopped") {
        # Si el servicio esta detenido, intentar iniciarlo
        $asunto = "Verificando el estado del servicio $servicio..."
        $cuerpo = @"
<html>
<body>
<p>Hola,</p>
<p>El servicio <strong>$servicio</strong> esta detenido en el servidor <strong>$servidor</strong> (IP: $ip, Ambiente: $ambiente). Intentando iniciarlo...</p>
</body>
</html>
"@
        Send-Email $asunto $cuerpo

        # Intentar iniciar el servicio
        Start-Service -Name $servicio

        # Verificar nuevamente si el servicio se inicio correctamente
        $estadoServicio = Get-Service -Name $servicio | Select-Object -ExpandProperty Status

        if ($estadoServicio -eq "Running") {
            $asunto = "Notificacion: El servicio $servicio ha sido iniciado correctamente"
            $cuerpo = @"
<html>
<body>
<p>Hola,</p>
<p>El servicio <strong>$servicio</strong> ha sido iniciado correctamente en el servidor <strong>$servidor</strong> (IP: $ip, Ambiente: $ambiente) a las <strong>$(Get-Date)</strong>.</p>
<p>Este correo es informativo, el servicio ha sido restaurado exitosamente.</p>
</body>
</html>
"@
            Send-Email $asunto $cuerpo
        }
    } elseif ($estadoServicio -eq "Running") {
        # Si el servicio ya esta en ejecucion, enviar solo un correo notificando que esta en estado "Running"
        $asunto = "Notificacion: El servicio $servicio ya esta en ejecucion"
        $cuerpo = @"
<html>
<body>
<p>Hola,</p>
<p>El servicio <strong>$servicio</strong> ya esta en ejecucion en el servidor <strong>$servidor</strong> (IP: $ip, Ambiente: $ambiente) a las <strong>$(Get-Date)</strong>.</p>
<p>No fue necesaria la intervencion.</p>
</body>
</html>
"@
        Send-Email $asunto $cuerpo
    }
}
