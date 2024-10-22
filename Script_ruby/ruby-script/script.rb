require 'net/http'
require 'json'
require 'mysql2'
require 'dotenv/load'

# URLs das APIs locais dos ESP32
url_esp1 = URI('http://192.168.15.9/dados')  # ESP32 1
url_esp2 = URI('http://192.168.15.16/dados')  # ESP32 2

# Função para gravar dados no banco de dados
def save_data
  begin
    # Fazendo a requisição para os ESP32
    http = Net::HTTP.new(url_esp1.host, url_esp1.port)
    request = Net::HTTP::Get.new(url_esp1)
    response_esp1 = http.request(request)
    data_esp1 = JSON.parse(response_esp1.body)
    puts "Dados recebidos do ESP32 1: #{data_esp1}"  # Verificação

    http = Net::HTTP.new(url_esp2.host, url_esp2.port)
    request = Net::HTTP::Get.new(url_esp2)
    response_esp2 = http.request(request)
    data_esp2 = JSON.parse(response_esp2.body)
    puts "Dados recebidos do ESP32 2: #{data_esp2}"  # Verificação

    # Conectando ao banco de dados MySQL
    client = Mysql2::Client.new(
      host: ENV['MYSQL_HOST'] || 'localhost',
      database: ENV['MYSQL_DATABASE'] || 'esp_data',
      username: ENV['MYSQL_USER'] || 'user',
      password: ENV['MYSQL_PASSWORD'] || '1234'
    )

    # Inserindo os dados do ESP32 1
    query_esp1 = "INSERT INTO sensor_data_esp1 (tempC, humidity, AQI, TVOC, eCO2)
                  VALUES (?, ?, ?, ?, ?)"
    values_esp1 = [
      data_esp1['tempC'], data_esp1['humidity'], 
      data_esp1['AQI'], data_esp1['TVOC'], data_esp1['eCO2']
    ]
    puts "Inserindo no ESP32 1: #{values_esp1}"  # Verificação
    client.prepare(query_esp1).execute(*values_esp1)

    # Inserindo os dados do ESP32 2
    query_esp2 = "INSERT INTO sensor_data_esp2 (temp_aht10, humidity_aht10, mq135_value)
                  VALUES (?, ?, ?)"
    values_esp2 = [
      data_esp2['temperatura'], data_esp2['umidade'], 
      data_esp2['CO2']  # Alterando as chaves para refletir o JSON correto
    ]
    puts "Inserindo no ESP32 2: #{values_esp2}"  # Verificação
    client.prepare(query_esp2).execute(*values_esp2)

    # Confirmando as transações
    puts "Dados dos ESP32 inseridos com sucesso"

  rescue Mysql2::Error => e
    puts "Erro ao conectar ao MySQL: #{e.message}"

  rescue StandardError => e
    puts "Erro ao fazer a requisição para a API ou ao processar os dados: #{e.message}"

  ensure
    # Fechando a conexão se ela foi aberta
    client.close if client
    puts "Conexão ao MySQL foi encerrada"
  end
end

# Loop para gravar dados a cada 5 segundos (ajustável)
loop do
  save_data
  sleep(5)  # Espera 5 segundos antes de executar novamente
end
