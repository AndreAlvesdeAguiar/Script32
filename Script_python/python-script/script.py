import requests
import mysql.connector
import os
import time

# URL da API local do ESP32
url_esp1 = "http://192.168.15.9/dados"  # ESP32 1

# Função para gravar dados no banco de dados
def save_data():
    try:
        # Fazendo a requisição para o ESP32
        response_esp1 = requests.get(url_esp1)
        data_esp1 = response_esp1.json()
        print(f"Dados recebidos do ESP32 1: {data_esp1}")  # Verificação

        # Conectando ao banco de dados MySQL
        connection = mysql.connector.connect(
            host=os.getenv('MYSQL_HOST', 'localhost'),  # Ajuste se necessário
            database=os.getenv('MYSQL_DATABASE', 'esp_data'),
            user=os.getenv('MYSQL_USER', 'user'),
            password=os.getenv('MYSQL_PASSWORD', '1234')
        )

        if connection:
            cursor = connection.cursor()

            # Inserindo os dados do ESP32 1
            query_esp1 = """INSERT INTO sensor_data_esp1 (temperatura, umidade)
                            VALUES (%s, %s)"""
            values_esp1 = (data_esp1.get('temperatura'), data_esp1.get('umidade'))

            print(f"Inserindo no ESP32 1: {values_esp1}")  # Verificação
            cursor.execute(query_esp1, values_esp1)

            # Confirmando a transação
            connection.commit()
            print("Dados do ESP32 1 inseridos com sucesso")

    except mysql.connector.Error as e:
        print(f"Erro ao conectar ao MySQL: {e}")

    except requests.exceptions.RequestException as e:
        print(f"Erro ao fazer a requisição para a API: {e}")

    finally:
        # Fechando a conexão se ela foi aberta
        if 'connection' in locals():
            cursor.close()
            connection.close()
            print("Conexão ao MySQL foi encerrada")

# Loop para gravar dados a cada 1 segundo (ajustável)
while True:
    save_data()
    time.sleep(1)  # Espera 1 segundo antes de executar novamente
