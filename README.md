# Mapa de Calor Jornalístico

Sistema de apuração em tempo real que recebe relatos via WhatsApp, classifica o tipo de
ocorrência, geocodifica o local, agrega relatos duplicados, dispara alertas para a redação
e alimenta um painel visual com mapa de calor.

## Arquitetura

```
WhatsApp (Evolution API)
        │  webhook POST
        ▼
┌───────────────────────────────────────────────────────────────────┐
│ n8n — workflow "Mapa de Calor Jornalístico - Salvar Eventos v2"    │
│                                                                     │
│  Webhook → Extrair WhatsApp                                        │
│    → Buscar Termos (Supabase) → Consolidar Termos                  │
│    → Buscar Categorias (Supabase) → Consolidar Config              │
│    → Classificar Evento (usa o dicionário dinâmico)                │
│    → Precisa Geocodificar? ─┬─(sim)→ maps (Nominatim/OSM)          │
│                              └─(não)─┐                              │
│    → Montar Evento Final ←──────────┘                              │
│    → Tem UF? ─┬─(sim)→ IBGE (por estado) → Aplicar Código IBGE     │
│                └─(não)─┐                                            │
│    → Preparar Chave do Evento ←─────┘                              │
│    → Buscar evento existente (Supabase) → Create/Update            │
│    → Avaliar Alerta → Deve Alertar? ─(sim)→ Enviar Alerta WhatsApp │
│    → Decidir Resposta Bot → Responder ao autor do relato           │
└───────────────────────────────────────────────────────────────────┘
        │
        ▼
   Supabase (Postgres) — tabela `eventos`
        │
        ▼  GET /webhook/eventos-painel?horas=&uf=&categorias=
   Painel HTML (painel/index.html) — mapa Leaflet/OpenStreetMap
```

## Componentes

### 1. Ingestão e classificação (n8n)
Recebe mensagens do WhatsApp via Evolution API, extrai o texto e classifica o tipo de
ocorrência usando um **dicionário dinâmico** guardado no Supabase (não hardcoded), o que
permite adicionar gírias/variações novas (`"muita bala"`, `"engarrafado"`, `"alagou"`, etc.)
sem precisar editar o workflow.

### 2. Geocodificação e localização
- **Geocoding**: Nominatim/OpenStreetMap, restrito ao Brasil.
- **Código IBGE**: resolvido dinamicamente por UF (`/estados/{uf}/municipios`), evitando
  buscar a lista nacional inteira (5.570 municípios) a cada mensagem.

### 3. Deduplicação e agregação
Relatos do mesmo fato, no mesmo local, na mesma janela de tempo, são agrupados em um único
evento (`event_key`), incrementando `quantidade` em vez de criar registros duplicados.

### 4. Alertas
Cada categoria tem um limiar de confirmações necessário para disparar alerta (ex: tiroteio
dispara com 1 relato; alagamento/acidente/segurança precisam de 2; trânsito/falta de luz
precisam de 3). O campo `alerta_enviado` evita alertas duplicados para o mesmo evento.

### 5. Painel (`painel/index.html`)
Dashboard standalone (HTML/CSS/JS puro, sem build) com:
- Mapa Leaflet + tiles do OpenStreetMap, pontos coloridos por categoria, tooltip/popup com
  detalhes do relato.
- Filtros de janela de tempo (1h/6h/24h/72h), UF e categoria.
- Lista de eventos clicável (aproxima o mapa no evento selecionado).
- Atualização automática configurável (15s/30s/1min/5min) com contador regressivo visível
  e destaque para eventos novos desde a última busca.
- Consome o endpoint `GET /webhook/eventos-painel` servido pelo Worker publicado no Cloudflare.

## Banco de dados (Supabase)

Ver [`docs/schema.sql`](docs/schema.sql) para a estrutura completa e
[`docs/dicionario_seed.sql`](docs/dicionario_seed.sql) para popular o dicionário de
classificação.

| Tabela | Uso |
|---|---|
| `eventos` | Registro consolidado de cada fato (fonte de dados do painel) |
| `eventos_pendentes` | Reservada para relatos sem localização identificada (ainda não conectada ao fluxo ativo) |
| `categorias_evento` | Metadados de cada categoria (peso, urgência, confiança, ordem de prioridade) |
| `termos_categoria` | Dicionário de termos/sinônimos/gírias que classificam cada relato |

### ⚠️ Atenção de segurança pendente
As tabelas `categorias_evento` e `termos_categoria` estão com **Row Level Security (RLS)
desabilitado** — se a chave `anon` do projeto for exposta, qualquer pessoa pode ler ou
alterar essas tabelas. Ver instruções de remediação no final de `docs/schema.sql`.

O endpoint público `eventos-painel` não exige autenticação; ele já **não expõe** número de
telefone, nome do WhatsApp ou outros dados pessoais dos autores dos relatos — apenas dados
agregados do evento. Se o painel for divulgado amplamente, considere adicionar um token de
acesso simples ao endpoint.

## Como rodar o painel localmente

```bash
# Basta abrir o arquivo no navegador — não tem build nem dependências
open painel/index.html
```

O painel usa a própria origem publicada no Cloudflare, com a rota `/webhook/eventos-painel` servida pelo Worker.
## Deploy no Cloudflare Workers

Este repositório já vem preparado para publicação com `wrangler`.

```bash
wrangler login
wrangler deploy
```

O Worker serve os arquivos estáticos da pasta `painel/`, então o `painel/index.html`
abre direto na raiz do site publicado.