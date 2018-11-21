<#
.SYNOPSIS
    .
.DESCRIPTION
    RUN THIS SCRIPT ON PC WHERE IS DB WICH YOU WANT TO ENCRYPTION AND WHERE YOU WANT TO CREATE NEW USER
.PARAMETER Path
    The path to the .
.PARAMETER LiteralPath
    YOU MUST CHOOSE ONE OF THIS OPTIONS:
    1.	Database encryption
    2.	Users creation. 
.EXAMPLE
    C:\PS> .\lab4_et1.ps1 -mode 2 -pass Pa$$word
.NOTES
    Author: Urbanovich Sergei
    Date:   Nov 21, 2018    
#>

[CmdletBinding()] 

Param ( 

[parameter(Mandatory=$true,HelpMessage="Сhoose a mode")] 
[int]$mode,
[parameter(Mandatory=$true,HelpMessage="Password for SQL DB")] 
[string]$pass

)

#################################################################### Querys
$Query_ENCRYPTION = @"

-- Create a DMK in the master DB

USE master;
CREATE MASTER KEY ENCRYPTION BY PASSWORD = '$DMK_Pass';

-- Creating a Certificate in the master DB

CREATE CERTIFICATE Security_Certificate WITH SUBJECT = 'DEK_Certificate';

-- Backing up a Certificate and its Private Key

BACKUP CERTIFICATE Security_Certificate TO FILE = 'C:\Temp\security_certificate.cer'
WITH PRIVATE KEY
(FILE = 'C:\Temp\security_certificate.key',
ENCRYPTION BY PASSWORD = '$Cert_Pass');

-- Creating a DB Encription KEY

USE $DB_Encription_Name;
CREATE DATABASE ENCRYPTION KEY
WITH ALGORITHM = AES_128
ENCRYPTION BY SERVER CERTIFICATE Security_Certificate;

-- Enable Encription for DB

ALTER DATABASE $DB_Encription_Name
SET ENCRYPTION ON;

-- Query sys.databases to Determine Encription Status

USE master;
SELECT name, is_encrypted FROM sys.databases; 

"@

#############################

$Query_CrNewUser = "

CREATE LOGIN $nameOfUser   
WITH PASSWORD = '$passOfUser' MUST_CHANGE,  CHECK_EXPIRATION = ON;

CREATE USER $nameOfUser FOR LOGIN $nameOfUser;

"

####################################################################

if ($mode -eq 1){

    try {

        $DB_Encription_Name = Read-Host 'What is name of Encription DB"?'
        $DMK_Pass = Read-Host 'What is DMK password?'
        $Cert_Pass = Read-Host 'What is pasword for Cert"?'
        

        Invoke-Sqlcmd -ServerInstance localhost -Username 'Sa' -Password $pass -Query $Query_ENCRYPTION
        Write-Host "ENCRYPTION DB" $DB_Encription_Name "- DONE!" -ForegroundColor White -BackgroundColor Green

    }
    catch [system.exception] {

        Write-Host "Caught a system exception (ENCRYPTION DB)" -ForegroundColor White -BackgroundColor Red

    }

} elseif($mode -eq 2) {

    try {
        
        [int]$numbersOfUsers = Read-Host 'How much users you want to create?'
        [int]$i = 0

        do {

            $nameOfUser = Read-Host 'What is new user name?'
            $passOfUser = Read-Host 'What is him password?'

            $Query_CrNewUser = "

            CREATE LOGIN $nameOfUser   
            WITH PASSWORD = '$passOfUser' MUST_CHANGE,  CHECK_EXPIRATION = ON;

            CREATE USER $nameOfUser FOR LOGIN $nameOfUser;

            "

            Invoke-Sqlcmd -ServerInstance localhost -Username 'Sa' -Password $pass -Query $Query_CrNewUser
            Write-Host "Create New User" $nameOfUser "- DONE!" -ForegroundColor White -BackgroundColor Green

            $i += 1

            Write-Host "User #" $i

        } while ($numbersOfUsers -gt $i)       

    }
    catch [system.exception] {

        Write-Host "Caught a system exception (Create New User)" -ForegroundColor White -BackgroundColor Red

    }

}