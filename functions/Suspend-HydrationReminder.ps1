<#
.SYNOPSIS
    Pauses your hydration reminders for a while, or until you resume them
.DESCRIPTION
    Without parameters, pauses until the end of today's reminder window; reminders come back tomorrow.
    -Minutes and -Until pause for a set time and resume by themselves.
    -Indefinitely disables the scheduled task (keeping your settings) until you run Resume-HydrationReminder.
    For meetings or games, Windows' Do Not Disturb / Focus also silences reminders.
.EXAMPLE
    PS C:\> Suspend-HydrationReminder
    No more reminders today
.EXAMPLE
    PS C:\> Suspend-HydrationReminder -Minutes 90
.EXAMPLE
    PS C:\> Suspend-HydrationReminder -Until 17:00
.EXAMPLE
    PS C:\> Suspend-HydrationReminder -Indefinitely
.LINK
    https://github.com/mmcmd/HydrationReminder
#>
function Suspend-HydrationReminder {
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'Today', HelpUri = 'https://github.com/mmcmd/HydrationReminder')]
    param (
        [Parameter(Mandatory, ParameterSetName = 'Minutes')]
        [ValidateRange(1, 100000)]
        [int]
        $Minutes,
        [Parameter(Mandatory, ParameterSetName = 'Until')]
        [datetime]
        $Until,
        [Parameter(Mandatory, ParameterSetName = 'Indefinitely')]
        [switch]
        $Indefinitely
    )

    $ErrorActionPreference = 'Stop'

    $State = Get-HydrationState
    if (-not $State) {
        throw "No hydration reminder is set up. Run Start-HydrationReminder first."
    }

    if ($Indefinitely) {
        if ($PSCmdlet.ShouldProcess('Task Scheduler', "Disable '$script:TaskName' task")) {
            Disable-ScheduledTask -TaskName $script:TaskName | Out-Null
            Write-Output "Hydration reminders paused until you run Resume-HydrationReminder."
        }
        return
    }

    $PausedUntil = switch ($PSCmdlet.ParameterSetName) {
        'Minutes' { (Get-Date).AddMinutes($Minutes) }
        'Until' { $Until }
        'Today' { [datetime]::Today + $State.EndTime }
    }
    if ($PausedUntil -le (Get-Date)) {
        throw "$PausedUntil is in the past. To pause until tomorrow use e.g. -Until '$((Get-Date).AddDays(1).ToString('yyyy-MM-dd')) 09:00'."
    }

    if ($PSCmdlet.ShouldProcess($script:StatePath, "Pause until $PausedUntil")) {
        $State.PausedUntil = $PausedUntil
        Set-HydrationState -State $State
        Write-Output "Hydration reminders paused until $PausedUntil."
    }
}
