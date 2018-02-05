$ErrorActionPreference = "Stop"

$CONTEXT = "$($args[0])"
$HUB_ORG = "$($args[1])"
$RES_VER = "$($args[2])"

$IMAGE_NAME = $CONTEXT
$CURR_JOB = "{0}_tag_push" -f $CONTEXT
$RES_IMAGE = "{0}_img" -f $CONTEXT
$UP_TAG_NAME = "master"
$RES_VER_NAME = $(shipctl get_resource_version_name $RES_VER)

$PULL_IMG = "{0}/{1}:{2}" -f $HUB_ORG, $IMAGE_NAME, $UP_TAG_NAME
$PUSH_IMG = "{0}/{1}:{2}" -f $HUB_ORG, $IMAGE_NAME, $RES_VER_NAME
$PUSH_LAT_IMG = "{0}/{1}:{2}" -f $HUB_ORG, $IMAGE_NAME, "latest"


Function set_context() {

  echo "CONTEXT=$CONTEXT"
  echo "CURR_JOB=$CURR_JOB"
  echo "IMAGE_NAME=$IMAGE_NAME"
  echo "RES_IMAGE=$RES_IMAGE"
  echo "RES_VER=$RES_VER"
  echo "HUB_ORG=$HUB_ORG"
  echo "UP_TAG_NAME=$UP_TAG_NAME"

  echo "RES_VER_NAME=$RES_VER_NAME"
  echo "PULL_IMG=$PULL_IMG"
  echo "PUSH_IMG=$PUSH_IMG"
}

Function pull_tag_image() {
  echo "Starting Docker tag and push for $IMAGE_NAME"
  docker pull "$PULL_IMG"

  echo "Tagging $PUSH_IMG"
  docker tag "$PULL_IMG" "$PUSH_IMG"

  echo "Tagging $PUSH_LAT_IMG"
  docker tag "$PULL_IMG" "$PUSH_LAT_IMG"

  echo "Pushing $PUSH_IMG"
  docker push "$PUSH_IMG"
  echo "Completed Docker tag & push for $PUSH_IMG"

  echo "Pushing $PUSH_LAT_IMG"
  docker push "$PUSH_LAT_IMG"
  echo "Completed Docker tag & push for $PUSH_LAT_IMG"

  echo "Completed Docker tag and push for $IMAGE_NAME"
}

Function create_out_state() {
  echo "Creating a state file for $CURR_JOB"
  $versionString = "versionName={0}" -f $RES_VER_NAME
  $outFile = Join-Path "$JOBSTATE" "$CURR_JOB.env"
  $versionString | Out-File $outFile
}

Function main() {
  set_context
  pull_tag_image
  create_out_state
}

main
