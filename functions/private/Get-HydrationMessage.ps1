function Format-WaterAmount {
    param (
        [double]
        $Amount,
        [string]
        $Unit
    )

    if ($Unit -eq 'Imperial') {
        return '{0} fl oz' -f [Math]::Round($Amount, [MidpointRounding]::AwayFromZero)
    }
    $Rounded = [Math]::Round($Amount / 50, [MidpointRounding]::AwayFromZero) * 50
    if ($Rounded -ge 1000) {
        return '{0:0.##} L' -f ($Rounded / 1000)
    }
    return '{0} mL' -f $Rounded
}

function Get-HydrationMessage {
    param (
        [Parameter(Mandatory)]
        [PSCustomObject]
        $State,
        [datetime]
        $Now = (Get-Date)
    )

    # Expect the goal to be spread evenly across the active window
    $Window = ($State.EndTime - $State.StartTime).TotalMinutes
    $Elapsed = ($Now.TimeOfDay - $State.StartTime).TotalMinutes
    $Fraction = [Math]::Min([Math]::Max($Elapsed / $Window, 0), 1)

    $Goal = Format-WaterAmount -Amount $State.DailyGoal -Unit $State.Unit
    $SoFar = Format-WaterAmount -Amount ($State.DailyGoal * $Fraction) -Unit $State.Unit

    if ($SoFar -match '^0 ') {
        return "Time for some water! Your goal today is $Goal."
    }
    return "Time for some water! By now you should have had about $SoFar of your $Goal goal."
}
