#requires -Module BurntToast
#requires -Version 5.0
<#
.SYNOPSIS
    Script that sends you a Windows Notification to remind you to hydrate
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
function Start-HydrationReminder {
    [CmdletBinding(SupportsShouldProcess=$true,
                   PositionalBinding=$false,
                   HelpUri = 'https://github.com/mmcmd/HydrationReminder',
                   ConfirmImpact='Medium')]
    [Alias('hydrate')]
    [OutputType([PSObject])]
    Param (
        [Parameter(HelpMessage='Interval in minutes at which you will receive a notification to drink')]
        [ValidateRange(1,1380)]
        [Int]
        $ReminderInterval = 60,
        [Parameter(HelpMessage='Amount of daily water intake needed (in mL)')]
        [ValidateRange(1,10000)]
        [Int]
        $DailyWaterIntake = 2000,
        [Parameter(HelpMessage='Amount in hours you want to be reminded for')]
        [Int]
        $Duration = 16
    )

    $ErrorActionPreference = 'Stop'


    if (([System.Environment]::OSVersion.Version).Major -lt 10) {
        throw "This module does not work on Windows versions below Windows 10"
    }


    $Init = Get-Date

    $Job = {

        while ($TimeSinceStart.TotalHours -le $Duration) {

            Start-Sleep ($ReminderInterval*60)

            $TimeSinceStart = ($Init - (Get-Date))



            # Calculate the amount of water that should have been consumed
            $TotalWaterConsumed = ($DailyWaterIntake * ((Get-Date) - $TimeSinceStart).TotalHours)/16     # Total water consumed in mL, the 16 is just assuming the avg human is awake 16 hours a day (so 2L in 16 hours)

            # Format the amount of water that should have been consumed
            if ($TotalWaterConsumed -gt 1000) {

                $LitresConsumed = [Math]::Floor($TotalWaterConsumed/1000)   # Calculate how many litres have been consumed and round down (in order to obtain the mL leftover)
                $mLconsumed = $TotalWaterConsumed - $LitresConsumed         # Calculate how many mL have been consumed

                $TotalWaterConsumed = "$LitresConsumed`L $mLConsumed`mL"
            }
            else {
                $TotalWaterConsumed = "$([Math]::Ceiling($TotalWaterConsumed)) mL"  # Round up a mL (there's nothing wrong with drinking a little more water 😉)
            }

            # Format time for notification
            if ($TimeSinceStart.Hours -lt 1){
                $TimeSinceStart = "$($TimeSinceStart.TotalMinutes) minutes"
            }
            else {
                $TimeSinceStart = "$($TimeSinceStart.Hours) hours $($TimeSinceStart.Minutes) minutes"
            }

            # Splat the parameters for readability
            $NotificationArgs = @{
                AppLogo = "$PSScriptRoot\images\waterbottle.png"
                ExpirationTime = (Get-Date).AddMinutes(5)
                Text = "It has been $TimeSinceStart since you've started your session and so far you should have consumed at least $TotalWaterConsumed of water to maintain optimal hydration! 💦"
            }

            # Send out the notification
            New-BurntToastNotification @NotificationArgs

        }

        if ($TimeSinceStart.TotalHours -gt $Duration) {
            $NotificationArgs = @{
                AppLogo = "$PSScriptRoot\images\waterbottle.png"
                ExpirationTime = (Get-Date).AddMinutes(5)
                Text = "Your reminder session has ended. In total you should have consumed $TotalWaterConsumed mL in the $Duration hours. 💦"
            }
        }

        

    }

    try {
        $CheckForJobs = Get-Job -Name "hydrate" -ErrorAction SilentlyContinue | Where-Object { $_.State -eq "Running" }
        if ($CheckForJobs) {
            throw "Hydration reminder is already running"
        }
        Start-Job -ScriptBlock $Job -Name "hydration"
        $Output = [PSCustomObject]@{
            Successful = $true
            ReminderInterval = $ReminderInterval
            DailyWaterIntake = $DailyWaterIntake
            StartedAt = $Init.DateTime
            EndsAt = (Get-Date).AddHours($Duration)
        }    
    }
    catch {
        $Output = [PSCustomObject]@{
            Successful = $false
        }
        throw $_
    }

    return $Output
}
#Export-ModuleMember -Function "Start-HydrationReminder" -Alias "hydrate"