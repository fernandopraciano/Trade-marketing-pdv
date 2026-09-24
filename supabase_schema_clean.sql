-- ============================================================================
-- TVLAR TRADE MARKETING PDV — ESQUEMA COMPLETO E 100% IDEMPOTENTE (SEM ERROS)
-- Pode ser executado repetidamente sem gerar nenhum erro (tipo 42710, etc.)
-- ============================================================================

-- 1. CRIAÇÃO SEGURA DE TIPOS ENUM (Nunca dá erro 42710 se já existirem)
DO $$ BEGIN
    CREATE TYPE tipo_visita_enum AS ENUM ('PROPRIA', 'CONCORRENTE');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE sync_status_enum AS ENUM ('PENDENTE', 'ENVIADO', 'FALHOU');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE material_pdv_enum AS ENUM ('SIM', 'PARCIAL', 'NAO');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE movimento_enum AS ENUM ('BAIXO', 'MEDIO', 'ALTO');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;


-- ============================================================================
-- 2. TABELA DE VISITAS (Estrutura Completa + Blocos 69 Perguntas + SKUs)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.visitas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tipo_visita TEXT NOT NULL DEFAULT 'PROPRIA',
    promotor_email TEXT,
    promotor_nome TEXT,
    promotor_id TEXT,
    user_id UUID,
    nome_loja TEXT,
    loja_id TEXT,
    data_visita DATE DEFAULT CURRENT_DATE,
    data_hora_inicio TIMESTAMPTZ DEFAULT NOW(),
    data_hora_fim TIMESTAMPTZ,
    duracao TEXT,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    status_sincronizacao TEXT DEFAULT 'ENVIADO',
    current_step INTEGER DEFAULT 1,
    is_draft BOOLEAN DEFAULT FALSE,
    alerta_gestor BOOLEAN DEFAULT FALSE,
    observacoes TEXT,
    organizacao_nota INTEGER,
    bloco1_fachada JSONB DEFAULT '{}',
    bloco2_marketing JSONB DEFAULT '{}',
    bloco3_predial JSONB DEFAULT '{}',
    benchmark_produtos JSONB DEFAULT '[]',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Garante que todas as colunas existam mesmo se a tabela foi criada antes
ALTER TABLE public.visitas
    ADD COLUMN IF NOT EXISTS tipo_visita TEXT DEFAULT 'PROPRIA',
    ADD COLUMN IF NOT EXISTS promotor_email TEXT,
    ADD COLUMN IF NOT EXISTS promotor_nome TEXT,
    ADD COLUMN IF NOT EXISTS promotor_id TEXT,
    ADD COLUMN IF NOT EXISTS user_id UUID,
    ADD COLUMN IF NOT EXISTS nome_loja TEXT,
    ADD COLUMN IF NOT EXISTS loja_id TEXT,
    ADD COLUMN IF NOT EXISTS data_visita DATE DEFAULT CURRENT_DATE,
    ADD COLUMN IF NOT EXISTS data_hora_inicio TIMESTAMPTZ DEFAULT NOW(),
    ADD COLUMN IF NOT EXISTS data_hora_fim TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS duracao TEXT,
    ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION,
    ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION,
    ADD COLUMN IF NOT EXISTS status_sincronizacao TEXT DEFAULT 'ENVIADO',
    ADD COLUMN IF NOT EXISTS current_step INTEGER DEFAULT 1,
    ADD COLUMN IF NOT EXISTS is_draft BOOLEAN DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS alerta_gestor BOOLEAN DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS observacoes TEXT,
    ADD COLUMN IF NOT EXISTS organizacao_nota INTEGER,
    ADD COLUMN IF NOT EXISTS bloco1_fachada JSONB DEFAULT '{}',
    ADD COLUMN IF NOT EXISTS bloco2_marketing JSONB DEFAULT '{}',
    ADD COLUMN IF NOT EXISTS bloco3_predial JSONB DEFAULT '{}',
    ADD COLUMN IF NOT EXISTS benchmark_produtos JSONB DEFAULT '[]',
    ADD COLUMN IF NOT EXISTS pilhas_promocionais BOOLEAN,
    ADD COLUMN IF NOT EXISTS codigos_produtos_promo JSONB,
    ADD COLUMN IF NOT EXISTS climatizacao BOOLEAN,
    ADD COLUMN IF NOT EXISTS climatizacao_obs TEXT,
    ADD COLUMN IF NOT EXISTS encarte_disponivel BOOLEAN,
    ADD COLUMN IF NOT EXISTS produtos_indisponiveis JSONB,
    ADD COLUMN IF NOT EXISTS pontos_extras BOOLEAN,
    ADD COLUMN IF NOT EXISTS pontos_extras_foto_url TEXT,
    ADD COLUMN IF NOT EXISTS materiais_pdv TEXT,
    ADD COLUMN IF NOT EXISTS materiais_pdv_obs TEXT,
    ADD COLUMN IF NOT EXISTS precificacao_correta BOOLEAN,
    ADD COLUMN IF NOT EXISTS precificacao_divergencias TEXT,
    ADD COLUMN IF NOT EXISTS concorrencia_na_loja BOOLEAN,
    ADD COLUMN IF NOT EXISTS concorrencia_descricao TEXT,
    ADD COLUMN IF NOT EXISTS ruptura_estoque BOOLEAN,
    ADD COLUMN IF NOT EXISTS ruptura_produtos JSONB,
    ADD COLUMN IF NOT EXISTS exposicao_pontas_gondola BOOLEAN,
    ADD COLUMN IF NOT EXISTS exposicao_foto_url TEXT,
    ADD COLUMN IF NOT EXISTS categorias_destaque JSONB,
    ADD COLUMN IF NOT EXISTS encarte_ativo_concorrente BOOLEAN,
    ADD COLUMN IF NOT EXISTS produtos_promo_concorrente JSONB,
    ADD COLUMN IF NOT EXISTS oferta_ancora TEXT,
    ADD COLUMN IF NOT EXISTS precos_comparativos JSONB,
    ADD COLUMN IF NOT EXISTS climatizacao_concorrente BOOLEAN,
    ADD COLUMN IF NOT EXISTS movimento_clientes TEXT,
    ADD COLUMN IF NOT EXISTS promotor_presente BOOLEAN,
    ADD COLUMN IF NOT EXISTS aprendizado_acao TEXT,
    ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW(),
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();


-- ============================================================================
-- 3. TABELA DE LOJAS (Rede TVLar & Concorrentes)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.lojas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nome TEXT NOT NULL,
    tipo TEXT NOT NULL DEFAULT 'PROPRIA', -- 'PROPRIA' ou 'CONCORRENTE'
    endereco TEXT,
    cidade TEXT DEFAULT 'Manaus',
    estado TEXT DEFAULT 'AM',
    ativo BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.lojas
    ADD COLUMN IF NOT EXISTS nome TEXT,
    ADD COLUMN IF NOT EXISTS tipo TEXT DEFAULT 'PROPRIA',
    ADD COLUMN IF NOT EXISTS endereco TEXT,
    ADD COLUMN IF NOT EXISTS cidade TEXT DEFAULT 'Manaus',
    ADD COLUMN IF NOT EXISTS estado TEXT DEFAULT 'AM',
    ADD COLUMN IF NOT EXISTS ativo BOOLEAN DEFAULT TRUE,
    ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW();


-- ============================================================================
-- 4. TABELA DE PRODUTOS DE REFERÊNCIA (Catálogo de SKUs)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.produtos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nome TEXT NOT NULL,
    codigo TEXT,
    categoria TEXT,
    preco_referencia NUMERIC(10,2),
    is_top10 BOOLEAN DEFAULT FALSE,
    ativo BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.produtos
    ADD COLUMN IF NOT EXISTS nome TEXT,
    ADD COLUMN IF NOT EXISTS codigo TEXT,
    ADD COLUMN IF NOT EXISTS categoria TEXT,
    ADD COLUMN IF NOT EXISTS preco_referencia NUMERIC(10,2),
    ADD COLUMN IF NOT EXISTS is_top10 BOOLEAN DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS ativo BOOLEAN DEFAULT TRUE,
    ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW();


-- ============================================================================
-- 5. REGRAS DE SEGURANÇA (RLS) — 100% LIBERADAS PARA A EQUIPE TVLAR
-- ============================================================================
-- Ativa RLS nas tabelas
ALTER TABLE public.visitas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lojas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.produtos ENABLE ROW LEVEL SECURITY;

-- Remove políticas antigas se existirem para evitar conflitos
DROP POLICY IF EXISTS "Permissao total visitas para todos" ON public.visitas;
DROP POLICY IF EXISTS "Permitir leitura para todos" ON public.visitas;
DROP POLICY IF EXISTS "Permitir insercao para todos" ON public.visitas;
DROP POLICY IF EXISTS "Permitir atualizacao para todos" ON public.visitas;
DROP POLICY IF EXISTS "Permitir exclusao para todos" ON public.visitas;

DROP POLICY IF EXISTS "Permissao total lojas para todos" ON public.lojas;
DROP POLICY IF EXISTS "Permitir leitura lojas para todos" ON public.lojas;
DROP POLICY IF EXISTS "Permitir insercao lojas para todos" ON public.lojas;
DROP POLICY IF EXISTS "Permitir atualizacao lojas para todos" ON public.lojas;

DROP POLICY IF EXISTS "Permissao total produtos para todos" ON public.produtos;
DROP POLICY IF EXISTS "Permitir leitura produtos para todos" ON public.produtos;
DROP POLICY IF EXISTS "Permitir insercao produtos para todos" ON public.produtos;

-- Cria políticas unificadas (SELECT, INSERT, UPDATE, DELETE)
CREATE POLICY "Permissao total visitas para todos"
    ON public.visitas
    FOR ALL
    USING (true)
    WITH CHECK (true);

CREATE POLICY "Permissao total lojas para todos"
    ON public.lojas
    FOR ALL
    USING (true)
    WITH CHECK (true);

CREATE POLICY "Permissao total produtos para todos"
    ON public.produtos
    FOR ALL
    USING (true)
    WITH CHECK (true);


-- ============================================================================
-- 6. PERMISSÕES DE ACESSO (Roles Anon, Authenticated e Service Role)
-- ============================================================================
GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;

GRANT ALL ON TABLE public.visitas TO anon, authenticated, service_role;
GRANT ALL ON TABLE public.lojas TO anon, authenticated, service_role;
GRANT ALL ON TABLE public.produtos TO anon, authenticated, service_role;

GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated, service_role;


-- ============================================================================
-- 7. DADOS INICIAIS DA REDE TVLAR (Opcional - só insere se não existirem)
-- ============================================================================
INSERT INTO public.lojas (nome, tipo, endereco, cidade, estado)
SELECT 'TVLar Matriz (Centro)', 'PROPRIA', 'Rua Marechal Deodoro, 220', 'Manaus', 'AM'
WHERE NOT EXISTS (SELECT 1 FROM public.lojas WHERE nome = 'TVLar Matriz (Centro)');

INSERT INTO public.lojas (nome, tipo, endereco, cidade, estado)
SELECT 'TVLar Manauara Shopping', 'PROPRIA', 'Av. Mário Ypiranga, 1300', 'Manaus', 'AM'
WHERE NOT EXISTS (SELECT 1 FROM public.lojas WHERE nome = 'TVLar Manauara Shopping');

INSERT INTO public.lojas (nome, tipo, endereco, cidade, estado)
SELECT 'TVLar Grande Circular', 'PROPRIA', 'Av. Autaz Mirim, 6100', 'Manaus', 'AM'
WHERE NOT EXISTS (SELECT 1 FROM public.lojas WHERE nome = 'TVLar Grande Circular');

INSERT INTO public.lojas (nome, tipo, endereco, cidade, estado)
SELECT 'Bemol Shopping Amazonas', 'CONCORRENTE', 'Av. Djalma Batista, 482', 'Manaus', 'AM'
WHERE NOT EXISTS (SELECT 1 FROM public.lojas WHERE nome = 'Bemol Shopping Amazonas');

INSERT INTO public.lojas (nome, tipo, endereco, cidade, estado)
SELECT 'Info Store Centro', 'CONCORRENTE', 'Rua Henrique Martins, 321', 'Manaus', 'AM'
WHERE NOT EXISTS (SELECT 1 FROM public.lojas WHERE nome = 'Info Store Centro');

SELECT '✅ Script executado com 100% de sucesso! Banco TVLar PDV pronto e sem erros.' AS status;
