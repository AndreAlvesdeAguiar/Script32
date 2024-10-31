# Usar a imagem oficial do Golang como base
FROM golang:1.16-alpine

WORKDIR /app

# Adicionar pacotes necessários, incluindo tzdata para suporte a fuso horário
RUN apk update && \
    apk add --no-cache libc-dev gcc make tzdata

# Definir a variável de ambiente TZ
ENV TZ="America/Sao_Paulo"

# Copiar o go.mod e go.sum e baixar as dependências
COPY go.mod go.sum ./
RUN go mod download

# Copiar o restante do código
COPY . .

# Compilar o aplicativo
RUN go build -o main .

# Definir o comando padrão
CMD ["./main"]
