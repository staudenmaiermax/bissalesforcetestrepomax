#!/bin/bash

# Exit on error
set -euo pipefail

main() {
   # Check if there is a changed submodule
   echo "Skript startet"
   changedSubmodule=$(git diff-tree --no-commit-id --name-only -r HEAD | grep '^packages/' | cut -d'/' -f1-2)
   echo "Erster command durch"
   echo "Changed Submodule: $changedSubmodule"

   # Exit script without errors if no submodule changed
   if [ -z "$changedSubmodule" ]; then
      echo "There is no changed submodule. Exit script without errors." ||
      exit 0
   fi 

   # Get packageId from sfdx-project.json
   packageName=$(jq -r '.packageDirectories[] | select(.path == "src/packaged") | .package' "$changedSubmodule/sfdx-project.json")
   echo "Package Name: $packageName"
   packageId=$(jq -r --arg package "$packageName" '.packageAliases[$package]' "$changedSubmodule/sfdx-project.json")
   echo "Package ID: $packageId"

   # Check if packageId is set correctly
   if [ -z "$packageId" ] || [ "$packageId" == "null" ]; then
      echo "Failed to get packageId from sfdx-project.json from $changedSubmodule."
      exit 101
   fi 

   # Get the package version number
   package_versionRaw=$(jq -r '.packageDirectories[] | select(.path == "src/packaged") | .versionNumber' "$changedSubmodule/sfdx-project.json")
   echo "Package Version Raw: $package_versionRaw"

   # Check if package_versionRaw is set correctly
   if [ -z "$package_versionRaw" ] || [ "$package_versionRaw" == "null" ]; then
      echo "Failed to get package version number from sfdx-project.json from $changedSubmodule."
      exit 104
   fi 

   # Remove last 5 characters (".NEXT")
   if [ ${#package_versionRaw} -le 5 ]; then
      echo "Package version number is too short: $package_versionRaw"
      exit 105
   fi

   versionName=${package_versionRaw::-5}
   echo "Version Name: $versionName"

   cd "$changedSubmodule"

   PARAM_DEVHUB_ORG="admin-salesforce@mobilityhouse.com"

   # Salesforce CLI Command to get latest package version
   # Extract the SubscriberPackageVersionId and save it in a variable
   subscriberVersionId=$(sfdx force:package:version:list --released --json | jq -r '.result[-1].SubscriberPackageVersionId')

   # Output the variable for verification
   echo "Subscriber Package Version ID: $subscriberVersionId"

   # Check if subscriberVersionId is set correctly
   if [ -z "$subscriberVersionId" ]; then
      echo "Failed to get subscriberVersionId for package $packageId."
      exit 102
   fi 

   # Check if subscriberVersionId starts with '04t'
   if [[ "$subscriberVersionId" != 04t* ]]; then
      echo "Unexpected format for subscriberVersionId: $subscriberVersionId"
      exit 103
   fi

   export PARAM_SUBSCRIBER_VERSION_EXPORT="$subscriberVersionId"

   # Check if PARAM_DEVHUB_ORG is set correctly
   if [ -z "$PARAM_DEVHUB_ORG" ]; then
      echo "There is no DevHub Org parameter"
      exit 201
   fi

   # Check if PARAM_SUBSCRIBER_VERSION_EXPORT is set correctly
   if [ -z "$PARAM_SUBSCRIBER_VERSION_EXPORT" ]; then
      echo "There is no subscriber version export parameter"
      exit 202
   fi
}

ORB_TEST_ENV="bats-core"

if [ "${0#*"$ORB_TEST_ENV"}" == "$0" ]; then
   main
fi
