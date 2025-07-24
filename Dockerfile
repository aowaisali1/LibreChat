# =========================
# Stage 1: Build Stage
# =========================
FROM node:20-alpine AS builder

# Install required packages
RUN apk add --no-cache python3 py3-pip jemalloc uv

# Use jemalloc for better memory management
ENV LD_PRELOAD=/usr/lib/libjemalloc.so.2

WORKDIR /app

# Copy package files and install dependencies (no audit for speed)
COPY package*.json ./
RUN npm config set fetch-retry-maxtimeout 600000 \
    && npm config set fetch-retries 5 \
    && npm config set fetch-retry-mintimeout 15000 \
    && npm install --no-audit \
    && npm install rollup -g \
    && npm install mongodb

# Copy entire project
COPY . .

# Build the frontend (React build)
RUN NODE_OPTIONS="--max-old-space-size=2048" npm run frontend \
    && npm prune --production \
    && npm cache clean --force

# =========================
# Stage 2: Runtime Stage
# =========================
FROM node:20-alpine

WORKDIR /app

# Copy build from the builder stage
COPY --from=builder /app /app

# Expose backend port
EXPOSE 3080

# Set host
ENV HOST=0.0.0.0

# Start backend
CMD ["npm", "run", "backend"]
