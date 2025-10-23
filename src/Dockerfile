# ---- Base Stage ----
# Use an official Node.js image.
FROM node:18-alpine AS base
WORKDIR /usr/src/app

# Copy package.json and package-lock.json
COPY package*.json ./

# ---- Dependencies Stage ----
# Install dependencies needed for the build
FROM base AS dependencies
RUN npm install

# ---- Test Stage ----
# Copy app source and run tests
FROM dependencies AS test
COPY . .
RUN npm test

# ---- Build Stage (if you had a build step) ----
# This app doesn't seem to have a build step (like Typescript or React),
# but if it did, it would go here.

# ---- Production Stage ----
# Start fresh from the base image for a clean, small production image
FROM base AS production

# Install *only* production dependencies
RUN npm ci --only=production

# Copy the application code
COPY . .

# Expose the port the app runs on
EXPOSE 3000

# The command to run the application
CMD [ "npm", "start" ]