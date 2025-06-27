<# a.ps1
pellis@cmitsolutions.com
2025-06-27-002

Latest Notes: Included check for file in script path, this is handy if you are working on offline systems.

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

# Define the full path to the script file based on the current script's directory
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath $scriptName


# Skip the block if the script file exists
if (-not (Test-Path $scriptPath)) {
    # Check if the script exists as a command
    if (-not (Get-Command $scriptName -ErrorAction SilentlyContinue)) {
        # Ensure NuGet provider is installed without prompting
        if (-not (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)) {
            Install-PackageProvider -Name NuGet -Force -Scope CurrentUser
        }

        # Install the script if it's not found
        Write-Host "Script not found. Installing from PowerShell Gallery..."
        Install-Script -Name Get-WindowsAutopilotInfo -Force -Scope CurrentUser
    }
} else {
    Write-Host "Script file already exists at $scriptPath. Skipping installation block."
}


# Run the script to get Autopilot HWID info and save to the temporary CSV file
& $scriptPath -OutputFile $tempCsvFile

Write-Host "*********************************************************************************************************"
Write-Host "If the script gave an error and no hash, citing Get-CimInstance : Access Denied and Unable to retrieve device hardware data, just run:"
Write-Host "winrm qc"
Write-Host "and click yes to the prompts and try again"
Write-Host "If it still didn't work you may need a build update of Windows 11 or else capture this OOBE after a Reset PC"
Write-Host "*********************************************************************************************************"

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