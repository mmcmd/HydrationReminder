<#
.SYNOPSIS
    Removes any task that HydrationReminder created in Task Scheduler
.EXAMPLE
    PS C:\> Unregister-HydrationReminderTask
    Removes any task with the name "HydrationReminder" from 
#>
function Unregister-HydrationReminderTask {
    [CmdletBinding(SupportsShouldProcess,ConfirmImpact="High")]
    param (
        [Parameter()]
        [PSCredential]
        $Credential
    )

    try {
        Get-ScheduledTask -TaskName "HydrationReminder" -ErrorAction Stop
    }
    catch [Microsoft.PowerShell.Cmdletization.Cim.CimJobException] {
        throw "No HydrationReminder task found"
    }
    catch {
        throw "Error accessing task scheduler. $($_.Exception.Message)"
    }
    
    if ($PSCmdlet.ShouldProcess("Task Scheduler","Unregister")) {
        Unregister-ScheduledTask -TaskName "HydrationReminder"
    }
    
}
Export-ModuleMember -Function "Unregister-HydrationReminderTask"