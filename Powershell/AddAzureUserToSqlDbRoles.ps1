param (
    [Parameter(Mandatory = $true)]
    [string]
    $identityName = '',
    [Parameter(Mandatory = $true)]
    [string]
    $managedIdentityClientId = '', 
    [Parameter(Mandatory = $true)]
    [string]
    $dbServer = '', 
    [Parameter(Mandatory = $true)]
    [string]
    $dbName = '', 
    [Parameter(Mandatory = $true)]
    [string[]]
    $roleNames = ''
)

# Example: 
# .\AddAzureUserToSqlDbRoles.ps1 -identityName 'DTS-PropertySearch-UAT-id'  -dbServer 'dts-apps-dev-sql' -dbName 'dts-propertysearch-dev-sqldb' -roleNames ("db_datareader", "db_datawriter")
try {
    #Generate sid
    [guid]$guid = [System.Guid]::Parse($managedIdentityClientId)
    foreach ($byte in $guid.ToByteArray()) {
        $sid += [System.String]::Format("{0:X2}", $byte)
    }
    $sid = "0x$sid"
    #Fetch token from azure auth
    # Get an access token with the Service Pricipal used in the Azure DevOps Pipeline
    $token = (Get-AzAccessToken -ResourceUrl https://database.windows.net).Token
    Write-Output "Retrieved token"
    #Instantiate SqlConnection
    Write-Output "DB Server: $dbServer Database Name: $dbName"
    $cnctString = "Server=tcp:$dbServer.database.windows.net,1433;Initial Catalog=$dbName;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
    Write-Output "Connection string: $cnctString" 
    $conn = new-object System.Data.SqlClient.SqlConnection
    $conn.ConnectionString = $cnctString
    $conn.AccessToken = $token
    $conn.Open()
    #Add user to DB access
    $sqlCommand = "IF NOT EXISTS(Select * from sys.sysusers where name = '$identityName')`n"
    $sqlCommand += "  BEGIN`n"
    $sqlCommand += "`tCREATE USER [$identityName] WITH DEFAULT_SCHEMA=[dbo], SID = $sid, TYPE = E;"
    $sqlCommand += "  END`n"
     
    $cmd = New-Object System.Data.SqlClient.SqlCommand
    $cmd.Connection = $conn
    $cmd.CommandText = $sqlCommand
    try {
        $cmd.ExecuteNonQuery()
    }
    catch {
        Write-Output "User add failed or already exists"
        Write-Output "$($_.Exception.Message) - Line Number: $($_.InvocationInfo.ScriptLineNumber)"
    }
    Write-Output "Grant connect to user $identityName"
    $sqlCommand = "GRANT CONNECT TO [$identityName]"
    $cmd = New-Object System.Data.SqlClient.SqlCommand
    $cmd.Connection = $conn
    $cmd.CommandText = $sqlCommand
    $cmd.ExecuteNonQuery()
    Write-Output "Grant connect to user $identityName complete"

	foreach($roleName in $roleNames){
        Write-Output "Adding User to $roleName"
        $sqlCommand = "ALTER ROLE $roleName ADD MEMBER [$identityName]"
        $cmd = New-Object System.Data.SqlClient.SqlCommand
        $cmd.Connection = $conn
        $cmd.CommandText = $sqlCommand
        $cmd.ExecuteNonQuery()
        Write-Output "Completed adding user to $roleName"
    }
    $conn.Close()
}
catch {
    Write-Output "$($_.Exception.Message) - Line Number: $($_.InvocationInfo.ScriptLineNumber)"
}