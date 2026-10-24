<#
.SYNOPSIS
    Sets up (or updates) your daily hydration reminders
.DESCRIPTION
    Creates a Windows scheduled task that shows a notification every -Interval minutes between -StartTime
    and -EndTime, every day. Run it once; it keeps working after reboots. Run it again to change settings.
    No administrator rights are needed: the task runs as you, only while you're logged on.
.EXAMPLE
    PS C:\> Start-HydrationReminder
    Reminds you every hour between 08:00 and 22:00 to drink towards a 2 L daily goal
.EXAMPLE
    PS C:\> Start-HydrationReminder -Interval 45 -DailyGoal 80 -Unit Imperial -StartTime 06:30 -EndTime 23:00
    Reminds you every 45 minutes between 06:30 and 23:00 to drink towards an 80 fl oz daily goal
.PARAMETER Interval
    Minutes between reminders. Default is 60
.PARAMETER DailyGoal
    How much water you want to drink each day, in the chosen -Unit. Default is 2000 (mL) or 64 (fl oz)
.PARAMETER Unit
    Metric (mL / L) or Imperial (fl oz). Default is Metric
.PARAMETER StartTime
    Time of day reminders start. Default is 08:00
.PARAMETER EndTime
    Time of day reminders stop. Default is 22:00
.LINK
    https://github.com/mmcmd/HydrationReminder
#>
function Start-HydrationReminder {
    [CmdletBinding(SupportsShouldProcess, HelpUri = 'https://github.com/mmcmd/HydrationReminder')]
    [OutputType([PSCustomObject])]
    param (
        [ValidateRange(1, 720)]
        [int]
        $Interval = 60,
        [ValidateRange(1, 10000)]
        [int]
        $DailyGoal,
        [ValidateSet('Metric', 'Imperial')]
        [string]
        $Unit = 'Metric',
        [timespan]
        $StartTime = '08:00',
        [timespan]
        $EndTime = '22:00'
    )

    $ErrorActionPreference = 'Stop'

    if (-not $PSBoundParameters.ContainsKey('DailyGoal')) {
        $DailyGoal = if ($Unit -eq 'Imperial') { 64 } else { 2000 }
    }
    # shortcut: no windows that cross midnight (e.g. 22:00-02:00); add if night-shift users ask
    if ($StartTime -lt [timespan]::Zero -or $EndTime -ge [timespan]::FromDays(1) -or $EndTime -le $StartTime) {
        throw "EndTime must be later than StartTime on the same day (between 00:00 and 23:59)."
    }
    $Window = $EndTime - $StartTime
    if ($Interval -ge $Window.TotalMinutes) {
        throw "Interval ($Interval minutes) must be shorter than the reminder window ($($Window.TotalMinutes) minutes)."
    }

    $State = [PSCustomObject]@{
        Interval    = $Interval
        DailyGoal   = $DailyGoal
        Unit        = $Unit
        StartTime   = $StartTime
        EndTime     = $EndTime
        PausedUntil = $null
    }

    if ($PSCmdlet.ShouldProcess('Task Scheduler', "Register '$script:TaskName' task")) {
        $Command = Get-HydrationTaskCommand
        $Action = New-ScheduledTaskAction -Execute $Command.Execute -Argument $Command.Argument

        # A daily trigger can't take -RepetitionInterval directly, so borrow the repetition from a -Once trigger.
        # The extra minute makes the run at exactly EndTime happen too.
        $Trigger = New-ScheduledTaskTrigger -Daily -At ([datetime]::Today + $StartTime)
        $Trigger.Repetition = (New-ScheduledTaskTrigger -Once -At ([datetime]::Today + $StartTime) `
                -RepetitionInterval (New-TimeSpan -Minutes $Interval) `
                -RepetitionDuration ($Window + (New-TimeSpan -Minutes 1))).Repetition

        $Principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive -RunLevel Limited
        $Settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries `
            -ExecutionTimeLimit (New-TimeSpan -Minutes 5) -MultipleInstances IgnoreNew

        $Task = @{
            TaskName    = $script:TaskName
            Action      = $Action
            Trigger     = $Trigger
            Principal   = $Principal
            Settings    = $Settings
            Description = 'Hydration reminders from the HydrationReminder PowerShell module. Change with Start-HydrationReminder, pause with Suspend-HydrationReminder, remove with Stop-HydrationReminder.'
            Force       = $true
        }
        Register-ScheduledTask @Task | Out-Null
        Set-HydrationState -State $State
    }

    $State | Select-Object Interval, DailyGoal, Unit, StartTime, EndTime
}
