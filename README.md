# OART: Offline ADS-B Realtime Tracker

OART is a self-hosted, offline-capable ADS-B tracking suite designed for Kubernetes (specifically K3s on Turing Pi 2).

## Architecture

- **Decoder**: `readsb` running on a specific node with SDR hardware.
- **Frontend**: `tar1090` for visualization.
- **Map Server**: `TileServer GL` to serve offline maps.
- **Database**: SpatiaLite for historical data storage.

## Deployment Prerequisites

### Hardware
- **Cluster**: K3s (Turing Pi 2 recommended).
- **SDR Node**: One node must have the RTL-SDR USB stick and label `hardware=sdr`.
- **Storage Nodes**: Nodes with SSDs should have label `disktype=ssd`.

### Data
1. **Map Tiles**: You must obtain an `.mbtiles` file (e.g., from [OpenMapTiles](https://openmaptiles.org/)) and place it in the location expected by the Map Server (controlled via PVC or ConfigMap, currently defaults to internal paths which need adjustment for real usage).

## Installation

1. **Apply Manifests**:
   ```bash
   kubectl apply -f k8s/config/configmaps.yaml
   kubectl apply -f k8s/decoder/service.yaml
   kubectl apply -f k8s/decoder/deployment.yaml
   kubectl apply -f k8s/map-server/deployment.yaml
   kubectl apply -f k8s/frontend/deployment.yaml
   kubectl apply -f k8s/database/deployment.yaml
   ```

2. **Verify**:
   ```bash
   kubectl get pods -o wide
   kubectl get svc
   ```

## Configuration

- **Decoder**: Edit `k8s/decoder/deployment.yaml` to adjust lat/lon/gain.
- **Map Region**: Edit `k8s/config/configmaps.yaml` (map-config) to point to your specific `.mbtiles` file.
