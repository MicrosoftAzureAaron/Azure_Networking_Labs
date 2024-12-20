# Description: A simple UDP client that sends a message to a server and receives a text response.
# This is to be used in conjunction with the UDP_Server.ps1 script.

param (
    [string]$DestinationIP,
    [int]$DestinationPort,
    [string]$SentMessage
)

$udpClient = New-Object System.Net.Sockets.UdpClient
$endpoint = New-Object System.Net.IPEndPoint ([System.Net.IPAddress]::Parse($DestinationIP), $DestinationPort)
while ($true) {
    $bytes = [System.Text.Encoding]::ASCII.GetBytes($SentMessage)
    $udpClient.Send($bytes, $bytes.Length, $endpoint)
    $receivedBytes = $udpClient.Receive([ref]$endpoint)
    $receivedData = [System.Text.Encoding]::ASCII.GetString($receivedBytes)
    Write-Host "Received: $receivedData"
    Start-Sleep -Seconds 1
}
