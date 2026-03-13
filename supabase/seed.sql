-- ═══════════════════════════════════════════════════════════════════════════════
-- turAventura · Datos de ejemplo
-- Ejecutar en: Supabase Dashboard → SQL Editor
--
-- ⚠️  Este script elimina y recrea los datos de demo.
--     Los usuarios reales NO son afectados (filtra por @demo.com).
--
-- Cuentas demo creadas:
--   patagonia@demo.com      /  Demo1234!   (prestador · Bariloche)
--   andesextreme@demo.com   /  Demo1234!   (prestador · Mendoza)
--   ushuaia@demo.com        /  Demo1234!   (prestador · Ushuaia)
--   nortaventura@demo.com   /  Demo1234!   (prestador · Salta)
--   turista1@demo.com       /  Demo1234!   (turista · Lucía Pérez)
--   turista2@demo.com       /  Demo1234!   (turista · Martín López)
-- ═══════════════════════════════════════════════════════════════════════════════

BEGIN;

-- Habilitar pgcrypto para hashear contraseñas
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ─── 1. Limpiar seed anterior ─────────────────────────────────────────────────
-- reviews y bookings tienen FK hacia profiles SIN CASCADE, hay que borrarlos primero.
-- Después auth.users cascadea: profiles → providers → activities → availability/images.

DELETE FROM public.reviews
  WHERE tourist_id IN (SELECT id FROM auth.users WHERE email LIKE '%@demo.com');

DELETE FROM public.bookings
  WHERE tourist_id IN (SELECT id FROM auth.users WHERE email LIKE '%@demo.com');

DELETE FROM auth.users WHERE email LIKE '%@demo.com';


-- ─── 2. Usuarios en auth.users ────────────────────────────────────────────────
-- El trigger handle_new_user() crea automáticamente el profile con role='tourist'
INSERT INTO auth.users (
  id, instance_id, aud, role, email, encrypted_password,
  email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
  created_at, updated_at,
  confirmation_token, email_change, email_change_token_new, recovery_token,
  is_sso_user, is_anonymous
) VALUES
  -- ── Prestadores ──────────────────────────────────────────────────────────────
  (
    'a0000001-0000-0000-0000-000000000000',
    '00000000-0000-0000-0000-000000000000',
    'authenticated', 'authenticated',
    'patagonia@demo.com',
    crypt('Demo1234!', gen_salt('bf', 10)),
    NOW(), '{"provider":"email","providers":["email"]}'::jsonb,
    '{"full_name":"Carlos Rodríguez"}'::jsonb,
    NOW() - INTERVAL '8 months', NOW(),
    '', '', '', '', FALSE, FALSE
  ),
  (
    'a0000002-0000-0000-0000-000000000000',
    '00000000-0000-0000-0000-000000000000',
    'authenticated', 'authenticated',
    'andesextreme@demo.com',
    crypt('Demo1234!', gen_salt('bf', 10)),
    NOW(), '{"provider":"email","providers":["email"]}'::jsonb,
    '{"full_name":"María González"}'::jsonb,
    NOW() - INTERVAL '6 months', NOW(),
    '', '', '', '', FALSE, FALSE
  ),
  (
    'a0000003-0000-0000-0000-000000000000',
    '00000000-0000-0000-0000-000000000000',
    'authenticated', 'authenticated',
    'ushuaia@demo.com',
    crypt('Demo1234!', gen_salt('bf', 10)),
    NOW(), '{"provider":"email","providers":["email"]}'::jsonb,
    '{"full_name":"Diego Fernández"}'::jsonb,
    NOW() - INTERVAL '5 months', NOW(),
    '', '', '', '', FALSE, FALSE
  ),
  (
    'a0000004-0000-0000-0000-000000000000',
    '00000000-0000-0000-0000-000000000000',
    'authenticated', 'authenticated',
    'nortaventura@demo.com',
    crypt('Demo1234!', gen_salt('bf', 10)),
    NOW(), '{"provider":"email","providers":["email"]}'::jsonb,
    '{"full_name":"Ana Martínez"}'::jsonb,
    NOW() - INTERVAL '3 months', NOW(),
    '', '', '', '', FALSE, FALSE
  ),
  -- ── Turistas ─────────────────────────────────────────────────────────────────
  (
    'b0000001-0000-0000-0000-000000000000',
    '00000000-0000-0000-0000-000000000000',
    'authenticated', 'authenticated',
    'turista1@demo.com',
    crypt('Demo1234!', gen_salt('bf', 10)),
    NOW(), '{"provider":"email","providers":["email"]}'::jsonb,
    '{"full_name":"Lucía Pérez"}'::jsonb,
    NOW() - INTERVAL '2 months', NOW(),
    '', '', '', '', FALSE, FALSE
  ),
  (
    'b0000002-0000-0000-0000-000000000000',
    '00000000-0000-0000-0000-000000000000',
    'authenticated', 'authenticated',
    'turista2@demo.com',
    crypt('Demo1234!', gen_salt('bf', 10)),
    NOW(), '{"provider":"email","providers":["email"]}'::jsonb,
    '{"full_name":"Martín López"}'::jsonb,
    NOW() - INTERVAL '1 month', NOW(),
    '', '', '', '', FALSE, FALSE
  );


-- ─── 3. Actualizar roles de prestadores ──────────────────────────────────────
-- El trigger ya creó los profiles como 'tourist'. Actualizamos los 4 prestadores.
UPDATE public.profiles
SET role = 'provider'
WHERE id IN (
  'a0000001-0000-0000-0000-000000000000',
  'a0000002-0000-0000-0000-000000000000',
  'a0000003-0000-0000-0000-000000000000',
  'a0000004-0000-0000-0000-000000000000'
);


-- ─── 4. Prestadores ───────────────────────────────────────────────────────────
INSERT INTO public.providers (id, user_id, business_name, description, location, verified, rating)
VALUES
  (
    'c0000001-0000-0000-0000-000000000000',
    'a0000001-0000-0000-0000-000000000000',
    'Patagonia Adventures',
    'Guías certificados con 15 años de experiencia en los lagos y montañas de la Patagonia. '
    'Ofrecemos las experiencias más auténticas en el entorno natural de Bariloche y sus '
    'alrededores. Cada salida es única y adaptada al grupo.',
    'Bariloche, Río Negro',
    TRUE, NULL
  ),
  (
    'c0000002-0000-0000-0000-000000000000',
    'a0000002-0000-0000-0000-000000000000',
    'Andes Extreme',
    'Especialistas en deportes extremos en la cordillera mendocina. Instructores certificados '
    'internacionalmente, equipamiento de primera clase y protocolos de seguridad estrictos. '
    'Desde principiantes hasta atletas avanzados.',
    'Mendoza, Mendoza',
    TRUE, NULL
  ),
  (
    'c0000003-0000-0000-0000-000000000000',
    'a0000003-0000-0000-0000-000000000000',
    'Fin del Mundo Tours',
    'Vivimos en el fin del mundo y lo conocemos como nadie. Trekking, ski y experiencias únicas '
    'en Ushuaia y el Parque Nacional Tierra del Fuego. El destino más austral del planeta.',
    'Ushuaia, Tierra del Fuego',
    TRUE, NULL
  ),
  (
    'c0000004-0000-0000-0000-000000000000',
    'a0000004-0000-0000-0000-000000000000',
    'Norte Aventura',
    'Exploramos el noroeste argentino: Jujuy, Salta y la Quebrada de Humahuaca. Cabalgatas, '
    'senderismo y conexión con la cultura andina. Guías bilingües con raíces en la región.',
    'Salta, Salta',
    FALSE, NULL
  );


-- ─── 5. Actividades ───────────────────────────────────────────────────────────
INSERT INTO public.activities (
  id, provider_id, title, description, category,
  difficulty, duration_hours, price_per_person, max_participants,
  min_age, location, latitude, longitude, is_active
) VALUES

  -- ── Patagonia Adventures · Bariloche ─────────────────────────────────────────
  (
    'd0000001-0000-0000-0000-000000000000',
    'c0000001-0000-0000-0000-000000000000',
    'Trekking Circuito Nahuel Huapi',
    'Recorremos los senderos más emblemáticos del Parque Nacional Nahuel Huapi. El recorrido '
    'de 15 km incluye miradores con vistas al lago y la cordillera nevada. Cruzamos bosques de '
    'coihue y lengas, y almorzamos junto a un arroyo de montaña. Apto para personas con '
    'condición física media. Incluye guía certificado, bastones y mochila de hidratación.',
    'trekking', 3, 8, 8500.00, 12, 14,
    'Bariloche, Río Negro', -41.1500, -71.4000, TRUE
  ),
  (
    'd0000002-0000-0000-0000-000000000000',
    'c0000001-0000-0000-0000-000000000000',
    'Kayak en el Brazo Blest',
    'Remamos por el brazo más virgen del lago Nahuel Huapi, rodeados de bosque valdiviano y '
    'cascadas que caen directamente al agua. La excursión incluye traslado en catamarán hasta '
    'el punto de partida, kayak doble, chaleco y guía experto. Terminamos con mate y facturas '
    'frente al lago mientras el sol se pone detrás de la cordillera.',
    'kayak', 2, 4, 12000.00, 8, 10,
    'Bariloche, Río Negro', -41.0700, -71.8000, TRUE
  ),
  (
    'd0000009-0000-0000-0000-000000000000',
    'c0000001-0000-0000-0000-000000000000',
    'Ciclismo de Montaña – Circuito Chico',
    'El Circuito Chico en bicicleta: un clásico de Bariloche con vistas al lago Nahuel Huapi, '
    'el Cerro López y la estepa patagónica. 40 km de recorrido con variantes según nivel. '
    'Pedaleamos por ripio y senderos en tierra rodeados de paisaje único. '
    'Incluye bici de montaña full-suspension, casco, guantes y guía.',
    'ciclismo', 3, 5, 6500.00, 10, 12,
    'Bariloche, Río Negro', -41.1200, -71.3500, TRUE
  ),

  -- ── Andes Extreme · Mendoza ──────────────────────────────────────────────────
  (
    'd0000003-0000-0000-0000-000000000000',
    'c0000002-0000-0000-0000-000000000000',
    'Rafting en el Cañón del Atuel',
    'Las aguas bravas del Río Atuel ofrecen uno de los rafting más emocionantes de Argentina. '
    'Rápidos clase III y IV en un cañón de paredes rojizas de 400 metros de altura. El recorrido '
    'de 12 km termina en una playa de arena blanca. Incluye neoprene completo, casco, chaleco '
    'salvavidas y guía certificado en primeros auxilios de montaña.',
    'rafting', 4, 5, 15000.00, 10, 16,
    'San Rafael, Mendoza', -34.6167, -68.3333, TRUE
  ),
  (
    'd0000004-0000-0000-0000-000000000000',
    'c0000002-0000-0000-0000-000000000000',
    'Escalada en Roca – Cerro Arco',
    'Escalamos el Cerro Arco con vistas panorámicas a la ciudad de Mendoza y la cordillera '
    'nevada al fondo. Rutas de dificultad 5a a 6b para niveles principiante e intermedio. '
    'El lugar más icónico de escalada en Mendoza. Incluye arnés, casco, zapatos de escalada, '
    'cuerdas y guía certificado UIAA. No se requiere experiencia previa.',
    'escalada', 4, 6, 22000.00, 6, 16,
    'Mendoza, Mendoza', -32.8833, -68.8500, TRUE
  ),
  (
    'd0000008-0000-0000-0000-000000000000',
    'c0000002-0000-0000-0000-000000000000',
    'Parapente en el Valle de Uco',
    'Volá sobre los viñedos del Valle de Uco con la cordillera de los Andes como telón de fondo. '
    'Vuelo en tándem con piloto certificado FAI, sin experiencia previa necesaria. Despegamos '
    'desde 2.200 msnm y sobrevolamos malbecs y chardonnays durante 20-30 minutos. '
    'Incluye video y fotos del vuelo, certificado y degustación de vinos al finalizar.',
    'parapente', 2, 2, 20000.00, 4, 14,
    'Tupungato, Mendoza', -33.3667, -69.1333, TRUE
  ),

  -- ── Fin del Mundo Tours · Ushuaia ────────────────────────────────────────────
  (
    'd0000005-0000-0000-0000-000000000000',
    'c0000003-0000-0000-0000-000000000000',
    'Ski y Snowboard en Cerro Castor',
    'El resort de ski más austral del mundo. 26 km de pistas para todos los niveles con vista '
    'directa al Canal Beagle y los picos de Chile al fondo. Nieve garantizada de junio a octubre. '
    'Incluye clase grupal de iniciación, equipo completo (tabla o skis, botas, bastones, casco) '
    'y guía de montaña para el día. Almuerzo en el refugio de montaña incluido.',
    'ski', 3, 8, 18500.00, 15, 8,
    'Ushuaia, Tierra del Fuego', -54.7167, -68.3000, TRUE
  ),
  (
    'd0000006-0000-0000-0000-000000000000',
    'c0000003-0000-0000-0000-000000000000',
    'Trekking Parque Nacional Tierra del Fuego',
    'Caminamos hasta el confín del mundo por los senderos del parque nacional más austral del '
    'planeta. Atravesamos bosque de lenga, lagos espejeados y la costa del Canal Beagle. '
    '12 km de trekking circular con fauna local: castores, cóndores y zorros grises. '
    'El trekking finaliza en la Bahía Lapataia, donde termina la Ruta Nacional 3.',
    'trekking', 2, 6, 9500.00, 14, 10,
    'Ushuaia, Tierra del Fuego', -54.8500, -68.5500, TRUE
  ),
  (
    'd0000010-0000-0000-0000-000000000000',
    'c0000003-0000-0000-0000-000000000000',
    'Trekking al Glaciar Martial',
    'Ascendemos al glaciar Martial con vistas únicas de la ciudad de Ushuaia y el Canal Beagle. '
    'El recorrido de 8 km ida y vuelta atraviesa bosque nativo de lengas y zonas de nieve '
    'permanente. El paisaje cambia cada 100 metros de altitud. '
    'Incluye guía, bastones, crampones de nieve y chocolate caliente en la cima.',
    'trekking', 3, 5, 11000.00, 12, 12,
    'Ushuaia, Tierra del Fuego', -54.7833, -68.3500, TRUE
  ),

  -- ── Norte Aventura · Salta/Jujuy ─────────────────────────────────────────────
  (
    'd0000007-0000-0000-0000-000000000000',
    'c0000004-0000-0000-0000-000000000000',
    'Cabalgata por la Quebrada de Humahuaca',
    'Recorremos a caballo la Quebrada de Humahuaca, Patrimonio de la Humanidad UNESCO. '
    'Pasamos por el Cerro de los Siete Colores, Tilcara, Uquía y Humahuaca. Los caballos son '
    'criollos, mansos y adaptados a la altura. Apto para jinetes sin experiencia. '
    'Incluye almuerzo típico norteño (locro o tamales), guía bilingüe y transfer desde Salta.',
    'cabalgata', 1, 4, 7500.00, 12, 8,
    'Humahuaca, Jujuy', -23.2000, -65.3500, TRUE
  ),

  -- ── Patagonia Adventures · 3 nuevas ──────────────────────────────────────────
  (
    'd0000011-0000-0000-0000-000000000000',
    'c0000001-0000-0000-0000-000000000000',
    'Escalada en Hielo – Cerro Tronador',
    'Una de las experiencias más desafiantes de la Patagonia: escalamos las paredes de hielo '
    'del Cerro Tronador, el volcán dormido más imponente de la región. Usamos crampones, '
    'piolets y cuerdas en un entorno glaciario único. El día incluye traslado al glaciar, '
    'clase técnica de 2 horas y ascenso guiado. Solo para personas en buen estado físico.',
    'escalada', 5, 7, 32000.00, 6, 18,
    'Bariloche, Río Negro', -41.1542, -71.8756, TRUE
  ),
  (
    'd0000012-0000-0000-0000-000000000000',
    'c0000001-0000-0000-0000-000000000000',
    'Rafting en el Río Manso',
    'El Río Manso ofrece un rafting más accesible que otros ríos patagónicos, ideal para '
    'toda la familia. Rápidos clase II y III entre bosques de coihue y paredes de basalto. '
    'El recorrido de 14 km finaliza en el campamento con asado patagónico a orillas del río. '
    'Incluye neoprene, casco, chaleco, pagayas y guía.',
    'rafting', 3, 4, 13500.00, 10, 10,
    'Bariloche, Río Negro', -41.5800, -71.7200, TRUE
  ),
  (
    'd0000013-0000-0000-0000-000000000000',
    'c0000001-0000-0000-0000-000000000000',
    'Trekking Nocturno y Astroturismo',
    'Cuando cae la noche en la Patagonia, el cielo se convierte en protagonista. Caminamos '
    '6 km por senderos iluminados por linternas frontales hasta un mirador sin contaminación '
    'lumínica. Un astrónomo local nos guía por las constelaciones australes, la Vía Láctea '
    'y los objetos del cielo profundo con telescopios. Incluye linterna frontal, mate y '
    'empanadas calientes bajo las estrellas.',
    'trekking', 2, 4, 9500.00, 10, 12,
    'Bariloche, Río Negro', -41.2100, -71.5500, TRUE
  ),

  -- ── Andes Extreme · 3 nuevas ─────────────────────────────────────────────────
  (
    'd0000014-0000-0000-0000-000000000000',
    'c0000002-0000-0000-0000-000000000000',
    'Trekking al Base Camp del Aconcagua',
    'El Aconcagua, el techo de América, nos llama desde la Plaza de Mulas a 4.300 msnm. '
    'Este trekking de 2 días llega al campamento base oficial sin necesidad de equipo de '
    'alta montaña. Atravesamos el Valle de Horcones, morenas glaciarias y escenarios que '
    'quitarán el aliento — literalmente. Incluye mulas para el equipaje, guías UIAA '
    'certificados, carpa 4 estaciones y alimentación completa.',
    'trekking', 5, 8, 38000.00, 8, 18,
    'Mendoza, Mendoza', -32.6532, -70.0110, TRUE
  ),
  (
    'd0000015-0000-0000-0000-000000000000',
    'c0000002-0000-0000-0000-000000000000',
    'Ski y Freeride en Las Leñas',
    'Las Leñas es el resort más glamoroso y técnico de Argentina. Pistas para todos los '
    'niveles, nieve seca garantizada y una vista que no tiene precio. Nuestro paquete incluye '
    'ski pass de día, equipo completo (tablas, botas, bastones, casco), clase magistral con '
    'instructor FIS y traslado desde Mendoza en van privada.',
    'ski', 4, 8, 24000.00, 12, 8,
    'Malargüe, Mendoza', -35.1500, -70.0667, TRUE
  ),
  (
    'd0000016-0000-0000-0000-000000000000',
    'c0000002-0000-0000-0000-000000000000',
    'Buceo en el Dique Potrerillos',
    'Un secreto bien guardado de Mendoza: el Dique Potrerillos esconde bajo sus aguas un '
    'pueblo sumergido cuando se llenó el embalse. Buceamos entre ruinas, árboles petrificados '
    'y cardúmenes de truchas en aguas de montaña. Incluye equipo completo de buceo, traje de '
    'neoprene 5mm, guía de buceo certificado PADI y snacks post-inmersión.',
    'buceo', 2, 3, 18000.00, 6, 14,
    'Potrerillos, Mendoza', -32.9500, -69.2000, TRUE
  ),

  -- ── Fin del Mundo Tours · 3 nuevas ───────────────────────────────────────────
  (
    'd0000017-0000-0000-0000-000000000000',
    'c0000003-0000-0000-0000-000000000000',
    'Kayak en el Canal Beagle',
    'Remamos por el Canal Beagle con vistas a Chile, los glaciares y la colonia de lobos '
    'marinos de la Isla de los Lobos. El kayak doble es la mejor manera de apreciar la '
    'escala colosal de este paisaje antártico. Pasamos cerca del Faro Les Eclaireurs, '
    'símbolo de Ushuaia, y avistamos pingüinos y cormoranes. '
    'Incluye traje seco, kayak, guía y transfer desde el puerto.',
    'kayak', 2, 4, 14000.00, 8, 12,
    'Ushuaia, Tierra del Fuego', -54.8019, -68.3030, TRUE
  ),
  (
    'd0000018-0000-0000-0000-000000000000',
    'c0000003-0000-0000-0000-000000000000',
    'Cabalgata Fin del Mundo',
    'Galopamos por los valles de Tierra del Fuego con el Canal Beagle como horizonte y la '
    'cordillera Darwin nevando al fondo. Los caballos criollos están adaptados al frío y al '
    'terreno irregular. Una experiencia única que combina la majestuosidad del paisaje '
    'fueguino con la tradición gaucha del sur. Incluye mate con tortas fritas al volver.',
    'cabalgata', 1, 3, 12000.00, 10, 8,
    'Ushuaia, Tierra del Fuego', -54.7600, -68.4200, TRUE
  ),
  (
    'd0000019-0000-0000-0000-000000000000',
    'c0000003-0000-0000-0000-000000000000',
    'Buceo en el Canal Beagle',
    'Uno de los buceos más exclusivos del mundo: el Canal Beagle tiene una biodiversidad '
    'marina subantártica que no existe en ningún otro lugar. Estrellas de mar gigantes, '
    'cangrejos centolla, pulpos patagónicos y bosques de kelp. El agua fría (4-8°C) está '
    'compensada por los trajes secos que proveemos. Requiere certificación Open Water mínima.',
    'buceo', 3, 3, 25000.00, 4, 16,
    'Ushuaia, Tierra del Fuego', -54.8100, -68.2500, TRUE
  ),

  -- ── Norte Aventura · 3 nuevas ─────────────────────────────────────────────────
  (
    'd0000020-0000-0000-0000-000000000000',
    'c0000004-0000-0000-0000-000000000000',
    'Trekking al Nevado de Cachi',
    'Ascendemos al Nevado de Cachi a 6.380 msnm, uno de los volcanes más altos de Salta. '
    'El trekking de aclimatación llega hasta los 4.800 msnm entre puna, vicuñas y cóndores. '
    'Salida desde el pueblo colonial de Cachi, una joya de arquitectura andina. '
    'Incluye guías de alta montaña certificados, mulas de apoyo, alimentación y equipo técnico.',
    'trekking', 4, 8, 13000.00, 10, 16,
    'Cachi, Salta', -25.1167, -66.1667, TRUE
  ),
  (
    'd0000021-0000-0000-0000-000000000000',
    'c0000004-0000-0000-0000-000000000000',
    'Rafting en el Río Juramento',
    'El Río Juramento baja con fuerza desde la Cordillera de los Andes entre paredes de roca '
    'roja y vegetación subtropical del NOA. Rápidos clase III en un cañón de increíble belleza '
    'con presencia de loros, tucanes y cóndores. Un contraste impresionante: naturaleza salvaje '
    'a minutos de la ciudad de Salta. Incluye equipo completo, guía y transfer.',
    'rafting', 3, 5, 11000.00, 8, 14,
    'Salta, Salta', -24.7833, -65.4167, TRUE
  ),
  (
    'd0000022-0000-0000-0000-000000000000',
    'c0000004-0000-0000-0000-000000000000',
    'Parapente sobre los Valles Calchaquíes',
    'Volamos en tándem sobre los Valles Calchaquíes, el paisaje más colorido de Argentina. '
    'Los cerros bordó, violeta y ocre se despliegan bajo los pies mientras sobrevolamos '
    'viñedos de altura, ruinas incas y pueblitos encalados. Despegamos desde 3.000 msnm '
    'sobre Cafayate con el piloto certificado FAA. Incluye video profesional del vuelo y '
    'degustación de torrontés al finalizar.',
    'parapente', 2, 2, 19000.00, 4, 14,
    'Cafayate, Salta', -26.0736, -65.9731, TRUE
  );


-- ─── 6. Imágenes de actividades ───────────────────────────────────────────────
INSERT INTO public.activity_images (activity_id, url, is_cover, order_index) VALUES
  -- Trekking Nahuel Huapi
  ('d0000001-0000-0000-0000-000000000000', 'https://images.unsplash.com/photo-1501854140801-50d01698950b?w=1200&q=80', TRUE,  0),
  ('d0000001-0000-0000-0000-000000000000', 'https://images.unsplash.com/photo-1551632811-561732d1e306?w=1200&q=80', FALSE, 1),
  ('d0000001-0000-0000-0000-000000000000', 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=1200&q=80', FALSE, 2),

  -- Kayak Brazo Blest
  ('d0000002-0000-0000-0000-000000000000', 'https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=1200&q=80', TRUE,  0),
  ('d0000002-0000-0000-0000-000000000000', 'https://images.unsplash.com/photo-1519331379826-f10be5486c6f?w=1200&q=80', FALSE, 1),

  -- Rafting Cañón del Atuel
  ('d0000003-0000-0000-0000-000000000000', 'https://images.unsplash.com/photo-1530053969600-caed2596d242?w=1200&q=80', TRUE,  0),
  ('d0000003-0000-0000-0000-000000000000', 'https://images.unsplash.com/photo-1477346611705-65d1883cee1e?w=1200&q=80', FALSE, 1),

  -- Escalada Cerro Arco
  ('d0000004-0000-0000-0000-000000000000', 'https://images.unsplash.com/photo-1504280390367-361c6d9f38f4?w=1200&q=80', TRUE,  0),
  ('d0000004-0000-0000-0000-000000000000', 'https://images.unsplash.com/photo-1522163182402-834f871fd851?w=1200&q=80', FALSE, 1),

  -- Ski Cerro Castor
  ('d0000005-0000-0000-0000-000000000000', 'https://images.unsplash.com/photo-1551524164-6cf2a14cf65a?w=1200&q=80', TRUE,  0),
  ('d0000005-0000-0000-0000-000000000000', 'https://images.unsplash.com/photo-1512132411229-c30391241dd8?w=1200&q=80', FALSE, 1),

  -- Trekking Tierra del Fuego
  ('d0000006-0000-0000-0000-000000000000', 'https://images.unsplash.com/photo-1489493887464-892be6d1daae?w=1200&q=80', TRUE,  0),
  ('d0000006-0000-0000-0000-000000000000', 'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=1200&q=80', FALSE, 1),

  -- Cabalgata Humahuaca
  ('d0000007-0000-0000-0000-000000000000', 'https://images.unsplash.com/photo-1553284965-83fd3e82fa5a?w=1200&q=80', TRUE,  0),
  ('d0000007-0000-0000-0000-000000000000', 'https://images.unsplash.com/photo-1474511320723-9a56873867b5?w=1200&q=80', FALSE, 1),

  -- Parapente Valle de Uco
  ('d0000008-0000-0000-0000-000000000000', 'https://images.unsplash.com/photo-1528183429752-a97d0bf99b5a?w=1200&q=80', TRUE,  0),
  ('d0000008-0000-0000-0000-000000000000', 'https://images.unsplash.com/photo-1533130061792-64b345e4a833?w=1200&q=80', FALSE, 1),

  -- Ciclismo Circuito Chico
  ('d0000009-0000-0000-0000-000000000000', 'https://images.unsplash.com/photo-1571902943202-507ec2618e8f?w=1200&q=80', TRUE,  0),
  ('d0000009-0000-0000-0000-000000000000', 'https://images.unsplash.com/photo-1541625602330-2277a4c46182?w=1200&q=80', FALSE, 1),

  -- Trekking Glaciar Martial
  ('d0000010-0000-0000-0000-000000000000', 'https://images.unsplash.com/photo-1476362174823-3a23f4aa6d36?w=1200&q=80', TRUE,  0),
  ('d0000010-0000-0000-0000-000000000000', 'https://images.unsplash.com/photo-1455156218388-5e61b526818b?w=1200&q=80', FALSE, 1),

  -- Escalada en Hielo Tronador
  ('d0000011-0000-0000-0000-000000000000', 'https://images.unsplash.com/photo-1551632811-561732d1e306?w=1200&q=80', TRUE,  0),
  ('d0000011-0000-0000-0000-000000000000', 'https://images.unsplash.com/photo-1522163182402-834f871fd851?w=1200&q=80', FALSE, 1),

  -- Rafting Río Manso
  ('d0000012-0000-0000-0000-000000000000', 'https://images.unsplash.com/photo-1593693411515-c20261bcad6e?w=1200&q=80', TRUE,  0),
  ('d0000012-0000-0000-0000-000000000000', 'https://images.unsplash.com/photo-1477346611705-65d1883cee1e?w=1200&q=80', FALSE, 1),

  -- Trekking Nocturno Astroturismo
  ('d0000013-0000-0000-0000-000000000000', 'https://images.unsplash.com/photo-1419242902214-272b3f66ee7a?w=1200&q=80', TRUE,  0),
  ('d0000013-0000-0000-0000-000000000000', 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=1200&q=80', FALSE, 1),

  -- Trekking Base Camp Aconcagua
  ('d0000014-0000-0000-0000-000000000000', 'https://images.unsplash.com/photo-1617390082980-7591cfdf04a9?w=1200&q=80', TRUE,  0),
  ('d0000014-0000-0000-0000-000000000000', 'https://images.unsplash.com/photo-1501854140801-50d01698950b?w=1200&q=80', FALSE, 1),

  -- Ski Las Leñas
  ('d0000015-0000-0000-0000-000000000000', 'https://images.unsplash.com/photo-1600166898405-da9535204226?w=1200&q=80', TRUE,  0),
  ('d0000015-0000-0000-0000-000000000000', 'https://images.unsplash.com/photo-1512132411229-c30391241dd8?w=1200&q=80', FALSE, 1),

  -- Buceo Dique Potrerillos
  ('d0000016-0000-0000-0000-000000000000', 'https://images.unsplash.com/photo-1682687982501-1e58ab814714?w=1200&q=80', TRUE,  0),
  ('d0000016-0000-0000-0000-000000000000', 'https://images.unsplash.com/photo-1559827260-dc66d52bef19?w=1200&q=80', FALSE, 1),

  -- Kayak Canal Beagle
  ('d0000017-0000-0000-0000-000000000000', 'https://images.unsplash.com/photo-1566438480900-0609be27a4be?w=1200&q=80', TRUE,  0),
  ('d0000017-0000-0000-0000-000000000000', 'https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=1200&q=80', FALSE, 1),

  -- Cabalgata Fin del Mundo
  ('d0000018-0000-0000-0000-000000000000', 'https://images.unsplash.com/photo-1469474968028-56623f02e42e?w=1200&q=80', TRUE,  0),
  ('d0000018-0000-0000-0000-000000000000', 'https://images.unsplash.com/photo-1474511320723-9a56873867b5?w=1200&q=80', FALSE, 1),

  -- Buceo Canal Beagle
  ('d0000019-0000-0000-0000-000000000000', 'https://images.unsplash.com/photo-1582967788606-a171c1080cb0?w=1200&q=80', TRUE,  0),
  ('d0000019-0000-0000-0000-000000000000', 'https://images.unsplash.com/photo-1518623489648-a173ef7824f3?w=1200&q=80', FALSE, 1),

  -- Trekking Nevado de Cachi
  ('d0000020-0000-0000-0000-000000000000', 'https://images.unsplash.com/photo-1455156218388-5e61b526818b?w=1200&q=80', TRUE,  0),
  ('d0000020-0000-0000-0000-000000000000', 'https://images.unsplash.com/photo-1551632811-561732d1e306?w=1200&q=80', FALSE, 1),

  -- Rafting Río Juramento
  ('d0000021-0000-0000-0000-000000000000', 'https://images.unsplash.com/photo-1495555687398-3f50d6e79e1e?w=1200&q=80', TRUE,  0),
  ('d0000021-0000-0000-0000-000000000000', 'https://images.unsplash.com/photo-1530053969600-caed2596d242?w=1200&q=80', FALSE, 1),

  -- Parapente Valles Calchaquíes
  ('d0000022-0000-0000-0000-000000000000', 'https://images.unsplash.com/photo-1549060279-7e168fcee0c2?w=1200&q=80', TRUE,  0),
  ('d0000022-0000-0000-0000-000000000000', 'https://images.unsplash.com/photo-1528183429752-a97d0bf99b5a?w=1200&q=80', FALSE, 1);


-- ─── 7. Disponibilidad (próximos 3 meses, slot semanal) ──────────────────────
-- Turno mañana para todas las actividades
INSERT INTO public.availability (activity_id, date, time, total_spots, booked_spots)
SELECT
  a.id,
  d::date,
  '09:00'::time,
  a.max_participants,
  0
FROM public.activities a
CROSS JOIN generate_series(
  CURRENT_DATE + INTERVAL '3 days',
  CURRENT_DATE + INTERVAL '3 months',
  '7 days'::interval
) d
WHERE a.is_active = TRUE;

-- Turno tarde para actividades de alta demanda
INSERT INTO public.availability (activity_id, date, time, total_spots, booked_spots)
SELECT
  a.id,
  d::date,
  '14:00'::time,
  a.max_participants,
  0
FROM public.activities a
CROSS JOIN generate_series(
  CURRENT_DATE + INTERVAL '3 days',
  CURRENT_DATE + INTERVAL '3 months',
  '7 days'::interval
) d
WHERE a.id IN (
  'd0000001-0000-0000-0000-000000000000',  -- Trekking Nahuel Huapi
  'd0000003-0000-0000-0000-000000000000',  -- Rafting Atuel
  'd0000008-0000-0000-0000-000000000000'   -- Parapente
);


-- ─── 8. Disponibilidad pasada (para reservas completadas) ────────────────────
INSERT INTO public.availability (id, activity_id, date, time, total_spots, booked_spots)
VALUES
  -- Trekking hace 3 semanas – 2 reservados por Lucía
  ('e0000001-0000-0000-0000-000000000000',
   'd0000001-0000-0000-0000-000000000000',
   CURRENT_DATE - INTERVAL '21 days', '09:00', 12, 2),
  -- Kayak hace 2 semanas – 1 reservado por Martín
  ('e0000002-0000-0000-0000-000000000000',
   'd0000002-0000-0000-0000-000000000000',
   CURRENT_DATE - INTERVAL '14 days', '09:00', 8, 1),
  -- Cabalgata hace 10 días – 2 reservados por Martín
  ('e0000003-0000-0000-0000-000000000000',
   'd0000007-0000-0000-0000-000000000000',
   CURRENT_DATE - INTERVAL '10 days', '09:00', 12, 2),
  -- Rafting en 15 días – 3 confirmados por Lucía (reserva futura)
  ('e0000004-0000-0000-0000-000000000000',
   'd0000003-0000-0000-0000-000000000000',
   CURRENT_DATE + INTERVAL '15 days', '09:00', 10, 3),
  -- Ski en 8 días – 1 pendiente de Martín
  ('e0000005-0000-0000-0000-000000000000',
   'd0000005-0000-0000-0000-000000000000',
   CURRENT_DATE + INTERVAL '8 days', '09:00', 15, 1);


-- ─── 9. Reservas ──────────────────────────────────────────────────────────────
INSERT INTO public.bookings (id, tourist_id, activity_id, availability_id, participants, total_price, status, notes)
VALUES
  -- Lucía: trekking completado (pasado)
  (
    'f0000001-0000-0000-0000-000000000000',
    'b0000001-0000-0000-0000-000000000000',
    'd0000001-0000-0000-0000-000000000000',
    'e0000001-0000-0000-0000-000000000000',
    2, 17000.00, 'completed',
    'Somos dos adultos en buena forma. ¿Llevamos comida o hay almuerzo incluido?'
  ),
  -- Lucía: rafting confirmado (futuro)
  (
    'f0000002-0000-0000-0000-000000000000',
    'b0000001-0000-0000-0000-000000000000',
    'd0000003-0000-0000-0000-000000000000',
    'e0000004-0000-0000-0000-000000000000',
    3, 45000.00, 'confirmed',
    'Vamos con un amigo. Ninguno tiene experiencia en rafting pero somos deportistas.'
  ),
  -- Martín: kayak completado (pasado)
  (
    'f0000003-0000-0000-0000-000000000000',
    'b0000002-0000-0000-0000-000000000000',
    'd0000002-0000-0000-0000-000000000000',
    'e0000002-0000-0000-0000-000000000000',
    1, 12000.00, 'completed',
    NULL
  ),
  -- Martín: cabalgata completada (pasada)
  (
    'f0000004-0000-0000-0000-000000000000',
    'b0000002-0000-0000-0000-000000000000',
    'd0000007-0000-0000-0000-000000000000',
    'e0000003-0000-0000-0000-000000000000',
    2, 15000.00, 'completed',
    'Nunca monté a caballo. ¿Hay clases previas?'
  ),
  -- Martín: ski pendiente (futuro)
  (
    'f0000005-0000-0000-0000-000000000000',
    'b0000002-0000-0000-0000-000000000000',
    'd0000005-0000-0000-0000-000000000000',
    'e0000005-0000-0000-0000-000000000000',
    1, 18500.00, 'pending',
    'Primera vez que esquío. Voy a necesitar clase de principiantes.'
  );


-- ─── 10. Reseñas ──────────────────────────────────────────────────────────────
-- Solo reservas con status='completed' pueden tener reseña (ver RLS policy)
INSERT INTO public.reviews (booking_id, tourist_id, activity_id, rating, comment)
VALUES
  -- Lucía reseña el trekking (5 estrellas)
  (
    'f0000001-0000-0000-0000-000000000000',
    'b0000001-0000-0000-0000-000000000000',
    'd0000001-0000-0000-0000-000000000000',
    5,
    'Una experiencia increíble. Carlos conoce cada piedra del parque. Los paisajes son de '
    'película y el grupo era muy amigable. El almuerzo junto al arroyo fue un lujo inesperado. '
    'Volvería sin dudarlo, ya estoy reservando el kayak para la próxima vez.'
  ),
  -- Martín reseña el kayak (5 estrellas)
  (
    'f0000003-0000-0000-0000-000000000000',
    'b0000002-0000-0000-0000-000000000000',
    'd0000002-0000-0000-0000-000000000000',
    5,
    'El Brazo Blest en kayak es algo que no te esperás. Silencio total, agua cristalina y el '
    'guía explicando todo sobre la flora nativa del bosque valdiviano. El mate al final del día '
    'fue el broche de oro. Altísimo nivel, 100% recomendable.'
  ),
  -- Martín reseña la cabalgata (4 estrellas)
  (
    'f0000004-0000-0000-0000-000000000000',
    'b0000002-0000-0000-0000-000000000000',
    'd0000007-0000-0000-0000-000000000000',
    4,
    'Una cabalgata hermosa por la Quebrada. Los caballos son muy mansos, ideal para '
    'principiantes. El almuerzo típico estuvo buenísimo y la guía Ana conoce la historia '
    'de cada pueblo que cruzamos. Le saco una estrella porque el traslado desde Salta '
    'llegó tarde y perdimos una hora de recorrido.'
  );


COMMIT;

-- ═══════════════════════════════════════════════════════════════════════════════
-- Resumen de datos creados:
--   Usuarios:      6 (4 prestadores + 2 turistas)
--   Prestadores:   4 empresas
--   Actividades:   22 (trekking ×6, kayak ×2, rafting ×3, escalada ×2,
--                       ski ×2, parapente ×2, ciclismo ×1, cabalgata ×3, buceo ×2 — 6 por prestador)
--   Imágenes:      46 (2 por actividad)
--   Disponibilidad: ~170 slots futuros + 5 slots pasados/específicos
--   Reservas:      5 (2 completed, 1 confirmed, 1 pending + 1 completed)
--   Reseñas:       3 (★5 trekking, ★5 kayak, ★4 cabalgata)
-- ═══════════════════════════════════════════════════════════════════════════════
