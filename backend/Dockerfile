# Stage 1: Build
FROM node:20-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install all dependencies (including dev)
RUN npm ci

# Copy source code and prisma schema
COPY . .

# Generate Prisma client
RUN npx prisma generate

# Build the application
RUN npm run build

# Stage 2: Production
FROM node:20-alpine

WORKDIR /app

# Install openssl for Prisma
RUN apk add --no-cache openssl

# Copy built assets from builder
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package*.json ./
COPY --from=builder /app/prisma ./prisma
COPY --from=builder /app/prisma.config.ts ./
COPY --from=builder /app/entrypoint.sh ./
COPY --from=builder /app/hr-app-18eef-firebase-adminsdk-fbsvc-0e03f6ece7.json ./

# Make entrypoint executable
RUN apk add --no-cache dos2unix && dos2unix ./entrypoint.sh && chmod +x ./entrypoint.sh

# Expose port
EXPOSE 3000

# Start via entrypoint
ENTRYPOINT ["sh", "./entrypoint.sh"]
