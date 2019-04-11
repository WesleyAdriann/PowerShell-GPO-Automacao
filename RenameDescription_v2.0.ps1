[void][system.reflection.Assembly]::LoadFrom("/MySql.Data.dll")

function getNomePC(){
    $ComputerSystem = Get-WmiObject -class win32_ComputerSystem
    $NamePC = $ComputerSystem.PSComputerName
    return $NamePC
}

function ConnectBD() {

    $server = '10.41.1.173'
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
        write-Host ("Conectado ao $database no servidor $server") -foreground green
    } else {
        write-warning ("Não foi possivel conectar ao $database no servidor $server.")
    }  
    return $bdConnect
}

function CloseBD($bdConnect) {
    $bdConnect.Close()
    write-Host("Conexao fechada") -foreground green      
}

function SelectQuery($bdConnect, [string]$query, [int]$numColumns) {   
    $bdCommand = New-Object MySql.Data.MySqlClient.MySqlCommand($query, $bdConnect)
    $bdDataReader = $bdCommand.ExecuteReader()

    while($bdDataReader.Read()) {
        for($i = 0; $i -le $numColumns; $i++) {
            write-Host "| " $bdDataReader[$i]
        }        
    }

    return ,$bdDataReader;
}

function InsertQuery($bdConnect, [string]$query) {
    $bdCommand = New-Object MySql.Data.MySqlClient.MySqlCommand($query, $bdConnect)
    try {
        $bdCommand.ExecuteNonQuery()
    } catch {
        write-warning("Nao foi possivel adicionar")
    }
}
function InsertResponse($message) {
    $queryInsert = "INSERT INTO tb_response VALUES ('$message', );"
    InsertQuery $bdConnect $queryInsert 
}
function getDescriptionBD(){
    $nomePC = getNomePC
    $querySelect = "SELECT modelo, setor, sala FROM tb_pcs WHERE nome='$nomePC';"
    $colsVal = SelectQuery $bdConnect $querySelect 3 #Array que contém os valores do modelo, setor e sala
    return "$($colsVal[0]) - $($colsVal[1]) - $($colsVal[2])"
}
function getDescriptionPC(){
    $Reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine',$computer)
    $RegKey= $Reg.OpenSubKey("SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters")
    return $RegKey.GetValue("srvcomment")     
}

function RenameDescriptionPC(){
    #Nome atual
    $nomePC = getNomePC

    #Descrição atual
    $description = getDescriptionPC

    #Nova Descrição
    $newDescription = getDescriptionBD        
<#
    try{
        net config server /srvcomment:$newDescription 
    }catch{
        $ErrorMessage = $_.Exception.Message
    }
#>    
    write-Host "Nome do PC:" $nomePC
    write-Host "Descrição do PC:" $description -foreground DarkCyan
    write-host "Descrição nova: " $newDescription -foreground Cyan
}


$bdConnect = ConnectBD

$querySelect = "select * from tb_pcs"
#$queryInsert = "INSERT INTO tb_pcs (nome, pat, modelo, setor, sala) VALUES ('teste2Nome', 'teste2pat', 'teste2modelo', 'teste2setor', 'teste2sala');"
#InsertQuery $bdConnect $queryInsert 
#ReadCsv $bdConnect

RenameDescriptionPC
#SelectQuery $bdConnect $querySelect 4

CloseBD $bdConnect
