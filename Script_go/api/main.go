package main

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"time"

	_ "github.com/go-sql-driver/mysql"
)

// Struct para os dados
type Data struct {
	Temperatura float64 `json:"temperatura"`
	Umidade     float64 `json:"umidade"`
}

// Função para buscar dados e salvar no banco
func fetchAndSaveData() error {
	log.Println("Iniciando a solicitação HTTP para obter os dados...")

	// Realiza a solicitação HTTP
	resp, err := http.Get("http://192.168.15.9/dados")
	if err != nil {
		log.Println("Erro ao fazer a solicitação HTTP:", err)
		return err
	}
	defer resp.Body.Close()

	// Lê a resposta como JSON
	var data Data
	if err := json.NewDecoder(resp.Body).Decode(&data); err != nil {
		log.Println("Erro ao decodificar JSON:", err)
		return err
	}

	log.Printf("Dados extraídos - Temperatura: %.2f, Umidade: %.2f\n", data.Temperatura, data.Umidade)

	// Conecta ao banco de dados MySQL
	log.Println("Conectando ao banco de dados...")
	db, err := sql.Open("mysql", "tester:secret@tcp(db:3306)/my_database")
	if err != nil {
		log.Println("Erro ao conectar ao banco de dados:", err)
		return err
	}
	defer db.Close()

	// Verifica a conexão com o banco
	if err = db.Ping(); err != nil {
		log.Println("Erro ao pingar o banco de dados:", err)
		return err
	}

	// Obtém o timestamp atual e ajusta para o fuso horário de SP (UTC-3)
	now := time.Now()
	loc, err := time.LoadLocation("America/Sao_Paulo")
	if err != nil {
		log.Println("Erro ao carregar localização:", err)
		return err
	}
	now = now.In(loc)

	// Insere os dados no banco de dados
	log.Println("Inserindo os dados no banco de dados...")
	_, err = db.Exec("INSERT INTO sensor_data (temperatura, umidade, created_at) VALUES (?, ?, ?)", data.Temperatura, data.Umidade, now.UTC())
	if err != nil {
		log.Println("Erro ao inserir os dados no banco de dados:", err)
		return err
	}

	log.Println("Dados inseridos com sucesso!")
	return nil
}

// Função para iniciar a coleta de dados a cada segundo
func startDataCollection() {
	ticker := time.NewTicker(1 * time.Second)
	defer ticker.Stop()

	for {
		select {
		case <-ticker.C:
			if err := fetchAndSaveData(); err != nil {
				log.Println("Erro ao coletar e salvar dados:", err)
			}
		}
	}
}

func main() {
	log.Println("Iniciando o servidor na porta 8080...")
	go startDataCollection() // Inicia a coleta de dados em uma goroutine
	http.HandleFunc("/fetchdata", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintln(w, "Coleta de dados em andamento...")
	})
	log.Fatal(http.ListenAndServe(":8080", nil))
}
