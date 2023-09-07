$storcli = "C:\tools\storcli64.exe"
$inputText = & $storcli " /call/eall/sall show all"


$commandOutput = $inputText

$drivePattern = "Drive /c(\d+)/e(\d{1,3})/s(\d+) - Detailed Information"
$temperaturePattern = "Drive Temperature =\s+(\d+)C"
$snPattern = "SN =\s+([A-Za-z0-9]+)"

$driveInfo = @()

$controllerNumber = ""
$enclosureNumber = ""
$slotNumber = ""
$temperatureValue = ""
$snValue = ""

foreach ($line in $commandOutput -split "`n") {
    if ($line -match $drivePattern) {
        $controllerNumber = $Matches[1]
        $enclosureNumber = ("{0:D3}" -f [int]$Matches[2])
        $slotNumber = $Matches[3]
        $slotNumber = if ($slotNumber -match '^\d$') { "0$slotNumber" } else { $slotNumber }
    } elseif ($line -match $temperaturePattern) {
        $temperatureValue = $Matches[1]
    } elseif ($line -match $snPattern) {
        $snValue = $Matches[1]
        
        $driveInfo += @{
            Controller = $controllerNumber
            Enclosure = $enclosureNumber
            Slot = $slotNumber
            Temperature = $temperatureValue
            SN = $snValue
        }

        $controllerNumber = ""
        $enclosureNumber = ""
        $slotNumber = ""
        $temperatureValue = ""
        $snValue = ""
    }
}

$output = @"
<<<local:sep(0)>>>`n
"@
foreach ($drive in $driveInfo) {
    $output += @"
P "MR C$($drive.Controller) - Enclosure $($drive.Enclosure) - Slot $($drive.Slot)" temperature=$($drive.Temperature);45;50;0;100 Temperature:$($drive.Temperature)C SN:$($drive.SN)`n
"@
}

Write-Output $output
