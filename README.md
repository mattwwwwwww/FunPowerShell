README File for UserCreationAD.ps1

This script begins by creating a CMDLET called 'Create-FullUserSetup'. 

This CMDLET can then be run in your PowerShell session to create multiple AD Users.

In order for this to run successfully, it requires the user to feed in a csv file      containing Firstnames, Lastnames and Passwords of the users they wish to create. If no password is listed in this csv the password will default to `Password1!'.

The user must also add a file containing the names of Departments that they wish the users to be sorted into. 

This script will take this department list and create Organisation Units based on those names, as well as randomize the departments and assign them to the users. The users will be created within the Organisational Units that they were randomly assigned.


**STEPS TO RUN** 

1. Run the script.

2. In the same PowerShell session run:
`Create-FullUserSetup -PathwayToCSV  "CSV FILE LOC" -DepartmentTextFile "Department FILE LOC"
Ensure you are running this in Administrator mode as a user who has the rights to create Users and OUs in AD.

3. Confirm in ADUC that the OU's have been created, the Users have been correctly assigned into the OUs and that the Users have the correct properties. 

