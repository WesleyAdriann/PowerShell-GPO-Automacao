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
    return ,$bdDataReader
}

function InsertQuery($bdConnect, [string]$query) {
    
    $bdCommand = New-Object MySql.Data.MySqlClient.MySqlCommand($query, $bdConnect)
    try {
        $bdCommand.ExecuteNonQuery()        
    } catch {
        write-warning("Nao foi possivel adicionar")
    }    
}

function sendResponse($message) {        
    #$nomePC = "pc-desconhecido"
    $nomePC = getNomePC  
    $description = getDescriptionPC
    $dataHora = Get-Date -Format g

    $bdConnect = ConnectBD
    $querySelect = "SELECT nome FROM tb_response WHERE nome='$nomePC';"
    $colNome = SelectQuery $bdConnect $querySelect 1 #Array que contém os valores do modelo, setor e sala
    write-host $colNome[0]

    if($colNome[0] -ne $null){
        write-host "coluna não está vazia, preciso realizar o UPDATE"
        $queryUpdate = "UPDATE tb_response SET descricao='$description', descRenomeada='$message', data_hora='$dataHora' WHERE nome='$nomePC';"         
        write-host 'atualizando linha...'
        $bdConnect = ConnectBD
        InsertQuery $bdConnect $queryUpdate 
        CloseBD $bdConnect    
    }else{
        write-host "coluna está vazia, preciso realizar o INSERT INTO"
        $queryInsert = "INSERT INTO tb_response (nome, descRenomeada, descricao, data_hora) VALUES ('$nomePC', '$message', '$description', '$dataHora');"         
        write-host 'inserindo linha...'
        $bdConnect = ConnectBD
        InsertQuery $bdConnect $queryInsert 
        CloseBD $bdConnect    
    }
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
    write-Host "Pega o nome no BD"
    $bdConnect = ConnectBD
    $newDescription = getDescriptionBD
    CloseBD $bdConnect        
    $message
    $remoeado = $true
    try{
        net config server /srvcomment:$newDescription                 
    }catch{
        $message = $_.Exception.Message
        $renomeado = $false
    }

    if($remoeado){
        write-host "PC renomeado com sucesso!"
        $message = "Ok"
    }else{
        write-host "Ocorreu um erro ao renomear"
    }    
    write-Host "Nome do PC:" $nomePC
    write-Host "Descrição do PC:" $description -foreground Magenta
    write-Host ""
    write-host "Descrição nova: " $newDescription -foreground Cyan
    sendResponse $message
    #insertOnFunc $message
}
function gerarLog(){      
    $dataHora = Get-Date -Format g  
    $mensagem="Script executado em " +$dataHora    
	$mensagem >> log_gpoRenameDescription.txt
}



#$querySelect = "select * from tb_pcs"
#$queryInsert = "INSERT INTO tb_pcs (nome) VALUES ('nome12/04');"
#InsertQuery $bdConnect $queryInsert 
#ReadCsv $bdConnect

RenameDescriptionPC
gerarLog