-- ============================================================
-- Mapa de Calor Jornalístico — Schema do Supabase
-- Projeto: egdbiqfqmkrtmtzwldki (mapadecalor)
-- ============================================================

-- ------------------------------------------------------------
-- eventos: registro consolidado de cada fato reportado
-- ------------------------------------------------------------
CREATE TABLE public.eventos (
  id                     uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  event_key              text,               -- chave de deduplicação (categoria+local+janela)
  janela_inicio          timestamptz,        -- início da janela horária de agregação

  texto_original         text,
  texto_normalizado      text,
  ultimo_texto           text,

  categoria              text,               -- tiroteio | alagamento | acidente | seguranca | falta_luz | transito | incendio | chuva | outro
  editoria               text,
  confianca              double precision,
  urgencia               integer,
  peso                   integer,
  score                  integer DEFAULT 0,
  quantidade             integer DEFAULT 1,  -- nº de relatos confirmando o mesmo evento
  resumo_objetivo        text,

  pais                   text,
  uf                     text,
  uf_nome                text,
  municipio              text,
  municipio_slug         text,
  bairro                 text,
  bairro_slug            text,
  zona                   text,
  regiao_local           text,
  nivel_localizacao      text,               -- bairro | municipio | uf
  localizacao_identificada boolean DEFAULT false,
  localizacao_confianca  double precision,
  geocodificado_por      text,
  latitude               double precision,
  longitude              double precision,

  ibge_resolvido         boolean DEFAULT false,
  ibge_uf_consultada     text,
  codigo_ibge            text,
  municipio_ibge         text,

  alerta_enviado         boolean NOT NULL DEFAULT false,

  origem                 text,               -- ex: whatsapp_evolution
  remote_jid             text,
  numero                 text,
  push_name              text,
  message_id             text,
  instance               text,
  ultimo_numero          text,
  ultimo_message_id      text,

  criado_em              timestamptz DEFAULT now(),
  atualizado_em          timestamptz DEFAULT now()
);

-- ------------------------------------------------------------
-- eventos_pendentes: reservado para relatos sem localização
-- identificada, aguardando complemento do usuário.
-- (estrutura existente, ainda não conectada ao fluxo ativo)
-- ------------------------------------------------------------
CREATE TABLE public.eventos_pendentes (
  id                bigserial PRIMARY KEY,
  remote_jid        text,
  numero            text,
  instance          text,
  texto_original    text,
  categoria         text,
  editoria          text,
  confianca         double precision,
  urgencia          integer,
  peso              integer,
  score             integer,
  resumo_objetivo   text,
  origem            text,
  message_id        text,
  push_name         text,
  status            text DEFAULT 'aguardando_localizacao',
  bairro            text,
  municipio         text,
  uf                text,
  pais              text DEFAULT 'Brasil',
  lat               double precision,
  lng               double precision,
  geo_raw           text,
  geo_nivel         text,
  criado_em         timestamptz
);

-- ------------------------------------------------------------
-- categorias_evento: metadados de cada categoria (peso, urgência,
-- confiança, ordem de prioridade na checagem de termos)
-- ------------------------------------------------------------
CREATE TABLE public.categorias_evento (
  categoria   text PRIMARY KEY,
  editoria    text NOT NULL,
  peso        int NOT NULL,
  confianca   numeric NOT NULL,
  urgencia    int NOT NULL,
  ordem       int NOT NULL,
  ativo       boolean NOT NULL DEFAULT true
);

-- ------------------------------------------------------------
-- termos_categoria: dicionário de sinônimos/gírias por categoria.
-- tipo 'raiz'  -> substring (pega conjugações: alag -> alagou/alagamento)
-- tipo 'frase' -> match de frase inteira com fronteira de palavra
-- ------------------------------------------------------------
CREATE TABLE public.termos_categoria (
  id        bigserial PRIMARY KEY,
  categoria text NOT NULL REFERENCES categorias_evento(categoria) ON DELETE CASCADE,
  termo     text NOT NULL,
  tipo      text NOT NULL CHECK (tipo IN ('raiz', 'frase')),
  ativo     boolean NOT NULL DEFAULT true,
  UNIQUE(categoria, termo)
);

CREATE INDEX idx_termos_categoria_categoria ON termos_categoria(categoria);

-- ============================================================
-- ATENÇÃO — SEGURANÇA (RLS)
-- Nas tabelas `categorias_evento` e `termos_categoria`, o Row
-- Level Security está DESABILITADO. Isso significa que, se a
-- chave `anon` do Supabase for exposta publicamente, qualquer
-- pessoa pode ler ou modificar essas tabelas.
--
-- Antes de habilitar RLS, crie políticas de acesso adequadas
-- (senão o acesso via chave anon/authenticated é bloqueado por
-- completo). Exemplo mínimo de política de leitura pública:
--
--   ALTER TABLE public.categorias_evento ENABLE ROW LEVEL SECURITY;
--   ALTER TABLE public.termos_categoria ENABLE ROW LEVEL SECURITY;
--
--   CREATE POLICY "leitura publica" ON public.categorias_evento
--     FOR SELECT USING (true);
--   CREATE POLICY "leitura publica" ON public.termos_categoria
--     FOR SELECT USING (true);
--
-- A tabela `eventos` já está com RLS habilitado.
-- ============================================================
