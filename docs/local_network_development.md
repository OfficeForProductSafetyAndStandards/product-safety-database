# Accessing the Application from Other Devices on Local Network

This document explains how to make the application accessible from other devices on your local network during development.

## Overview

By default, the Rails server in development mode only listens on `127.0.0.1` (localhost), making it inaccessible from other devices. This guide explains how to make the application accessible over your local network.

## Step 1: Start Required Docker Services

First, ensure the required Docker services are running:

```bash
docker compose up antivirus db redis opensearch
```

## Step 2: Start the Rails Server with Network Access

Use one of these commands to start the server:

```bash
# Option 1: Use the Rails wrapper (automatically redirects to network-enabled server)
rails s

# Option 2: Use the bin script
s
# If this doesn't work, run 'export PATH="./bin:$PATH"' to add ./bin to your path.
```

The command will:
1. Automatically detect your local IP address
2. Configure the server to bind to all network interfaces
3. Display the URL to use for accessing from other devices

Example output:
```
========================================================
Starting server accessible from your local network at:
Local access: http://localhost:3000
Network access: http://YOUR_IP_ADDRESS:3000
========================================================
```

## Step 3: Access the Application

You can access the application in two ways:
- From your local machine: `http://localhost:3000`
- From other devices: `http://YOUR_IP_ADDRESS:3000` (using the IP shown in the output)
