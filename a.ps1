<# a.ps1
pellis@cmitsolutions.com
2025-06-26-002

Latest Notes: Nested nuget check

When system returns gets to OOBE we want to be able to issue a quick F10 command prompt and then D:\a
this runs the batch to start powershell unrestricted and executes the Get-WindowsAutopilotInfo.ps1 to capture the hardware hash
These devices are often not connected, so we need the Get-WindowsAutopilotInfo.ps1 to be extracted from the nupkg file at 
https://www.powershellgallery.com/packages/Get-WindowsAutopilotInfo

Just add that file to the root of the flash drive and with each run you build a larger AutopilotHWID.ps1 file to import.

In case of file corruption we also keep the individual files as well.

#>
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Set location to the script's directory
Set-Location -Path $PSScriptRoot
$scriptName = "Get-WindowsAutopilotInfo.ps1"

# Generate a unique name for the temporary CSV file based on the device
$serialno =  (Get-WmiObject -Class Win32_BIOS | Select-Object -Property SerialNumber).SerialNumber
$tempCsvFile = "$PSScriptRoot\AutopilotHWID_$serialno.csv"

# Check if the script exists
if (-not (Get-Command $scriptName -ErrorAction SilentlyContinue)) {
# Ensure NuGet provider is installed without prompting
    if (-not (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)) {
        Install-PackageProvider -Name NuGet -Force -Scope CurrentUser
    }

    # Install the script if it's not found
    Write-Host "Script not found. Installing from PowerShell Gallery..."
    Install-Script -Name Get-WindowsAutopilotInfo -Force -Scope CurrentUser
}

# Run the script to get Autopilot HWID info and save to the temporary CSV file
Get-WindowsAutopilotInfo.ps1 -OutputFile $tempCsvFile
Import-Csv -Path $tempCsvFile | Format-Table -AutoSize

# Read the contents of the temporary CSV file
$tempCsvContent = Get-Content -Path $tempCsvFile

# Append the contents to the main AutopilotHWID.csv file, excluding the header if it exists
if (Test-Path "$PSScriptRoot\AutopilotHWID.csv") {
    $mainCsvContent = Get-Content -Path "$PSScriptRoot\AutopilotHWID.csv"
    $header = $mainCsvContent[0]
    $tempCsvContentWithoutHeader = $tempCsvContent | Select-Object -Skip 1
    Add-Content -Path "$PSScriptRoot\AutopilotHWID.csv" -Value $tempCsvContentWithoutHeader
} else {
    # If the main CSV file does not exist, create it with the contents of the temporary CSV file
    $tempCsvContent | Out-File -FilePath "$PSScriptRoot\AutopilotHWID.csv"
}
read-host -Prompt "Press enter to reboot, CTRL-C to abort"
shutdown -r -t 2 -f