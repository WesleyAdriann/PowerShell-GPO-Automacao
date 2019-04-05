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


$bdConnect = ConnectBD



CloseBD $bdConnect