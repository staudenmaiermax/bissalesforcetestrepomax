#!/bin/bash

# Exit on error
set -euo pipefail

check_changed_submodule() {
   echo $(git diff-tree --no-commit-id --name-only -r HEAD | grep '^packages/' | cut -d'/' -f1-2)
}

verify_submodule_change() {
   if [ -z "$1" ] || [ "$1" == "null" ]; then
      echo "No submodule commited. Exiting with 0."
      exit 0
   fi
   echo "Changed submodule detected: $1"
}

verify_submodule_is_sfdx_project() {
   # navigate to submodule
   # assert that sfdx-project.json exists
   # exit with error code and helpful message, if it doesn't
   exit 0
}

get_package_id_from_changed_submodule() {
   packageName=$(jq -r '.packageDirectories[] | select(.path == "src/packaged") | .package' "$1/sfdx-project.json")
   echo $(jq -r --arg package "$packageName" '.packageAliases[$package]' "$1/sfdx-project.json")
}

verify_package_id_extract() {
   if [ -z "$1" ] || [ "$1" == "null" ]; then
      echo "Failed to extract valid package id from commited package."
      exit 101
   fi
   if [[ "$1" != 0Ho* ]]; then
      echo "Unexpected format for extracted package id: $1. Something wrong with sfdx-project.json?"
      exit 102
   fi
   echo "Package Id: $1"
}

extract_package_version_literal() {
   rawVersionNumberLiteral=$(jq -r '.packageDirectories[] | select(.path == "src/packaged") | .versionNumber' "$1/sfdx-project.json")
   echo ${rawVersionNumberLiteral:0:${#rawVersionNumberLiteral}-5}
}

verify_package_version_literal() {
   echo "Identified package version: $1"
   if [ -z "$1" ] || [ "$1" == "null" ]; then
      echo "Failed to read package version number from sfdx-project.json."
      exit 104
   fi
}

query_package_subscriber_id() {
   sf data query --use-tooling-api --json --query "$1" --target-org "$2" | jq -r '.result.records[0].SubscriberPackageVersionId' 2> /dev/null
}

build_subscriber_version_query() {
   IFS='.' read -ra versionArray <<< "$2"
   # line breaks for readability. Asserts rely on WHERE clause in single line
   echo "SELECT SubscriberPackageVersionId \ 
      FROM Package2Version \
      WHERE \
         Package2Id = '$1' AND MajorVersion = ${versionArray[0]} AND MinorVersion = ${versionArray[1]} AND PatchVersion = ${versionArray[2]} AND IsReleased = true"
}

verify_subscriber_package_id() {
   if [ -z "$1" ] || [ "$1" == "null" ]; then
      echo "Failed to get subscriberVersionId. Is there already a released package version?"
      exit 102
   fi
   if [[ "$1" != 04t* ]]; then
      echo "Unexpected format for subscriberVersionId $1"
      exit 103
   fi
   echo "Subscriber Package Id: $subscriberVersionId"
}

parameter_verification() {
   export PARAM_SUBSCRIBER_VERSION_EXPORT="$subscriberVersionId"
   export PARAM_DEVHUB_ORG="admin-salesforce@mobilityhouse.com"

   # Check if PARAM_DEVHUB_ORG is set correctly
   if [ -z "$PARAM_DEVHUB_ORG" ] || [ "$PARAM_DEVHUB_ORG" == "null" ]; then
      echo "There is no DevHub Org parameter"
      exit 201
   fi

   # Check if PARAM_SUBSCRIBER_VERSION_EXPORT is set correctly
   if [ -z "$PARAM_SUBSCRIBER_VERSION_EXPORT" ] || [ "$PARAM_SUBSCRIBER_VERSION_EXPORT" == "null" ]; then
      echo "There is no subscriber version export parameter"
      exit 202
   fi
}

main() {
   changedSubmodule=$(check_changed_submodule)
   verify_submodule_change "$changedSubmodule"
   packageId=$(get_package_id_from_changed_submodule "$changedSubmodule")
   verify_package_id_extract "$packageId"
   versionLiteral=$(extract_package_version_literal $changedSubmodule)
   verify_package_version_literal $versionLiteral
   toolingApiQuery=$(build_subscriber_version_query $packageId $versionLiteral)
   echo "Running query ...: $toolingApiQuery"
   subscriberVersionId=$(query_package_subscriber_id $toolingApiQuery $PARAM_DEVHUB_ORG)
   verify_subscriber_package_id $subscriberVersionId
   # parameter_verification
}

ORB_TEST_ENV="bats-core"
if [ "${0#*"$ORB_TEST_ENV"}" == "$0" ]; then
   main
fi
