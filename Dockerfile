# Stage 1: Build the Next.js app
FROM node:18-alpine AS builder

WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

# Stage 2: Run the app using next start (optimized production)
FROM node:18-alpine

WORKDIR /app
COPY --from=builder /app ./
EXPOSE 3000

ENV NODE_ENV production
CMD ["npm", "run", "start"]
<<<<<<< HEAD

=======
>>>>>>> 566103e7681107360bc64131874fc6062e2346d1
