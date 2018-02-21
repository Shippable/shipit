#!/bin/bash -e

# Input parameters
export ARCHITECTURE="$1"
export OS="$2"
export RES_VER=$3
export ARCHIVE_EXTENSION=$4

export ARTIFACTS_BUCKET="s3://shippable-artifacts"

export RES_VER_NAME=$(shipctl get_resource_version_name $RES_VER)

# Source path
export FROM_VERSION=master
export S3_BUCKET_FROM_PATH="$ARTIFACTS_BUCKET/reports/$FROM_VERSION/reports-$FROM_VERSION-$ARCHITECTURE-$OS.$ARCHIVE_EXTENSION"

# Destination path
export TO_VERSION="$RES_VER_NAME"
export S3_BUCKET_TO_PATH="$ARTIFACTS_BUCKET/reports/$TO_VERSION/reports-$TO_VERSION-$ARCHITECTURE-$OS.$ARCHIVE_EXTENSION"

check_input() {
  if [ -z "$ARCHITECTURE" ]; then
    echo "Missing input parameter ARCHITECTURE"
    exit 1
  fi

  if [ -z "$OS" ]; then
    echo "Missing input parameter OS"
    exit 1
  fi

  if [ -z "$ARTIFACTS_BUCKET" ]; then
    echo "Missing input parameter ARTIFACTS_BUCKET"
    exit 1
  fi

  if [ -z "$ARCHIVE_EXTENSION" ]; then
    echo "Missing input parameter ARCHIVE_EXTENSION"
    exit 1
  fi
}

copy_artifact() {
  echo "Copying from $S3_BUCKET_FROM_PATH to $S3_BUCKET_TO_PATH"
  aws s3 cp --acl public-read "$S3_BUCKET_FROM_PATH" "$S3_BUCKET_TO_PATH"
}

main() {
  check_input
  copy_artifact
}

main
