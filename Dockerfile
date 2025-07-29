FROM ubuntu:22.04

# Build arguments
ARG TARGETARCH=amd64

# Environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV GUNTHY_HOME=/opt/gunthy
ENV GUNTHY_DATA=/data

# Install system dependencies including Node.js
RUN apt-get update && apt-get install -y \
    wget \
    unzip \
    ca-certificates \
    curl \
    gnupg \
    build-essential \
    python3 \
    python3-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js 18.x (following official Gunbot guide)
RUN mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_18.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list && \
    apt-get update && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

# Install PM2 globally for process management
RUN npm install -g pm2 && \
    pm2 install pm2-logrotate

# Create directories
RUN mkdir -p ${GUNTHY_HOME} ${GUNTHY_DATA}

# Create non-root user for security
RUN useradd -r -s /bin/false -d ${GUNTHY_HOME} gunthy && \
    chown -R gunthy:gunthy ${GUNTHY_HOME} ${GUNTHY_DATA}

# Download and install Gunthy
WORKDIR ${GUNTHY_HOME}

# Download and install latest Gunthy
RUN echo "Downloading latest Gunbot version..." && \
    wget -O /tmp/gunthy_linux.zip "https://gunthy.org/downloads/gunthy_linux.zip" && \
    cd ${GUNTHY_HOME} && \
    unzip -q /tmp/gunthy_linux.zip && \
    chmod +x gunthy-linux && \
    rm /tmp/gunthy_linux.zip && \
    echo "Latest Gunbot version installed successfully"

# Verify that config.js exists - fail build if not found
RUN if [ ! -f ${GUNTHY_HOME}/config.js ]; then \
        echo "ERROR: config.js not found in Gunthy installation!" && \
        echo "Available files:" && \
        ls -la ${GUNTHY_HOME}/ && \
        exit 1; \
    fi && \
    echo "config.js found and verified"

# Setup persistent data directory structure
RUN mkdir -p ${GUNTHY_DATA}/config \
             ${GUNTHY_DATA}/json \
             ${GUNTHY_DATA}/logs \
             ${GUNTHY_DATA}/backtesting \
             ${GUNTHY_DATA}/backups \
             ${GUNTHY_DATA}/customStrategies \
             ${GUNTHY_DATA}/gunbot_logs \
             ${GUNTHY_DATA}/database

# Create symlinks for persistent config files  
# Note: Don't move config.js during build - keep it for runtime initialization
RUN if [ -f ${GUNTHY_HOME}/autoconfig.json ]; then \
        mv ${GUNTHY_HOME}/autoconfig.json ${GUNTHY_DATA}/config/ && \
        ln -s ${GUNTHY_DATA}/config/autoconfig.json ${GUNTHY_HOME}/autoconfig.json; \
    fi && \
    if [ -f ${GUNTHY_HOME}/UTAconfig.json ]; then \
        mv ${GUNTHY_HOME}/UTAconfig.json ${GUNTHY_DATA}/config/ && \
        ln -s ${GUNTHY_DATA}/config/UTAconfig.json ${GUNTHY_HOME}/UTAconfig.json; \
    fi && \
    if [ -f ${GUNTHY_HOME}/server.cert ]; then \
        mv ${GUNTHY_HOME}/server.cert ${GUNTHY_DATA}/config/ && \
        ln -s ${GUNTHY_DATA}/config/server.cert ${GUNTHY_HOME}/server.cert; \
    fi

# Create symlinks for persistent directories
RUN ln -sf ${GUNTHY_DATA}/json ${GUNTHY_HOME}/json && \
    ln -sf ${GUNTHY_DATA}/logs ${GUNTHY_HOME}/logs && \
    ln -sf ${GUNTHY_DATA}/backtesting ${GUNTHY_HOME}/backtesting && \
    ln -sf ${GUNTHY_DATA}/backups ${GUNTHY_HOME}/backups && \
    ln -sf ${GUNTHY_DATA}/customStrategies ${GUNTHY_HOME}/customStrategies && \
    ln -sf ${GUNTHY_DATA}/gunbot_logs ${GUNTHY_HOME}/gunbot_logs

# Change ownership
RUN chown -R gunthy:gunthy ${GUNTHY_HOME} ${GUNTHY_DATA}

# Install gosu for proper user switching
RUN ARCH=$(dpkg --print-architecture) && \
    wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/1.17/gosu-${ARCH}" && \
    chmod +x /usr/local/bin/gosu && \
    gosu nobody true

# Create startup script
COPY <<EOF /docker-entrypoint.sh
#!/bin/bash
set -e

# Ensure all required directories exist
mkdir -p ${GUNTHY_DATA}/config
mkdir -p ${GUNTHY_DATA}/json
mkdir -p ${GUNTHY_DATA}/logs
mkdir -p ${GUNTHY_DATA}/backtesting
mkdir -p ${GUNTHY_DATA}/backups
mkdir -p ${GUNTHY_DATA}/customStrategies
mkdir -p ${GUNTHY_DATA}/gunbot_logs
mkdir -p ${GUNTHY_DATA}/database

# Ensure data directory permissions
chown -R gunthy:gunthy ${GUNTHY_DATA}

# Initialize config files if they don't exist
if [ ! -f ${GUNTHY_DATA}/config/config.js ]; then
    echo "Initializing default config.js..."
    if [ -f ${GUNTHY_HOME}/config.js ]; then
        cp ${GUNTHY_HOME}/config.js ${GUNTHY_DATA}/config/config.js
        echo "config.js copied from installation"
    else
        echo "ERROR: config.js not found in ${GUNTHY_HOME}!"
        exit 1
    fi
fi

if [ ! -f ${GUNTHY_DATA}/config/autoconfig.json ]; then
    echo "{}" > ${GUNTHY_DATA}/config/autoconfig.json
fi

if [ ! -f ${GUNTHY_DATA}/config/UTAconfig.json ]; then
    echo "{}" > ${GUNTHY_DATA}/config/UTAconfig.json
fi

# Ensure symlinks exist for config files
[ ! -L ${GUNTHY_HOME}/config.js ] && [ -f ${GUNTHY_DATA}/config/config.js ] && \
    ln -sf ${GUNTHY_DATA}/config/config.js ${GUNTHY_HOME}/config.js

[ ! -L ${GUNTHY_HOME}/autoconfig.json ] && [ -f ${GUNTHY_DATA}/config/autoconfig.json ] && \
    ln -sf ${GUNTHY_DATA}/config/autoconfig.json ${GUNTHY_HOME}/autoconfig.json

[ ! -L ${GUNTHY_HOME}/UTAconfig.json ] && [ -f ${GUNTHY_DATA}/config/UTAconfig.json ] && \
    ln -sf ${GUNTHY_DATA}/config/UTAconfig.json ${GUNTHY_HOME}/UTAconfig.json

[ ! -L ${GUNTHY_HOME}/server.cert ] && [ -f ${GUNTHY_DATA}/config/server.cert ] && \
    ln -sf ${GUNTHY_DATA}/config/server.cert ${GUNTHY_HOME}/server.cert

# Ensure directory symlinks exist
[ ! -L ${GUNTHY_HOME}/json ] && ln -sf ${GUNTHY_DATA}/json ${GUNTHY_HOME}/json
[ ! -L ${GUNTHY_HOME}/logs ] && ln -sf ${GUNTHY_DATA}/logs ${GUNTHY_HOME}/logs
[ ! -L ${GUNTHY_HOME}/backtesting ] && ln -sf ${GUNTHY_DATA}/backtesting ${GUNTHY_HOME}/backtesting
[ ! -L ${GUNTHY_HOME}/backups ] && ln -sf ${GUNTHY_DATA}/backups ${GUNTHY_HOME}/backups
[ ! -L ${GUNTHY_HOME}/customStrategies ] && ln -sf ${GUNTHY_DATA}/customStrategies ${GUNTHY_HOME}/customStrategies
[ ! -L ${GUNTHY_HOME}/gunbot_logs ] && ln -sf ${GUNTHY_DATA}/gunbot_logs ${GUNTHY_HOME}/gunbot_logs

# Create symlinks for SQLite database files and other persistent files
# Pre-create symlinks so files are created in the persistent location
for file in gunbotgui.db new_gui.sqlite state.db state.db-shm state.db-wal bitrage.sqlite bitrage_total_profits.sqlite conversion.json gunbot.pid; do
    # If file exists in GUNTHY_HOME and is not a symlink, move it to persistent storage
    if [ -f ${GUNTHY_HOME}/\$file ] && [ ! -L ${GUNTHY_HOME}/\$file ]; then
        mv ${GUNTHY_HOME}/\$file ${GUNTHY_DATA}/database/
    fi
    # Always create symlink (this ensures new files are created in persistent storage)
    ln -sf ${GUNTHY_DATA}/database/\$file ${GUNTHY_HOME}/\$file
done

# Change to working directory
cd ${GUNTHY_HOME}

# Check if PM2 should be used
if [ "\${USE_PM2}" = "true" ]; then
    echo "Starting Gunbot with PM2..."
    # Switch to gunthy user and start with PM2
    gosu gunthy pm2-runtime start gunthy-linux --name gunthy --log-date-format "YYYY-MM-DD HH:mm:ss Z"
else
    echo "Starting Gunbot directly..."
    # Change to non-root user and start Gunbot directly
    exec gosu gunthy ./gunthy-linux "\$@"
fi
EOF

RUN chmod +x /docker-entrypoint.sh

# Expose ports
EXPOSE 3000 3001 5001

# Set working directory
WORKDIR ${GUNTHY_HOME}

# Volumes for persistent data
VOLUME ["${GUNTHY_DATA}"]

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:3001/health || exit 1

# Set entrypoint
ENTRYPOINT ["/docker-entrypoint.sh"] 