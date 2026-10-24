[CmdletBinding()]
param ()

$script:TaskName = 'HydrationReminder'
$script:ModuleRoot = $PSScriptRoot
$script:StatePath = Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'HydrationReminder\settings.json'

$Public = @(Get-ChildItem -Path "$PSScriptRoot\functions\*.ps1")
$Private = @(Get-ChildItem -Path "$PSScriptRoot\functions\private\*.ps1")

foreach ($File in $Public + $Private) {
    try {
        . $File.FullName
        Write-Verbose "Imported function $($File.Name)"
    }
    catch {
        Write-Error "An error occured importing $($File.FullName). $($_.Exception.Message)"
    }
}

Export-ModuleMember -Function $Public.BaseName -Alias 'hydrate'
