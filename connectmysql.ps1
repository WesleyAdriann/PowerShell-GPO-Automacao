[void][system.reflection.Assembly]::LoadFrom("/MySql.Data.dll")

function ConnectBD() {

    $server = '10.41.171.207'
    $user = 'admin'
    $password = 'admin'
    $database = 'db_renamepc'
    $port = '3306'
    $connectString = "server=$server;port=$port;user id=$user;password=$password;database=$database"

    $bdConnect = New-Object MySql.Data.MySqlClient.MySqlConnection($connectString)
    $bdStatus = $true
    try {
        $bdConnect.Open()
    }
    catch {
        $bdStatus = $false
    } 

    if($bdStatus) {
        write-Host ("Conectado ao $database no servidor $server")
    } else {
        write-warning ("Não foi possivel conectar ao $database no servidor $server.")
    }  
    return $bdConnect
}

function CloseBD($bdConnect) {
    $bdConnect.Close()
    write-Host("Conexao fechada")
}

function SelectQuery($bdConnect, [string]$query, [int]$numColumns) {
    $bdCommand = New-Object MySql.Data.MySqlClient.MySqlCommand($query, $bdConnect)
    $bdDataReader = $bdCommand.ExecuteReader()
    
    while($bdDataReader.Read()) {
        for($i = 0; $i -le $numColumns; $i++) {
            write-Host "| " $bdDataReader[$i]
        }
        write-Host "+-------------------"
        # write-Host $bdDataReader[0] - $bdDataReader[1] - $bdDataReader[2] - $bdDataReader[3] - $bdDataReader[4]
    }
    
    return $bdDataReader[1]
}

function InsertQuery($bdConnect, [string]$query) {
    $bdCommand = New-Object MySql.Data.MySqlClient.MySqlCommand($query, $bdConnect)
    try {
        $bdCommand.ExecuteNonQuery()
    } catch {
        write-warning("Nao foi possivel adicionar")
    }
}

$bdConnect = ConnectBD

$query = "select * from tb_pcs"

SelectQuery $bdConnect $query 5

CloseBD $bdConnect
