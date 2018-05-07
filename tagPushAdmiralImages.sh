#!/bin/bash -e

export CURR_JOB="$1"
export HUB_ORG="374168611083.dkr.ecr.us-east-1.amazonaws.com"

export UP_TAG_NAME="master"
export RES_VER="prod_release"

export RES_VER_NAME=$(shipctl get_resource_version_name $RES_VER)

set_context() {
  if [[ $# -gt 0 ]]; then
    echo "Images: $@"
  else
    echo "Images should be passed as arguments"
  fi

  echo "CURR_JOB=$CURR_JOB"
  echo "RES_VER=$RES_VER"
  echo "HUB_ORG=$HUB_ORG"
  echo "UP_TAG_NAME=$UP_TAG_NAME"
  echo "RES_VER_NAME=$RES_VER_NAME"
}

pull_tag_push_image() {
  local IMAGE_NAME="$1"

  local PULL_IMG=$HUB_ORG/$IMAGE_NAME:$UP_TAG_NAME
  local PUSH_IMG=$HUB_ORG/$IMAGE_NAME:$RES_VER_NAME
  local PUSH_LAT_IMG=$HUB_ORG/$IMAGE_NAME:latest

  echo "PULL_IMG=$PULL_IMG"
  echo "PUSH_IMG=$PUSH_IMG"
  echo "IMAGE_NAME=$IMAGE_NAME"

  echo "Starting Docker tag and push for $IMAGE_NAME"
  sudo docker pull $PULL_IMG

  echo "Tagging $PUSH_IMG"
  sudo docker tag $PULL_IMG $PUSH_IMG

  echo "Tagging $PUSH_LAT_IMG"
  sudo docker tag $PULL_IMG $PUSH_LAT_IMG

  echo "Pushing $PUSH_IMG"
  sudo docker push $PUSH_IMG
  echo "Completed Docker tag & push for $PUSH_IMG"

  echo "Pushing $PUSH_LAT_IMG"
  sudo docker push $PUSH_LAT_IMG
  echo "Completed Docker tag & push for $PUSH_LAT_IMG"

  echo "Completed Docker tag and push for $IMAGE_NAME"
}

main() {
  set_context
  while [[ $# -gt 0 ]]; do
    pull_tag_push_image $1
    shift
  done
}

main
