# Settings and pause state live in one small JSON file per user, so the scheduled task,
# a manual 'hydrate' and Suspend/Resume all agree without anything running in the background.

function Get-HydrationState {
    if (-not (Test-Path -Path $script:StatePath)) {
        return $null
    }
    $State = Get-Content -Path $script:StatePath -Raw | ConvertFrom-Json
    [PSCustomObject]@{
        Interval    = [int]$State.Interval
        DailyGoal   = [int]$State.DailyGoal
        Unit        = [string]$State.Unit
        StartTime   = [timespan]$State.StartTime
        EndTime     = [timespan]$State.EndTime
        PausedUntil = if ($State.PausedUntil) { [datetime]$State.PausedUntil } else { $null }
    }
}

function Set-HydrationState {
    param (
        [Parameter(Mandatory)]
        [PSCustomObject]
        $State
    )

    $Folder = Split-Path -Path $script:StatePath -Parent
    if (-not (Test-Path -Path $Folder)) {
        New-Item -Path $Folder -ItemType Directory -Force | Out-Null
    }
    [PSCustomObject]@{
        Interval    = $State.Interval
        DailyGoal   = $State.DailyGoal
        Unit        = $State.Unit
        StartTime   = $State.StartTime.ToString('hh\:mm')
        EndTime     = $State.EndTime.ToString('hh\:mm')
        PausedUntil = if ($State.PausedUntil) { $State.PausedUntil.ToString('o') } else { $null }
    } | ConvertTo-Json | Set-Content -Path $script:StatePath -Encoding UTF8
}
