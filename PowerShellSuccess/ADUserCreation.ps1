# Get the DC distinquished Name -- Remember to remove this variable. 

$DcInformation = get-addomain
$DcInformation.DistinguishedName

# Create the OUs -- TRY/CATCH If they already exist. Potential Future Ideas - User can parse this information through.
function Set-OUs 
{
    try 
    {
        $CreatingMarketing = New-ADOrganizationalUnit -Name "Marketing Users" -Path $DcInformation.DistinguishedName -ErrorAction Stop
        $CreatingSales = New-ADOrganizationalUnit -Name "Sales Users" -Path $DcInformation.DistinguishedName -ErrorAction Stop
        $CreatingIT = New-ADOrganizationalUnit -Name "IT Users" -Path $DcInformation.DistinguishedName -ErrorAction Stop
    }
    catch 
    {
        Write-Host "Sorry, It looks like this OU already exists"
    }
}

Set-OUs

# This function corrects the CSV File and overrides the CSV in the current directly. 
# TEST PATH for ".\PracticeUsersRedo.csv"
function Set-MyCSV 
{
    $UsersSoFar = Import-CSV -Path ".\PracticeUsers.csv"
    $EmployeeId = 5000

    foreach ($user in $UsersSoFar)
    {
        $DisplayName = $user.Name + "." + $user.Surname
        $user.DisplayName = $DisplayName

        $EmailAdd = $user.Name + "." + $user.Surname + "@" + $DcInformation.Forest
        $user.EmailAddress = $EmailAdd

        $EmployeeId = $EmployeeId + 1
        $user.EmployeeID = $EmployeeId
        $user.EmployeeNumber = $EmployeeId

        $user.Country = "AUS"
    }

    $UsersSoFar | Export-csv -Path ".\PracticeUsers.csv"
    $UsersSoFar
}

Set-MyCSV

function Create-MultiUsers
{
    $UpdatedUsersList = Import-Csv -Path ".\PracticeUsers.csv"

    foreach ($user in $UpdatedUsersList)
    {
        $SecureStringConvert = ConvertTo-SecureString $user.Credential -AsPlainText -Force

        try 
        {
            New-ADUser -Name $user.Name -Surname $user.Surname -DisplayName $user.DisplayName -Country $user.Country -EmployeeID $user.EmployeeID -EmployeeNumber $user.EmployeeNumber -EmailAddress $user.EmailAddress -Department $user.Department -AccountPassword $SecureStringConvert -ErrorAction Stop  
        }
        catch 
        {
            Write-Host "Looks Like the user" $user.Name "already exists!"
        }    
        
        $NewUserDetails = Get-ADUser -Identity $user.Name

        if ($user.Department -eq "Marketing") 
        {
            $PathOfOU = "OU=Marketing Users," + $DcInformation.DistinguishedName
            Move-ADObject -Identity $NewUserDetails.ObjectGUID -TargetPath $PathOfOU
        }

        elseif ($user.Department -eq "Sales") 
        {
            $PathOfOU = "OU=Sales Users," + $DcInformation.DistinguishedName
            Move-ADObject -Identity $NewUserDetails.ObjectGUID -TargetPath $PathOfOU
        }

        elseif ($user.Department -eq "IT") 
        {
            $PathOfOU = "OU=IT Users," + $DcInformation.DistinguishedName
            Move-ADObject -Identity $NewUserDetails.ObjectGUID -TargetPath $PathOfOU
        }

        else 
        {
            Write-Host "No Department listed - This user will remain in the default AD location"
        }
    }
}

Create-MultiUsers
