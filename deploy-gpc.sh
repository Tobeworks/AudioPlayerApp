#!/bin/bash

# Setze Fehlererkennung
set -e

# Umgebungsvariablen
PROJECT_ID="tw-01-382310"
REGION="europe-west4"
SERVICE_NAME="logicmoonaudioplayer"
API_URL="https://twapi1-358632560159.europe-west6.run.app"

# Projekt und Region setzen
echo "Setting project and region..."
gcloud config set project $PROJECT_ID
gcloud config set run/region $REGION

# Build und Deploy
echo "Deploying to Cloud Run..."
gcloud run deploy $SERVICE_NAME \
  --source . \
  --set-env-vars "PUBLIC_API_BASE_URL=https://twapi1-358632560159.europe-west6.run.app" \

# Deployment verifizieren
echo "Verifying deployment..."
gcloud run services describe $SERVICE_NAME --platform managed

echo "Deployment complete! Service URL:"
gcloud run services describe $SERVICE_NAME --format='value(status.url)'