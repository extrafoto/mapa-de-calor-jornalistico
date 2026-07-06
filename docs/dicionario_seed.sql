-- ============================================================
-- Seed do dicionário de classificação (categorias_evento + termos_categoria)
-- Rodar depois de aplicar schema.sql
-- ============================================================

INSERT INTO categorias_evento (categoria, editoria, peso, confianca, urgencia, ordem) VALUES
  ('tiroteio',   'segurança', 10, 0.90, 5, 1),
  ('alagamento', 'cidade',     9, 0.90, 4, 2),
  ('acidente',   'trânsito',   7, 0.80, 4, 3),
  ('seguranca',  'segurança',  7, 0.80, 4, 4),
  ('falta_luz',  'serviço',    6, 0.75, 3, 5),
  ('transito',   'trânsito',   6, 0.75, 3, 6),
  ('chuva',      'tempo',      4, 0.80, 2, 7)
ON CONFLICT (categoria) DO NOTHING;

INSERT INTO termos_categoria (categoria, termo, tipo) VALUES
  ('tiroteio', 'tiro', 'raiz'),
  ('tiroteio', 'dispar', 'raiz'),
  ('tiroteio', 'fuzil', 'raiz'),
  ('tiroteio', 'balead', 'raiz'),
  ('tiroteio', 'confronto', 'raiz'),
  ('tiroteio', 'muita bala', 'frase'),
  ('tiroteio', 'tem bala', 'frase'),
  ('tiroteio', 'trocando tiro', 'frase'),
  ('tiroteio', 'bala perdida', 'frase'),
  ('tiroteio', 'correria', 'frase'),
  ('tiroteio', 'operacao policial', 'frase'),
  ('tiroteio', 'policia atirando', 'frase'),

  ('alagamento', 'alag', 'raiz'),
  ('alagamento', 'inund', 'raiz'),
  ('alagamento', 'enchent', 'raiz'),
  ('alagamento', 'transbord', 'raiz'),
  ('alagamento', 'agua subiu', 'frase'),
  ('alagamento', 'rua cheia', 'frase'),
  ('alagamento', 'bolsao d agua', 'frase'),
  ('alagamento', 'bolsao de agua', 'frase'),
  ('alagamento', 'rio transbordou', 'frase'),

  ('acidente', 'acident', 'raiz'),
  ('acidente', 'colis', 'raiz'),
  ('acidente', 'capot', 'raiz'),
  ('acidente', 'atropel', 'raiz'),
  ('acidente', 'engavet', 'raiz'),
  ('acidente', 'queda de moto', 'frase'),
  ('acidente', 'bateu o carro', 'frase'),

  ('seguranca', 'assalt', 'raiz'),
  ('seguranca', 'roub', 'raiz'),
  ('seguranca', 'furt', 'raiz'),
  ('seguranca', 'bandid', 'raiz'),
  ('seguranca', 'arrastao', 'frase'),
  ('seguranca', 'ladrao', 'frase'),
  ('seguranca', 'mao na cintura', 'frase'),
  ('seguranca', 'sequestro relampago', 'frase'),

  ('falta_luz', 'apaga', 'raiz'),
  ('falta_luz', 'sem luz', 'frase'),
  ('falta_luz', 'sem energia', 'frase'),
  ('falta_luz', 'falta de energia', 'frase'),
  ('falta_luz', 'queda de energia', 'frase'),
  ('falta_luz', 'energia acabou', 'frase'),
  ('falta_luz', 'luz caiu', 'frase'),
  ('falta_luz', 'luz foi', 'frase'),

  ('transito', 'transit', 'raiz'),
  ('transito', 'engarraf', 'raiz'),
  ('transito', 'congestion', 'raiz'),
  ('transito', 'pista fechada', 'frase'),
  ('transito', 'via interditada', 'frase'),
  ('transito', 'transito parado', 'frase'),
  ('transito', 'retencao no transito', 'frase'),

  ('chuva', 'chuv', 'raiz'),
  ('chuva', 'tempora', 'raiz'),
  ('chuva', 'tempesta', 'raiz'),
  ('chuva', 'ventani', 'raiz'),
  ('chuva', 'muita chuva', 'frase'),
  ('chuva', 'pancada de chuva', 'frase'),
  ('chuva', 'caiu um raio', 'frase')
ON CONFLICT (categoria, termo) DO NOTHING;
