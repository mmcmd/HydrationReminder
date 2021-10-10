<#
.SYNOPSIS
    Short description
.DESCRIPTION
    Long description
.EXAMPLE
    Example of how to use this cmdlet
.EXAMPLE
    Another example of how to use this cmdlet
.INPUTS
    Inputs to this cmdlet (if any)
.OUTPUTS
    Output from this cmdlet (if any)
.NOTES
    General notes
.COMPONENT
    The component this cmdlet belongs to
.ROLE
    The role this cmdlet belongs to
.FUNCTIONALITY
    The functionality that best describes this cmdlet
#>
function Stop-HydrationReminder {
    [CmdletBinding(HelpUri = 'https://github.com/mmcmd/HydrationReminder',
                   ConfirmImpact='Medium')]
    [OutputType([PSObject])]
    Param (
    )

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