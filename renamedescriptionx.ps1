[void][system.reflection.Assembly]::LoadFrom('C:\MySql.Data.dll')


$server = '10.41.171.207'
$user = 'admin'
$password = 'admin'
$database = 'db_renamepc'
$connectString = "server=$server;user id=$user;password=$password;database=$database"

$oConnection = New-Object MySql.Data.MySqlClient.MySqlConnection($connectString)
try
{
    $oConnection.Open()
}
catch
{
    write-warning ("Could not open a connection to Database $database on Host $server. Error: "+$Error[0].ToString())
}

