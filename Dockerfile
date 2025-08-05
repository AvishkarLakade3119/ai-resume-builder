FROM node:18-alpine

WORKDIR /app

COPY . .

# Copy .env file into the image
COPY .env .env

RUN npm install
RUN npm run build

EXPOSE 3000

CMD ["npm", "start"]
