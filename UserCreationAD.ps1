function Create-FullUserSetup 
{
    <#
    .SYNOPSIS
    After initially running this script, this will create a CMDLET that does the following:

    Takes in a CSV file for user creation. The CSV file requires the following headings:
    (Fields containing ** must contain values)
    - **Name**
    - **Surname**
    - DisplayName
    - Country
    - EmployeeID
    - EmployeeNumber
    - EmailAddress
    - Department
    - **Credential**
    
    Also takes in a text file containing the names of Departments that you wish to assign to the users.
    
    This script creates OU's based on the department names and users based on the CSV file.
    Users will be sorted into their respective OU'ss.
    OU's are randomized to each user.

    .Description
    Creates multiple AD Users and Organization Units & assigns the users to an OU.

    .EXAMPLE
    Create-FullUserSetup -PathwayToCSV ".\PracticeUsers.csv" -DepartmentFile ".\Departments.txt"
    #>



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
                Write-Verbose "Attempting to create the organizational unit for $Name"
                $CreatingOUs = New-ADOrganizationalUnit -Name $Name -Path $DcInformation.DistinguishedName -ErrorAction Stop
            }
            catch 
            {
                Write-Host "Failed to create the OU: '$Name'. Error: $($_.Exception.Message)"
            }
        }
        
    }

    if ($TestingPathwayCSV -and $TestingPathwayDEP)
    {
        $UsersSoFar = Import-CSV -Path $PathwayToCSV
        $EmployeeId = 5000

        Write-Verbose "Updating the CSV file & Exporting it to the same location."

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

    if ($TestingPathwayCSV -and $TestingPathwayDEP)
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
                Write-Verbose "Create the AD User for $user.Name & sorting into the OU $user.Department."
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






