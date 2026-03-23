# MiEstudioMarket AI

> De datos crudos a decisiones premium

Plataforma analítica que transforma reportes globales masivos en estrategias de ejecución local para microempresarios, utilizando un motor RAG (Retrieval-Augmented Generation).

## Project Structure (Monorepo)

```
├── miestudiomarket_ai_app/   # Flutter mobile/web app
│   └── lib/
│       ├── core/             # Theme, constants, utils
│       ├── features/         # Feature-first modules (US01-US03)
│       └── shared/           # Shared widgets and models
├── functions/                # Firebase Cloud Functions (TypeScript + Genkit)
│   └── src/
│       ├── index.ts          # Entry point + Genkit initialization
│       ├── types/            # Firestore document schemas
│       └── genkit/           # Genkit RAG flows (per US)
├── docs/                     # Requirements and design documentation
├── firebase.json             # Firebase unified configuration
├── firestore.rules           # Firestore security rules
└── storage.rules             # Cloud Storage security rules
```

## Tech Stack

| Layer | Technology |
|:------|:-----------|
| Frontend | Flutter (Material Design 3) |
| Backend | Firebase Cloud Functions (TypeScript) |
| AI Orchestration | Firebase Genkit + Vertex AI (Gemini) |
| Database | Cloud Firestore (with Vector Search) |
| Storage | Firebase Cloud Storage |
| Security | Firebase App Check |

## Getting Started

### Prerequisites

- Flutter SDK 3.35+
- Node.js 20+
- Firebase CLI 15+

### Setup & Development

```bash
# 1. Install dependencies
# Flutter app
cd miestudiomarket_ai_app && flutter pub get

# Cloud Functions
cd ../functions && npm install

# 2. Local Build
npm run build
```

### Deployment

Para desplegar el proyecto completo o componentes específicos:

```bash
# Desplegar todo (Functions, Rules, Indexes)
firebase deploy

# Desplegar solo funciones
firebase deploy --only functions

# Desplegar índices de Firestore (requerido para búsquedas vectoriales)
firebase deploy --only firestore:indexes
```

> [!NOTE]
> Si encuentras errores de índices en la consola de Firebase al realizar búsquedas, sigue el enlace proporcionado en el error para generar automáticamente el índice faltante.

## Documentation

- [Requirements](docs/requirements.md) — User stories and acceptance criteria
- [Design](docs/design.md) — Architecture, patterns, and quality attributes
