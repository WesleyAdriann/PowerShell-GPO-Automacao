#latest version date: 22/04/19
$dataHora = Get-Date -Format g

function gerarLog($message){          
    $mensagem="Script executado em " +$dataHora + "`r`n`r`n"      
    $mensagem += "Status: "+$message+ "`r`n`r`n __________________________________`r`n`r`n"      
    
	$mensagem >> C:\Drivers\Renomeacao_descricao\log_gpoRenameDescription.txt
}

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
    gerarLog $message 
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
    
    $message
    try{
        #Nome atual
        $nomePC = getNomePC

        #Descrição atual
        $description = getDescriptionPC

        #Nova Descrição
        write-Host "Pega o nome no BD"
        $bdConnect = ConnectBD
        $newDescription = getDescriptionBD
        CloseBD $bdConnect                
        
        #Executa comando para renomear o PC
        net config server /srvcomment:$newDescription                 
        write-host "PC renomeado com sucesso!"
        $message = "Ok"
    }catch{
        write-host "Ocorreu um erro ao renomear"
        $message = $_.Exception.Message        
    }
 
    write-Host "Nome do PC:" $nomePC
    write-Host "Descrição do PC:" $description -foreground Magenta
    write-Host ""
    write-host "Descrição nova: " $newDescription -foreground Cyan
    
    sendResponse $message    
}
function init{
    $pathOrigin_dll = '\\paloma\Log_Script_Renomeacao\MySql.Data.dll'
    try{                        
        if(!(test-path -path C:\Drivers\Renomeacao_descricao)){
            write-host "CRIANDO pasta Renomeacao_descricao..."
            New-Item -Path C:\Drivers\Renomeacao_descricao -ItemType directory   
            write-host "pasta Renomeacao_descricao CRIADA!"
            
            write-host "COPIANDO arquivo dll..."
            Copy-Item -Path $pathOrigin_DLL -Destination 'C:\Drivers\Renomeacao_descricao\MySql.Data.dll' 
            write-host "arquivo Dll COPIADO!"

        }elseif(!(Test-Path -path C:\Drivers\Renomeacao_descricao\MySql.Data.dll -PathType Leaf)){
            write-host "COPIANDO arquivo dll..."
            Copy-Item -Path $pathOrigin_DLL -Destination 'C:\Drivers\Renomeacao_descricao\MySql.Data.dll' 
            write-host "arquivo Dll COPIADO!"
        }else{
            write-host "Pasta e dll já existem!"
        }	            
#Copy-Item -Path '\\DESKTOP-V6HR2FI\Users\Programador Java\Desktop\Mapeamento - Estágio\PowerShell-GPO-Automacao\pasta_paloma\MySql.Data.dll' -Destination 'C:\Drivers\Renomeacao_descricao\MySql.Data.dll'
    }catch{                    
        $mensagem += $_.Exception.Message
        gerarLog $mensagem
    }           	
    write-host "Saindo do init......"     
}
init
write-host "Fazendo o Load do dll"
[void][system.reflection.Assembly]::LoadFrom("C:\Drivers\Renomeacao_descricao\MySql.Data.dll")
RenameDescriptionPC


