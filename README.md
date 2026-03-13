<<<<<<< HEAD
Alemania: ¿Unificación o Frontera Invisible?

Análisis socioeconómico y electoral de Alemania (1991–2024)

Este proyecto analiza si Alemania realmente se ha unificado tras la caída del Muro de Berlín o si todavía existe una “frontera invisible” entre el Este y el Oeste del país.

Para ello se combinan datos económicos, demográficos y electorales de los estados federales alemanes (Bundesländer) desde 1991 hasta 2024.

El análisis utiliza técnicas de:

- Data Cleaning

- SQL Data Modeling

- Machine Learning

- Explainable AI

- Business Intelligence

El objetivo es estudiar si las diferencias históricas entre las antiguas Alemania Oriental y Occidental siguen reflejándose en:

- La economía

- La demografía

- El comportamiento electoral

🎯 Hipótesis de investigación
1️⃣ Hipótesis principal

Tras más de tres décadas desde la reunificación alemana:

¿Alemania se ha unificado realmente o sigue existiendo una “frontera invisible” entre el Este y el Oeste?

Esta frontera podría manifestarse en:

- Diferencias económicas

- Desigualdad demográfica

- Comportamiento electoral distinto

2️⃣ Hipótesis sobre voto protesta

Se plantea que en los estados del Este de Alemania existe mayor presencia de voto protesta hacia partidos situados en los extremos del espectro político.

Para analizarlo se define una variable:

Protesta_Total = AfD + Die Linke
Partido	Posición
AfD	- Derecha radical
Die Linke -	Izquierda radical
SPD	- Centro izquierda
CDU/CSU - Centro derecha
FDP	- Liberal
Verdes - Ecologista

3️⃣ Hipótesis socioeconómica

El voto protesta podría estar asociado con variables estructurales como:

- Menor PIB

- Mayor desempleo

- Declive demográfico

- Menor natalidad

📊 Datos

Los datos utilizados provienen de la oficina oficial de estadísticas alemana:

Statistisches Bundesamt

Variables utilizadas:

Variable	Descripción
PIB	Producto - interior bruto por estado
Natalidad -	Número de nacimientos
Paro_Pct -	Tasa de desempleo
Resultados electorales - Porcentaje de voto por partido

Periodo analizado:

1991 – 2024

Nivel geográfico:

Estados federales alemanes (Bundesländer)

🗂 Estructura del proyecto
Alemania_Unificacion_Analisis/

data/
Dataset_Final_ML_Alemania.csv

notebooks/
analisis_ml.ipynb

sql/
datawarehouse.sql

dashboard/
dashboard_powerbi.pbix

images/
dashboard_powerbi.png

README.md

🧹 Limpieza de datos

Los datos electorales utilizan formato europeo con coma decimal, por lo que se realiza una limpieza inicial.

Carga del dataset
import pandas as pd

df = pd.read_csv("Dataset_Final_ML_Alemania.csv", sep=";")

Conversión de porcentajes electorales
electoral_cols = ['AfD','CDU_CSU','FDP','LINKE','SPD','VERDES']

df[electoral_cols] = df[electoral_cols].apply(
    lambda x: x.str.replace(",", ".").astype(float)
)

Esto convierte valores como:

"12,5" → 12.5

Creación de variable de voto protesta
df["Protesta_Total"] = df["AfD"] + df["LINKE"]

Esta variable permite analizar el voto hacia partidos considerados antisistema.

🗄️ Modelado SQL

Para facilitar el análisis se construye una tabla de hechos central que integra las variables socioeconómicas y electorales.

Tabla principal
Fact_Alemania_Master

Contiene:

- Estado

- Región (Este / Oeste) y Berlin como variable separada para para evitar introducir sesgos en las comparaciones regionales

- Año

- PIB

- Desempleo

- Natalidad

- Resultados electorales

Creación de la tabla
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
    v.Porcentaje AS Votos_Pct
FROM tabla_pib_largo p
JOIN tabla_paro_largo r
    ON p.ID_Estado = r.ID_Estado
    AND p.Anio = r.Anio
JOIN tabla_natalidad_largo n
    ON p.ID_Estado = n.ID_Estado
    AND p.Anio = n.Anio
JOIN tabla_votos_largo v
    ON p.ID_Estado = v.ID_Estado
    AND p.Anio = v.Anio;

🤖 Machine Learning

Se aplican varios enfoques de análisis:

Clustering (K-Means)

Para identificar tipos de estados según:

- PIB

- Natalidad

- Desempleo

- Voto protesta

Esto permite detectar patrones estructurales dentro del país.

Random Forest

Se entrena un modelo para analizar qué factores explican mejor el voto protesta.

Variables utilizadas:

PIB
Natalidad
Paro_Pct

Objetivo:

Protesta_Total

Explainable AI (SHAP)

Para interpretar el modelo se utilizan valores SHAP que permiten entender:

qué variables influyen más en el voto protesta

cómo influyen en cada región

Se utiliza la librería:

SHAP

📈 Predicción temporal

Se realizan proyecciones hasta 2030 utilizando modelos de regresión para analizar tendencias futuras en:

- Voto protesta

- Evolución demográfica

Esto permite estudiar posibles escenarios futuros para el país.

📊 Dashboard interactivo

Se ha desarrollado un dashboard interactivo en Power BI para visualizar los resultados del análisis.

Microsoft Power BI

El dashboard permite explorar:

- Evidencia Histórica

- Descontento (Este vs Oeste)

- Segmentación

- Analisis Regional con mapa coroplético

📚 Contexto histórico

El análisis parte del proceso histórico de:

German Reunification

Cuando se integraron:

- La República Democrática Alemana (RDA)

- La República Federal Alemana (RFA)

Más de 30 años después, este proyecto analiza si la integración ha sido completa o si todavía persisten diferencias estructurales entre ambas regiones.

🚀 Futuras mejoras

Posibles extensiones del proyecto:

- Incorporar más variables socioeconómicas (educación, migración, inversión pública)

- Utilizar modelos de series temporales avanzados como ARIMA o Prophet

- Ampliar el análisis a nivel de distrito (Kreise)

- Desarrollar una aplicación web interactiva

- Integrar análisis geoespacial con GeoPandas

- Mejorar la predicción electoral con modelos de clasificación

👤 Autor

Alejandro de Tuero

Proyecto de análisis de datos centrado en:

- Ciencia política

- Análisis socioeconómico

- Machine learning aplicado a datos públicos

Herramientas utilizadas:

- Python

- SQL

- Power BI
=======
# alemania-unificacion-o-frontera-invisible
Análisis de datos, SQL, Machine Learning y visualización en Power BI sobre si hay una frontera invisible o unificación en Alemania después de la caída del muro (1991-2024)
>>>>>>> 1e632bd917ebef2c42d3070849b92afc12d20a8b
