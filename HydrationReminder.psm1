[CmdletBinding()]
param ()
Get-ChildItem -Path $PSScriptRoot\*.ps1 | ForEach-Object {
    $File = $_
    try{
        . $_.FullName
        Write-Verbose "Imported function $($_.Name)"
    }
    catch{
        Write-Error "An error occured importing $($File.FullName). $($_.Exception.Message)"
    }
}