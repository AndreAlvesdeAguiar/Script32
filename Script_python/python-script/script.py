import requests
import mysql.connector
import os
import time

# URLs das APIs locais dos ESP32
url_esp1 = "http://192.168.15.20/dados"  # ESP32 1
url_esp2 = "http://192.168.15.16/dados"  # ESP32 2

# Função para gravar dados no banco de dados
def save_data():
    try:
        # Fazendo a requisição para os ESP32
        response_esp1 = requests.get(url_esp1)
        data_esp1 = response_esp1.json()
        print(f"Dados recebidos do ESP32 1: {data_esp1}")  # Verificação

        response_esp2 = requests.get(url_esp2)
        data_esp2 = response_esp2.json()
        print(f"Dados recebidos do ESP32 2: {data_esp2}")  # Verificação

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
            query_esp1 = """INSERT INTO sensor_data_esp1 (tempC, humidity, AQI, TVOC, eCO2)
                            VALUES (%s, %s, %s, %s, %s)"""
            values_esp1 = (data_esp1.get('tempC'), data_esp1.get('humidity'),
                           data_esp1.get('AQI'), data_esp1.get('TVOC'), data_esp1.get('eCO2'))

            print(f"Inserindo no ESP32 1: {values_esp1}")  # Verificação
            cursor.execute(query_esp1, values_esp1)

            # Inserindo os dados do ESP32 2
            query_esp2 = """INSERT INTO sensor_data_esp2 (temp_aht10, humidity_aht10, mq135_value)
                            VALUES (%s, %s, %s)"""
            values_esp2 = (data_esp2.get('temperatura'), data_esp2.get('umidade'),
                        data_esp2.get('CO2'))  # Alterando as chaves para refletir o JSON correto

            print(f"Inserindo no ESP32 2: {values_esp2}")  # Verificação
            cursor.execute(query_esp2, values_esp2)

            # Confirmando as transações
            connection.commit()
            print("Dados dos ESP32 inseridos com sucesso")

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

# Loop para gravar dados a cada 5 segundos (ajustável)
while True:
    save_data()
    time.sleep(5)  # Espera 5 segundos antes de executar novamente
