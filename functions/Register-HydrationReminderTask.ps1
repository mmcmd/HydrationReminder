<#
.SYNOPSIS
    Registers a task in task scheduler to start reminding you to hydrate at startup
.DESCRIPTION
    Registers a task in task scheduler to start reminding you to hydrate at startup. Specifiying a custom
    argument list is possible using the -HydrationCommand parameter
.EXAMPLE
    PS C:\> Register-HydrationReminderTask
    Registers a  hydration reminder task with the default parameters for Start-HydrationReminder
.EXAMPLE
    PS C:\> Register-HydrationReminderTask -HydrationCommand "Start-HydrationReminder -ReminderInterval 45 -DailyWaterIntake 2200"
    Registers a hydration reminder task with custom parameters. Be careful not to make any spelling mistakes
    with the parameter names or the task will fail.
.PARAMETER Credential
    Specify custom credentials to run the task under, if necessary.
.PARAMETER HydrationCommand
    This parammeter is only to be used if you want to pass custom arguments to the Start-HydrationReminder command:
    PS C:\> Register-HydrationReminderTask -HydrationCommand "Start-HydrationReminder -ReminderInterval 45 -DailyWaterIntake 2200"
.LINK 
    https://github.com/mmcmd/HydrationReminder
#>
function Register-HydrationReminderTask {
    [CmdletBinding(SupportsShouldProcess,ConfirmImpact="High")]
    param (
        [Parameter()]
        [PSCredential]
        $Credential,
        [Parameter(HelpMessage="This parammeter is only to be used if you want to pass custom arguments to the Start-HydrationReminder command")]
        [ValidatePattern("Start-HydrationReminder.*")]
        [string]
        $HydrationCommand = "Start-HydrationReminder"
    )

    if ($PSCmdlet.ShouldProcess("Task Scheduler","New Task")) {
        $Time = New-ScheduledTaskTrigger -AtLogon
        $Launch = New-ScheduledTaskAction -Execute "Powershell.exe" -Argument "Import-Module HydrationReminder;$HydrationCommand"
        if ($Credential) {
            $Params = @{
                TaskName = "HydrationReminder"
                Trigger = $Time
                Action = $Launch
                User = $Credential.UserName
                Password = $Credential.Password
                Description = "Task created by the HydrationReminder PowerShell module"
            }
        }
        else {
            $Params = @{
                TaskName = "HydrationReminder"
                Trigger = $Time
                Action = $Launch
                User = $env:USERNAME
                Description = "Task created by the HydrationReminder PowerShell module"
            }
        }
        Register-ScheduledTask @Params
    }
}
Export-ModuleMember -Function "Register-HydrationReminderTask"