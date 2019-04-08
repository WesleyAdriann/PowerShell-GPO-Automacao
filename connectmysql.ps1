[void][system.reflection.Assembly]::LoadFrom("/MySql.Data.dll")
$ComputerSystem = Get-WmiObject -class win32_ComputerSystem
$NamePC = $ComputerSystem.PSComputerName

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

function ReadCsv($bdConnect) {
    $pathCsv = "./NomePcs.csv"

    $nomePc
    $patPc 
    $modelo 
    $setor 
    $sala 
    Import-Csv $pathCsv |`
        ForEach-Object {
            $nomePc = $_."Nome"
            $patPc = $_."Patrimonio"
            $modelo = $_."Modelo"
            $setor = $_."Setor"
            $sala = $_."Sala"
            write-Host("$nomePc  $patPc  $modelo  $setor  $sala")
            $query = "insert into tb_pcs values ('$nomePc', '$patPc', '$modelo','$setor','$sala');"
            InsertQuery $bdConnect $query
        }
}

$bdConnect = ConnectBD

# $nomePc = "ITN-300002703"
# $patPc = "30001288"
# $modelo = "ELITEDESK 800 G1 MINI"
# $setor = "SECAO DE PATRIMONIO (DEPOSITO DE MOVEIS)"
# $sala = "G2"
# $query = "insert into tb_pcs values ('$nomePc', '$patPc', '$modelo','$setor','$sala');"

# InsertQuery $bdConnect $query

# $queryS = "select * from tb_response"

# SelectQuery $bdConnect $queryS

# ReadCsv $bdConnect

write-host "Nome-PC:" $NamePC -ForegroundColor gray

CloseBD $bdConnect
