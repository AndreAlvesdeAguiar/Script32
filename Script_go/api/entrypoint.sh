#!/bin/sh

# Aguarda o banco de dados estar pronto
/wait-for db:3306

# Executa a aplicação
go run main.go
