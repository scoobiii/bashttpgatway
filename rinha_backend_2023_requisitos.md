# Requisitos e Regras da Rinha de Backend 2023 Q3

Extraído de: https://github.com/zanfranceschi/rinha-de-backend-2023-q3/blob/main/INSTRUCOES.md

## Resumo

- **Objetivo:** Criar uma API REST para um CRUD de "pessoas" (sem Update/Delete).
- **Bancos de Dados Permitidos:** Postgres, MySQL, ou MongoDB.
- **Deployment:** Docker Compose com limites de 1.5 CPU e 3GB de memória.
- **Ferramenta de Teste:** Gatling.
- **Critério de Vitória (Simplificado):** Maior número de registros no banco após teste de stress.
- **Prazo de Submissão:** 22/08/2023.

## Endpoints Obrigatórios

### 1. `POST /pessoas`

- **Função:** Criar um recurso pessoa.
- **Request Body (JSON):**
    - `apelido`: String (obrigatório, único, max 32 chars)
    - `nome`: String (obrigatório, max 100 chars)
    - `nascimento`: String (obrigatório, formato AAAA-MM-DD)
    - `stack`: Array de Strings (opcional, cada string max 32 chars)
- **Response (Sucesso):**
    - Status Code: `201 Created`
    - Header: `Location: /pessoas/:id` (onde `:id` é o UUID da pessoa criada)
    - Body: Conteúdo a critério do participante.
- **Response (Erro - Dados Inválidos):**
    - Status Code: `422 Unprocessable Entity` (Ex: `apelido` duplicado, campos obrigatórios nulos)
    - Body: Conteúdo a critério do participante.
- **Response (Erro - Sintaxe Inválida):**
    - Status Code: `400 Bad Request` (Ex: tipos de dados incorretos)
    - Body: Conteúdo a critério do participante.

### 2. `GET /pessoas/:id`

- **Função:** Consultar um recurso pessoa pelo ID.
- **Parâmetro URL:** `:id` (UUID)
- **Response (Sucesso):**
    - Status Code: `200 OK`
    - Body (JSON): `{ "id": "...", "apelido": "...", "nome": "...", "nascimento": "...", "stack": [...] }`
- **Response (Erro - Não Encontrado):**
    - Status Code: `404 Not Found`

### 3. `GET /pessoas?t=[:termo]`

- **Função:** Buscar pessoas por termo.
- **Query Parameter:** `t` (termo de busca)
- **Lógica de Busca:** O termo deve ser buscado nos campos `apelido`, `nome` e nos elementos do array `stack`.
- **Response:**
    - Status Code: `200 OK`
    - Body (JSON): Array com os primeiros 50 registros encontrados que satisfaçam o termo. Retorna array vazio `[]` se nada for encontrado.

### 4. `GET /contagem-pessoas`

- **Função:** Contar o número total de pessoas cadastradas.
- **Response:**
    - Status Code: `200 OK`
    - Body: Plain text com o número total de registros.

## Detalhes Adicionais

- O ID da pessoa (`:id`) deve ser um UUID (versão a critério do participante).
- A busca em `GET /pessoas?t=...` não precisa ser paginada, apenas limitada aos 50 primeiros resultados.
- Os detalhes específicos do teste de stress (scripts Gatling) estão disponíveis no repositório.
