# Downloads packages using Chocolatey after installing chocolatey and restarting.

choco install python311 -y
choco install pstools -y

Unregister-ScheduledTask -TaskName "ChocoInstalls" -Confirm:$false
