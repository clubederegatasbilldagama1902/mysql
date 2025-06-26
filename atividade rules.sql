------------------------------- >>> MÓDULO 1<<< -------------------------------

-- # QUESTÃO 1

CREATE RULE atualiza_data_ultimo_contato AS
ON INSERT TO interacoes_crm
DO ALSO
UPDATE clientes_crm
SET data_ultimo_contato = NEW.data_interacao
WHERE id_cliente = NEW.id_cliente;

-- # QUESTÃO 2

CREATE RULE log_mudanca_status_lead AS
ON UPDATE TO clientes_crm
WHERE OLD.status_lead IS DISTINCT FROM NEW.status_lead
DO ALSO
INSERT INTO log_alteracao_status_lead (
    id_cliente, status_anterior, status_novo, alterado_por, motivo_alteracao
) VALUES (
    OLD.id_cliente, OLD.status_lead, NEW.status_lead, current_user, 'Mudança automática via RULE'
);

-- # QUESTÃO 3

CREATE RULE previne_downgrade_qualificado AS
ON UPDATE TO clientes_crm
WHERE OLD.status_lead = 'QUALIFICADO'
  AND NEW.status_lead IN ('NOVO', 'CONTATADO')
DO INSTEAD NOTHING;

-- # QUESTÃO 4

CREATE VIEW vw_leads_ativos_campanha AS
SELECT c.nome_campanha, cl.nome_completo, cl.email, cl.status_lead
FROM campanhas_mkt c
JOIN leads_por_campanha l ON c.id_campanha = l.id_campanha
JOIN clientes_crm cl ON l.id_cliente_crm = cl.id_cliente
WHERE cl.status_lead NOT IN ('PERDIDO', 'GANHO');

CREATE RULE delete_vw_leads_ativos_campanha AS
ON DELETE TO vw_leads_ativos_campanha
DO INSTEAD (
    UPDATE clientes_crm
    SET status_lead = 'ARQUIVADO_MARKETING'
    WHERE email = OLD.email;

    INSERT INTO log_alteracao_status_lead (
        id_cliente, status_anterior, status_novo, alterado_por, motivo_alteracao
    )
    VALUES (
        (SELECT id_cliente FROM clientes_crm WHERE email = OLD.email),
        OLD.status_lead, 'ARQUIVADO_MARKETING', current_user, 'ARQUIVADO_VIA_VIEW_MKT'
    );
);

------------------------------- >>> MÓDULO 2 <<< -------------------------------

-- # QUESTÃO 5

CREATE RULE insert_produto_calc_preco AS
ON INSERT TO produtos
WHERE NEW.preco_venda_base IS NULL
DO INSTEAD
INSERT INTO produtos (
    sku, nome_produto, descricao, id_categoria, preco_custo, preco_venda_base, estoque_disponivel, ativo_para_venda
) VALUES (
    NEW.sku, NEW.nome_produto, NEW.descricao, NEW.id_categoria, NEW.preco_custo,
    NEW.preco_custo * (1 + (SELECT margem_lucro_padrao FROM categorias_produto WHERE id_categoria = NEW.id_categoria)),
    COALESCE(NEW.estoque_disponivel, 0),
    COALESCE(NEW.ativo_para_venda, TRUE)
);

-- # QUESTÃO 6

CREATE RULE log_alteracao_preco_venda AS
ON UPDATE TO produtos
WHERE OLD.preco_venda_base IS DISTINCT FROM NEW.preco_venda_base
DO ALSO
INSERT INTO historico_precos_venda (
    id_produto, preco_venda_anterior, preco_venda_novo, motivo_alteracao
) VALUES (
    OLD.id_produto, OLD.preco_venda_base, NEW.preco_venda_base, 'ATUALIZACAO_MANUAL'
);

-- # QUESTÃO 7

CREATE RULE desativa_produto_estoque_zero AS
ON UPDATE TO produtos
WHERE NEW.estoque_disponivel = 0 AND OLD.ativo_para_venda = TRUE
DO ALSO
UPDATE produtos
SET ativo_para_venda = FALSE
WHERE id_produto = NEW.id_produto;

-- # QUESTÃO 8

CREATE VIEW vw_produtos_em_promocao AS
SELECT p.id_produto, p.nome_produto, p.preco_venda_base
FROM produtos p
JOIN promocoes pr ON p.id_produto = pr.id_produto_especifico
WHERE pr.ativa = TRUE
  AND CURRENT_DATE BETWEEN pr.data_inicio_promo AND COALESCE(pr.data_fim_promo, CURRENT_DATE);

CREATE RULE delete_vw_produtos_em_promocao AS
ON DELETE TO vw_produtos_em_promocao
DO INSTEAD
UPDATE promocoes
SET ativa = FALSE
WHERE id_produto_especifico = OLD.id_produto
  AND ativa = TRUE;

------------------------------- >>> MÓDULO 3 <<< -------------------------------

-- # QUESTÃO 9

CREATE RULE log_mudanca_plano AS
ON UPDATE TO assinaturas
WHERE OLD.id_plano IS DISTINCT FROM NEW.id_plano
DO ALSO
INSERT INTO log_eventos_assinatura (
    id_assinatura, tipo_evento, plano_anterior_id, plano_novo_id
) VALUES (
    OLD.id_assinatura, 'MUDANCA_PLANO', OLD.id_plano, NEW.id_plano
);

-- QUESTÃO 10

CREATE RULE previne_reativacao_assinatura AS
ON UPDATE TO assinaturas
WHERE OLD.status_assinatura = 'CANCELADA_USUARIO' AND NEW.status_assinatura = 'ATIVA'
DO INSTEAD NOTHING;

-- QUESTÃO 11

CREATE RULE atualiza_data_status AS
ON UPDATE TO assinaturas
WHERE OLD.status_assinatura IS DISTINCT FROM NEW.status_assinatura
DO ALSO
UPDATE assinaturas
SET data_status = NOW()
WHERE id_assinatura = NEW.id_assinatura;

-- QUESTÃO 12

CREATE VIEW vw_testes_a_expirar AS
SELECT a.id_assinatura, c.nome_empresa, a.data_proxima_cobranca
FROM assinaturas a
JOIN clientes_saas c ON a.id_cliente_saas = c.id_cliente_saas
WHERE a.status_assinatura = 'TESTE_GRATUITO'
  AND a.data_proxima_cobranca <= CURRENT_DATE + INTERVAL '7 days';

CREATE RULE delete_vw_testes_a_expirar AS
ON DELETE TO vw_testes_a_expirar
DO INSTEAD
INSERT INTO log_eventos_assinatura (
    id_assinatura, tipo_evento
) VALUES (
    OLD.id_assinatura, 'CONTATO_PRE_EXPIRACAO_TESTE'
);
