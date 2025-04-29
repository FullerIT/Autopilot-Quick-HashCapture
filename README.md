# Autopilot-Quick-HashCapture
 
Just a short script to make capturing the hardware hash from a usb drive a bit quicker.


If it's a single disk system, from the OOBE you just need to press SHIFT-F10 to open command prompt and then type:


D:\a

Then the batch runs the powershell and captures the hash to the csv.


You need to add the https://www.powershellgallery.com/packages/Get-WindowsAutopilotInfo  ps1 file so it can work in offline mode.


