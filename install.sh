#!/bin/bash

# Verificar se o proxy já está instalado
if [ -f /usr/bin/proxy ]; then
    echo "O proxy já está instalado. Ignorando a instalação."
else
    # Função para instalar o proxy
    install_proxy() {
        echo "Instalando o proxy..."
        {
            rm -f /usr/bin/proxy
            curl -s -L -o /usr/bin/proxy https://raw.githubusercontent.com/TelksBr/proxy/main/proxy
            chmod +x /usr/bin/proxy
        } > /dev/null 2>&1
        echo "Proxy instalado com sucesso."
    }
    
    # Instalar o proxy
    install_proxy
fi


uninstall_proxy() {
    echo -e "\nDesinstalando o proxy..."
    
    # Encontra e remove todos os arquivos de serviço do proxy
    service_files=$(find /etc/systemd/system -name 'proxy-*.service')
    for service_file in $service_files; do
        service_name=$(basename "$service_file")
        service_name=${service_name%.service}
        
        # Verifica se o serviço está ativo antes de tentar parar e desabilitar
        if  systemctl is-active "$service_name" &> /dev/null; then
            systemctl stop "$service_name"
            systemctl disable "$service_name"
        fi
        
        rm -f "$service_file"
        echo "Serviço $service_name parado e arquivo de serviço removido: $service_file"
    done
    
    # Remove o arquivo binário do proxy
    rm -f /usr/bin/proxy
    
    echo "Proxy desinstalado com sucesso."
}

# Configurar e iniciar o serviço
configure_and_start_service() {
    read -p "Digite a porta a ser usada (--port): " PORT
    read -p "Você quer usar HTTP (H) ou HTTPS (S)? [H/S]: " HTTP_OR_HTTPS
    if [[ $HTTP_OR_HTTPS == "S" || $HTTP_OR_HTTPS == "s" ]]; then
        read -p "Digite o caminho do certificado (--cert): " CERT_PATH
    fi
    read -p "Digite o conteúdo da resposta HTTP (--response): " RESPONSE
    read -p "Você quer usar apenas SSH (Y/N)? [Y/N]: " SSH_ONLY
    
    # Defina as opções de comando
    OPTIONS="--port $PORT"
    
    if [[ $HTTP_OR_HTTPS == "S" || $HTTP_OR_HTTPS == "s" ]]; then
        OPTIONS="$OPTIONS --https --cert $CERT_PATH"
    else
        OPTIONS="$OPTIONS --http"
    fi
    
    if [[ $SSH_ONLY == "Y" || $SSH_ONLY == "y" ]]; then
        OPTIONS="$OPTIONS --ssh-only"
    fi
    
    # Crie o arquivo de serviço
    SERVICE_FILE="/etc/systemd/system/proxy-$PORT.service"
    echo "[Unit]" > "$SERVICE_FILE"
    echo "Description=Proxy Service on Port $PORT" >> "$SERVICE_FILE"
    echo "After=network.target" >> "$SERVICE_FILE"
    echo "" >> "$SERVICE_FILE"
    echo "[Service]" >> "$SERVICE_FILE"
    echo "Type=simple" >> "$SERVICE_FILE"
    echo "User=root" >> "$SERVICE_FILE"
    echo "WorkingDirectory=/root" >> "$SERVICE_FILE"
    echo "ExecStart=/usr/bin/proxy $OPTIONS --buffer-size 2048 --workers 5000 --response $RESPONSE" >> "$SERVICE_FILE" # Parâmetro --response no final
    echo "Restart=always" >> "$SERVICE_FILE"
    echo "" >> "$SERVICE_FILE"
    echo "[Install]" >> "$SERVICE_FILE"
    echo "WantedBy=multi-user.target" >> "$SERVICE_FILE"
    
    
    
    # Recarregue o systemd
    systemctl daemon-reload
    
    # Inicie o serviço e configure o início automático
    systemctl start proxy-$PORT
    systemctl enable proxy-$PORT
    
    echo "O serviço do proxy na porta $PORT foi configurado e iniciado automaticamente."
}

stop_and_remove_service() {
    read -p "Digite o número do serviço a ser parado e removido: " service_number
    
    # Parar o serviço
    systemctl stop proxy-$service_number
    
    # Desabilitar o serviço
    systemctl disable proxy-$service_number
    
    # Encontrar e remover o arquivo do serviço
    service_file=$(find /etc/systemd/system -name "proxy-$service_number.service")
    if [ -f "$service_file" ]; then
        rm "$service_file"
        echo "Arquivo de serviço removido: $service_file"
    else
        echo "Arquivo de serviço não encontrado para o serviço proxy-$service_number."
    fi
    
    echo "Serviço proxy-$service_number parado e removido."
}

# Criar link simbólico para o script do menu
SCRIPT_PATH=$(realpath "$0")
SCRIPT_DIR=$(dirname "$SCRIPT_PATH")
LINK_NAME="/usr/local/bin/mainproxy"

if [[ ! -f "$LINK_NAME" ]]; then
    ln -s "$SCRIPT_PATH" "$LINK_NAME"
    echo "Link simbólico 'mainproxy' criado. Você pode executar o menu usando 'mainproxy'."
else
    echo "Link simbólico 'mainproxy' já existe."
fi




# Menu de gerenciamento
while true; do
    clear
    echo "Menu de Gerenciamento do Serviço Proxy:"
    echo "1. Configurar e Iniciar um Novo Serviço"
    echo "2. Parar e Remover um Serviço"
    echo "3. Reiniciar um Serviço"
    echo "4. Ver Status dos Serviços"
    echo "5. Reinstalar o Proxy"
    echo "6. Sair"
    
    read -p "Escolha uma opção: " choice
    
    case $choice in
        1)
            configure_and_start_service
        ;;
        2)
            stop_and_remove_service
        ;;
        3)
            echo "Serviços em execução:"
            systemctl list-units --type=service --state=running | grep proxy-
            read -p "Digite o número do serviço a ser reiniciado: " service_number
            systemctl restart proxy-$service_number
            echo "Serviço proxy-$service_number reiniciado."
        ;;
        4)
            systemctl list-units --type=service --state=running | grep proxy-
        ;;
        5)
            echo "Desinstalando o proxy antes de reinstalar..."
            uninstall_proxy
            install_proxy
        ;;
        6)
            echo "Saindo."
            break
        ;;
        *)
            echo "Opção inválida. Escolha uma opção válida."
        ;;
    esac
    
    read -p "Pressione Enter para continuar..."
done
