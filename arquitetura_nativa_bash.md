# Proposta de Arquitetura: Bash HTTP Gateway (BHG)

## Objetivo

Propor uma arquitetura para melhorar drasticamente a performance da API Bash da Rinha de Backend, abordando o principal gargalo identificado na análise anterior: o servidor HTTP baseado em `netcat`/`mkfifo` e o modelo de execução por processo.

A meta é alcançar uma performance mais próxima do Top 5, inspirando-se nas soluções nativas (como Lean4), mas mantendo a lógica de negócio principal nos scripts Bash existentes, conforme o espírito do desafio original.

## Arquitetura Proposta: Híbrida com Gateway Nativo

A solução proposta é um **Gateway HTTP leve e eficiente**, escrito em uma linguagem compilada (como C ou Go), que atua como a interface de rede principal, delegando a lógica de negócio aos scripts Bash.

```mermaid
graph LR
    Client[Cliente HTTP] -- Requisição --> Nginx;
    Nginx -- Requisição --> BHG[Bash HTTP Gateway (C/Go)];
    BHG -- Invoca Script + Dados (stdin/env) --> BashHandler[handler.bash];
    BashHandler -- Lógica + Consulta --> PgBouncer;
    PgBouncer -- Conexão Pool --> Postgres[PostgreSQL DB];
    Postgres -- Resultado --> PgBouncer;
    PgBouncer -- Resultado --> BashHandler;
    BashHandler -- Resposta HTTP (stdout) --> BHG;
    BHG -- Resposta --> Nginx;
    Nginx -- Resposta --> Client;
```

**Componentes:**

1.  **Nginx:** Mantido como proxy reverso e load balancer (opcionalmente, o BHG poderia escutar diretamente na porta 9999, mas Nginx ainda oferece vantagens como SSL termination, logging centralizado, etc.). Configurado para encaminhar para as instâncias do BHG.
2.  **Bash HTTP Gateway (BHG):**
    *   **Linguagem:** C (com `libevent` ou `epoll` para I/O assíncrono) ou Go (com `net/http` e goroutines). A escolha depende da preferência por controle de baixo nível (C) ou facilidade de desenvolvimento e concorrência (Go).
    *   **Funcionalidade Principal:**
        *   Escuta em uma porta específica (ex: 8081, 8082).
        *   Aceita conexões HTTP concorrentes.
        *   Realiza o parsing mínimo essencial da requisição HTTP (método, URI, versão, headers relevantes como `Content-Length`, `Content-Type`).
        *   Lê o corpo da requisição (request body).
        *   **Invoca o script `handler.bash`** (ou scripts específicos por endpoint, se otimizado).
        *   **Passa os dados da requisição para o Bash:**
            *   Método, URI, Query String, etc., via **variáveis de ambiente** (ex: `REQUEST_METHOD`, `REQUEST_URI`, `QUERY_STRING`, `HTTP_CONTENT_TYPE`, `HTTP_CONTENT_LENGTH`).
            *   Corpo da requisição via **stdin** do processo Bash.
        *   **Captura a saída do Bash:** Lê todo o conteúdo escrito pelo `handler.bash` em seu **stdout**, que deve ser a resposta HTTP completa (incluindo status line, headers e corpo).
        *   Envia a resposta capturada de volta ao cliente HTTP.
    *   **Concorrência:** O BHG gerencia a concorrência eficientemente usando os mecanismos da linguagem escolhida (event loop, threads, goroutines), evitando o modelo de um processo por requisição do `netcat`.
3.  **Scripts Bash (`handler.bash`, `create.bash`, etc.):**
    *   **Modificações Mínimas:** Os scripts precisam ser ligeiramente adaptados para:
        *   Ler os dados da requisição das variáveis de ambiente e do stdin (em vez do parsing manual do `netcat`).
        *   Escrever a resposta HTTP completa (status, headers, body) no stdout.
    *   A lógica de negócio principal e a interação com o banco (via `psql` para PgBouncer) permanecem em Bash.
    *   A otimização de **Batch Insert** implementada anteriormente no `create.bash` continua válida e essencial.
4.  **PgBouncer e PostgreSQL:** Mantidos como na versão otimizada, com tuning adequado de pools e configurações.

## Vantagens

*   **Performance HTTP:** Substitui o `netcat`/`mkfifo` por um servidor HTTP nativo e concorrente, eliminando o maior gargalo.
*   **Redução de Overhead:** Minimiza a criação de processos para cada requisição HTTP.
*   **Manutenção da Lógica Bash:** Preserva a maior parte do código de negócio existente em Bash.
*   **Viabilidade:** Implementar um gateway HTTP simples em C ou Go é uma tarefa bem definida e mais viável do que reescrever toda a lógica ou criar um servidor HTTP complexo em Bash puro.

## Desafios e Considerações

*   **Dependência Externa:** Introduz uma dependência em um componente compilado (C/Go).
*   **Comunicação BHG <-> Bash:** A passagem de dados via variáveis de ambiente e stdin/stdout precisa ser robusta e eficiente. Limites no tamanho de variáveis de ambiente podem ser um problema para headers grandes (improvável na Rinha).
*   **Gerenciamento de Processos Bash:** O BHG precisa decidir como gerenciar os processos Bash invocados (criar um novo a cada vez? manter um pool?). Manter um pool pode ser mais eficiente, mas adiciona complexidade.
*   **Limitação do Bash:** A velocidade de execução da própria lógica em Bash ainda será um fator limitante, mas significativamente menor que o gargalo anterior do servidor HTTP.

## Próximos Passos

Implementar um protótipo do BHG (por exemplo, em Go pela facilidade) e adaptar minimamente o `handler.bash` para interagir com ele. Realizar testes comparativos para validar o ganho de performance.

