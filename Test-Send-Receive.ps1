Clear-Host
# |F|O|N|C|T|I|O|N| |S|E|R|V|E|R| |U|D|P| #
Function StartSrvUDP
{
    Param (
        $Port,
        $ReturnUDP
    )
    Write-Host "Demarrage du serveur UDP $Port"
    #Initialisation.
    $ReturnUDP = ""

    #Création d'un objet EndPoint.
    $endpoint2 = new-object System.Net.IPEndPoint ([IPAddress]::Any,$Port)

    #Création d'un objet Socket UDP.
    $socudp2 = new-Object System.Net.Sockets.UdpClient $Port

    #Définition du TimeOut
    $socudp2.Client.ReceiveTimeout = 10000

    Try {
        #Attent l'arrivée des données.
        $encode2 = $socudp2.Receive([ref]$endpoint2)
    } Catch {
        #Affichage du message d'erreur
        Write-Warning "$($Error[0].Exception.InnerException.SocketErrorCode)"
        $TmpError = "$($Error[0].Exception.InnerException.SocketErrorCode)"
    }
    Try {
        #Converti les données reçues.
        $ReturnUDP  = [Text.Encoding]::ASCII.GetString($encode2)
    } Catch {
        #Affiche un message d'erreur si il y à pas de TimedOut
        if ($($Error[0].Exception.InnerException.InnerException) -eq $null -and $TmpError -ne "TimedOut") 
        {Write-Warning "Aucunes donees recus"}
    }
    
    #Fermeture.
    $socudp2.Close()

    #Fin. 
    Return $ReturnUDP
}
# |F|I|N| |D|E| |L|A| |F|O|N|C|T|I|O|N| |S|E|R|V|E|R| |U|D|P| #

###############################################################################

# |F|O|N|C|T|I|O|N| |S|E|R|V|E|R| |T|C|P| #
function StartSrvTCP
{
    Param (
        $Port,
        $ReturnTCP
    )
    #Initialisation de la variable
    $Buffer = ""

    #Creation d'un Job
    $Job = Start-Job -ArgumentList $port -Name "StartSrvTCP" -ScriptBlock {
            #Récuperation de la varible $port pour l'utiliser dans le job
            $port = $args[0]

            #Paramétrage du TcpListener
            $server = New-Object -TypeName System.Net.Sockets.TcpListener -ArgumentList @([System.Net.IPAddress]::Any, $port)
            
            #Démarrage de l'ecoute
            $server.Start()
            
            Write-Host "Listening on port $port"

            #Accepte une demande de connexion en attente.
            $clientSocket = $server.AcceptSocket()

            #Paramétrage du buffer
            $buffer = new-object System.Byte[] 2048;

            #Réception des données
            $clientSocket.Receive($buffer) 

            ##Converti les données reçues.
            $ReturnTCP = [System.Text.Encoding]::ASCII.GetString($Buffer)

            #Fermeture du socket
            $clientSocket.Close()
        
            #Arret de l'ecoute 
            $server.Stop()

            # Retour du resultat
            Return $ReturnTCP
    }
    #Fin du Job

    #Timeout de 10s
    Wait-Job -Id $job.Id -Timeout 10

    Write-Host "Stopped Listening"

    #Retour des infos
    Return (Get-Job -Id $job.Id | Receive-Job)
   
}
# |F|I|N| |D|E| |L|A| |F|O|N|C|T|I|O|N| |S|E|R|V|E|R| |T|C|P| #

###############################################################################

# |F|O|N|C|T|I|O|N| |C|L|I|E|N|T| |U|D|P| #
function StartClientUDP
{
    Param (
        $Port,
        $ReturnUDP,
        $IP
    )
            #Récuperation du nom de l'hote
            $hostname = $env:computername

            Write-Host "Emission des donnees sur le reseau. Port UDP : $Port"

            #Ip du destinataire.
            $ippc1 = [System.Net.Dns]::GetHostAddresses($IP)

            #Texte à envoyer.
            $SendText = "Test du $hostname -> $IP Port UDP: $Port reussi"

            #Création d'un objet EndPoint.
            $endpoint1 = new-object System.Net.IPEndPoint ([IPAddress]$ippc1[0],$Port)

            #Création d'un objet Socket UDP.
            $SocUDP = new-Object System.Net.Sockets.UdpClient

            #Préparation du text à l'envoi.
            $SendText = [Text.Encoding]::ASCII.GetBytes($SendText)

            #Envoie du message.
            $envoie1 = $SocUDP.Send($SendText,$SendText.length,$endpoint1)

            #Fermeture.
            $SocUDP.Close()
}
# |F|I|N| |D|E| |L|A| |F|O|N|C|T|I|O|N| |C|L|I|E|N|T| |U|D|P| #

###############################################################################

# |F|O|N|C|T|I|O|N| |C|L|I|E|N|T| |T|C|P| #
function StartClientTCP
{
    Param (
        $Port,
        $ReturnTCP,
        $IP
    )    
                #Récuperation du nom de l'hote
                $hostname = $env:computername
                
                Write-Host "Emission des donnees sur le reseau. Port TCP : $Port"

                #Ip du destinataire.
                $ippc1 = [System.Net.Dns]::GetHostAddresses($IP)

                #Texte à envoyer.
                $SendText = "Test du $hostname -> $IP Port TCP: $Port reussi"

                #Création d'un objet Socket TCP.
                $SocTCP = New-Object -TypeName System.Net.Sockets.TcpClient -ArgumentList $IP,$port
                
                #Retourne le NetworkStream utilisé pour l'envoi et la réception de données.
                $stream = $SocTCP.GetStream()
                
                #Préparation du text à l'envoi.
                $buffer = [System.Text.Encoding]::ASCII.GetBytes($SendText)
                $ReturnTCP = [System.Text.Encoding]::ASCII.GetString($Buffer)
                
                #Envoie du message.
                $stream.Write($buffer, 0, $buffer.Length)

                #Fermeture.
                $stream.Close()
                $SocTCP.Close()
}
# |F|I|N| |D|E| |L|A| |F|O|N|C|T|I|O|N| |C|L|I|E|N|T| |T|C|P| #

# |M|E|N|U| #
do {
    do {
        write-host ""
        write-host "U - Serveur UDP"
        write-host "T - Serveur TCP"
        write-host "A - Client UDP"
        write-host "B - Client TCP"
        write-host ""
        write-host "X - Exit"
        write-host ""
        write-host -nonewline "Tapez votre choix et appuyez sur Entree: "
        
        $choice = read-host
        
        write-host ""
        
        $ok = $choice -match '^[abutx]+$'
        
        if ( -not $ok) { write-host "Choix invalide !" }
    } until ( $ok )
    
    switch -Regex ( $choice ) {
        "U"
        # SERVEUR UDP #
        {
            write-host "Serveur UDP"

            $Port=Read-Host "Entrer le numero de port UDP"

            # Vérification du port, si le port n'est pas utilisé $CheckPort est null
            $CheckPort = Get-NetUDPEndpoint -LocalPort $Port -ErrorAction SilentlyContinue
            if ($null -eq $CheckPort)
                {Write-Information "Le port n'est pas utilise"
                #Démarrage du Serveur UDP
                $ReturnUDP = StartSrvUDP -Port $Port
                Write-Host $ReturnUDP -ForegroundColor green
                }

            else {
                Write-Warning "Le port $Port est utilise, impossible de tester !"
            }



        }
        
        "T"
        # SERVEUR TCP #
        {
            write-host "Serveur TCP"
            $Port=Read-Host "Entrer le numero de port TCP"

            # Vérification du port, si le port n'est pas utilisé $CheckPort est null
            $CheckPort = Get-NetTCPConnection -LocalPort $Port -ErrorAction SilentlyContinue
            if ($null -eq $CheckPort)
                {Write-Information "Le port n'est pas utilise"
                #Démarrage du Serveur TCP
                $ReturnTCP = StartSrvTCP -Port $Port -ErrorAction SilentlyContinue
                if ($ReturnTCP -eq $null) 
                    {Write-Warning "!! Time Out !!"
                    
                    #Envoie d'une requete pour liberer le socket
                    Write-Warning "Envoie d'une requete local pour liberer le socket"
                    StartClientTCP -Port $Port -IP "127.0.0.1"
                    }
                else {Write-Host $ReturnTCP[2] -ForegroundColor green}

                
                }

            else {
                Write-Warning "Le port $Port est utilise, impossible de tester !"
            }



        }

        "A"
        # CLIENT UDP #
        {
            write-host "Client UDP"

            #Port de communication.
            $Port=Read-Host "Entrer le numero de port UDP"
            $IP=Read-Host "Entrer l'IP de destination"

            #Démarrage du Serveur UDP
            $ReturnUDP = StartClientUDP -Port $Port -IP $IP
            Write-Host $ReturnUDP -ForegroundColor green
           
        }
        
        "B"
        # CLIENT TCP #
        {
            write-host "Client TCP"
            
            $Port=Read-Host "Entrer le numero de port TCP"
            $IP=Read-Host "Entrer l'IP de destination"
            
            #Démarrage du Serveur TCP
            $ReturnTCP = StartClientTCP -Port $Port -IP $IP
            Write-Host $ReturnTCP -ForegroundColor green
        }
    }
} until ( $choice -match "X" )