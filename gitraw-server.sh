#!/bin/bash

# Stop any Docker containers that may conflict on port 8000
conflicting_containers=$(docker ps --filter "publish=8000" -q)
for container in $conflicting_containers; do
    echo "Stopping conflicting container: $container"
    docker stop $container
    docker rm $container
done

# Create server.py script
cat > server.py <<EOF
from fastapi import FastAPI
import requests

app = FastAPI()

@app.get("/{user}/{repo}/{branch}/{filepath:path}")
async def read_file_from_github(user: str, repo: str, branch: str, filepath: str):
    url = f"https://raw.githubusercontent.com/{user}/{repo}/{branch}/{filepath}"
    response = requests.get(url)
    return response.text
EOF

# Create requirements.txt
cat > requirements.txt <<EOF
fastapi
uvicorn[standard]
requests
EOF

# Create Dockerfile
cat > Dockerfile <<EOF
FROM python:3.8

WORKDIR /app

COPY requirements.txt /app/
RUN pip install --no-cache-dir -r requirements.txt

COPY server.py /app/

CMD ["uvicorn", "server:app", "--host", "0.0.0.0", "--port", "80"]
EOF

# Create Docker Compose file
cat > docker-compose.yml <<EOF
version: '3.8'
services:
  gitraw-server:
    build: .
    ports:
      - "8000:80"
    restart: unless-stopped
EOF

# Build and run with Docker Compose
docker compose build
docker compose up -d

# Optional: Test the setup
echo "Testing the setup..."
sleep 1  # Wait briefly for the server to start
curl -f "http://localhost:8000/m-c-frank/apimesh/main/gitraw-server.sh"

