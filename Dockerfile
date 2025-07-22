# Dockerfile
FROM node:18-alpine

WORKDIR /app
COPY . .
RUN npm install

# Next.js build and production setup
RUN npm run build

EXPOSE 3000
CMD ["npm", "run", "start"]
