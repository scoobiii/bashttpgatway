# Otimizações de Fabio Akita - Rinha de Backend 2023

Fonte: https://www.akitaonrails.com/2023/09/20/akitando-145-16-linguagens-em-16-dias-minha-saga-da-rinha-de-backend

## Resumo do Artigo/Vídeo

A Rinha de Backend que aconteceu em Agosto de 2023 foi muito divertida. Eu só fiquei sabendo quando acabou, mas não quer dizer que não pude me divertir. Hoje quero resumir tudo que eu fiz nos 16 dias seguintes do evento, detalhes sobre os projetos dos participantes, a controvérsia do Ranking de Linguagens, quais os truques por trás dos vencedores, e como você também poderia ser um vencedor!

Finalmente vou demonstrar o que significa "ser promíscuo" com linguagens de programação. Vamos entender porque como de fato ler um ranking. E como podemos fazer TODO MUNDO alcançar o primeiro lugar do Rust!

## Conteúdo (Índice)

*   00:00:00 - Intro
*   00:01:41 - CAP 01 - As Regras - Requerimentos da Rinha
*   00:09:46 - CAP 02 - Os Participantes - Vencedores da Rinha
*   00:15:25 - CAP 03 - Dia 1: Entrando na Rinha - Minha versão em Ruby on Rails
*   00:21:08 - CAP 04 - MrPowerGamerBR entra em cena - A chegada dos Piratas!
*   00:27:55 - CAP 05 - Tentando com Crystal - Aprendendo Lucky Framework
*   00:34:01 - CAP 06 - Dia 8: Gerenciando Baratie - Fluxo de Restaurante
*   00:38:37 - CAP 07 - Consertando Meu Rails - Aprendendo com Erros
*   00:42:54 - CAP 08 - Aprendendo com Node.js - Muita Refatoração
*   00:49:48 - CAP 09 - Apanhando de Erlang - Segredos de Elixir
*   00:55:51 - CAP 10 - Explorando Go Lang - Essa foi fácil
*   00:57:31 - CAP 11 - Dando Moral pra NATS - C# Vencedor
*   00:58:15 - CAP 12 - Dia 12: Explorando PHP Moderno - De Node a Swoole
*   01:00:12 - CAP 13 - Elevando Python - Pequeno Erro
*   01:02:21 - CAP 14 - "foi lá, E FEZ" - A Saga de Lean4
*   01:06:28 - CAP 15 - Pré-Feriado: Tentando NIM - A decepção
*   01:08:47 - CAP 16 - Diário de Bordo: Resumo - Chegando na Grand Line
*   01:13:05 - CAP 17 - Feriadão! - Encontrando o One Piece??
*   01:19:16 - CAP 18 - Testando o One Piece! Todos ao Primeiro Lugar!
*   01:27:16 - CAP 19 - Conclusão: Por que todo mundo não usa Rust?? - Escala de Mercados
*   01:37:33 - Bloopers

## Links Relevantes

*   Repo Oficial da Rinha: https://github.com/zanfranceschi/rinha-de-backend-2023-q3/tree/main
*   MrPowerGamerBR: # Os Resultados da RINHA DE BACKEND estão ERRADOS, e eu posso provar https://www.youtube.com/watch?v=XqYdhlkRlus
*   Raciocínio Automatizado com Leonardo de Moura, Pesquisador na Microsoft Research https://dev.to/elixir_utfpr/raciocinio-automatizado-com-leonardo-de-moura-pesquisador-na-microsoft-research-4d1k
*   Rinha versão Algebraic https://github.com/meoowers/rinha Repositórios da Sofia https://github.com/algebraic-sofia?tab=repositories

## Tweets e Discussões Técnicas (Potenciais Otimizações)

*   **Diminuir workers do Nginx:** Melhora uso no lado do Postgres (Tweet Leandro: https://x.com/leandronsp/status/1696292520106299417?s=20)
*   **Batch Insert:** Técnica de otimização (Tweet Akita: https://x.com/AkitaOnRails/status/1696255958328938745?s=20)
*   **Diminuir workers e pool (Ruby):** Experimento do Leandro que levou Ruby a quase 30k (Tweet Leandro: https://x.com/leandronsp/status/1696219396316836331?s=20)
*   **Diminuir vazão do Nginx:** Lógica explicada por Leandro (Tweet Leandro: https://twitter.com/leandronsp/status/1699568664859603184)
*   **`network_mode: host`:** Descoberta por Vinicius Ferraz (Tweet Akita: https://twitter.com/AkitaOnRails/status/1700488994323128673)
*   **Zero Knockouts:** Atingido por Reinaldo/Zsantana (Tweet Reinaldo: https://twitter.com/reijsantana/status/1701000310280573287)
*   **Ajustes Gerais Pós-Viagem (Akita):** Várias linguagens atingindo >45k após ajustes (Tweets Akita: https://x.com/AkitaOnRails/status/1701230737922339143?s=20 e seguintes)
*   **Refatoração Rust (Akita):** Análise e refatoração do projeto vencedor (Tweet Akita: https://twitter.com/AkitaOnRails/status/1701816747274260698)

## Pull Requests (Potenciais Otimizações)

*   PR versão Node.js: https://github.com/lukas8219/rinha-be-2023-q3/pull/1
*   PR versão Node.js (network mode): https://github.com/lukas8219/rinha-be-2023-q3/pull/2
*   PR versão Go Lang: https://github.com/luanpontes100/rinha-de-backend-2023-q3-golang/pull/1
*   PR versão Go Lang (network mode): https://github.com/luanpontes100/rinha-de-backend-2023-q3-golang/pull/1
*   PR versão PHP/Swoole: https://github.com/lauroappelt/rinha-de-backend-2023/pull/1
*   PR versão Python/Sanic: https://github.com/iancambrea/rinha-python-sanic/pull/1
*   PR versão de Lean4 (fix Location): https://github.com/meoowers/rinha/pull/1
*   PR versão de Lean4 (fix data): https://github.com/meoowers/rinha/pull/2
*   PR versão V Lang: https://github.com/insalubre/rinha-de-backend-v/pull/1
*   PR versão C++: https://github.com/lucaswilliameufrasio/rinha-backend-cpp/pull/1
*   PR versão Rust (Akita): https://github.com/viniciusfonseca/rinha-backend-rust/pull/3

*(Nota: O conteúdo do artigo original foi truncado na extração anterior. Esta seção será completada após obter o texto completo.)*
