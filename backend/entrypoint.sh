#!/bin/sh
set -e

echo "Deploying Prisma migrations..."
npx prisma migrate deploy

echo "Running seed script..."
npx tsc prisma/seed.ts --target es2022 --module CommonJS --esModuleInterop
node prisma/seed.js

echo "Starting application..."
node dist/main
