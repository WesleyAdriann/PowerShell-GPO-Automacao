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
function InsertResponse($bdConnect) {
   
}
function getDescriptionBD(){
    $nomePC = getNomePC
    $querySelect = "SELECT modelo, setor, sala FROM tb_pcs WHERE nome='$nomePC';"
    $colsVal = SelectQuery $bdConnect $querySelect 3 #Array que contém os valores do modelo, setor e sala
    write-host "values from ExplicitArray are $($colsVal[0]) and $($colsVal[1])  $($colsVal[2])"
    RenameDescriptionPC $colsVal 
}
function RenameDescriptionPC($colsVal){
    #Nome atual
    $nomePC = getNomePC

    #Descrição atual
    $Reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine',$computer)
    $RegKey= $Reg.OpenSubKey("SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters")
    $description = $RegKey.GetValue("srvcomment")

    #Nova Descrição
    $newDescription = "$($colsVal[0]) - $($colsVal[1]) - $($colsVal[2])"
    
    write-Host "Nome do PC:" $nomePC
    write-Host "Descrição do PC:" $description
    
    try{
        #net config server /srvcomment:$newDescription 
    }catch{
        $ErrorMessage = $_.Exception.Message
    }
    
    write-host "Descrição nova: " $newDescription.toString() -ForegroundColor Green  

}


$bdConnect = ConnectBD

$querySelect = "select * from tb_pcs"
#$queryInsert = "INSERT INTO tb_pcs (nome, pat, modelo, setor, sala) VALUES ('teste2Nome', 'teste2pat', 'teste2modelo', 'teste2setor', 'teste2sala');"
#InsertQuery $bdConnect $queryInsert 
#ReadCsv $bdConnect

getDescriptionBD
#SelectQuery $bdConnect $querySelect 4

CloseBD $bdConnect
