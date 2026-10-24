<#
.SYNOPSIS
    Resumes hydration reminders paused with Suspend-HydrationReminder
.DESCRIPTION
    Clears any timed pause and re-enables the scheduled task if it was suspended with -Indefinitely.
.EXAMPLE
    PS C:\> Resume-HydrationReminder
.LINK
    https://github.com/mmcmd/HydrationReminder
#>
function Resume-HydrationReminder {
    [CmdletBinding(SupportsShouldProcess, HelpUri = 'https://github.com/mmcmd/HydrationReminder')]
    param ()

    $ErrorActionPreference = 'Stop'

    $State = Get-HydrationState
    if (-not $State) {
        throw "No hydration reminder is set up. Run Start-HydrationReminder first."
    }

    if ($PSCmdlet.ShouldProcess('Task Scheduler', "Resume '$script:TaskName' task")) {
        $State.PausedUntil = $null
        Set-HydrationState -State $State
        Enable-ScheduledTask -TaskName $script:TaskName | Out-Null
        Write-Output "Hydration reminders resumed."
    }
}
