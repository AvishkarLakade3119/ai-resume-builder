FROM node:18-alpine

WORKDIR /app

COPY . .

# Removed COPY .env .env because .env is not committed to repo

RUN npm install
RUN npm run build

EXPOSE 3000

CMD ["npm", "start"]
