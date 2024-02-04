#!/bin/bash

# Função para instalar o proxy
instalar_proxy() {
    echo "Instalando o proxy..."
    {
        rm -f /usr/bin/proxy
        curl -s -L -o /usr/bin/proxy https://raw.githubusercontent.com/PhoenixxZ2023/proxy/main/proxy
        chmod +x /usr/bin/proxy
    } > /dev/null 2>&1
    echo "Proxy instalado com sucesso."
}

# Função para desinstalar o proxy
desinstalar_proxy() {
    echo -e "\nDesinstalando o proxy..."

    # Encontrar e remover todos os arquivos de serviço do proxy
    arquivos_servico=$(find /etc/systemd/system -name 'proxy-*.service')
    for arquivo_servico in $arquivos_servico; do
        nome_servico=$(basename "$arquivo_servico")
        nome_servico=${nome_servico%.service}

        # Verificar se o serviço está ativo antes de parar e desabilitar
        if systemctl is-active "$nome_servico" &> /dev/null; then
            systemctl stop "$nome_servico"
            systemctl disable "$nome_servico"
        fi

        rm -f "$arquivo_servico"
        echo "Serviço $nome_servico parado, e arquivo de serviço removido: $arquivo_servico"
    done

    # Remover o arquivo binário do proxy
    rm -f /usr/bin/proxy

    echo "Proxy desinstalado com sucesso."
}

# Função para configurar e iniciar o serviço
configurar_e_iniciar_servico() {
    echo -e "\nConfigurando e iniciando o serviço de proxy..."

    read -p "Digite a porta para ativar: " PORTA
    read -p "Deseja usar HTTP(H) ou HTTPS(S)?: " HTTP_OU_HTTPS

    if [[ $HTTP_OU_HTTPS == "S" || $HTTP_OU_HTTPS == "s" ]]; then
        read -p "Digite o caminho do certificado (--cert): " CAMINHO_CERTIFICADO
    fi

    read -p "Digite o status do proxy: " RESPOSTA
    read -p "Deseja usar apenas SSH (S/N)?: " SOMENTE_SSH

    # Definir opções de comando
    OPCOES="--porta $PORTA"

    if [[ $HTTP_OU_HTTPS == "S" || $HTTP_OU_HTTPS == "s" ]]; then
        read -p "Digite o tamanho do buffer: " TAMANHO_BUFFER
        read -p "Digite o número de trabalhadores: " TRABALHADORES
        OPCOES="$OPCOES --https --cert $CAMINHO_CERTIFICADO --tamanho-buffer $TAMANHO_BUFFER --trabalhadores $TRABALHADORES"
    else
        OPCOES="$OPCOES --http"
    fi

    if [[ $SOMENTE_SSH == "S" || $SOMENTE_SSH == "s" ]]; then
        OPCOES="$OPCOES --somente-ssh"
    fi

    # Criar o arquivo de serviço
    ARQUIVO_SERVICO="/etc/systemd/system/proxy-$PORTA.service"
    cat <<EOF > "$ARQUIVO_SERVICO"
[Unit]
Descrição=Proxy Ativo na Porta $PORTA
Depois=network.target

[Service]
Tipo=simples
Usuário=root
DiretorioDeTrabalho=/root
ExecStart=/usr/bin/proxy $OPCOES --resposta $RESPOSTA
Reiniciar=sempre

[Install]
QueridoPor=multi-user.target
EOF

    # Recarregar o systemd
    systemctl daemon-reload

    # Iniciar o serviço e configurar a inicialização automática
    systemctl start "proxy-$PORTA"
    systemctl enable "proxy-$PORTA"

    echo "Serviço de proxy na porta $PORTA configurado e iniciado automaticamente."
}

# Função para parar e remover o serviço
parar_e_remover_servico() {
    echo -e "\nParando e removendo o serviço de proxy..."

    read -p "Digite a porta para parar: " NUMERO_SERVICO

    # Parar o serviço
    systemctl stop "proxy-$NUMERO_SERVICO"

    # Desabilitar o serviço
    systemctl disable "proxy-$NUMERO_SERVICO"

    # Encontrar e remover o arquivo de serviço
    arquivo_servico=$(find /etc/systemd/system -name "proxy-$NUMERO_SERVICO.service")
    if [ -f "$arquivo_servico" ]; then
        rm "$arquivo_servico"
        echo "Porta removida com sucesso: $arquivo_servico"
    else
        echo "Arquivo de serviço não encontrado para o serviço proxy-$NUMERO_SERVICO."
    fi

    echo "Porta proxy-$NUMERO_SERVICO parada e removida."
}

# Função para criar um link simbólico para o script de menu
criar_link_simbolico() {
    CAMINHO_SCRIPT=$(realpath "$0")
    NOME_LINK="/usr/local/bin/mainproxy"

    if [[ ! -f "$NOME_LINK" ]]; then
        ln -s "$CAMINHO_SCRIPT" "$NOME_LINK"
        echo "Link simbólico 'mainproxy' criado. Você pode executar o menu usando 'mainproxy'."
    else
        echo "Link simbólico 'mainproxy' já existe."
    fi
}

# Função para imprimir o cabeçalho
imprimir_cabecalho() {
    echo -e "\n\e[1;94m=======================================\e[0m"
    echo -e "\e[1;94m         MENU DO TURBONET PROXY MOD       \e[0m"
    echo -e "\e[1;94m=======================================\e[0m"
}

# Menu de Gerenciamento
while true; do
    clear
    imprimir_cabecalho
    echo -e "\033[1;31m║\033[0m\033[1;31m[\033[1;36m1\033[1;31m] \033[1;37m• \033[1;33mInstalar o TURBONET PROXY MOD \033[0m"
    echo -e "\033[1;31m║\033[0m\033[1;31m[\033[1;36m2\033[1;31m] \033[1;37m• \033[1;33mParar e Remover Porta \033[0m"
    echo -e "\033[1;31m║\033[0m\033[1;31m[\033[1;36m3\033[1;31m] \033[1;37m• \033[1;33mReiniciar o Proxy \033[0m"
    echo -e "\033[1;31m║\033[0m\033[1;31m[\033[1;36m4\033[1;31m] \033[1;37m• \033[1;33mVer Status do Proxy \033[0m"
    echo -e "\033[1;31m║\033[0m\033[1;31m[\033[1;36m5\033[1;31m] \033[1;37m• \033[1;33mReinstalar o Proxy \033[0m"
    echo -e "\033[1;31m║\033[0m\033[1;31m[\033[1;36m6\033[1;31m] \033[1;37m• \033[1;33mSair \033[0m"
    echo -e "\033[1;31m=======================================\e[0m"
    echo ""
    echo -ne "\033[1;31m➤ \033[1;32mEscolha a opção desejada\033[1;33m\033[1;31m\033[1;37m: "
    read -p "" escolha

    case $escolha in
        1 | 01) instalar_proxy ;;
        2 | 02) parar_e_remover_servico ;;
        3 | 03)
            echo "Serviços em execução:"
            systemctl list-units --type=service --state=running | grep proxy-
            read -p "Digite a porta para reiniciar: " numero_servico
            systemctl restart "proxy-$numero_servico"
            echo "Serviço Proxy-$numero_servico reiniciado."
            ;;
        4 | 04)
            systemctl list-units --type=service --state=running | grep proxy-
            ;;
        5 | 05)
            echo "Desinstalando o proxy antes de reinstalar..."
            desinstalar_proxy
            instalar_proxy
            ;;
        6 | 06)
            echo "Saindo."
            exit
            ;;
        *)
            echo "Opção inválida. Escolha uma opção válida."
            ;;
    esac

    read -p "Pressione Enter para continuar..."
done
