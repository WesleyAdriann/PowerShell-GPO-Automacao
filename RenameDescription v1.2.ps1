$ComputerSystem = Get-WmiObject -class win32_ComputerSystem
$NamePC = $ComputerSystem.PSComputerName
$dataHora = Get-Date -Format g

function criarDiretorioLocal{
	if(!(test-path -path C:\Drivers\Renomeacao_descricao)){
        New-Item -Path C:\Drivers\Renomeacao_descricao -ItemType directory 
        $mensagem >> C:\Drivers\Renomeacao_descricao\log_gpoRenameDescription.txt
        $mensagem="Script para renomear a descrição do pc foi inicializado."
	}  
}

try{       
	criarDiretorioLocal
    Copy-Item -Path '\\10.41.0.163\Log_Script_Renomeacao\Saida - Map. PCs.csv' -Destination 'C:\Drivers\Renomeacao_descricao\copy_Saida - Map. PCs.csv'
    Start-Sleep -s 2   
    $path = 'C:\Drivers\Renomeacao_descricao\copy_Saida - Map. PCs.csv'

    #Colunas
    $nomePC = @()
    $modelo = @()
    $setorSub = @()
    $sala = @()

    Import-Csv $path |`
        ForEach-Object {
            $nomePC += $_."Nome"
            $modelo += $_."Modelo"
            $setorSub += $_."Setor"
            $sala += $_."Sala"
        }

    #Salva o arquivo csv
    $csvFile = Import-Csv $path

    #Descrição atual
    $Reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine',$computer)
    $RegKey= $Reg.OpenSubKey("SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters")
    $description = $RegKey.GetValue("srvcomment")

    write-host "Nome-PC:" $NamePC -ForegroundColor gray

    if ($nomePC -contains $NamePC){
        $dataHora = Get-Date -Format g
        $pcFound = "["+$dataHora+"] Máquina encontrada!"
        $mensagem += " -> "+$pcFound  
        Write-Host $pcFound
        write-host "Descrição atual: " $description -ForegroundColor Yellow
        write-host "" 
        $Where = [array]::IndexOf($nomePC, $NamePC)
        $newDescription = $modelo[$Where] + " - " + $setorSub[$Where] + " - " + $sala[$Where]
        
        $csvFile[$Where]."Status" = "Ok" #Escreve na planilha que a renomeação foi realizada
        
        net config server /srvcomment:$newDescription 
        write-host "Descrição nova: " $newDescription.toString() -ForegroundColor Green    
        write-host ""
        $mensagem += " -> Descrição atual: " + $description + " -> Nova descrição: "+ $newDescription 
		$description = $newDescription 
         
    }else{
        write-host "Máquina não encontrada na planilha!" -ForegroundColor Red   
        write-host "Não foi possível renomear a descrição de" $ComputerSystem.PSComputerName   
        $mensagem += " -> Máquina não encontrada na planilha"  
    }   

}catch{
    $ErrorMessage = $_.Exception.Message
    $mensagem += " -> " + $ErrorMessage
    $csvFile[$Where]."Status" = $ErrorMessage #Escreve na planilha que a renomeação ocorreu um erro.    
}


function gerarLog($mensagem){
	#Tamanho máximo = 512 KB = 512000 Bytes
	$sizeMax = 512000
	$logSize = Get-Childitem -file C:\Drivers\Renomeacao_descricao\log_gpoRenameDescription.txt | select length
	$logSizeNum = $logSize -replace "[^0-9]"
	
	
	if([int]$logSizeNum -ge $sizeMax){
		Clear-Content C:\Drivers\Renomeacao_descricao\log_gpoRenameDescription.txt
		write-host "Limpando arquivo..."
		Start-Sleep -s 3    
		$mensagem = "Foi criado um novo arquivo `r`n" + $mensagem    
	}
	write-host "Gerando log..."
	$mensagem += "`r`n`r`n"
	$mensagem >> C:\Drivers\Renomeacao_descricao\log_gpoRenameDescription.txt
}

function criarCSVAtualizado($mensagem){
	$info = $mensagem
	try{
		$csvFile[$Where]."Descri??o Atual" = $description #Escreve na planilha que a renomeação foi realizada
		
		gerarLog($info) #Chama o método para criar o log .txt
				
		$csvFile | Export-Csv -Path "C:\Drivers\Renomeacao_descricao\new_Saida - Map. PCs.csv" #Criar um novo CSV		
		Start-Sleep -s 5 #Espera cinco segundo para dar tempo de  copiar a nova saída para o \\paloma
		Copy-Item -Path 'C:\Drivers\Renomeacao_descricao\new_Saida - Map. PCs.csv' -Destination '\\10.41.0.163\Log_Script_Renomeacao\Saida - Map. PCs.csv'
	}
	catch{
		write-host "O arquivo está aberto. Portanto não pode ser sobreescrito. `r`n Esperando ele ser fechado para que a saída seja registrada..."
		Start-Sleep -s 5 		
		$ErrorMessage = $_.Exception.Message
		$info += " -> " + $ErrorMessage
		$csvFile[$Where]."Status" = $ErrorMessage #Escreve na planilha que a renomeação ocorreu um erro. 
		criarCSVAtualizado($info)
	}
}       
criarCSVAtualizado($mensagem)

