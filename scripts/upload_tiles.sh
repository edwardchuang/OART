#!/bin/bash
set -e

FILE_PATH=$1

if [ -z "$FILE_PATH" ]; then
    echo "Usage: ./scripts/upload_tiles.sh <path_to_mbtiles>"
    exit 1
fi

if [ ! -f "$FILE_PATH" ]; then
    echo "Error: File $FILE_PATH not found."
    exit 1
fi

echo "Starting upload helper pod..."
kubectl run tile-uploader --image=busybox --restart=Never --overrides='
{
  "spec": {
    "containers": [
      {
        "name": "uploader",
        "image": "busybox",
        "command": ["sleep", "3600"],
        "volumeMounts": [
          {
            "mountPath": "/data",
            "name": "tiles-storage"
          }
        ]
      }
    ],
    "volumes": [
      {
        "name": "tiles-storage",
        "persistentVolumeClaim": {
          "claimName": "oart-map-tiles-pvc"
        }
      }
    ],
    "nodeSelector": {
      "disktype": "ssd"
    }
  }
}'

echo "Waiting for pod to be ready..."
kubectl wait --for=condition=Ready pod/tile-uploader --timeout=60s

echo "Uploading $FILE_PATH to PVC..."
kubectl cp "$FILE_PATH" tile-uploader:/data/map.mbtiles

echo "Upload complete. Verifying file size..."
kubectl exec tile-uploader -- ls -lh /data/map.mbtiles

echo "Cleaning up..."
kubectl delete pod tile-uploader

echo "Done! You may need to restart the map-server pods if they were already running:"
echo "kubectl rollout restart deployment oart-map-server"
