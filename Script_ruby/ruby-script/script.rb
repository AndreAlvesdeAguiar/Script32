require 'net/http'
require 'json'
require 'mysql2'
require 'dotenv/load'
require 'active_support/all'  # Para usar ActiveSupport

# URL da API local do ESP32
$url_esp1 = URI('http://192.168.15.9/dados')  # ESP32 único

# Função para gravar dados no banco de dados
def save_data
  client = nil
  begin
    # Conectando ao banco de dados MySQL
    client = Mysql2::Client.new(
      host: ENV['MYSQL_HOST'] || 'localhost',
      database: ENV['MYSQL_DATABASE'] || 'esp_data',
      username: ENV['MYSQL_USER'] || 'user',
      password: ENV['MYSQL_PASSWORD'] || '1234'
    )

    # Requisição HTTP para ESP32
    http = Net::HTTP.new($url_esp1.host, $url_esp1.port)
    request = Net::HTTP::Get.new($url_esp1)
    response_esp1 = http.request(request)
    data_esp1 = JSON.parse(response_esp1.body)
    puts "Dados recebidos do ESP32: #{data_esp1}"  # Verificação

    # Obter timestamp atual no fuso horário de São Paulo
    timestamp = Time.now.in_time_zone("America/Sao_Paulo").strftime("%Y-%m-%d %H:%M:%S")

    # Inserindo os dados do ESP32 (temperatura, umidade e timestamp)
    query_esp1 = "INSERT INTO sensor_data_esp1 (tempC, humidity, timestamp) VALUES (?, ?, ?)"
    values_esp1 = [data_esp1['temperatura'], data_esp1['umidade'], timestamp]
    puts "Inserindo dados: #{values_esp1}"  # Verificação
    client.prepare(query_esp1).execute(*values_esp1)

    puts "Dados do ESP32 processados com sucesso"

  rescue Mysql2::Error => e
    puts "Erro ao conectar ao MySQL: #{e.message}"
  rescue StandardError => e
    puts "Erro ao fazer a requisição para o ESP32 ou ao processar os dados: #{e.message}"
  ensure
    # Fechando a conexão se ela foi aberta
    client.close if client
    puts "Conexão ao MySQL foi encerrada"
  end
end

# Loop para gravar dados a cada segundo
loop do
  save_data
  sleep(1)  # Espera 1 segundo antes de executar novamente
end
