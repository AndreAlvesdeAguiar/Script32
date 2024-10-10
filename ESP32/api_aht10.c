#include <Adafruit_AHTX0.h>
#include <WiFi.h>
#include <ESPAsyncWebServer.h>

// Instância do sensor AHT
Adafruit_AHTX0 aht;

// Configurações de rede WiFi
const char* ssid = "Login";  // Substitua pelo seu SSID
const char* password = "Senha";  // Substitua pela sua senha

// Criação do servidor
AsyncWebServer server(80);

void setup() {
  Serial.begin(115200);
  
  // Inicializando o sensor AHT
  Serial.println("Inicializando sensor AHT...");
  if (!aht.begin()) {
    Serial.println("Falha ao iniciar o sensor AHT.");
    while (1);
  }
  Serial.println("Sensor AHT iniciado com sucesso!");

  // Conectar à rede WiFi
  Serial.print("Conectando-se à rede WiFi...");
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(1000);
    Serial.print(".");
  }
  Serial.println();
  Serial.println("Conectado ao WiFi!");
  Serial.print("Endereço IP: ");
  Serial.println(WiFi.localIP());

  // Configura a rota da API para fornecer dados do sensor AHT
  server.on("/dados", HTTP_GET, [](AsyncWebServerRequest *request) {
    sensors_event_t humidity_event, temp_event;
    aht.getEvent(&humidity_event, &temp_event);

    String json = "{";
    json += "\"temperatura\": " + String(temp_event.temperature) + ",";
    json += "\"umidade\": " + String(humidity_event.relative_humidity);
    json += "}";

    request->send(200, "application/json", json);  // Envia a resposta em JSON
  });

  // Inicia o servidor
  server.begin();
}

void loop() {
  // Aguarda 2 segundos entre as leituras
  delay(2000);

  // Leitura dos dados do sensor AHT
  sensors_event_t humidity_event, temp_event;
  aht.getEvent(&humidity_event, &temp_event);

  // Exibe os dados no Serial Monitor
  Serial.print("Temperatura: ");
  Serial.print(temp_event.temperature);
  Serial.println(" °C");

  Serial.print("Umidade: ");
  Serial.print(humidity_event.relative_humidity);
  Serial.println(" %");
}
