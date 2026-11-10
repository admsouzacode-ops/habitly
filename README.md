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


## Package name (Android)
O `applicationId` / namespace do app é **`br.com.souzacode.habitly`** (mesmo padrão do Checa Brasil).

A pasta `mobile/android/` ainda não foi gerada neste repositório (Flutter SDK não estava disponível no ambiente). Quando o Flutter estiver instalado, a partir de `mobile/`:

```bash
flutter create --org br.com.souzacode --project-name habitly --platforms android .
```

Isso deve criar o projeto Android com `applicationId` e namespace `br.com.souzacode.habitly`. Confira em `android/app/build.gradle` (ou `.kts`) antes do primeiro AAB.

## Próximos passos
1. Gerar `mobile/android/` com o comando `flutter create` acima e conferir o applicationId
2. Schema do PostgreSQL
3. Endpoints da API
4. Deploy no Dokploy via bot Assistente Habitly
