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

function RenamePc($bdConnect ,[string]$nomePc) {
    $Reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine',$computer)
    $RegKey= $Reg.OpenSubKey("SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters")
    $description = $RegKey.GetValue("srvcomment")

    Write-Host "Nome Atual: " $nomePc
    Write-Host "Descricao Atual:"  $description

    $query = "select * from tb_pcs where nome='$nomePc'"
    $bdInfoPc = SelectQuery $bdConnect $query
    Write-Host $bdInfoPc


    # $query = "select * from tb_pcs where nome='$nomePC'"
    # SelectQuery $bdConnect $query
}

write-Host "Script Iniciado"

$ComputerSystem = Get-WmiObject -class win32_ComputerSystem
$nomePc = $ComputerSystem.PSComputerName

$bdConnect = ConnectBD

RenamePc $bdConnect $nomePc

CloseBD $bdConnect
