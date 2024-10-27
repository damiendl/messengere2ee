# Input Folder Path, insert the folder path where all input files are placed in
$inputFolderPath = "E:\DESKTOP\New folder\batch"
# Output Folder Path
$outputFolderPath = "$inputFolderPath\Output"
if (-not (Test-Path $outputFolderPath)) {
    try {
        New-Item -Path $outputFolderPath -ItemType Directory -ErrorAction Stop
        Write-Host "Created output folder: $outputFolderPath"
    } catch {
        Write-Error "Failed to create output folder: $_"
        exit
    }
}

# Function to convert timestamp to human-readable value
function Convert-Timestamp {
    param (
        [long]$timestamp
    )
    return [System.DateTimeOffset]::FromUnixTimeMilliseconds($timestamp).ToLocalTime().ToString("MMMM dd, yyyy h:mm:ss.fff tt")
}

# Get all files from the folder
$allFiles = Get-ChildItem -Path $inputFolderPath -File -ErrorAction Stop

foreach ($file in $allFiles) {
    try {
        $outputFilePath = "$outputFolderPath\$($file.BaseName)-output.txt"
        # Read Content
        $jsonData = Get-Content -Path $file.FullName -Encoding UTF8 -ErrorAction Stop
        # Convert data to JSON
        $data = $jsonData | ConvertFrom-Json -ErrorAction Stop

        # Prepare the participant list
        $participants = "Participants:`n - " + ($data.participants -join "`n - ") + "`n"

        # Process the data and create the output
        $output = @()
        $output += $participants  # Add participants section

        foreach ($message in $data.messages) {
            $sender = $message.senderName
            $timestamp = Convert-Timestamp $message.timestamp
            $content = if ($message.text -ne "") { $message.text } else { "" }
            $mediaId = if ($message.media.Count -gt 0) { $message.media[0].uri.Split("/")[-1] } else { "" }

            # Format output based on content and media presence
            if ($content -and $mediaId) {
                $output += "Message sender: $sender`nMessage timestamp: $timestamp`nMessage content: $content`nMedia ID: $mediaId`n"
            } elseif ($content) {
                $output += "Message sender: $sender`nMessage timestamp: $timestamp`nMessage content: $content`n"
            } elseif ($mediaId) {
                $output += "Message sender: $sender`nMessage timestamp: $timestamp`nMedia ID: $mediaId`n"
            }
        }

        # Output the result to the output file
        $output -join "`n" | Out-File -FilePath $outputFilePath -Encoding UTF8 -ErrorAction Stop
        Write-Host "Processed $($file.Name). Output saved to $outputFilePath"
    } catch {
        Write-Error "Failed to process $($file.Name): $_"
    }
}
