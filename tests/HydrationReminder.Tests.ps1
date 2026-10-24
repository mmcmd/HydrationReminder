# Unit tests run anywhere (Linux pwsh included): Invoke-Pester ./tests
# Integration tests replace your real 'HydrationReminder' scheduled task, so they only run on Windows when asked for:
#   $env:HYDRATION_INTEGRATION = 1; Invoke-Pester ./tests

BeforeAll {
    # Stand-ins so the Windows-only cmdlets exist (and can be mocked) on any OS
    foreach ($Name in 'New-BurntToastNotification', 'Get-ScheduledTask', 'Register-ScheduledTask', 'Unregister-ScheduledTask',
        'Enable-ScheduledTask', 'Disable-ScheduledTask', 'New-ScheduledTaskAction', 'New-ScheduledTaskTrigger',
        'New-ScheduledTaskPrincipal', 'New-ScheduledTaskSettingsSet') {
        if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
            New-Item -Path "function:global:$Name" -Value { param() } | Out-Null
        }
    }
    # The .psm1, not the .psd1, so BurntToast doesn't need to be installed for unit tests
    Import-Module "$PSScriptRoot/../HydrationReminder.psm1" -Force
}

Describe 'Get-HydrationMessage' {
    BeforeAll {
        function New-State($Goal = 2000, $Unit = 'Metric') {
            [PSCustomObject]@{ DailyGoal = $Goal; Unit = $Unit; StartTime = [timespan]'08:00'; EndTime = [timespan]'22:00' }
        }
    }

    It 'expects a share of the goal proportional to the time passed' {
        InModuleScope HydrationReminder -Parameters @{ State = (New-State) } {
            # 3.5 of 14 hours = 1/4 of 2000 mL = 500 mL
            Get-HydrationMessage -State $State -Now ([datetime]'2026-01-01 11:30') |
                Should -Be 'Time for some water! By now you should have had about 500 mL of your 2 L goal.'
        }
    }

    It 'rounds metric amounts to the nearest 50 mL' {
        InModuleScope HydrationReminder -Parameters @{ State = (New-State) } {
            # 1/14 of 2000 = 142.9 mL -> 150 mL
            Get-HydrationMessage -State $State -Now ([datetime]'2026-01-01 09:00') | Should -Match 'about 150 mL of your 2 L goal'
        }
    }

    It 'switches to litres from 1000 mL' {
        InModuleScope HydrationReminder -Parameters @{ State = (New-State) } {
            Get-HydrationMessage -State $State -Now ([datetime]'2026-01-01 15:00') | Should -Match 'about 1 L of your 2 L goal'
        }
    }

    It 'uses whole fl oz for imperial' {
        InModuleScope HydrationReminder -Parameters @{ State = (New-State -Goal 64 -Unit Imperial) } {
            # 2/14 of 64 = 9.14 fl oz -> 9 fl oz
            Get-HydrationMessage -State $State -Now ([datetime]'2026-01-01 10:00') | Should -Match 'about 9 fl oz of your 64 fl oz goal'
        }
    }

    It 'caps at the full goal after the window ends' {
        InModuleScope HydrationReminder -Parameters @{ State = (New-State) } {
            Get-HydrationMessage -State $State -Now ([datetime]'2026-01-01 23:30') | Should -Match 'about 2 L of your 2 L goal'
        }
    }

    It 'just states the goal at the very start of the day' {
        InModuleScope HydrationReminder -Parameters @{ State = (New-State) } {
            Get-HydrationMessage -State $State -Now ([datetime]'2026-01-01 08:00') | Should -Be 'Time for some water! Your goal today is 2 L.'
        }
    }
}

Describe 'Get-HydrationTaskCommand' {
    It 'runs the given shell headless and imports the module by full path' {
        InModuleScope HydrationReminder {
            $Command = Get-HydrationTaskCommand -PowerShellPath 'C:\Program Files\PowerShell\7\pwsh.exe' -ModulePath "C:\Users\O'Neil\HydrationReminder.psd1"
            $Command.Execute | Should -Be 'conhost.exe'
            $Command.Argument | Should -Be ('--headless "C:\Program Files\PowerShell\7\pwsh.exe" -NoProfile -NonInteractive -ExecutionPolicy Bypass ' +
                '-Command "Import-Module ''C:\Users\O''''Neil\HydrationReminder.psd1''; Send-HydrationReminder -Scheduled"')
        }
    }
}

Describe 'Reminder lifecycle' {
    BeforeAll {
        $script:TestState = Join-Path $TestDrive 'HydrationReminder/settings.json'
        InModuleScope HydrationReminder -Parameters @{ Path = $script:TestState } { $script:StatePath = $Path }
    }
    BeforeEach {
        Remove-Item -Path $script:TestState -ErrorAction SilentlyContinue
        Mock -ModuleName HydrationReminder Register-ScheduledTask {}
        Mock -ModuleName HydrationReminder New-ScheduledTaskTrigger { [PSCustomObject]@{ Repetition = $null } }
        Mock -ModuleName HydrationReminder Disable-ScheduledTask {}
        Mock -ModuleName HydrationReminder Enable-ScheduledTask {}
        Mock -ModuleName HydrationReminder New-BurntToastNotification {}
    }

    It 'Start saves the settings and registers the task' {
        $Result = Start-HydrationReminder -Unit Imperial -StartTime 07:00 -EndTime 19:00 -Interval 30
        $Result.DailyGoal | Should -Be 64
        Should -Invoke -ModuleName HydrationReminder Register-ScheduledTask -Times 1
        Get-Content $script:TestState -Raw | ConvertFrom-Json | ForEach-Object {
            $_.Unit | Should -Be 'Imperial'
            $_.StartTime | Should -Be '07:00'
            $_.Interval | Should -Be 30
        }
    }

    It 'Start rejects a window that ends before it starts' {
        { Start-HydrationReminder -StartTime 22:00 -EndTime 08:00 } | Should -Throw '*EndTime*'
        Should -Invoke -ModuleName HydrationReminder Register-ScheduledTask -Times 0
    }

    It 'Start rejects an interval longer than the window' {
        { Start-HydrationReminder -StartTime 08:00 -EndTime 09:00 -Interval 90 } | Should -Throw '*Interval*'
    }

    It 'Suspend -Minutes silences scheduled reminders but not manual ones' {
        Start-HydrationReminder -StartTime 00:00 -EndTime 23:59 -Interval 60
        Suspend-HydrationReminder -Minutes 30
        Send-HydrationReminder -Scheduled
        Should -Invoke -ModuleName HydrationReminder New-BurntToastNotification -Times 0
        Send-HydrationReminder
        Should -Invoke -ModuleName HydrationReminder New-BurntToastNotification -Times 1
    }

    It 'Resume clears a timed pause and re-enables the task' {
        Start-HydrationReminder -StartTime 00:00 -EndTime 23:59 -Interval 60
        Suspend-HydrationReminder -Minutes 30
        Resume-HydrationReminder
        Should -Invoke -ModuleName HydrationReminder Enable-ScheduledTask -Times 1
        Send-HydrationReminder -Scheduled
        Should -Invoke -ModuleName HydrationReminder New-BurntToastNotification -Times 1
    }

    It 'Suspend -Indefinitely disables the task' {
        Start-HydrationReminder
        Suspend-HydrationReminder -Indefinitely
        Should -Invoke -ModuleName HydrationReminder Disable-ScheduledTask -Times 1
    }

    It 'Suspend refuses a time in the past' {
        Start-HydrationReminder
        { Suspend-HydrationReminder -Until (Get-Date).AddMinutes(-5) } | Should -Throw '*in the past*'
    }

    It 'Suspend needs Start first' {
        { Suspend-HydrationReminder -Minutes 10 } | Should -Throw '*Start-HydrationReminder first*'
    }

    It 'Scheduled reminders stay quiet outside the window' {
        $Now = Get-Date
        $Start = $Now.AddHours(1).TimeOfDay
        if ($Start -gt [timespan]'22:00') { Set-ItResult -Skipped -Because 'too close to midnight for this test' }
        Start-HydrationReminder -StartTime $Start.ToString('hh\:mm') -EndTime 23:59 -Interval 30
        Send-HydrationReminder -Scheduled
        Should -Invoke -ModuleName HydrationReminder New-BurntToastNotification -Times 0
    }
}

Describe 'Scheduled task on real Windows' -Tag 'Integration' -Skip:(-not $env:HYDRATION_INTEGRATION) {
    BeforeAll {
        Remove-Module HydrationReminder -Force
        Import-Module "$PSScriptRoot/../HydrationReminder.psd1" -Force
    }
    AfterAll {
        Unregister-ScheduledTask -TaskName HydrationReminder -Confirm:$false -ErrorAction SilentlyContinue
    }

    It 'registers a daily task repeating every interval inside the window' {
        Start-HydrationReminder -Interval 30 -StartTime 09:00 -EndTime 17:00 | Out-Null
        $Task = Get-ScheduledTask -TaskName HydrationReminder
        $Task.State | Should -Be 'Ready'
        $Task.Actions[0].Execute | Should -Be 'conhost.exe'
        $Task.Actions[0].Arguments | Should -Match '^--headless '
        $Task.Principal.LogonType | Should -Be 'Interactive'
        $Task.Principal.RunLevel | Should -Be 'Limited'
        $Task.Triggers[0].StartBoundary | Should -Match 'T09:00:00'
        $Task.Triggers[0].Repetition.Interval | Should -Be 'PT30M'
        $Task.Triggers[0].Repetition.Duration | Should -Be 'PT8H1M'
    }

    It 'Suspend -Indefinitely disables it and Resume enables it' {
        Suspend-HydrationReminder -Indefinitely | Out-Null
        (Get-ScheduledTask -TaskName HydrationReminder).State | Should -Be 'Disabled'
        Resume-HydrationReminder | Out-Null
        (Get-ScheduledTask -TaskName HydrationReminder).State | Should -Be 'Ready'
    }

    It 'Stop removes it' {
        Stop-HydrationReminder -Confirm:$false
        Get-ScheduledTask -TaskName HydrationReminder -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
    }
}
