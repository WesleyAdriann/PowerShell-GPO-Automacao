#latest version date: 30/04/19 - v0.3
$dataHora = Get-Date -Format g

function gerarLog($message){          
    $mensagem="Script executado em " +$dataHora + "`r`n`r`n"      
    $mensagem += "Status: "+$message+ "`r`n`r`n __________________________________`r`n`r`n"      
    
	$mensagem >> C:\Drivers\Renomeacao_nome\log_gpoRenameName.txt
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

    $bdConnect = ConnectBD
    $querySelect = "SELECT state FROM tb_nomes WHERE nome='$nomePC';"
    $colNome = SelectQuery $bdConnect $querySelect 1 #Array que contém os valores do modelo, setor e sala
    write-host $colNome[0]

    if($colNome[0] -ne $null){
        write-host "coluna não está vazia, preciso realizar o UPDATE"
        $queryUpdate = "UPDATE tb_nomes SET state='$message' WHERE nome='$nomePC';"         
        write-host 'atualizando linha...'
        $bdConnect = ConnectBD
        InsertQuery $bdConnect $queryUpdate 
        CloseBD $bdConnect    
    }else{
        write-host "coluna está vazia, preciso realizar o INSERT INTO"
        $queryInsert = "INSERT INTO tb_nomes (state) VALUES ('$message');"         
        write-host 'inserindo linha...'
        $bdConnect = ConnectBD
        InsertQuery $bdConnect $queryInsert 
        CloseBD $bdConnect    
    }
    gerarLog $message 
}

function getNomeBD(){
    $nomePC = getNomePC #Linha deve ser descomentada depois que o script tiver quase pronto.
    #$nomePC = "HP--59005679"
    $querySelect = "SELECT nome_novo FROM tb_nomes WHERE nome='$nomePC';"
    
    $colVal = SelectQuery $bdConnect $querySelect 1 #Array que contém os valores do modelo, setor e sala
    write-host "Coluna novo_nome: " "$($colVal[0])"
    return "$($colVal[0])"
}

function verificarNome(){
    $mensagem = ""
    $nomePC = ""
    $newNomePC = ""
    try{
        #Nome atual
        $nomePC = getNomePC

        #Novo Nome
        write-Host "Obtém o nome correto no BD"
        $bdConnect = ConnectBD
        $newNomePC = getNomeBD
        CloseBD $bdConnect                  
    }catch{
        write-warning "Erro ao verificar o nome"
        $mensagem += "Erro ao verificar o nome"
        $mensagem += $_.Exception.Message
        gerarLog $message 
    }     
    if($nomePC -notcontains $newNomePC -and $newNomePC -notcontains "" ){ #Processo de verificação para saber se o PC já foi renomeado
            RenameNamePC $mensagem $nomePC $newNomePC #Linha que chama a função para alterar o nome do PC
            write-host "Alterando o nome do PC.."
            write-host "Nome:" $nomePC -foreground Magenta
            write-host "Novo nome:" $newNomePC -foreground Cyan
    }else{
        write-warning "PC ja foi renomeado!"
    }         
}

function RenameNamePC($message, $nomePC, $newNomePC){    
    try{                
        #Executa comando para renomear o PC
        Rename-computer –computername $nomePC –newname $newNomePC #Renomear o nome do PC
        write-host "PC renomeado com sucesso!"
        $message += "Ok"
    }catch{
        write-host "Ocorreu um erro ao renomear!"
        $message += "Ocorreu um erro ao renomear!"
        $message += $_.Exception.Message        
    }
    sendResponse $message    
}
function init{
    $pathOrigin_dll = '\\paloma\Log_Script_Renomeacao\MySql.Data.dll'
    try{                        
        if(!(test-path -path C:\Drivers\Renomeacao_nome)){
            write-host "CRIANDO pasta Renomeacao_nome..."
            New-Item -Path C:\Drivers\Renomeacao_nome -ItemType directory   
            write-host "pasta Renomeacao_descricao CRIADA!"
            
            write-host "COPIANDO arquivo dll..."
            Copy-Item -Path $pathOrigin_DLL -Destination 'C:\Drivers\Renomeacao_nome\MySql.Data.dll' 
            write-host "arquivo Dll COPIADO!"

        }elseif(!(Test-Path -path C:\Drivers\Renomeacao_nome\MySql.Data.dll -PathType Leaf)){
            write-host "COPIANDO arquivo dll..."
            Copy-Item -Path $pathOrigin_DLL -Destination 'C:\Drivers\Renomeacao_nome\MySql.Data.dll' 
            write-host "arquivo Dll COPIADO!"
        }else{
            write-warning "Pasta e dll já existem!"
        }	            

    }catch{                    
        $mensagem += $_.Exception.Message
        gerarLog $mensagem
    }           	
    write-host "Saindo do init......"     
}

init

write-host "Fazendo o Load do dll"
[void][system.reflection.Assembly]::LoadFrom("C:\Drivers\Renomeacao_nome\MySql.Data.dll")
verificarNome