-- Cria o banco de dados se ele não existir
CREATE DATABASE IF NOT EXISTS my_database;

-- Usa o banco de dados criado
USE my_database;

-- Cria a tabela 'sensor_data' para armazenar dados de temperatura e umidade
CREATE TABLE IF NOT EXISTS sensor_data (
    id BIGINT AUTO_INCREMENT,
    temperatura FLOAT NOT NULL,
    umidade FLOAT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
);
