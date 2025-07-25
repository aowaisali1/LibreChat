# =========================
# Stage 1: Build Stage
# =========================
FROM node:20-alpine AS builder

# Install required packages
RUN apk add --no-cache python3 py3-pip jemalloc uv

# Use jemalloc for better memory management
ENV LD_PRELOAD=/usr/lib/libjemalloc.so.2

WORKDIR /app

# Improve fetch reliability
RUN npm config set fetch-retry-maxtimeout 600000 \
    && npm config set fetch-retries 5 \
    && npm config set fetch-retry-mintimeout 15000

# Copy package files and install dependencies
COPY package*.json ./
RUN npm install --no-audit

# Optional: install specific tools globally
RUN npm install -g rollup rollup-plugin-typescript2

# Copy the rest of the project
COPY . .

# Ensure all deps are installed (again for monorepo safety)
RUN npm install

# Build the frontend (React)
RUN NODE_OPTIONS="--max-old-space-size=2048" npm run frontend

# Remove dev deps for production image
RUN npm prune --omit=dev && npm cache clean --force


# =========================
# Stage 2: Runtime Stage
# =========================
FROM node:20-alpine

# Use jemalloc in runtime too
RUN apk add --no-cache jemalloc
ENV LD_PRELOAD=/usr/lib/libjemalloc.so.2

WORKDIR /app

# Copy only the built app from builder stage
COPY --from=builder /app /app

# ✅ Now copy librechat.yaml (if not already in project repo root)
COPY librechat.yaml /app/librechat.yaml

# Expose correct backend port (Render needs this!)
EXPOSE 3080

# Ensure Render detects port
ENV PORT=3080
ENV HOST=0.0.0.0
ENV NODE_ENV=production

# Start backend directly
CMD ["node", "api/server/index.js"]
