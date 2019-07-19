Function Compare-Department {
<#
    .SYNOPSIS
    Compare-Department is a function that accepts a user and compares their department and iSUBusinessAddressLine1 field

    MORE INFO: Confluence article 

    Required Parameters:
        -ULID

#>
Param (
[Parameter(Mandatory = $true, HelpMessage="Enter a ULID")]
[ValidateNotNullorEmpty()]
[string] $ULID
) 

    try {
        $user = Get-ADUser $ULID -Properties Department,iSUBusinessAddressLine1 | Select-Object Name,Department,iSUBusinessAddressLine1

        if ($user.Department -notmatch $user.iSUBusinessAddressLine1){
            Write-Host "`nThere is a discrepancy in their values" -ForegroundColor Yellow
            Write-Host "Department: " -ForegroundColor Gray -NoNewline; Write-Host $user.Department
            Write-Host "iSUBusinessAddressLine1: " -ForegroundColor Gray -NoNewline; Write-Host $user.iSUBusinessAddressLine1
        } else {
            Write-Host ""
            Write-Host ($user.Name).ToUpper() -ForegroundColor Cyan -NoNewline; Write-Host "'s values match"
        }
    } catch {
        $_.Exception.Response.StatusCode.Value__
        Write-Host $ULID.ToUpper() -ForegroundColor Yellow -NoNewline; Write-Host " is not a valid ULID" 
    }
}

