<#
.SYNOPSIS
    Stops any active notification jobs from HydrationReminders 
.EXAMPLE
    Stop-HydrationReminder
.LINK
    https://github.com/mmcmd/HydrationReminder
#>
function Stop-HydrationReminder {
    [CmdletBinding(HelpUri = 'https://github.com/mmcmd/HydrationReminder')]
    [OutputType([PSCustomObject])]
    Param ()

    $JobsStopped = [PSCustomObject]@()

    try {
        $HydrationReminderJob = Get-Job -Name "HydrationReminder" | Where-Object {($_.Name -eq "HydrationReminder") -and ($_.State -eq "Running")}
        if (!$HydrationReminderJob) {
            throw "No active hydration reminder job found"
        }
        $HydrationReminderJob | Stop-Job
        $HydrationReminderJob | ForEach-Object {
            $JobsStopped += Get-Job $_.Id
        }
        return $JobsStopped
    }
    catch {
        Write-Error "Failed to stop hydration reminder. $($_.Exception.Message)"
    }


}
Export-ModuleMember -Function "Stop-HydrationReminder"