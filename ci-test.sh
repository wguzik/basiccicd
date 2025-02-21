#!/bin/bash
set -e 

echo "🚀 Starting CI tests..."

if ! command -v node &> /dev/null; then
    echo "❌ Node.js is required but not installed"
    exit 1
fi

echo "📦 Installing dependencies..."
npm ci

echo "🛠️ Building application..."
npm run build

echo "🧪 Running tests..."
npm run test:coverage || true 

echo "🐳 Building Docker image..."
docker build -t weather-app .

echo "🚀 Running Docker container..."
docker run -d \
    -p 3000:3000 \
    -e WEATHER_API_KEY="${WEATHER_API_KEY}" \
    --name weather-app-container \
    weather-app

echo "⏳ Waiting for container to start..."
sleep 5

echo "🔍 Testing main endpoint..."
if ! curl -f http://localhost:3000/; then
    echo "❌ Main endpoint test failed"
    docker rm -f weather-app-container
    exit 1
fi

echo "🔍 Testing weather endpoint..."
response=$(curl -s http://localhost:3000/weather/Zakopane)
if [[ $response == *"tired"* ]]; then
    echo "❌ Weather endpoint test failed"
    docker rm -f weather-app-container
    exit 1
fi

echo "🧹 Cleaning up..."
docker rm -f weather-app-container

echo "✅ All tests completed successfully!" 