[void][system.reflection.Assembly]::LoadFrom("/MySql.Data.dll")

function ConnectBD() {

    $server = '192.168.0.104'
    $user = 'admin'
    $password = 'admin'
    $database = 'db_renamepc'
    $connectString = "server=$server;user id=$user;password=$password;database=$database"

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

function SelectQuery($bdConnect, [string]$query) {
    $bdCommand = New-Object MySql.Data.MySqlClient.MySqlCommand($query, $bdConnect)
    $bdDataReader = $bdCommand.ExecuteReader()

    while($bdDataReader.Read()) {
        write-Host ("Status:    " +$bdDataReader[0]+ "  |   Descricao:  " +$bdDataReader[1])
    }
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

# $query = "insert into tb_response values ('ok', 'itautec')"

# InsertQuery $bdConnect $query

# $queryS = "select * from tb_response"

# SelectQuery $bdConnect $queryS

CloseBD $bdConnect
