#!/bin/bash -e

export CURR_JOB="$1"
export HUB_ORG="374168611083.dkr.ecr.us-east-1.amazonaws.com"
export GH_ORG="Shippable"
export RES_GH_SSH="shipit_gh_ssh"

export UP_TAG_NAME="master"
export IMAGE_NAME="$2"
export SKIP_REPO_TAG="$3"

export RES_VER="prod_release"
export RES_VER_DATE=$(date +"%A, %b %d %Y")
export RES_IMAGE=$2"_img"
export RES_REPO="admiral_repo"
export SSH_PATH="git@github.com:$GH_ORG/admiral.git"

export RES_VER_NAME=$(shipctl get_resource_version_name $RES_VER)

set_context() {
  export PULL_IMG=$HUB_ORG/$IMAGE_NAME:$UP_TAG_NAME
  export PUSH_IMG=$HUB_ORG/$IMAGE_NAME:$RES_VER_NAME
  export PUSH_LAT_IMG=$HUB_ORG/$IMAGE_NAME:latest

  pushd $(shipctl get_resource_meta $RES_IMAGE)
    export IMG_REPO_COMMIT_SHA=$(jq -r '.version.propertyBag.IMG_REPO_COMMIT_SHA' version.json)
  popd

  echo "CURR_JOB=$CURR_JOB"
  echo "IMAGE_NAME=$IMAGE_NAME"
  echo "RES_IMAGE=$RES_IMAGE"
  echo "RES_VER=$RES_VER"
  echo "RES_REPO=$RES_REPO"
  echo "RES_GH_SSH=$RES_GH_SSH"
  echo "GH_ORG=$GH_ORG"
  echo "SSH_PATH=$SSH_PATH"
  echo "HUB_ORG=$HUB_ORG"
  echo "UP_TAG_NAME=$UP_TAG_NAME"

  echo "RES_VER_NAME=$RES_VER_NAME"

  echo "IMG_REPO_COMMIT_SHA=$IMG_REPO_COMMIT_SHA"
  echo "PULL_IMG=$PULL_IMG"
  echo "PUSH_IMG=$PUSH_IMG"
}

add_ssh_key() {
 pushd $(shipctl get_resource_meta $RES_GH_SSH)
   echo "Extracting AWS PEM"
   echo "-----------------------------------"
   cat "integration.json"  | jq -r '.privateKey' > gh_ssh.key
   chmod 600 gh_ssh.key
   ssh-add gh_ssh.key
   echo "Completed Extracting AWS PEM"
   echo "-----------------------------------"
 popd
}

pull_tag_image() {
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

tag_push_repo() {
  if [ -n "$SKIP_REPO_TAG" ]; then
    return
  fi
  pushd $(shipctl get_resource_state $RES_REPO)
    git remote add up $SSH_PATH
    git remote -v
    git checkout master

  # don't checkout the sha here as we are going to edit and we might hit merge
  # conflicts. master should typically not change an also implementing lock on
  # release also will reduce this. Hence this is an acceptable risk

    git pull --tags

    if git tag -d $RES_VER_NAME; then
      git push --delete up $RES_VER_NAME
    fi

    local version_file="version.txt"
    echo $RES_VER_NAME > $version_file

  # prepare release notes
    local template_file="releaseNotes/template.md"
    local master_notes="releaseNotes/master.md"
    local new_notes="releaseNotes/$RES_VER_NAME.md"
    shipctl replace $master_notes
    cp $master_notes $new_notes
    cp $template_file $master_notes

    git add .
    git commit -m "updating version.txt to $RES_VER_NAME and adding release notes" || true

    git push up master
    IMG_REPO_COMMIT_SHA=$(git rev-parse HEAD)

    git tag $RES_VER_NAME
    git push up $RES_VER_NAME
  popd
}

create_out_state() {
  echo "Creating a state file for $CURR_JOB"
  echo versionName=$RES_VER_NAME > "$JOB_STATE/$CURR_JOB.env"
  if [ -z "$SKIP_REPO_TAG" ]; then
    echo IMG_REPO_COMMIT_SHA=$IMG_REPO_COMMIT_SHA >> "$JOB_STATE/$CURR_JOB.env"
  fi
}

main() {
  eval `ssh-agent -s`
  ps -eaf | grep ssh
  which ssh-agent

  set_context
  add_ssh_key
  pull_tag_image
  tag_push_repo
  create_out_state
}

main
