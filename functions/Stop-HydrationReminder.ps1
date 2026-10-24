<#
.SYNOPSIS
    Removes your hydration reminders completely
.DESCRIPTION
    Deletes the scheduled task and the saved settings. To pause instead, use Suspend-HydrationReminder.
.EXAMPLE
    PS C:\> Stop-HydrationReminder
.LINK
    https://github.com/mmcmd/HydrationReminder
#>
function Stop-HydrationReminder {
    [CmdletBinding(SupportsShouldProcess, HelpUri = 'https://github.com/mmcmd/HydrationReminder')]
    param ()

    $ErrorActionPreference = 'Stop'

    if (-not (Get-ScheduledTask -TaskName $script:TaskName -ErrorAction SilentlyContinue)) {
        throw "No hydration reminder is set up. Nothing to stop."
    }
    if ($PSCmdlet.ShouldProcess('Task Scheduler', "Remove '$script:TaskName' task")) {
        Unregister-ScheduledTask -TaskName $script:TaskName -Confirm:$false
        Remove-Item -Path (Split-Path -Path $script:StatePath -Parent) -Recurse -Force -ErrorAction SilentlyContinue
    }
}
