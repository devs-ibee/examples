#!/usr/bin/env bash
# Mount an IBEE Object Storage bucket as a local directory with s3fs.
#
# Usage:   sudo -E bash mount-filesystem.sh <bucket> <mount-point>
# Requires: Linux with s3fs (Ubuntu/Debian: apt-get install s3fs)
# Environment:
#   IBEE_WORKSPACE_ID          workspace ID (part of the S3 endpoint)
#   IBEE_S3_ACCESS_KEY_ID      access key with read/write access to the bucket
#   IBEE_S3_SECRET_ACCESS_KEY  its secret access key
#   PERSIST=1                  also add the mount to /etc/fstab so it survives reboots
#
# Object Storage is not a POSIX filesystem. Mounts suit sequential reads and
# whole-file writes; avoid databases and workloads that need file locking.
set -euo pipefail

BUCKET="${1:?usage: mount-filesystem.sh <bucket> <mount-point>}"
MOUNT_POINT="${2:?usage: mount-filesystem.sh <bucket> <mount-point>}"
ENDPOINT="https://${IBEE_WORKSPACE_ID}.blob.ibeestorage.com"
PASSWD_FILE="/etc/passwd-s3fs-${BUCKET}"

if ! command -v s3fs >/dev/null; then
  apt-get update -y && apt-get install -y s3fs
fi

umask 077
printf '%s:%s\n' "$IBEE_S3_ACCESS_KEY_ID" "$IBEE_S3_SECRET_ACCESS_KEY" >"$PASSWD_FILE"
mkdir -p "$MOUNT_POINT"

OPTIONS="url=${ENDPOINT},use_path_request_style,passwd_file=${PASSWD_FILE},allow_other,_netdev"
s3fs "$BUCKET" "$MOUNT_POINT" -o "$OPTIONS"
echo "Mounted s3://$BUCKET at $MOUNT_POINT"

if [[ "${PERSIST:-}" == "1" ]] && ! grep -q " ${MOUNT_POINT} fuse.s3fs " /etc/fstab; then
  echo "${BUCKET} ${MOUNT_POINT} fuse.s3fs ${OPTIONS} 0 0" >>/etc/fstab
  echo "Added $MOUNT_POINT to /etc/fstab"
fi

# Unmount with: umount "$MOUNT_POINT"
