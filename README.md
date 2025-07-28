# Gunbot Docker Image

This repository provides an automated Docker image that allows you to run the [Gunbot](https://gunbot.com) trading bot in a Docker container.

## Features

- **Automatic Version Management**: Automatic detection and building of the latest Gunbot version through GitHub Actions
- **Node.js Integration**: Includes Node.js 18.x and PM2 required for Gunbot execution
- **Data Persistence**: Configuration files and logs are separated into volumes and preserved during container restarts
- **Process Management**: Optional process management through PM2 (automatic restart, log management)
- **Security**: Runs as non-root user
- **Easy Management**: Simple deployment through Docker Compose
- **CI/CD**: Automated build and Docker Hub deployment through GitHub Actions

## Quick Start

### 1. Using Docker Compose (Recommended)

```bash
# Run latest version
docker-compose up -d

# GUI access: http://localhost:3001
```

### 2. Direct Docker Execution

```bash
# Latest version
docker run -d -p 3001:3001 -p 5001:5001 -v gunbot_data:/data riemannulus/gunbot:latest

# Specific version (e.g., 30.4.4)
docker run -d -p 3001:3001 -p 5001:5001 -v gunbot_data:/data riemannulus/gunbot:30.4.4
```

### 3. Using PM2 Process Management

```bash
# Enable PM2
docker run -d -p 3001:3001 -p 5001:5001 -e USE_PM2=true -v gunbot_data:/data gunthy/gunbot:latest

# Or uncomment USE_PM2=true in docker-compose.yml
```

## Access

- **GUI**: http://localhost:3001 (or the port mapped in docker-compose.yml)
- **WebSocket**: localhost:5001

## Data Management

### Volume Structure

```
/data/
├── config/           # Configuration files
│   ├── config.js
│   ├── autoconfig.json
│   ├── UTAconfig.json
│   └── server.cert
├── json/            # JSON output and logs
└── logs/            # Log files
```

### Configuration File Access

```bash
# Access container interior
docker exec -it gunthy bash

# Check volume data
docker volume ls
docker volume inspect gunthy_gunthy_data

# Direct configuration file editing (from host)
docker cp gunthy:/data/config/config.js ./config.js
# After editing, copy back
docker cp ./config.js gunthy:/data/config/config.js
docker restart gunthy
```

## Automatic Version Management

### GitHub Actions Automated Build

This repository uses GitHub Actions to automatically detect the latest Gunbot version and build Docker images:

- **Scheduled Build**: Automatically runs daily at 15:00 KST (UTC 06:00)
- **Version Detection**: Automatically extracts the latest version from [Gunbot download page](https://gunbot.com/downloads/)
- **Duplicate Prevention**: Skips build if the version already exists on Docker Hub
- **Automatic Deployment**: Automatically pushes to Docker Hub when new version is detected

### Available Tags

- `riemannulus/gunthy:latest` - Latest version
- `riemannulus/gunthy:30.4.4` - Specific version (example)
- `riemannulus/gunthy:30.4.3` - Previous versions

### Upgrade

```bash
# Pull latest image
docker-compose pull

# Restart container (data is preserved)
docker-compose up -d
```

## Docker Compose Configuration

Key configuration options in `docker-compose.yml`:

```yaml
services:
  gunthy:
    image: riemannulus/gunthy:latest  # Pull from Docker Hub
    # build:  # Uncomment for local build
    #   context: .
    #   dockerfile: Dockerfile
    ports:
      - "3001:3001"  # GUI port
      - "5001:5001"  # WebSocket port
    volumes:
      - gunthy_data:/data  # Data persistence
    environment:
      - TZ=Asia/Seoul  # Timezone
      # - USE_PM2=true  # Use PM2 process management
```

## Troubleshooting

### Check Logs

```bash
# Check container logs
docker logs gunthy

# Real-time log stream
docker logs -f gunthy

# Check Gunbot internal logs
docker exec gunthy ls -la /data/logs/

# Check PM2 logs when running with PM2
docker exec gunthy gosu gunthy pm2 logs
docker exec gunthy gosu gunthy pm2 status
```

### Permission Issues

```bash
# Reset data directory permissions
docker exec gunthy chown -R gunthy:gunthy /data
```

### Port Conflicts

```bash
# Check ports in use
netstat -tulpn | grep :3001

# Map to different port in docker-compose.yml
ports:
  - "8080:3001"  # Use host port 8080
```

## Development/Customization

### Local Build

```bash
# Clone current repository
git clone https://github.com/your-username/gunbot-docker.git
cd gunbot-docker

# Local build
docker build -t my-gunbot:latest .

# Use local build in docker-compose
# Comment out image line and uncomment build line in docker-compose.yml
docker-compose up -d --build
```

### GitHub Actions Configuration

To automatically deploy to Docker Hub, set the following secrets:

- `DOCKER_USERNAME`: Docker Hub username
- `DOCKER_PASSWORD`: Docker Hub access token

### System Requirements

- **Node.js**: 18.x (Official Gunbot recommendation)
- **PM2**: Process management (optional)
- **Architecture**: x86_64 (amd64)
- **GitHub Actions**: Automated build and deployment

### Environment-specific Configuration

```bash
# Development
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d

# Production
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

## Security Considerations

- Container runs as non-root user (`gunthy`)
- Important configuration files are separated into volumes
- To restrict network access, adjust Docker network settings

## License

This Docker configuration is open source, but Gunbot itself requires a commercial license.
For details, refer to the [official Gunbot website](https://gunbot.com).

## Support

- [Docker Hub Repository](https://hub.docker.com/r/gunthy/gunbot)
- [GitHub Repository](https://github.com/your-username/gunbot-docker)
- [Official Gunbot Documentation](https://gunbot.com/support/)
- [Gunbot Community](https://gunbot.com/community/)

## Contributing

- Please report issues or improvements through GitHub Issues
- Pull Requests are always welcome
- GitHub Actions workflow improvement suggestions are also welcome

## Automated Deployment Status

![Docker Build](https://github.com/your-username/gunbot-docker/workflows/Build%20and%20Push%20Gunbot%20Docker%20Image/badge.svg)
![Docker Hub](https://img.shields.io/docker/pulls/gunthy/gunbot)
![GitHub Release](https://img.shields.io/github/v/release/your-username/gunbot-docker) 