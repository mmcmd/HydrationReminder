<#
.SYNOPSIS
    Shows a hydration reminder notification right now
.DESCRIPTION
    Shows one notification using your Start-HydrationReminder settings (or the defaults if none are set up).
    The scheduled task calls this with -Scheduled, which stays quiet while reminders are suspended.
.EXAMPLE
    PS C:\> hydrate
.PARAMETER Scheduled
    Used by the scheduled task: skip the notification while suspended
.LINK
    https://github.com/mmcmd/HydrationReminder
#>
function Send-HydrationReminder {
    [CmdletBinding(HelpUri = 'https://github.com/mmcmd/HydrationReminder')]
    [Alias('hydrate')]
    param (
        [switch]
        $Scheduled
    )

    $ErrorActionPreference = 'Stop'

    $State = Get-HydrationState
    if (-not $State) {
        $State = [PSCustomObject]@{ Interval = 60; DailyGoal = 2000; Unit = 'Metric'; StartTime = [timespan]'08:00'; EndTime = [timespan]'22:00'; PausedUntil = $null }
    }
    $Now = Get-Date
    if ($Scheduled -and $State.PausedUntil -and $State.PausedUntil -gt $Now) {
        Write-Verbose "Suspended until $($State.PausedUntil)"
        return
    }
    # A run missed while the PC was asleep can fire late on wake-up; don't let it nag at midnight
    if ($Scheduled -and ($Now.TimeOfDay -lt $State.StartTime -or $Now.TimeOfDay -gt $State.EndTime.Add([timespan]::FromMinutes(5)))) {
        Write-Verbose "Outside the reminder window"
        return
    }

    $Droplet = [char]::ConvertFromUtf32(0x1F4A7)
    $Notification = @{
        Text             = "$Droplet Hydration Reminder", (Get-HydrationMessage -State $State)
        AppLogo          = Join-Path $script:ModuleRoot 'images\drinkwater.png'
        SnoozeAndDismiss = $true
        # Replaces the previous reminder instead of stacking them up in the notification centre
        UniqueIdentifier = 'HydrationReminder'
    }
    New-BurntToastNotification @Notification
}
