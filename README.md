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

### Setup

```bash
# Flutter app
cd miestudiomarket_ai_app
flutter pub get

# Cloud Functions
cd ../functions
npm install
npm run build
```

## Documentation

- [Requirements](docs/requirements.md) — User stories and acceptance criteria
- [Design](docs/design.md) — Architecture, patterns, and quality attributes
