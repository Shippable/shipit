#!/bin/bash -e

export ARCHIVES_LIST="$1"
export ARCHIVE_EXTENSION="$2"
export RES_VER="prod_release"
export FROM_VERSION="master"
export ARTIFACTS_BUCKET="s3://shippable-artifacts"

set_context() {
  export TO_VERSION=$(shipctl get_resource_version_name $RES_VER)

  echo ""
  echo "============= Begin info for JOB $CURR_JOB======================"
  echo "RES_VER=$RES_VER"
  echo "TO_VERSION=$TO_VERSION"
  echo "FROM_VERSION=$FROM_VERSION"
  echo "ARTIFACTS_BUCKET=s3://shippable-artifacts"
  echo "ARCHIVE_EXTENSION=$ARCHIVE_EXTENSION"
  echo "ARCHIVES_LIST=$ARCHIVES_LIST"
  echo "============= End info for JOB $CURR_JOB======================"
  echo ""
}

process_archives() {
  for archive in `cat $ARCHIVES_LIST`; do
    export CONTEXT=$archive
    export S3_BUCKET_FROM_PATH="$ARTIFACTS_BUCKET/$CONTEXT/$FROM_VERSION/$CONTEXT-$FROM_VERSION.$ARCHIVE_EXTENSION"
    export S3_BUCKET_TO_PATH="$ARTIFACTS_BUCKET/$CONTEXT/$TO_VERSION/$CONTEXT-$TO_VERSION.$ARCHIVE_EXTENSION"

    echo ""
    echo "============= Begin info for CONTEXT $CONTEXT======================"
    echo "CONTEXT=$CONTEXT"
    echo "S3_BUCKET_FROM_PATH=$S3_BUCKET_FROM_PATH"
    echo "S3_BUCKET_TO_PATH=$S3_BUCKET_TO_PATH"
    echo "============= End info for CONTEXT $CONTEXT======================"
    echo ""

    echo "Copying from $S3_BUCKET_FROM_PATH to $S3_BUCKET_TO_PATH"
    aws s3 cp --acl public-read "$S3_BUCKET_FROM_PATH" "$S3_BUCKET_TO_PATH"
  done
}

main() {
  set_context
  process_archives
}

main
