-- ref_promo_calendar: calendario publico de promociones de Taco Bueno (fuente: anuncios publicos, armado por el equipo).
-- end_date nulo = fecha de fin desconocida (se asumen 14 dias en mv_gold_promo_performance).
CREATE OR REFRESH MATERIALIZED VIEW ref_promo_calendar
COMMENT 'Calendario de promociones publicas usado para comparar antes, durante y despues.'
AS
SELECT * FROM VALUES
  (1,  '3 for $6',                                DATE'2025-01-22', CAST(NULL AS DATE), 'Value bundle',         '3 FOR|3/6',                                                  'In store', 'Chain'),
  (2,  'Free delivery weekend ($20+)',            DATE'2025-02-07', DATE'2025-02-09',   'Delivery',             CAST(NULL AS STRING),                                         'Online',   'Chain'),
  (3,  'Two Can Dine $12.99 (Valentine)',         DATE'2025-02-14', DATE'2025-02-14',   'Value bundle',         'TWO CAN|2 CAN|DINE',                                         'Code',     'Chain'),
  (4,  'Bring on the Brisket',                    DATE'2025-03-10', CAST(NULL AS DATE), 'New product',          'BRISKET',                                                    'In store', 'Chain'),
  (5,  'National Burrito Day free Party Burrito', DATE'2025-04-03', DATE'2025-04-03',   'Free item',            'PARTY BURRITO',                                              'Code',     'Chain'),
  (6,  'Wholotta Value Menu $1.69',               DATE'2025-04-22', CAST(NULL AS DATE), 'Price point',          'PARTY TACO|PARTY BURRITO|PARTY TOSTADA|ROLLUP|PARTY QUESADILLA', 'In store', 'Chain'),
  (7,  '5 for $5 Cinco de Mayo',                  DATE'2025-05-03', DATE'2025-05-05',   'Value bundle',         'PARTY TACO|PARTY BURRITO',                                   'Code',     'Chain'),
  (8,  'Party Tostada $1.69',                     DATE'2025-05-17', CAST(NULL AS DATE), 'Price point',          'TOSTADA',                                                    'In store', 'Chain'),
  (9,  '$6 Party Box',                            DATE'2025-08-15', CAST(NULL AS DATE), 'Value bundle',         'PARTY BOX',                                                  'In store', 'Chain'),
  (10, 'Buy a burrito get another free',          DATE'2025-08-23', CAST(NULL AS DATE), 'BOGO',                 'BURRITO',                                                    'In store', 'Chain'),
  (11, 'Cowboys tickets giveaway (social)',       DATE'2025-09-09', DATE'2025-09-11',   'Marketing (no price)', CAST(NULL AS STRING),                                         'Social',   'DFW'),
  (12, 'Loyalty app launch (free Muchaco)',       DATE'2026-02-01', CAST(NULL AS DATE), 'Loyalty',              'MUCHACO',                                                    'App',      'Chain'),
  (13, 'Bueno Bingo',                             DATE'2026-02-01', DATE'2026-02-28',   'Loyalty game',         CAST(NULL AS STRING),                                         'App',      'App users'),
  (14, 'Fuego line (limited time)',               DATE'2026-03-24', CAST(NULL AS DATE), 'New product',          'FUEGO',                                                      'In store', 'Chain'),
  (15, 'Gold Bowl Sweepstakes',                   DATE'2026-06-05', DATE'2026-07-20',   'Sweepstakes',          'BOWL',                                                       'In store', 'DFW only')
AS t(promo_id, promo_name, start_date, end_date, promo_type, items_keyword, channel, scope);
