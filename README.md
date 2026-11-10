# Habitly

**Habitly** – App de rastreamento de hábitos diários.

## Sobre o nome
Escolhido para aparecer junto nas buscas com apps populares como:
- Habitica (5M+ downloads)
- Habit Diary (10M downloads)
- Loop Habit Tracker (5M downloads)
- Habitify

Nome curto, memorável e otimizado para busca na Play Store ("habit" é a palavra-chave principal).

## Modelo Freemium
- **Free**: Limitado (ex: 5 hábitos) + anúncios
- **Premium (R$ 19,90/mês)**: Ilimitado, sem anúncios, estatísticas completas, sincronização e backup

## Stack
- **Mobile**: Flutter
- **Banco local**: Drift (SQLite) — offline-first
- **Backend**: Node.js (NestJS) no Dokploy + PostgreSQL
- **Auth**: JWT

## Estrutura do projeto
```
habitly/
├── mobile/          # App Flutter
├── backend/         # API no Dokploy
└── README.md
```

## Próximos passos
1. Criar estrutura do app Flutter
2. Schema do PostgreSQL
3. Endpoints da API
4. Deploy no Dokploy via bot Assistente Habitly
