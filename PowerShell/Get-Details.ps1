Function Get-Details {
<#
    .SYNOPSIS
    Get-Details is a function that returns valuable actionable information about a user 
    
    MORE INFO: Cherwel KB #
    
    Required Parameters:
        -ulid
            
#>

Param(
[Parameter(Mandatory = $true, HelpMessage="Enter a ULID")]
[ValidateNotNullorEmpty()]
[string] $object
) 
    $banner = Invoke-WebRequest -uri "https://raw.githubusercontent.com/jhaywo1/OIAM/master/Banners/details.txt" | Select-Object -ExpandProperty Content
    $banner = ($banner -split "`n")[0..5]
    
    #check if entered object is a computer 
    $computerpattern = "\b^at\d{6}\b|\b^sys\d{6}\b"
    $switch = ($object -match $computerpattern)

    if ($switch -eq "True"){
        try {
            #pull computer information 
            $atcomputer = (Get-ADComputer $object -Properties *)

            #top border
            Write-Host $('_' * (75)) -ForegroundColor Gray
            #display banner 
            $banner | %{Write-Host "".PadLeft(5) $_ -ForegroundColor Cyan}

            #regex pattern for username
            $usernamepattern = "\bADILSTU\S\w{1,}\b" 
            
            #Get username of asset
            $atcomputerinfo = $atcomputer.info
            $atcomputerinfo -match $usernamepattern | Out-Null
            $username = $Matches[0] -replace "ADILSTU\\" 
            
            #Get managers username 
            $managerusername = ($atcomputer.ManagedBy -split ","  | Select-String "CN=")
            $managerusername = ($managerusername -replace "CN=")
            
            #Display asset information 
            Write-Host $('_' * (75)) -ForegroundColor Gray
            Write-Host "Details:" -ForegroundColor Cyan
            
            #Asset/user/manager details
            Write-Host "Asset Tag: ".PadLeft(20) -ForegroundColor Gray -NoNewline; Write-Host $atcomputer.cn -ForegroundColor White
            Write-Host "User: ".PadLeft(20) -ForegroundColor Gray -NoNewline; Write-Host $username -ForegroundColor White
            Write-Host "Managed By: ".PadLeft(20) -ForegroundColor Gray -NoNewline; Write-Host $managerusername -ForegroundColor White
            
            #separate border
            Write-Host "".PadLeft(2) $('-' * (69)) -ForegroundColor White
            
            #verbose details about asset 
            Write-Host "Asset Information:" -ForegroundColor Cyan
            Write-Host "Location: ".PadLeft(20) -ForegroundColor Gray -NoNewline; Write-Host $atcomputer.Location -ForegroundColor White
            Write-Host "IP Address: ".PadLeft(20) -ForegroundColor Gray -NoNewline; Write-Host $atcomputer.IPv4Address -ForegroundColor White
            Write-Host "Operating System: ".PadLeft(20) -ForegroundColor Gray -NoNewline; Write-Host $atcomputer.OperatingSystem -ForegroundColor White
            Write-Host "Description: ".PadLeft(20) -ForegroundColor Gray -NoNewline; Write-Host $atcomputer.Description -ForegroundColor White
            Write-Host "Created on: ".PadLeft(20) -ForegroundColor Gray -NoNewline; Write-Host $atcomputer.Created -ForegroundColor White
            Write-Host "Last Logon: ".PadLeft(20) -ForegroundColor Gray -NoNewline; Write-Host $atcomputer.LastLogonDate -ForegroundColor White
            
            try {
                #separate border
                Write-Host "".PadLeft(2) $('-' * (69)) -ForegroundColor White
                Write-Host "Membership: " -ForegroundColor Cyan
                $compmemberdetails = $atcomputer.MemberOf 
                $compmemberdetails = ($compmemberdetails.split(',') | Select-String -Pattern 'cn') -replace "cn=" 
                $compmemberdetails | %{Write-Host "Member Of: ".PadLeft(20) -ForegroundColor Gray -NoNewline; Write-Host $_ -ForegroundColor White}
            }
            catch {$_.Exception.Response.StatusCode.Value__
                Write-Host "Member Of: ".PadLeft(20) -ForegroundColor Gray -NoNewline; Write-Host " No Membership Data" -ForegroundColor White
            }
            #bottom border 
            Write-Host $('_' * (75)) -ForegroundColor Gray
        }
        catch {$_.Exception.Response.StatusCode.Value__
            Write-Host "Not a valid computer" -ForegroundColor Yellow
        } 
    }
    else {

        try {
            #pull user information
            $Details = (get-aduser $object -Properties * | Select-Object SamAccountName,DisplayName,Department,Description,EmailAddress,Enabled,Modified,Created,LastLogonDate,PasswordLastSet,PasswordExpired,MemberOf,LockedOut,iSUacademicPPD,Manager,iSUPersonPrimaryAffiliation,DistinguishedName)
            
            #top border
            Write-Host $('_' * (75)) -ForegroundColor Gray
            #display banner 
            $banner | %{Write-Host "".PadLeft(5) $_ -ForegroundColor Cyan}

            #populate department field if null
            if($Details.Department -eq $null){
                $Details.Department = "-------" 
            }

            #populate description field if null
            if($Details.Description -eq $null){
                $Details.Description = "-------" 
            }

            #populate Primary Affil fielf if null
            if($Details.iSUPersonPrimaryAffiliation -eq $null){
               $Details.iSUPersonPrimaryAffiliation = "-------"
            }

            #set current time
            $currenttime = Get-Date
            $currenttime.toUniversalTime() | Out-Null
            
            #set password last set variable for further call
            $pwlastset = ($currenttime - $Details.PasswordLastSet)
            $pwlastset = $pwlastset.days

            #OU Designation and Formatting 
            $DN = $Details.DistinguishedName
            $OU = ($DN.Split(',') | Select-String "OU=") -replace "OU="
            
            #Account details section
            Write-Host $('_' * (75)) -ForegroundColor Gray
            Write-Host "Details:" -ForegroundColor Cyan
            Write-Host "ULID: ".PadLeft(20) -ForegroundColor Gray -NoNewline; Write-Host "" $Details.SamAccountName -ForegroundColor White
            Write-Host "Name: ".PadLeft(20) -ForegroundColor Gray -NoNewline; Write-Host "" $Details.DisplayName -ForegroundColor White
            Write-Host "Email: ".PadLeft(20) -ForegroundColor Gray -NoNewline; Write-Host "" $Details.EmailAddress -ForegroundColor White
            Write-Host "Department: ".PadLeft(20) -ForegroundColor Gray -NoNewline; Write-Host "" $Details.Department -ForegroundColor White
            Write-Host "Org. Uni: ".PadLeft(20) -ForegroundColor Gray -NoNewline; Write-Host "" $OU -ForegroundColor White
            Write-Host "Primary Affil: ".PadLeft(20) -ForegroundColor Gray -NoNewline; Write-Host "" $Details.iSUPersonPrimaryAffiliation -ForegroundColor White
            if ($Details.Manager -ne $null){ 
                $manager = $Details.Manager
                $manager = ($manager.Split(',') | Select-String -Pattern "CN=") -replace "CN=" 
                Write-Host "Manager: ".PadLeft(20) -ForegroundColor Gray -NoNewline; Write-Host "" $manager -ForegroundColor White
            }

            #Academic data 
            if ($Details.iSUacademicPPD -ne $null){
   
                #Assigning academic ppd 
                $academicppd = $Details.ISUacademicPPD 

                #formatting array 
                $academicppd = ($academicppd.split(',') | Select-String -Pattern 'plan|acad_title') -replace "}]" 
 
                #assigning plan and title variables 
                try { 
                    $plan = ($academicppd | Select-String -pattern "plan\b")

                    #formatting of plan variable
                    $planpos = $plan.toString().IndexOf(":") 
                    $plan = (($plan | % {$_.toString().Substring($planpos+1)}) -replace """") -replace "plan:" 
                    Write-Host "Major: ".PadLeft(20) -ForegroundColor Gray -NoNewline; Write-Host "" $plan -ForegroundColor White
                } catch{Write-Host "Major: ".PadLeft(20) -ForegroundColor Gray -NoNewline; Write-Host " N/A" -ForegroundColor White} 

                try {
                    $title = $academicppd[2]

                    #formatting of title variable 
                    $titlepos = $title.IndexOf(":")
                    $title = (($title.Substring($titlepos+1)) -replace """") -replace "}"
                    Write-Host "Grade Level: ".PadLeft(20) -ForegroundColor Gray -NoNewline; Write-Host "" $title -ForegroundColor White
                } catch{Write-Host "Grade Level: ".PadLeft(20) -ForegroundColor Gray -NoNewline; Write-Host " N/A" -ForegroundColor White} 

            }

            #Separator border
            Write-Host "".PadLeft(2) $('-' * (69)) -ForegroundColor White
            
            #Key Account details section
            Write-Host "Account: " -ForegroundColor Cyan
            
            #check if account is enabled or not
            if ($Details.Enabled -like "True"){
                Write-Host "Enabled: ".PadLeft(20) -ForegroundColor Gray -NoNewline; Write-Host "" $Details.Enabled -ForegroundColor White
            } 
            else {
                Write-Host "Enabled: ".PadLeft(20) -ForegroundColor Gray -NoNewline; Write-Host "" $Details.Enabled -ForegroundColor Red
            }
            
            #check if account is locked out
            if ($Details.LockedOUt -like "False"){
                Write-Host "Locked Out: ".PadLeft(20) -ForegroundColor Gray -NoNewline; Write-Host "" $Details.LockedOut -ForegroundColor White
            }
            else { 
                Write-Host "Locked Out: ".PadLeft(20) -ForegroundColor Gray -NoNewline; Write-Host "" $Details.LockedOut -ForegroundColor Red
            }
            
            #print rest of account detials
            Write-Host "Modified On: ".PadLeft(20) -ForegroundColor Gray -NoNewline; Write-Host "" $Details.Modified -ForegroundColor White
            Write-Host "Created On: ".PadLeft(20) -ForegroundColor Gray -NoNewline; Write-Host "" $Details.Created -ForegroundColor White
            Write-Host "Last Logon: ".PadLeft(20) -ForegroundColor Gray -NoNewline; Write-Host "" $Details.LastLogonDate -ForegroundColor White
            Write-Host "Password Last Set: ".PadLeft(20) -ForegroundColor Gray -NoNewline; Write-Host "" $Details.PasswordLastSet -ForegroundColor White
            
            #check if password set date exceeds policy
            if ($pwlastset -lt 180){
            Write-Host "Days Since PW Set: ".PadLeft(20) -ForegroundColor Gray -NoNewline; Write-Host "" $pwlastset -ForegroundColor White
            }
            else {
            Write-Host "Days Since PW Set: ".PadLeft(20) -ForegroundColor Gray -NoNewline; Write-Host "" $pwlastset -ForegroundColor Red
            }
            
            #check if account password is expired 
            if ($Details.PasswordExpired -like "False"){
                Write-Host "Password Expired: ".PadLeft(20) -ForegroundColor Gray -NoNewline; Write-Host "" $Details.PasswordExpired -ForegroundColor White
            }
            else {
                Write-Host "Password Expired: ".PadLeft(20) -ForegroundColor Gray -NoNewline; Write-Host "" $Details.PasswordExpired -ForegroundColor Red 
            }
            
            #extensive switch listing member of property
            
            try {
                Write-Host "".PadLeft(2) $('-' * (69)) -ForegroundColor White
                Write-Host "Membership: " -ForegroundColor Cyan
                $decision = 'y'
                $breakvalues = @('n','N','No','no','NO')
                $count = 0
                $memberdetails = $Details.MemberOf 
                $memberdetails = ($memberdetails.split(',') | Select-String -Pattern 'cn') -replace "cn=" 
                foreach ($_ in $memberdetails){
                    Write-Host "Member Of: ".PadLeft(20) -ForegroundColor Gray -NoNewline; Write-Host "" $_ -ForegroundColor White
                    $count++
                    if ($count -eq 10){
                        $decision = Read-Host -Prompt 'Would you like to see more?(y/n)'
                        if ($decision -cin $breakvalues){
                            break
                        }
                    }
                }
            }
            
            #catch error if there is no MemberOf information
            catch {$_.Exception.Response.StatusCode.Value__
                Write-Host "Member Of: ".PadLeft(20) -ForegroundColor Gray -NoNewline; Write-Host " No Membership Data" -ForegroundColor White
            }

            try {
                Write-Host "".PadLeft(2) $('-' * (69)) -ForegroundColor White
                Write-Host "User Groups: " -ForegroundColor Cyan
                $decision = 'y'
                $breakvalues = @('n','N','No','no','NO')
                $count = 0
                $group = $Details.MemberOf
                $group = ($group.split(',') | Select-String -Pattern 'OU=') -replace "ou=" 
                $group = ($group | Sort-Object | Get-Unique)
                foreach ($_ in $group) {
                    Write-Host "Group: ".PadLeft(20) -ForegroundColor Gray -NoNewline; Write-Host "" $_ -ForegroundColor White
                    $count++
                    if ($count -eq 10){
                    $decision = Read-Host -Prompt 'Would you like to see more?(y/n)'
                        if ($decision -cin $breakvalues){
                            break
                        }

                    }
                }
            }

            catch {$_.Exception.Response.StatusCode.Value__
                Write-Host "Org. Unit: ".PadLeft(20) -ForegroundColor Gray -NoNewline; Write-Host " No OU Data" -ForegroundColor White
            }
            
            
            #bottom border
            Write-Host $('_' * (75)) -ForegroundColor Gray
        }
        
        #catch error if bad ULID 
        catch {$_.Exception.Response.StatusCode.Value__
            Write-Host "Not a valid ULID" -ForegroundColor Yellow
        }
    }
}
