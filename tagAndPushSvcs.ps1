``$ErrorActionPreference = "Stop"

$HUB_ORG = "$($args[0])"
$GH_ORG = "$($args[1])"
$SVCS_LIST = "$($args[2])"
$CURR_JOB = "$($args[3])"
$IMG_SKIP = "$($args[4])"
$RES_GH_SSH = "shipit_gh_ssh"
$RES_VER = "prod_release"
$UP_TAG_NAME = "master"

# exec_exe executes an exe program and throws a powershell exception if it fails
# $ErrorActionPreference = "Stop" catches only cmdlet exceptions
# Hence exit status of exe programs need to be wrapped and thrown as exception
Function exec_exe([string]$cmd) {
  $global:LASTEXITCODE = 0;
  Invoke-Expression $cmd
  $ret = $LASTEXITCODE
  if ($ret -ne 0) {
    $msg = "$cmd exited with $ret"
    throw $msg
  }
}

Function set_job_context() {
  $RES_VER_NAME = $(shipctl get_resource_version_name $RES_VER)

  echo ""
  echo "============= Begin info for JOB $CURR_JOB======================"
  echo "CURR_JOB=$CURR_JOB"
  echo "RES_VER=$RES_VER"
  echo "RES_VER_NAME=$RES_VER_NAME"
  echo "UP_TAG_NAME=$UP_TAG_NAME"
  echo "RES_GH_SSH=$RES_GH_SSH"
  echo "HUB_ORG=$HUB_ORG"
  echo "GH_ORG=$GH_ORG"
  echo "============= End info for JOB $CURR_JOB======================"
  echo ""

  echo "Creating a state file for $CURR_JOB"
  shipctl post_resource_state $CURR_JOB versionName $RES_VER_NAME
}

Function add_ssh_key() {
  pushd $(shipctl get_resource_meta $RES_GH_SSH)
    echo "Extracting GH SSH Key"
    echo "-----------------------------------"
    # TODO: Add SSH key for accessing github
    echo "Completed Extracting GH SSH Key"
    echo "-----------------------------------"
  popd
}

Function pull_tag_image() {
  $script:IMAGE_NAME = $CONTEXT_IMAGE
  $script:RES_IMAGE = "${CONTEXT}_img"
  $script:PULL_IMG = "${HUB_ORG}/${IMAGE_NAME}:${UP_TAG_NAME}"
  $script:PUSH_IMG = "${HUB_ORG}/${IMAGE_NAME}:${RES_VER_NAME}"
  $script:PUSH_LAT_IMG = "${HUB_ORG}/${IMAGE_NAME}:latest"

  echo ""
  echo "============= Begin info for IMG $RES_IMAGE======================"
  echo "IMAGE_NAME=$IMAGE_NAME"
  echo "RES_IMAGE=$RES_IMAGE"
  echo "PULL_IMG=$PULL_IMG"
  echo "PUSH_IMG=$PUSH_IMG"
  echo "============= End info for IMG $RES_IMAGE======================"
  echo ""

  echo "Starting Docker tag and push for $IMAGE_NAME"
  docker pull $PULL_IMG

  echo "Tagging $PUSH_IMG"
  docker tag $PULL_IMG $PUSH_IMG

  echo "Tagging $PUSH_LAT_IMG"
  docker tag $PULL_IMG $PUSH_LAT_IMG

  echo "Pushing $PUSH_IMG"
  docker push $PUSH_IMG
  echo "Completed Docker tag & push for $PUSH_IMG"

  echo "Pushing $PUSH_LAT_IMG"
  docker push $PUSH_LAT_IMG
  echo "Completed Docker tag & push for $PUSH_LAT_IMG"

  echo "Completed Docker tag and push for $IMAGE_NAME"
}

Function tag_push_repo() {
  $script:SSH_PATH = "git@github.com:${GH_ORG}/${CONTEXT_REPO}.git"
  $script:RES_REPO = "${CONTEXT}_repo"

  $script:RES_REPO_META = $(shipctl get_resource_meta $RES_REPO)
  $script:RES_REPO_STATE = $(shipctl get_resource_state $RES_REPO)

  echo ""
  echo "============= Begin info for REPO $RES_REPO======================"
  echo "SSH_PATH=$SSH_PATH"
  echo "RES_REPO=$RES_REPO"
  echo "RES_REPO_META=$RES_REPO_META"
  echo "RES_REPO_STATE=$RES_REPO_STATE"
  echo "IMG_REPO_COMMIT_SHA=$IMG_REPO_COMMIT_SHA"
  echo "============= End info for REPO $RES_REPO======================"
  echo ""

  pushd $RES_REPO_META
    $script:IMG_REPO_COMMIT_SHA = $(shipctl get_json_value version.json 'version.propertyBag.shaData.commitSha')
  popd

  pushd $RES_REPO_STATE
    git remote add up $SSH_PATH
    git remote -v
    git checkout master

    git pull --tags
    git checkout $IMG_REPO_COMMIT_SHA

    $global:LASTEXITCODE = 0;
    Invoke-Expression "git tag -d $RES_VER_NAME"
    $ret = $LASTEXITCODE
    if ($ret -eq 0) {
      echo "Removing existing tag"
      git push --delete up $RES_VER_NAME
    }

    echo "Tagging repo with $RES_VER_NAME"
    git tag $RES_VER_NAME
    echo "Pushing tag $RES_VER_NAME"
    git push up $RES_VER_NAME
  popd

  shipctl put_resource_state $CURR_JOB $CONTEXT"_COMMIT_SHA" $IMG_REPO_COMMIT_SHA
}

Function process_services() {
  foreach($c in Get-Content $SVCS_LIST) {
    $script:CONTEXT = $c
    $script:CONTEXT_IMAGE = $c
    $script:CONTEXT_REPO = $c

    echo ""
    echo "============= Begin info for CONTEXT $CONTEXT======================"
    echo "CONTEXT=$CONTEXT"
    echo "CONTEXT_IMAGE=$CONTEXT_IMAGE"
    echo "CONTEXT_REPO=$CONTEXT_REPO"
    echo "============= End info for CONTEXT $CONTEXT======================"
    echo ""

    if ([string]::IsNullOrEmpty("$IMG_SKIP")) {
      pull_tag_image
    }

    tag_push_repo
  }
}

Function main() {
  set_job_context
  add_ssh_key
  process_services
}

main
