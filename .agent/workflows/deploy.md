---
description: Deploy Backend and Firestore Rules
---

1. Deploy Firestore Security Rules
// turbo
firebase deploy --only firestore:rules

2. Deploy Backend Code (Serverless)
// turbo
cd backend && doppler run -- npx sls deploy
