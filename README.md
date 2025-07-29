# Gunbot Docker Image

This repository provides an automated Docker image that allows you to run the [Gunbot](https://gunbot.com) trading bot in a Docker container.

## Usage

### Quick Start (Recommended)
```bash
# Pull and run from Docker Hub
docker run -d \
  --name gunbot \
  -p 3000:3000 \
  -p 3001:3001 \
  -p 5001:5001 \
  -v $(pwd)/data:/data \
  riemannulus/gunthy

# With PM2 process manager
docker run -d \
  --name gunbot \
  -e USE_PM2=true \
  -p 3000:3000 \
  -p 3001:3001 \
  -p 5001:5001 \
  -v $(pwd)/data:/data \
  riemannulus/gunthy
```

### Build from Source (Optional)
```bash
docker build -t gunbot .
```

### Configuration
- **Data persistence**: Mount `/data` volume to persist configurations, logs, and database files
- **Ports**: 3000 (GUI), 3001 (API), 5001 (WebSocket)
- **Config files**: Place your `config.js` in the data volume at `/data/config/config.js`
- **PM2 mode**: Set `USE_PM2=true` for process management and automatic restarts

### Docker Compose
```yaml
version: '3.8'
services:
  gunbot:
    image: riemannulus/gunthy
    ports:
      - "3000:3000"
      - "3001:3001" 
      - "5001:5001"
    volumes:
      - ./data:/data
    environment:
      - USE_PM2=true
    restart: unless-stopped
```