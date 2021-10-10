<#
.SYNOPSIS
    Short description
.DESCRIPTION
    Long description
.EXAMPLE
    PS C:\> <example usage>
    Explanation of what the example does
.INPUTS
    Inputs (if any)
.OUTPUTS
    Output (if any)
.NOTES
    General notes
#>
function Unregister-HydrationReminderTask {
    [CmdletBinding(SupportsShouldProcess,ConfirmImpact="High")]
    param ()

    try {
        Get-ScheduledTask -TaskName "HydrationReminder"
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