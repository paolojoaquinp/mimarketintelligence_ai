# Especificación de Requerimientos: MiEstudioMarket AI

## 1. Identificación del Proyecto
* [cite_start]**Nombre:** MiEstudioMarket AI[cite: 1].
* [cite_start]**Slogan:** De datos crudos a decisiones premium[cite: 2].
* **Estado:** Fase 1 - MVP Operacional.

## 2. Descripción y Objetivo
[cite_start]**MiEstudioMarket AI** es una plataforma analítica diseñada para transformar reportes globales masivos (procedentes de Statista, Tyson, Sigma) en estrategias de ejecución local[cite: 4]. [cite_start]Utiliza un motor de **Generación Aumentada por Recuperación (RAG)** para identificar nichos de mercado desatendidos, permitiendo que microempresarios tomen decisiones basadas en datos macroeconómicos traducidos a su contexto inmediato[cite: 4, 9].

[cite_start]**Objetivo Central:** Democratizar el acceso a inteligencia de mercado de alto nivel mediante el análisis automatizado de tendencias y la simulación financiera determinística[cite: 4, 31].

---

## 3. Historias de Usuario (US) y Criterios de Aceptación (AC)

### US01: Ingesta y Destilación de Reportes Globales
[cite_start]**Como** dueño de negocio, **quiero** cargar reportes PDF extensos para obtener un resumen ejecutivo que traduzca datos macro a oportunidades micro locales[cite: 5].

* [cite_start]**AC1:** El sistema debe procesar documentos PDF/Excel de más de 50 páginas en menos de 15 segundos mediante el uso de **Vertex AI RAG Engine**[cite: 5].
* [cite_start]**AC2:** El resumen generado debe incluir obligatoriamente una sección de **"Impacto Local"**[cite: 5].
* [cite_start]**AC3:** Cada conclusión debe incluir una cita de fuente exacta (página y párrafo) para auditoría inmediata[cite: 5, 46].
* [cite_start]**AC4:** El sistema debe mantener una arquitectura **KISS** (Keep It Simple, Stupid) en la interfaz de carga[cite: 5].

### US02: Detección de Nichos Desatendidos (Market Gaps)
[cite_start]**Como** estratega de ventas, **quiero** que la IA identifique puntos ciegos comparando las tendencias globales con la oferta de competidores locales registrados[cite: 6].

* [cite_start]**AC1:** La IA debe cruzar tendencias específicas (ej. aumento de consumo keto o bajo en sodio) con el catálogo de competidores locales a disposición[cite: 6].
* [cite_start]**AC2:** El sistema debe generar un **"Gráfico de Brecha de Mercado"** que visualice productos con alta demanda proyectada y baja oferta actual[cite: 6].
* [cite_start]**AC3:** Cada nicho identificado debe generar un **"Perfil de Consumidor" (Buyer Persona)** detallado[cite: 6].

### US03: Simulador de Precios Estratégicos "Premium"
[cite_start]**Como** microempresario, **quiero** correlacionar el costo de mis insumos con los precios de mercado sugeridos para asegurar márgenes de ganancia óptimos[cite: 6].

* [cite_start]**AC1:** El sistema debe integrar feeds de precios de **commodities cárnicos** para actualizar el costo base automáticamente[cite: 6].
* [cite_start]**AC2:** Interfaz de tabla comparativa: Mostrar "Costo de Producción" vs "Precio Promedio de Mercado" detectado en reportes sectoriales[cite: 6].
* **AC3:** Lógica de Semáforo de Margen (Basada en el precio de venta elegido por el usuario):
    * [cite_start]**Verde:** Margen $> 30\%$[cite: 6].
    * [cite_start]**Amarillo:** Margen entre $15\%$ y $29\%$[cite: 6].
    * [cite_start]**Rojo:** Margen $< 15\%$[cite: 6].

---

## 4. Atributos de Calidad y Restricciones Técnicas (QAs)

### Q1: Fidelidad y Anclaje (Factual Grounding)
* [cite_start]**Restricción:** El sistema tiene prohibido usar la "memoria interna" del LLM para inventar datos[cite: 13].
* [cite_start]**Métrica:** El 100% de las afirmaciones deben estar ancladas a los documentos indexados en el corpus[cite: 18].
* [cite_start]**Táctica:** Uso de **Negative Constraints** en el System Prompt: "Si la información no está en los documentos, responder 'Información no disponible'"[cite: 78].

### Q2: Eficiencia de Rendimiento (Latency)
* [cite_start]**Métrica:** La búsqueda semántica y generación de respuesta debe completarse en $< 15$ segundos totales[cite: 27].
* [cite_start]**Táctica:** Implementación de **Streaming de Tokens** y uso de modelos ligeros (**Gemini 2.0 Flash**) para flujos de resumen[cite: 28, 78].

### Q3: Trazabilidad (Explainability)
* [cite_start]**Métrica:** Recuperación de metadatos (página X, párrafo Y) en menos de 2 segundos al hacer clic en una recomendación[cite: 46].
* [cite_start]**Táctica:** Mapeo nativo de vectores en **Firestore** con metadata original del PDF[cite: 48].

---

## 5. Instrucción para Agentes de IA Coding (System Prompt Base)
> [cite_start]"Eres un desarrollador experto trabajando en MiEstudioMarket AI. Todas las implementaciones deben seguir el principio de **Deterministic Tooling**: la IA extrae datos, pero el código (TypeScript/Dart) realiza los cálculos matemáticos[cite: 74, 75]. [cite_start]Prioriza la seguridad mediante **Firebase App Check** y asegúrate de que el componente de 'Impacto Local' mantenga una temperatura de 0.1 para evitar improvisaciones creativas[cite: 53, 55]."
