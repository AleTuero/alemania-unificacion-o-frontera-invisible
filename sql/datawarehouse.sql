USE alemania_analisis;
-- Ejecuta estos uno por uno según el nombre de tus tablas
ALTER TABLE tabla_natalidad_largo RENAME COLUMN `AÃ±o` TO Anio;
ALTER TABLE tabla_paro_largo RENAME COLUMN `AÃ±o` TO Anio;
ALTER TABLE tabla_pib_largo RENAME COLUMN `AÃ±o` TO Anio;
ALTER TABLE tabla_votos_largo RENAME COLUMN `AÃ±o` TO Anio;

ALTER TABLE tabla_pib_largo RENAME COLUMN `ï»¿ID_Estado` TO ID_Estado;
ALTER TABLE tabla_paro_largo RENAME COLUMN `ï»¿ID_Estado` TO ID_Estado;
ALTER TABLE tabla_natalidad_largo RENAME COLUMN `ï»¿ID_Estado` TO ID_Estado;
ALTER TABLE tabla_votos_largo RENAME COLUMN `ï»¿ID_Estado` TO ID_Estado;

-- 3. Crear la gran tabla maestra (Solo se hace una vez)
CREATE TABLE Fact_Alemania_Master AS
SELECT 
    p.ID_Estado, 
    p.Estado, 
    p.Region_Tipo, 
    p.Anio, 
    p.PIB, 
    r.Paro_Pct, 
    n.Natalidad,
    v.Partido,
    v.Porcentaje as Votos_Pct
FROM tabla_pib_largo p
JOIN tabla_paro_largo r ON p.ID_Estado = r.ID_Estado AND p.Anio = r.Anio
JOIN tabla_natalidad_largo n ON p.ID_Estado = n.ID_Estado AND p.Anio = n.Anio
JOIN tabla_votos_largo v ON p.ID_Estado = v.ID_Estado AND p.Anio = v.Anio;

SELECT * FROM Fact_Alemania_Master LIMIT 20;

-- ¿En que estados y años se registro el PIB más alto junto con el menor paro?
SELECT DISTINCT Estado, Anio, PIB, Paro_Pct
FROM Fact_Alemania_Master
ORDER BY PIB DESC, Paro_Pct ASC
LIMIT 10;

-- ¿A quienes votan los estados que no son tan ricos?
SELECT 
    f1.Anio,
    f1.Estado, 
    f1.Region_Tipo,
    f1.PIB, 
    f1.Paro_Pct, 
    f1.Partido AS Ganador, 
    f1.Votos_Pct AS Porcentaje_Ganador
FROM Fact_Alemania_Master f1
WHERE f1.Votos_Pct = (
    -- Esta subquery busca el porcentaje más alto para ese estado y año
    SELECT MAX(Votos_Pct) 
    FROM Fact_Alemania_Master f2 
    WHERE f1.Estado = f2.Estado AND f1.Anio = f2.Anio
)
ORDER BY f1.Anio DESC, f1.PIB DESC;

-- ¿Cómo se han ido moviendo estos 3 partidos en el estado de Sajonia (Este)?
SELECT 
    Anio, 
    Estado,
    -- TRIM elimina espacios y LIKE busca aunque el nombre varíe un poco
    MAX(CASE WHEN TRIM(Partido) LIKE '%AfD%' THEN Votos_Pct END) AS AfD,
    MAX(CASE WHEN TRIM(Partido) LIKE '%CDU%' THEN Votos_Pct END) AS CDU,
    MAX(CASE WHEN TRIM(Partido) LIKE '%Linke%' THEN Votos_Pct END) AS Linke,
    Paro_Pct,
    PIB
FROM Fact_Alemania_Master
WHERE Estado = 'Sajonia'
GROUP BY Anio, Estado, Paro_Pct, PIB
ORDER BY Anio ASC;

-- Comparamos los Estados de Baviera (oeste) con Sajonia (Este)
SELECT 
    Anio,
    -- Comparativa de Partidos en Sajonia (Este)
    MAX(CASE WHEN Estado = 'Sajonia' AND Partido LIKE '%AfD%' THEN Votos_Pct END) AS Saj_AfD,
    MAX(CASE WHEN Estado = 'Sajonia' AND Partido LIKE '%CDU%' THEN Votos_Pct END) AS Saj_CDU,
    MAX(CASE WHEN Estado = 'Sajonia' AND Partido LIKE '%SPD%' THEN Votos_Pct END) AS Saj_SPD,
    MAX(CASE WHEN Estado = 'Sajonia' AND Partido LIKE '%Linke%' THEN Votos_Pct END) AS Saj_Linke,
    
    -- Comparativa de Partidos en Baviera (Oeste)
    MAX(CASE WHEN Estado = 'Baviera' AND Partido LIKE '%AfD%' THEN Votos_Pct END) AS Bav_AfD,
    MAX(CASE WHEN Estado = 'Baviera' AND (Partido LIKE '%CDU%' OR Partido LIKE '%CSU%') THEN Votos_Pct END) AS Bav_Union,
    MAX(CASE WHEN Estado = 'Baviera' AND Partido LIKE '%SPD%' THEN Votos_Pct END) AS Bav_SPD,
    MAX(CASE WHEN Estado = 'Baviera' AND Partido LIKE '%Linke%' THEN Votos_Pct END) AS Bav_Linke,
    
    -- Diferencia de contexto
    MAX(CASE WHEN Estado = 'Sajonia' THEN Paro_Pct END) AS Paro_Sajonia,
    MAX(CASE WHEN Estado = 'Baviera' THEN Paro_Pct END) AS Paro_Baviera
FROM Fact_Alemania_Master
WHERE Estado IN ('Sajonia', 'Baviera')
GROUP BY Anio
ORDER BY Anio ASC;

-- PIB de Baviera (oeste) con Sajonia (este)
SELECT 
    Anio,
    -- PIB de cada estado
    MAX(CASE WHEN Estado = 'Baviera' THEN PIB END) AS PIB_Baviera,
    MAX(CASE WHEN Estado = 'Sajonia' THEN PIB END) AS PIB_Sajonia,
    -- Cálculo de la diferencia (Baviera es N veces Sajonia)
    ROUND(MAX(CASE WHEN Estado = 'Baviera' THEN PIB END) / 
          MAX(CASE WHEN Estado = 'Sajonia' THEN PIB END), 2) AS Multiplicador_Riqueza,
    -- Porcentaje de paro relativo (opcional para contexto)
    ROUND((MAX(CASE WHEN Estado = 'Sajonia' THEN Paro_Pct END) / 
           MAX(CASE WHEN Estado = 'Sajonia' THEN PIB END)) * 100, 2) AS Ratio_Paro_PIB_Sajonia
FROM Fact_Alemania_Master
WHERE Estado IN ('Sajonia', 'Baviera')
GROUP BY Anio
ORDER BY Anio DESC;

-- Crear la dimension de tiempo
CREATE TABLE Dim_Time AS
SELECT DISTINCT 
    Anio,
    CASE 
        WHEN Anio >= 2020 THEN '2020s'
        WHEN Anio >= 2010 THEN '2010s'
        ELSE '2000s'
    END AS Decada
FROM Fact_Alemania_Master;

-- La ponemos como llave primaria para que sea rápida
ALTER TABLE Dim_Time ADD PRIMARY KEY (Anio);

DROP TABLE IF EXISTS Dim_Region;

-- Creamos la dimension geografica
-- 1. Reiniciamos la tabla
DROP TABLE IF EXISTS Dim_Region;

CREATE TABLE Dim_Region AS
SELECT DISTINCT 
    ID_Estado, 
    Estado, 
    Region_Tipo 
FROM Fact_Alemania_Master;

-- 2. Definimos la Primary Key INMEDIATAMENTE
-- Esto le dice a MySQL: "ID_Estado es la columna clave"
ALTER TABLE Dim_Region ADD PRIMARY KEY (ID_Estado);

-- 3. Ahora añadimos la columna
ALTER TABLE Dim_Region ADD COLUMN Es_Capital BOOLEAN;

-- 4. Ahora el UPDATE funcionará porque ID_Estado ya es una KEY oficial
UPDATE Dim_Region 
SET Es_Capital = (Estado = 'Berlín')
WHERE ID_Estado > 0;

-- 5. Verificamos
SELECT * FROM Dim_Region;

-- Veamos si la natalidad ha crecido con respecto al PIB
SELECT 
    t.Decada,
    r.Region_Tipo,
    ROUND(AVG(f.PIB), 2) AS PIB_Promedio,
    ROUND(AVG(f.Natalidad), 2) AS Natalidad_Promedio,
    -- Calculamos cuántos nacimientos hay por cada millón de euros de PIB (Ratio)
    ROUND(AVG(f.Natalidad) / AVG(f.PIB) * 1000, 4) AS Ratio_Natalidad_PIB
FROM Fact_Alemania_Master f
JOIN Dim_Time t ON f.Anio = t.Anio
JOIN Dim_Region r ON f.ID_Estado = r.ID_Estado
GROUP BY t.Decada, r.Region_Tipo
ORDER BY t.Decada ASC, r.Region_Tipo DESC;

-- Comparativas Oeste vs Este paro con voto politico

WITH Hitos_Economicos AS (
    -- Buscamos el año con más paro y el año con menos paro por región
    SELECT 
        r.Region_Tipo,
        MAX(f.Paro_Pct) AS Paro_Max,
        MIN(f.Paro_Pct) AS Paro_Min
    FROM Fact_Alemania_Master f
    JOIN Dim_Region r ON f.ID_Estado = r.ID_Estado
    WHERE r.Region_Tipo IN ('Este', 'Oeste')
    GROUP BY r.Region_Tipo
)
SELECT 
    h.Region_Tipo,
    'Peor Momento (Paro Max)' AS Escenario,
    f1.Anio,
    ROUND(f1.Paro_Pct, 0) AS Paro,
    f1.Partido,
    f1.Votos_Pct AS Votos_Partido_Dominante
FROM Fact_Alemania_Master f1
JOIN Dim_Region r ON f1.ID_Estado = r.ID_Estado
JOIN Hitos_Economicos h ON r.Region_Tipo = h.Region_Tipo AND f1.Paro_Pct = h.Paro_Max

UNION ALL

SELECT 
    h.Region_Tipo,
    'Mejor Momento (Paro Min)' AS Escenario,
    f2.Anio,
    ROUND(f2.Paro_Pct, 0) AS Paro,
    f2.Partido,
    f2.Votos_Pct AS Votos_Partido_Dominante
FROM Fact_Alemania_Master f2
JOIN Dim_Region r ON f2.ID_Estado = r.ID_Estado
JOIN Hitos_Economicos h ON r.Region_Tipo = h.Region_Tipo AND f2.Paro_Pct = h.Paro_Min

ORDER BY Region_Tipo, Paro DESC;

-- Mejor y peor momento de paro con partido politico

WITH Hitos_Paro AS (
    -- Primero identificamos cuál fue el valor de paro max y min por región
    SELECT 
        r.Region_Tipo,
        MAX(f.Paro_Pct) as Max_Paro,
        MIN(f.Paro_Pct) as Min_Paro
    FROM Fact_Alemania_Master f
    JOIN Dim_Region r ON f.ID_Estado = r.ID_Estado
    WHERE r.Region_Tipo IN ('Este', 'Oeste')
    GROUP BY r.Region_Tipo
),
Ranking_Partidos AS (
    -- Ahora buscamos todos los partidos de esos años y los ordenamos por votos
    SELECT 
        r.Region_Tipo,
        f.Anio,
        f.Paro_Pct,
        f.Partido,
        f.Votos_Pct,
        h.Max_Paro,
        h.Min_Paro,
        ROW_NUMBER() OVER(PARTITION BY r.Region_Tipo, f.Anio ORDER BY f.Votos_Pct DESC) as Posicion
    FROM Fact_Alemania_Master f
    JOIN Dim_Region r ON f.ID_Estado = r.ID_Estado
    JOIN Hitos_Paro h ON r.Region_Tipo = h.Region_Tipo
    WHERE f.Paro_Pct = h.Max_Paro OR f.Paro_Pct = h.Min_Paro
)
-- Finalmente, filtramos solo para ver al número 1 (el más votado)
SELECT 
    Region_Tipo,
    CASE 
        WHEN Paro_Pct = Max_Paro THEN 'PEOR MOMENTO (Máximo Paro)'
        ELSE 'MEJOR MOMENTO (Mínimo Paro)'
    END AS Escenario,
    Anio,
    ROUND(Paro_Pct, 1) AS Tasa_Paro,
    Partido AS Partido_Ganador,
    Votos_Pct AS Porcentaje_Votos
FROM Ranking_Partidos
WHERE Posicion = 1
ORDER BY Region_Tipo, Paro_Pct DESC;

-- Consultamos el partido más votado por cada estado en 1991
-- para comprobar si el Este votó "comunista" o se volcó con la unificación
WITH Ranking_1991 AS (
    SELECT 
        r.Region_Tipo,
        f.Estado,
        f.Partido,
        f.Votos_Pct,
        -- Creamos un ranking para saber cuál es el partido #1 en cada estado
        ROW_NUMBER() OVER(PARTITION BY f.Estado ORDER BY f.Votos_Pct DESC) as Posicion
    FROM Fact_Alemania_Master f
    JOIN Dim_Region r ON f.ID_Estado = r.ID_Estado
    WHERE f.Anio IN (1990, 1991) -- Dependiendo de cómo figure el primer año en tu Excel
)
SELECT 
    Region_Tipo,
    Estado,
    Partido AS Partido_Ganador,
    Votos_Pct AS Porcentaje
FROM Ranking_1991
WHERE Posicion = 1
ORDER BY Region_Tipo DESC, Porcentaje DESC;

-- Bajo paro vs Alto voto de protesta

SELECT 
    r.Region_Tipo,
    f.Estado,
    f.Anio,
    f.Partido,
    f.Votos_Pct AS Voto_Protesta,
    -- Calculamos qué porcentaje del voto NO está 'explicado' por el volumen de paro
    -- Cuanto más alto el %, más 'ideológica' es la protesta en ese estado
    ROUND((f.Votos_Pct / (f.Paro_Pct / 1000)) * 10, 2) AS Porcentaje_Intensidad_Protesta
FROM Fact_Alemania_Master f
JOIN Dim_Region r ON f.ID_Estado = r.ID_Estado
WHERE f.Partido IN ('AfD', 'Linke') 
  AND f.Anio > 2015
ORDER BY Porcentaje_Intensidad_Protesta DESC
LIMIT 10;

-- Vamos a cruzar los datos del PIB con la intensidad de protesta

WITH Calculos_PIB AS (
    SELECT 
        r.Region_Tipo,
        f.Estado,
        f.Anio,
        f.Partido,
        f.Votos_Pct,
        f.PIB,
        -- Ratio: Puntos de voto por cada 1.000M de PIB
        -- Cuanto más alto, más "rentable" es la protesta en ese estado
        ROUND((f.Votos_Pct / (f.PIB / 1000)), 4) AS Ratio_Riqueza_Protesta
    FROM Fact_Alemania_Master f
    JOIN Dim_Region r ON f.ID_Estado = r.ID_Estado
    WHERE f.Partido IN ('AfD', 'Linke', 'PDS')
)
SELECT *
FROM Calculos_PIB
WHERE Anio IN (1991, 2002, 2022) -- Comparamos el inicio, la crisis y el presente
ORDER BY Ratio_Riqueza_Protesta DESC
LIMIT 10;

-- Comparativa de PIB Este vs Oeste (2024)

SELECT 
    f.Anio,
    -- Promedio PIB Este (Sajonia, Turingia, etc.)
    ROUND(AVG(CASE WHEN r.Region_Tipo = 'Este' THEN f.PIB END), 2) AS PIB_Medio_Este,
    -- Promedio PIB Oeste (Baviera, Renania, etc.)
    ROUND(AVG(CASE WHEN r.Region_Tipo = 'Oeste' THEN f.PIB END), 2) AS PIB_Medio_Oeste,
    -- La Brecha: Cuánto le falta al Este para alcanzar al Oeste
    ROUND(
        (1 - (AVG(CASE WHEN r.Region_Tipo = 'Este' THEN f.PIB END) / 
              AVG(CASE WHEN r.Region_Tipo = 'Oeste' THEN f.PIB END))) * 100, 2
    ) AS Porcentaje_Brecha
FROM Fact_Alemania_Master f
JOIN Dim_Region r ON f.ID_Estado = r.ID_Estado
WHERE f.Anio IN (1991, 2024)
GROUP BY f.Anio;

-- Comparativa natalidad Este vs Oeste

SELECT 
    f.Anio,
    -- Promedio Nacimientos Este
    ROUND(AVG(CASE WHEN r.Region_Tipo = 'Este' THEN f.Natalidad END), 2) AS Natalidad_Media_Este,
    -- Promedio Nacimientos Oeste
    ROUND(AVG(CASE WHEN r.Region_Tipo = 'Oeste' THEN f.Natalidad END), 2) AS Natalidad_Media_Oeste,
    -- La Brecha: Diferencia porcentual de nacimientos entre regiones
    ROUND(
        (1 - (AVG(CASE WHEN r.Region_Tipo = 'Este' THEN f.Natalidad END) / 
              AVG(CASE WHEN r.Region_Tipo = 'Oeste' THEN f.Natalidad END))) * 100, 2
    ) AS Porcentaje_Brecha_Natalidad
FROM Fact_Alemania_Master f
JOIN Dim_Region r ON f.ID_Estado = r.ID_Estado
WHERE f.Anio IN (1991, 2024)
GROUP BY f.Anio;

-- Comparativa paro Este vs Oeste

SELECT 
    f.Anio,
    -- Promedio Paro (en número de personas o Pct según tu tabla)
    ROUND(AVG(CASE WHEN r.Region_Tipo = 'Este' THEN f.Paro_Pct END), 2) AS Paro_Medio_Este,
    ROUND(AVG(CASE WHEN r.Region_Tipo = 'Oeste' THEN f.Paro_Pct END), 2) AS Paro_Medio_Oeste,
    -- La Brecha: Si sale negativo, significa que el Este tiene MAS paro que el Oeste
    ROUND(
        (1 - (AVG(CASE WHEN r.Region_Tipo = 'Este' THEN f.Paro_Pct END) / 
              AVG(CASE WHEN r.Region_Tipo = 'Oeste' THEN f.Paro_Pct END))) * 100, 2
    ) AS Porcentaje_Diferencia_Paro
FROM Fact_Alemania_Master f
JOIN Dim_Region r ON f.ID_Estado = r.ID_Estado
WHERE f.Anio IN (1991, 2024)
GROUP BY f.Anio;

-- Inferencia ecologica básica (Modelo de Goodman) 

SELECT 
    f.Estado,
    f.Anio,
    -- Eje X: Variable independiente (Causa probable)
    f.Paro_Pct AS Tasa_Desempleo,
    -- Eje Y: Variable dependiente (Efecto)
    f.Votos_Pct AS Voto_AfD,
    -- Calculamos la covarianza simple para ver la fuerza de la relación
    (f.Paro_Pct * f.Votos_Pct) AS Interaccion_Ecologica
FROM Fact_Alemania_Master f
WHERE f.Partido = 'AfD' AND f.Anio = 2024;

-- Inferencia ecologica (Voto real vs Voto esperado)

WITH Media_Nacional AS (
    -- Calculamos la relación media entre paro y voto en toda Alemania
    SELECT AVG(Votos_Pct / NULLIF(Paro_Pct, 0)) AS Ratio_Medio_Nacional
    FROM Fact_Alemania_Master
    WHERE Anio = 2024 AND Partido = 'AfD'
)
SELECT 
    r.Region_Tipo,
    f.Estado,
    f.Votos_Pct AS Voto_Real_AfD,
    -- Calculamos cuánto voto "debería" tener según su tasa de paro
    ROUND(f.Paro_Pct * (SELECT Ratio_Medio_Nacional FROM Media_Nacional), 2) AS Voto_Esperado_Economico,
    -- La diferencia es la Inferencia Ecológica de Protesta Pura
    ROUND(f.Votos_Pct - (f.Paro_Pct * (SELECT Ratio_Medio_Nacional FROM Media_Nacional)), 2) AS Exceso_Protesta_Ideologica
FROM Fact_Alemania_Master f
JOIN Dim_Region r ON f.ID_Estado = r.ID_Estado
WHERE f.Anio = 2024 AND f.Partido = 'AfD'
ORDER BY Exceso_Protesta_Ideologica DESC;

-- Inferencia multivariante con paro, pib y natalidad

SELECT 
    f.Estado,
    r.Region_Tipo,
    f.Votos_Pct AS Voto_Real_AfD,
    -- 1. Factor Económico (PIB bajo = Presión alta)
    ROUND(f.PIB / 1000, 2) AS Factor_Riqueza,
    -- 2. Factor Demográfico (Natalidad baja = Presión alta)
    f.Natalidad AS Factor_Vida,
    -- 3. Inferencia Combinada: 
    -- Buscamos estados donde el Paro es BAJO pero el Voto es ALTO y el PIB es BAJO
    ROUND(
        (f.Votos_Pct * 100) / (NULLIF(f.PIB, 0) / NULLIF(f.Natalidad, 0)), 
    4) AS Indice_Inferencia_Multivariante
FROM Fact_Alemania_Master f
JOIN Dim_Region r ON f.ID_Estado = r.ID_Estado
WHERE f.Anio = 2024 AND f.Partido = 'AfD'
ORDER BY Indice_Inferencia_Multivariante DESC;

-- En porcentaje

WITH Calculo_Base AS (
    SELECT 
        f.Estado,
        r.Region_Tipo,
        -- Tu fórmula original
        ROUND((f.Votos_Pct * 100) / (NULLIF(f.PIB, 0) / NULLIF(f.Natalidad, 0)), 4) AS Indice_Bruto
    FROM Fact_Alemania_Master f
    JOIN Dim_Region r ON f.ID_Estado = r.ID_Estado
    WHERE f.Anio = 2024 AND f.Partido = 'AfD'
),
Maximo AS (
    SELECT MAX(Indice_Bruto) AS Max_Valor FROM Calculo_Base
)
SELECT 
    Estado,
    Region_Tipo,
    Indice_Bruto,
    -- Normalización a Porcentaje (0-100)
    ROUND((Indice_Bruto / (SELECT Max_Valor FROM Maximo)) * 100, 2) AS Porcentaje_Tension_Relativa
FROM Calculo_Base
ORDER BY Porcentaje_Tension_Relativa DESC;

-- Inercia historica

SELECT 
    f.Anio,
    r.Region_Tipo,
    AVG(f.PIB) AS PIB_Medio,
    -- Comparamos con el año anterior para ver el ritmo de crecimiento
    ROUND(
        (AVG(f.PIB) - LAG(AVG(f.PIB)) OVER (PARTITION BY r.Region_Tipo ORDER BY f.Anio)) 
        / NULLIF(LAG(AVG(f.PIB)) OVER (PARTITION BY r.Region_Tipo ORDER BY f.Anio), 0) * 100, 2
    ) AS Crecimiento_Anual_Pct
FROM Fact_Alemania_Master f
JOIN Dim_Region r ON f.ID_Estado = r.ID_Estado
WHERE f.Anio BETWEEN 1991 AND 2024
GROUP BY f.Anio, r.Region_Tipo;

-- Estados criticos (por debajo de la media nacional, en PIB y natalidad)

SELECT 
    Estado,
    Votos_Pct,
    PIB,
    Natalidad
FROM Fact_Alemania_Master
WHERE Anio = 2024 
  AND Partido = 'AfD'
  AND PIB < (SELECT AVG(PIB) FROM Fact_Alemania_Master WHERE Anio = 2024)
  AND Natalidad < (SELECT AVG(Natalidad) FROM Fact_Alemania_Master WHERE Anio = 2024)
  AND Votos_Pct > (SELECT AVG(Votos_Pct) FROM Fact_Alemania_Master WHERE Anio = 2024 AND Partido = 'AfD')
ORDER BY Votos_Pct DESC;

-- Ranking de resiliencia

SELECT 
    r.Region_Tipo,
    f.Estado,
    -- Sumamos ambos extremos para tener la "Protesta Real"
    SUM(f.Votos_Pct) AS Voto_Protesta_Total,
    CASE 
        WHEN SUM(f.Votos_Pct) < 15 AND AVG(f.PIB) > 300000 THEN 'Estado Motor (Estable)'
        WHEN SUM(f.Votos_Pct) BETWEEN 15 AND 30 AND AVG(f.PIB) > 200000 THEN 'Estado en Tensión (Riesgo)'
        -- Si la suma de AfD + Linke supera el 30% con PIB bajo, es Fractura Total
        WHEN SUM(f.Votos_Pct) > 30 AND AVG(f.PIB) < 180000 THEN 'Estado de Protesta (Fractura Total)'
        ELSE 'Estado en Transición'
    END AS Perfil_Sociopolitico
FROM Fact_Alemania_Master f
JOIN Dim_Region r ON f.ID_Estado = r.ID_Estado
WHERE f.Anio = 2024 
  AND f.Partido IN ('AfD', 'Die Linke') -- Metemos a los dos
GROUP BY r.Region_Tipo, f.Estado
ORDER BY Voto_Protesta_Total DESC;

-- Hacemos lo mismo con el PIB

SELECT 
    r.Region_Tipo,
    f.Estado,
    AVG(f.PIB) AS PIB_2024,
    CASE 
        -- ESTADO MOTOR: El gigante económico (Solo los que tiran del carro)
        WHEN AVG(f.PIB) > 250000 THEN 'Estado Motor (Potencia Económica)'
        
        -- ESTADO ESTABLE: El Oeste que funciona pero no es gigante (o el Este más avanzado)
        WHEN AVG(f.PIB) BETWEEN 120000 AND 250000 THEN 'Estado en Estabilidad'
        
        -- ESTADO EN CONVERGENCIA: Los que aún luchan con la brecha del 73%
        ELSE 'Estado en Proceso de Convergencia'
    END AS Perfil_Sociopolitico
FROM Fact_Alemania_Master f
JOIN Dim_Region r ON f.ID_Estado = r.ID_Estado
WHERE f.Anio = 2024 
GROUP BY r.Region_Tipo, f.Estado
ORDER BY AVG(f.PIB) DESC;