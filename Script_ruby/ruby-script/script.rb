require 'net/http'
require 'json'
require 'mysql2'
require 'dotenv/load'
require 'active_support/all'  # Adicione esta linha para usar ActiveSupport

# URLs das APIs locais dos ESP32
$url_esp1 = URI('http://192.168.15.9/dados')  # ESP32 1
$url_esp2 = URI('http://192.168.15.16/dados')  # ESP32 2

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

    # Array para armazenar threads
    threads = []

    # Thread para ESP32 1
    threads << Thread.new do
      begin
        http = Net::HTTP.new($url_esp1.host, $url_esp1.port)
        request = Net::HTTP::Get.new($url_esp1)
        response_esp1 = http.request(request)
        data_esp1 = JSON.parse(response_esp1.body)
        puts "Dados recebidos do ESP32 1: #{data_esp1}"  # Verificação

        # Obter timestamp atual no fuso horário de São Paulo
        timestamp = Time.now.in_time_zone("America/Sao_Paulo").strftime("%Y-%m-%d %H:%M:%S")

        # Inserindo os dados do ESP32 1 (temperatura, umidade e timestamp)
        query_esp1 = "INSERT INTO sensor_data_esp1 (tempC, humidity, timestamp) VALUES (?, ?, ?)"
        values_esp1 = [data_esp1['temperatura'], data_esp1['umidade'], timestamp]
        puts "Inserindo no ESP32 1: #{values_esp1}"  # Verificação
        client.prepare(query_esp1).execute(*values_esp1)

      rescue StandardError => e
        puts "Erro ao fazer a requisição para o ESP32 1 ou ao processar os dados: #{e.message}"
      end
    end

    # Thread para ESP32 2
    threads << Thread.new do
      begin
        http = Net::HTTP.new($url_esp2.host, $url_esp2.port)
        request = Net::HTTP::Get.new($url_esp2)
        response_esp2 = http.request(request)
        data_esp2 = JSON.parse(response_esp2.body)
        puts "Dados recebidos do ESP32 2: #{data_esp2}"  # Verificação

        # Obter timestamp atual no fuso horário de São Paulo
        timestamp = Time.now.in_time_zone("America/Sao_Paulo").strftime("%Y-%m-%d %H:%M:%S")

        # Inserindo os dados do ESP32 2 (temperatura, umidade e timestamp)
        query_esp2 = "INSERT INTO sensor_data_esp2 (tempC, humidity, timestamp) VALUES (?, ?, ?)"
        values_esp2 = [data_esp2['temperatura'], data_esp2['umidade'], timestamp]
        puts "Inserindo no ESP32 2: #{values_esp2}"  # Verificação
        client.prepare(query_esp2).execute(*values_esp2)

      rescue StandardError => e
        puts "Erro ao fazer a requisição para o ESP32 2 ou ao processar os dados: #{e.message}"
      end
    end

    # Aguarda todas as threads terminarem
    threads.each(&:join)

    puts "Dados dos ESP32 processados com sucesso"

  rescue Mysql2::Error => e
    puts "Erro ao conectar ao MySQL: #{e.message}"
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
