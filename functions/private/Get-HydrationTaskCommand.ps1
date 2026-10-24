function Get-HydrationTaskCommand {
    param (
        [string]
        $PowerShellPath = $(
            # $PSHOME, not the current process, so registering from ISE or VS Code still points at a real shell
            if ($PSVersionTable.PSEdition -eq 'Core') { Join-Path $PSHOME 'pwsh.exe' } else { Join-Path $PSHOME 'powershell.exe' }
        ),
        [string]
        $ModulePath = (Join-Path $script:ModuleRoot 'HydrationReminder.psd1')
    )

    # shortcut: the task pins this module version's folder; re-run Start-HydrationReminder after Update-Module
    $EscapedModulePath = $ModulePath -replace "'", "''"
    $Command = "Import-Module '$EscapedModulePath'; Send-HydrationReminder -Scheduled"

    # conhost --headless runs the shell with no window at all (undocumented, Windows 10 1809+).
    # If it ever stops working, run the shell directly with '-WindowStyle Hidden' instead, which flashes briefly.
    [PSCustomObject]@{
        Execute  = 'conhost.exe'
        Argument = "--headless `"$PowerShellPath`" -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command `"$Command`""
    }
}
