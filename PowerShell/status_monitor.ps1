# Variables
$logDirectory = "C:\Users\$env:USERNAME\AppData\Local\Packages\MSTeams_8wekyb3d8bbwe\LocalCache\Microsoft\MSTeams\Logs"
$drivePath = "D:\"  # Path to the drive where status.txt is stored
$statusFileName = "status.txt"
$debug = $false  # Set to $false to reduce console output
$lastWrittenStatus = $null

# Mapping Teams statuses to custom statuses
$statusMapping = @{
    "beschäftigt"  = "busy"
    "nicht stören" = "dnd"
    "verfügbar"    = "available"
    "abwesend"     = "away"
}

# Function: Get the latest log file
function Get-LatestLogFile {
    return Get-ChildItem -Path $logDirectory -Filter "MSTeams_*.log" |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
}

# Function: Extract status from the log file
function Extract-Status {
    param (
        [string]$logFile
    )

    Get-Content -Path $logFile -Encoding UTF8 |
        Select-String -Pattern 'Status (.*?)$' |
        ForEach-Object {
            $matches = [regex]::Match($_.Line, 'Status (.*?)$')
            if ($matches.Success) {
                [PSCustomObject]@{
                    TimeStamp = $_.Line.Substring(0, 23)  # Timestamp from the log line
                    Status    = $matches.Groups[1].Value.Trim()
                }
            }
        } | Select-Object -Last 1  # Return only the last status
}

# Function: Write status to the file on the drive
function Write-StatusToFile {
    param (
        [string]$status
    )
	
	Set-Variable -Name lastWrittenStatus -Scope Global

    # Ensure the status is valid and different from the last written status
    if (-not $status -or $status -eq $Global:lastWrittenStatus) {
        if ($debug) { Write-Host "No change in status. Skipping file update." }
        return
    }

    # Check if the drive is connected
    if (Test-Path $drivePath) {
        $filePath = Join-Path -Path $drivePath -ChildPath $statusFileName
        $content = "#latestStatus=$status#"

        try {
            Set-Content -Path $filePath -Value $content -Encoding UTF8
            $Global:lastWrittenStatus = $status
            Write-Host "Status $status written to file: $filePath"
        } catch {
            Write-Host "Failed to write status to file: $($_.Exception.Message)"
        }
    } else {
        Write-Host "Drive not connected: $drivePath. Skipping file update."
    }
}

# Monitor and log status changes
function Monitor-TeamsStatus {
	$customStatus = $null
	$customStatusTimestamp = $null
    $lastTeamsStatus = $null
    $lastTeamsTimestamp = $null

    while ($true) {
        if ($debug) { Write-Host "Searching for the latest log file..." }
        $latestLogFile = Get-LatestLogFile

        if ($latestLogFile) {
            if ($debug) { Write-Host "Found log file: $($latestLogFile.FullName)" }
            $statusData = Extract-Status -logFile $latestLogFile.FullName

            if ($statusData) {
                $rawStatus = $statusData.Status
                $normalizedStatus = $rawStatus.ToLower().Trim()

                if ($statusMapping.ContainsKey($normalizedStatus)) {
                    $currentTeamsStatus = $statusMapping[$normalizedStatus]

                    if ($lastTeamsStatus -ne $currentTeamsStatus) {
                        $lastTeamsStatus = $currentTeamsStatus
                        $lastTeamsTimestamp = Get-Date
                        if ($debug) {  Write-Host "Teams status updated: $currentTeamsStatus" }
                    }
                } elseif ($debug) {
                    Write-Host "Ignored unrecognized status: '$rawStatus'"
                }
            }
        }

        # Determine the latest status
        $finalStatus = $null
        if ($customStatusTimestamp -and ($lastTeamsTimestamp -eq $null -or $customStatusTimestamp -gt $lastTeamsTimestamp)) {
            $finalStatus = $customStatus
        } elseif ($lastTeamsTimestamp) {
            $finalStatus = $lastTeamsStatus
        }

        if ($finalStatus) {
            Write-StatusToFile -status $finalStatus
            if ($debug) { Write-Host "Final status: $finalStatus" }
        }

        # Sleep with input simulation
        if ($debug) { Write-Host "Press [E] to manually change the status, or wait 10 seconds until refresh from log files..." }
        $input = $null
        $start = (Get-Date).AddSeconds(10)

        while ((Get-Date) -lt $start) {
            if ([Console]::KeyAvailable) {
                $key = [Console]::ReadKey($true).Key
                if ($key -eq "E") {
                    $input = "E"
                    break
                }
            }
        }

        if ($input -eq "E") {
            Write-Host "Select your status:"
            Write-Host "1: Available"
            Write-Host "2: Busy"
            Write-Host "3: Away"
            Write-Host "4: Do Not Disturb"

            $selection = Read-Host "Enter your choice (1-4)"

            switch ($selection) {
                "1" { $customStatus = "available" }
                "2" { $customStatus = "busy" }
                "3" { $customStatus = "away" }
                "4" { $customStatus = "dnd" }
                default { Write-Host "Invalid selection. Skipping..."; continue }
            }

            $customStatusTimestamp = Get-Date
            if ($debug) { Write-Host "Manually set custom status: $customStatus" }
        }
    }
}

if (-not $debug) { Write-Host "Press [E] to manually change the status, or wait 10 seconds until refresh from log files..." }
# Start monitoring
Monitor-TeamsStatus
