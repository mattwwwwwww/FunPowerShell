function Create-FullUserSetup 
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,HelpMessage='Please give me the pathway to the User Creation CSV file')]
        [Alias('CSV','UserCSV')]
        [string]$PathwayToCSV,
     
        [Parameter(Mandatory=$true,HelpMessage='Please give me the pathway to a text file containing Department names for Users.')]
        [Alias('DepartmentFile','Department')]
        [string]$DepartmentTextFile
        )

        $DcInformation = get-addomain
        $DcInformation.DistinguishedName
        
        $TestingPathwayCSV = Test-Path -Path $PathwayToCSV
        $TestingPathwayDEP = Test-Path -Path $DepartmentTextFile

        $AllDepartments = Get-Content -Path $DepartmentTextFile

if ($TestingPathwayDEP)
{
    foreach($Name in $AllDepartments)
    {
        try 
        {
            $CreatingOUs = New-ADOrganizationalUnit -Name $Name -Path $DcInformation.DistinguishedName -ErrorAction Stop
        }
        catch 
        {
            Write-Host "Failed to create the OU: '$Name'. Error: $($_.Exception.Message)"
        }
    }
    
}

if ($TestingPathwayCSV)
{
    $UsersSoFar = Import-CSV -Path $PathwayToCSV
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

        # RANDOMIZING DEPARTMENTS HERE:
        $RandomDepartment = Get-Random $AllDepartments
        $user.Department = $RandomDepartment
    }
}

else 
{
    Write-Host "Invalid CSV Pathway. Please Try again!"
    return
}

# EXPORTING CSV HERE - ENSURE TO USE NOTYPEINFORMATION OTHERWISE IT WILL SHOW A HEADER AT THE TOP:

$UsersSoFar | Export-csv -Path $PathwayToCSV -NoTypeInformation


# CREATING MULTIPLE USERS HERE:

$UpdatedUsersList = Import-Csv -Path $PathwayToCSV

if ($TestingPathwayCSV)
{
    foreach ($user in $UpdatedUsersList)
    {
        # CONVERTING PLAIN TEXT TO SECURE STRINGS HERE:
        if($user.Credential)
        {
            $SecureStringConvert = ConvertTo-SecureString $user.Credential -AsPlainText -Force
        }
        else
        {
            $SecureStringConvert = ConvertTo-SecureString "Password1!" -AsPlainText -Force
        } 

        # TRY CREATING THE USER THEN MOVING THEM INTO THE CORRECT OU HERE:
        try 
        {   
            $PathOfOU = "OU=" + $user.Department + "," + $DcInformation.DistinguishedName
            $NewUserCreated = New-ADUser -Name $user.Name -Surname $user.Surname -DisplayName $user.DisplayName -Country $user.Country -EmployeeID $user.EmployeeID -EmployeeNumber $user.EmployeeNumber -EmailAddress $user.EmailAddress -Department $user.Department -AccountPassword $SecureStringConvert -Path $PathOfOU -ErrorAction Stop
        }
        catch 
        {
            Write-Host "Failed to either create the user '$($user.Name)'. Error: $($_.Exception.Message)"
        }    
    }
}
}






