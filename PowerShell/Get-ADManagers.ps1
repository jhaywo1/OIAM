Function Get-ADManagers {
<#
    .SYNOPSIS
    Get-ADManagers is a function that accepts a list of users and outputs a txt or csv file with their associated managers

    Required Parameters:
        -location
        -destination 
#>
Param(
[Parameter(Mandatory = $true, HelpMessage="Enter a location")]
[ValidateNotNullorEmpty()]
[string] $location, 
[Parameter(Mandatory = $true, HelpMessage="Enter a destination")]
[ValidateNotNullorEmpty()]
[string] $destination,
[switch] $csv
)
    $userlist = Get-Content $location
    $users = ($userlist | %{Get-aduser $_ -Properties Manager | Select-Object SamAccountName,Manager})

    foreach ($_ in $users) {
        $_.Manager = ($_.Manager.split(',') | Select-String -Pattern "CN=") -replace "CN="
    }

    if ($csv){
        $endpos = $destination.IndexOf('.')
        $destination = $destination.Substring(0,$endpos) + ".csv" 
        $users | Select-Object SamAccountName,Manager | export-csv $destination -NoTypeInformation
    } else {
        $users | Out-File $destination
    }

    Write-Host "Your file has been created" 
    Write-host "Location: " -NoNewline; Write-Host $destination -ForegroundColor Cyan
}