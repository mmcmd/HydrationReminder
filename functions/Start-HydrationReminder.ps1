#requires -Modules BurntToast
#requires -Version 5.1
<#
.SYNOPSIS
    Script that sends you a Windows Notification to remind you to hydrate
.DESCRIPTION
    A fairly simple module to remind you (by default every hour) to drink some water in order to stay hydrated. Inspired by a Twitch Hydration bot
.EXAMPLE
    The following example would send a reminder every 45 mins for 24 hours and assume you're drinking 2500mL of water every 16 hours
    Start-HydrationReminder -ReminderInterval 45 -DailyWaterIntake 2500 -Duration 24
.EXAMPLE
    The following example will use the default values of the cmdlet, which is to remind you every hour for 16 hours to drink
    up to a total of 2000mL at the 16th hour
    Start-HydrationReminder
.PARAMETER ReminderInterval
    Interval in minutes where a reminder will be sent
.PARAMETER DailyWaterIntake
    How much water per 16 hours needs to be consumed
.PARAMETER Duration
    Amount of hours notifications to hydrate will be sent for
.OUTPUTS
    PSCustomObject
        Outputs a PSCustomObject with the following properties:
            Successful = boolean
            ReminderInterval =  Interval in minutes where a reminder will be sent
            DailyWaterIntake = How much water per 16 hours needs to be consumed
            StartedAt = Time at which hydration reminder started (datetime)
            EndsAt = Time at which hydration reminder will end (datetime)
            Status = Status of the background job created
            Location = Location attribute of the job created
            JobID = ID of the job created
            JobName = Name of the job created (by default called 'HydrationReminder')
            JobInstanceID = Instance ID of the job created
.LINK
    https://github.com/mmcmd/HydrationReminder
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
        [ValidateRange(1,1000)]
        [Int]
        $Duration = 16
    )

    $ErrorActionPreference = 'Stop'


    if (([System.Environment]::OSVersion.Version).Major -lt 10) {
        throw "This module does not work on Windows versions below Windows 10"
    }


    $Init = Get-Date

    $EndTime = ($Init).AddHours($Duration)

    $LogoPath = "$PSScriptRoot\..\images\drinkwater.png"


    $Job = {
        param ($ReminderInterval,$DailyWaterIntake,$Duration,$Init,$EndTime,$LogoPath)


        while ($TimeSinceStart -le $EndTime) {

            Start-Sleep ($ReminderInterval*60)

            $TimeSinceStart = ((Get-Date) - $Init)


            # Calculate the amount of water that should have been consumed
            $TotalWaterConsumed = ($DailyWaterIntake * ((Get-Date) - $TimeSinceStart).TotalHours)/16     # Total water consumed in mL, the 16 is just assuming the avg human is awake 16 hours a day (so 2L in 16 hours)

            # Format the amount of water that should have been consumed
            if ($TotalWaterConsumed -gt 1000) {

                $LitresConsumed = [Math]::Floor($TotalWaterConsumed/1000)   # Calculate how many litres have been consumed and round down (in order to obtain the mL leftover)
                $mLconsumed = $TotalWaterConsumed - $LitresConsumed         # Calculate how many mL have been consumed

                $TotalWaterConsumed = "$LitresConsumed`L $mLConsumed`mL"
            }
            else {
                $TotalWaterConsumed = [Math]::Ceiling($TotalWaterConsumed)  # Round up a mL (there's nothing wrong with drinking a little more water 😉)
            }

            # Format time for notification
            if ($TimeSinceStart.Hours -lt 1){
                $TimeSinceStart = "$($TimeSinceStart.Minutes) minutes"
            }
            else {
                $TimeSinceStart = "$($TimeSinceStart.Hours) hours $($TimeSinceStart.Minutes) minutes"
            }

            # Splat the parameters for readability
            $NotificationArgs = @{
                AppLogo = $LogoPath
                ExpirationTime = (Get-Date).AddMinutes(10)
                Text = "It has been $TimeSinceStart since you've started your session and so far you should have consumed at least $TotalWaterConsumed mL of water to maintain optimal hydration!"
            }

            # Send out the notification
            New-BurntToastNotification @NotificationArgs

        }

        if ($TimeSinceStart.TotalHours -gt $Duration) {
            $NotificationArgs = @{
                AppLogo = $LogoPath
                ExpirationTime = (Get-Date).AddMinutes(5)
                Text = "Your reminder session has ended. In total you should have consumed $TotalWaterConsumed mL in the $Duration hours."
            }
        }

        

    }

    try {
        $CheckForJobs = Get-Job -Name "HydrationReminder" -ErrorAction SilentlyContinue | Where-Object { $_.State -eq "Running" }
        if ($CheckForJobs) {
            throw "Hydration reminder is already running"
        }
        $Job = Start-Job -ScriptBlock $Job -Name "HydrationReminder" -ArgumentList $ReminderInterval,$DailyWaterIntake,$Duration,$Init,$EndTime,$LogoPath
        $Output = [PSCustomObject]@{
            Successful = $true
            ReminderInterval = $ReminderInterval
            DailyWaterIntake = $DailyWaterIntake
            StartedAt = $Init.DateTime
            EndsAt = $EndTime
            Status = $Job.State
            Location = $Job.Location
            JobID = $Job.Id
            JobName = $Job.Name
            JobInstanceID = $Job.InstanceId
        }    
    }
    catch {
        throw "Failed to initiate hydration reminder. $($_.Exception.Message)"
    }

    return $Output
}
Export-ModuleMember -Function "Start-HydrationReminder" -Alias "hydrate"