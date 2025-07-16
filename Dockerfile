# Stage 1: Build the Next.js app
FROM node:18-alpine AS builder

WORKDIR /app

# Install dependencies
COPY package*.json ./
RUN npm install

# Copy app source code
COPY . .

# Build the Next.js app
RUN npm run build

# Stage 2: Run the app in production mode
FROM node:18-alpine

WORKDIR /app

# Copy only the necessary files from the builder
COPY --from=builder /app ./

# Set environment to production
ENV NODE_ENV=production

# Expose the port the app runs on
EXPOSE 3000

# Run the app using next start
CMD ["npm", "run", "start"]
