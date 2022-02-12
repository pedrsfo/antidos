#!/bin/bash

# Autor: Pedro Otávio
# Atualização: 11/02/2022

# Este simples script tem por finalidade verificar a ocorrência de ataques de negação de serviço uma determinada porta
# de um determinado endereço IP.

# A lógica do script consiste na verificação das conexões TCPs realizadas em uma determinada porta, a qual será
# definida pelo usuário.

# Em seguida é ralizado o procedimento para verificão. Caso ocorra um número N de conexões em 1 segundo, entende-se como um ataque.

# Dependências para execução: tcpdump

#################### INÍCIO ##########################

# Verifica se o usuário entrou com os argumentos corretamente.
if [ "$1" == "" ] || [ "$2" == "" ];
then
	echo -e "Modo de uso: $0 IP PORTA\nExemplo: 192.168.0.11 80"
else

	# Torna o script contínuo
	while true;
	do
		# Utilizando o TCPdump para captura 5 pacotes contendo a flag TCP SYN ativa na porta e no host definido pelo usuário
		tcpdump -c 5 -nw dos.pcap -i enp0s3 dst host $1 and dst port $2 and 'tcp[13] == 2'

		# Verifica se o arquivo dos.pcap está vazio
		if [ -s dos.pcap ];
		then
			# Salva endereço do atacante na variável atacate.
			atacante=`tcpdump -nr dos.pcap | cut -d " " -f 3 | cut -d "." -f 1,2,3,4 | uniq`

			# A logica aqui é manipular o campo dos segundos do arquivo .pcap de maneira a quantificalos em um arquivo de texto
			tcpdump -nr dos.pcap | cut -d " " -f 1 | cut -d":" -f 3 | cut -d "." -f 1 | tail -n 5 | sort -u | wc -l > verificar

			# Se o número de linhas do arquivo for igual a 1,
			if [ "$(cat verificar)" == "1" ];
			# então configura um ataque de negação de serviço (dos).
			then
				echo -e "\n ATAQUE DOS DETECTADO!!!"
				echo -e "\n BLOQUEANDO ATACANTE..."

				# Bloqueando atacante.
				iptables -A INPUT -s $atacante -j DROP

				# Verifica se o atacante foi bloqueado.
				if [ "$?" != "0" ];
				then
					echo -e "\n ERRO NO BLOQUEIO!!!\n"
				else
					echo -e "\n ATAQUE BLOQUEADO!!!\n"

				fi
			fi
			# Exclui os arquivos temporários criados.
			rm dos.pcap verificar

			# Verifica a cada 3 segundos.
			sleep 3
		fi

	done;

fi
