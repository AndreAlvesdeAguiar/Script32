#include <Wire.h>
#include <Adafruit_AHTX0.h>     // Biblioteca para AHT10
#include <RTClib.h>             // Biblioteca para RTC (DS3231/DS1307)
#include <SD.h>                 // Biblioteca para microSD
#include <SPI.h>

// Instância do sensor AHT10 e do RTC
Adafruit_AHTX0 aht;
RTC_DS3231 rtc;

// Configurações do microSD
const int chipSelect = 5;

File dataFile;

void setup() {
  // Inicializa a comunicação serial
  Serial.begin(115200);

  // Inicializa o sensor AHT10
  if (!aht.begin()) {
    Serial.println("Não foi possível inicializar o AHT10!");
    while (1);
  }
  Serial.println("AHT10 inicializado com sucesso!");

  // Inicializa o RTC
  if (!rtc.begin()) {
    Serial.println("Não foi possível encontrar o RTC!");
    while (1);
  }

  // Verifica se o RTC está funcionando, caso contrário, configura uma hora inicial
  if (rtc.lostPower()) {
    Serial.println("RTC perdeu a hora, configurando a hora inicial...");
    // Ajusta a data/hora inicial do RTC (Apenas na primeira vez, depois pode comentar esta linha)
    rtc.adjust(DateTime(F(__DATE__), F(__TIME__)));
  }

  // Inicializa o cartão SD
  if (!SD.begin(chipSelect)) {
    Serial.println("Erro ao inicializar o cartão SD!");
    while (1);
  }
  Serial.println("Cartão SD inicializado com sucesso!");

  // Abre ou cria o arquivo no cartão SD
  dataFile = SD.open("/dados_sensor.txt", FILE_WRITE);
  if (!dataFile) {
    Serial.println("Erro ao abrir o arquivo no cartão SD!");
    while (1);
  }
}

void loop() {
  // Lê os dados do AHT10
  sensors_event_t humidity, temp;
  aht.getEvent(&humidity, &temp);

  // Obtém a data e hora atuais do RTC
  DateTime now = rtc.now();

  // Formata a data e hora como "YYYY-MM-DD HH:MM:SS"
  char datetime[20];
  snprintf(datetime, sizeof(datetime), "%04d-%02d-%02d %02d:%02d:%02d",
           now.year(), now.month(), now.day(), now.hour(), now.minute(), now.second());

  // Exibe os dados no monitor serial
  Serial.print("Data/Hora: ");
  Serial.println(datetime);
  
  Serial.print("Temperatura: ");
  Serial.print(temp.temperature);
  Serial.println(" °C");
  
  Serial.print("Umidade: ");
  Serial.print(humidity.relative_humidity);
  Serial.println(" %");

  // Grava os dados no arquivo do cartão SD
  dataFile.print("Data/Hora: ");
  dataFile.print(datetime);
  dataFile.print(", Temperatura: ");
  dataFile.print(temp.temperature);
  dataFile.print(" °C, Umidade: ");
  dataFile.print(humidity.relative_humidity);
  dataFile.println(" %");

  // Assegura que os dados são gravados
  dataFile.flush();

  // Intervalo de 5 segundos antes da próxima leitura
  delay(5000);
}
