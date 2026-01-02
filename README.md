# OART: Offline ADS-B Realtime Tracker

OART is a self-hosted, offline-capable ADS-B tracking suite designed for Kubernetes (specifically K3s on Turing Pi 2). It provides high-performance tracking, historical data storage, and spatial analytics even without an internet connection.

## Architecture

- **Decoder**: `readsb` running on a dedicated node with SDR hardware. Optimized with a fixed 49.6dB gain and 60s removal timeouts.
- **Frontend**: `tar1090` for real-time visualization. Supports automatic offline/online map switching and persistent flight tracks.
- **Map Server**: `TileServer GL` serving offline vector/raster tiles.
- **Database**: SpatiaLite-powered historical data storage with an automated ingestion script that groups positions into track sessions.
- **Web Console**: `Datasette` sidecar for browsing and querying historical flight data via SQL.

## Services & Networking

| Service | Purpose | URL |
| :--- | :--- | :--- |
| **Frontend** | Radar Map (tar1090) | [http://10.9.0.22](http://10.9.0.22) |
| **Map Server** | Offline Tile Server | [http://10.9.0.21](http://10.9.0.21) |
| **DB Browser** | SQL Web Console (Datasette) | [http://10.9.0.23](http://10.9.0.23) |
| **Decoder** | Raw SBS/Beast Data | `oart-decoder-svc:30003` |

## Deployment Prerequisites

### Hardware
- **Cluster**: K3s (Turing Pi 2 recommended).
- **SDR Node**: One node must have the RTL-SDR USB stick and label `hardware=sdr`.
- **Storage Nodes**: Nodes with SSDs should have label `disktype=ssd`.

### Data
1. **Map Tiles**: Obtain an `.mbtiles` file and place it in the Map Server's PVC.
2. **Storage**: Cluster must support the `fast-ssd` storage class (e.g., via Longhorn).

## Persistence & Reliability

OART is designed to survive pod restarts and node failures without data loss:
- **Aircraft History**: Tracks are synced from RAM to PVC every few minutes and on shutdown.
- **Statistics**: `graphs1090` data is persisted in `/var/lib/collectd`.
- **Database**: All captured flight paths are stored in a 10Gi SpatiaLite database.
- **Optimized Startup**: Python dependencies are cached on the PV via `initContainers`, ensuring fast recovery after restarts.

## Spatial Intelligence

The database ingestor automatically upgrades the schema to support geographic analytics:
- **Geometries**: Positions are stored as SpatiaLite `Point` objects.
- **Track Sessions**: Consecutive messages from the same ICAO are grouped into unique `track_id`s based on a 15-minute inactivity window.
- **Querying**: Use the DB Browser to run spatial queries (e.g., "Find all flights that entered a specific radius").

## Installation

1. **Apply Manifests**:
   ```bash
   kubectl apply -f k8s/config/configmaps.yaml
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

- **Decoder**: Edit `k8s/decoder/deployment.yaml` to adjust `READSB_LAT/LON` and `READSB_GAIN`.
- **UI Settings**: `tar1090` timeouts and professional features (like range outlines) are configured via `TAR1090_CONFIGJS_APPEND` in the frontend deployment.