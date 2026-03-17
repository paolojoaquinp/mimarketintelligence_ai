# DESIGN.md - Arquitectura de MiEstudioMarket AI
**Versión:** 1.0.0  
**Estado:** Aprobado para Implementación  
**Última Actualización:** 2026-03-17  
**Contexto para AI:** Este documento rige la implementación del sistema. Todo código generado debe respetar la separación entre lógica de IA (probabilística) y lógica de negocio (determinística), priorizando el anclaje de datos (grounding) sobre la creatividad del modelo.

---

## 1. ATRIBUTOS DE CALIDAD (QA Scenarios)
*Las siguientes métricas son mandatorias. [cite_start]El código debe optimizarse para cumplir estos KPIs sobre cualquier otra preferencia estética.* [cite: 8]

| ID | Atributo | Escenario (Estímulo -> Respuesta) | Medida de Éxito (KPI) |
| :--- | :--- | :--- | :--- |
| **QA-01** | **Latencia (RAG)** | [cite_start]Ingesta de reporte > 50 págs -> Generación de resumen. [cite: 5] | [cite_start]**< 15 segundos** totales. [cite: 5, 27] |
| **QA-02** | **Fidelidad (Grounding)** | [cite_start]Solicitud de análisis de nichos (US02). [cite: 6] | [cite_start]**100%** de citas ancladas a documentos. [cite: 18] |
| **QA-03** | **Cost Efficiency** | [cite_start]Procesamiento de comparaciones de precios masivas. [cite: 34] | [cite_start]**90% ahorro** vs fine-tuning mediante routing. [cite: 36] |
| **QA-04** | **Trazabilidad** | [cite_start]Clic en recomendación -> Mostrar origen exacto. [cite: 43] | [cite_start]**< 2 segundos** para mostrar metadatos. [cite: 46] |
| **QA-05** | **Precisión (Math)** | [cite_start]Cálculo de márgenes en Simulador (US03). [cite: 6] | [cite_start]**0% Error**: Lógica no-LLM para aritmética. [cite: 74, 76] |

---

## 2. PATRONES ARQUITECTÓNICOS

### 2.1 Estilos Globales
* [cite_start]**Arquitectura Híbrida (Monolito Modular + Serverless):** [cite: 61]
    * [cite_start]**Core (Módulos):** Gestión de usuarios, Visualización y Simulador en un Monolito Modular (KISS). [cite: 62, 87]
    * [cite_start]**Ingesta (Event-Driven):** Pipeline RAG (PDF -> OCR -> Embeddings) mediante Cloud Functions. [cite: 63, 101]
* **API Strategy:** Arquitectura orientada a contratos para facilitar el desarrollo guiado por especificaciones (SDD).

### [cite_start]2.2 Patrones de IA (AI Design Patterns) [cite: 69]
* [cite_start]**Model Router (Enrutamiento Inteligente):** [cite: 70]
    * [cite_start]Usar **Gemini 2.0 Flash** para resúmenes rápidos y extracción (US01). [cite: 28, 71]
    * [cite_start]Escalar a **Gemini 1.5 Pro** solo para análisis de "Puntos Ciegos" (US02). [cite: 38, 72]
* [cite_start]**Deterministic Tooling (Function Calling):** [cite: 74]
    * La IA **nunca** realiza cálculos. [cite_start]Extrae valores y los pasa a funciones TypeScript/Dart. [cite: 75]
* [cite_start]**Semantic Grounding:** [cite: 78]
    * [cite_start]Uso de *Negative Constraints*: "Si la info no está en el corpus, responder 'Información no disponible'". [cite: 78]

---

## 3. TÁCTICAS Y ESTRATEGIAS TÉCNICAS

### 3.1 Gestión de Errores y Resiliencia
* [cite_start]**Dead Letter Queues (DLQ):** Reintento automático de eventos de ingesta fallidos. [cite: 105]
* [cite_start]**Negative Constraint Guardrails:** Bloqueo de alucinaciones mediante la verificación de citas antes de la entrega al usuario. [cite: 73]

### 3.2 Estrategia de Persistencia y Búsqueda
* [cite_start]**Tecnología:** **Cloud Firestore** con Vector Search. [cite: 9, 29]
* [cite_start]**Esquema de Metadatos:** Cada vector debe incluir obligatoriamente el campo `source_ref` (página, coordenadas de párrafo, hash de archivo). [cite: 48, 78]
* [cite_start]**Semantic Caching:** Cachear respuestas semánticamente idénticas para reducir latencia y costos de tokens. [cite: 78]

### 3.3 Lógica del Simulador de Precios (US03)
[cite_start]La lógica de semáforo debe ser implementada por código determinístico puro: [cite: 6]
* [cite_start]**Verde:** Margen $> 30\%$. [cite: 6]
* [cite_start]**Amarillo:** Margen entre $15\%$ y $29\%$. [cite: 6]
* [cite_start]**Rojo:** Margen $< 15\%$. [cite: 6]

---

## [cite_start]4. STACK TECNOLÓGICO (Restricciones) [cite: 9, 49]

* [cite_start]**Orquestación de IA:** **Firebase Genkit** (Mandatorio para flujos RAG). [cite: 51]
* [cite_start]**Modelos:** Familia Gemini (1.5 Pro/Flash, 2.0 Flash). [cite: 17, 28, 38]
* [cite_start]**Backend:** Node.js / TypeScript (Firebase Cloud Functions). [cite: 26, 75]
* [cite_start]**Base de Datos:** Cloud Firestore (Vectores) + Cloud Storage (Archivos). [cite: 29, 50]
* [cite_start]**Seguridad:** Firebase App Check para protección de cuotas de Vertex AI. [cite: 53]

---

## 5. DECISIONES DE ARQUITECTURA (ADR Summary)

### [cite_start]ADR-001: Monolito Modular para el Core [cite: 80]
[cite_start]**Decisión:** Mantener la lógica de negocio central en un monolito para reducir latencia de red y facilitar el principio KISS. [cite: 87, 92]

### [cite_start]ADR-002: Ingesta Asíncrona Serverless [cite: 97]
[cite_start]**Decisión:** La subida de reportes (US01) dispara funciones independientes para evitar bloqueos del hilo principal. [cite: 100, 101]

### [cite_start]ADR-003: Temperatura de Modelo Controlada [cite: 54]
[cite_start]**Decisión:** Mantener `temperature: 0.1` en análisis de impacto local. [cite: 55]
[cite_start]**Justificación:** Garantizar análisis de datos sobre improvisación creativa. [cite: 55]

---

## 6. INSTRUCCIONES PARA EL AGENTE DE CÓDIGO (AI PROMPT)

> **Reglas para Generar Código en MiEstudioMarket AI:**
> 1.  **Strict Typing:** Define interfaces TypeScript para cada respuesta de Genkit que incluya `source_ref`.
> 2.  **Logic Separation:** El módulo de precios (`US03`) no debe contener llamadas a LLM para el cálculo final; usa funciones puras de TS.
> 3.  **Observability:** Implementa logs estructurados en cada paso del pipeline RAG (Chunking -> Embedding -> Retrieval).
> 4.  **No Hallucinations:** Al configurar los prompts de Genkit, usa siempre el delimitador de contexto y la instrucción negativa de "información no disponible".
> 5.  **Streaming First:** Prioriza el uso de `streaming` en las respuestas de la API para cumplir con la percepción de latencia del usuario.
