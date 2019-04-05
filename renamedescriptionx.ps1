function ConnectBD() {
    [void][system.reflection.Assembly]::LoadFrom('C:\MySql.Data.dll')

    $server = '10.41.171.207'
    $user = 'admin'
    $password = 'admin'
    $database = 'db_renamepc'
    $connectString = "server=$server;user id=$user;password=$password;database=$database"

    

    $bdConnect = New-Object MySql.Data.MySqlClient.MySqlConnection($connectString)
    try {
        $bdConnect.Open()
    }
    catch {
        write-warning ("Não foi possivel conectar ao $database no servidor $server.")
        break
    } 
    write-Host ("Conectado ao $database no servidor $server")

    
    return $bdConnect
}

function CloseBD($bdConnect) {
    $bdConnect.Close()
    write-Host("Conexao fechada")
}

function SelectQuery($bdConnect, [string]$query) {
    $bdCommand = $bdConnect.CreateCommand()
    $bdCommand.CommandText = $query

    $dataAdapter = MySql.Data.MySqlClient.MySqlDataAdapter($bdCommand)
    
    $dataSet = New-Object System.Data.DataSet


    
    $bdCommand.ExecuteScalar()

    # $results = $bdCommand.ExecuteReader()

    # $bdCommand.Dispose()
    # while ($results.Read()) {
    #     for($i = 0; $i -lt $reader.FieldCount; $i++) {
    #         write-Host $reader.GetValue($i).ToString()
    #     }
    # }
}

function InsertQuery($bdConnect, [string]$query) {
    $bdCommand = $bdCommand.CreateCommand()
    $bdCommand.CommandText = $query

    $RowsInserted = $bdCommand.ExecuteNonQuery()

    $bdCommand.Dispose()

    if($RowsInserted) {
        write-Host("Inserido $RowInserted")
    } else {
        write-Host("Erro $RowInserted")
    }

}

function MySqlClient() {
    [void][system.reflection.Assembly]::LoadFrom('C:\MySql.Data.dll')
    
    $Client = New-Object MySql.Data.MySqlClient
    return 
}

$bdConnect = ConnectBD
$query = "insert into tb_response values (`ok`, `itautec`)"

InsertQuery $bdConnect $query
# SelectQuery $bdConnect $query

CloseBD $bdConnect