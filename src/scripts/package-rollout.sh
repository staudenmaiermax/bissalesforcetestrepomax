#! /bin/bash

# Exit on error
set -euo pipefail


# Check if there is a changed submodule
changed_submodule=$(git diff-tree --no-commit-id --name-only -r HEAD | grep '^packages/' | head -n 1)

# Throw exit 0 when no submodule changed
if [ -z "$changed_submodule" ]; then
   echo "There is no changed submodule. Exit script without errors."
   exit 0
fi 

# Get packageId from sfdx-project.json
package_id=$(jq -r '.packageDirectories[0].packageAliases' "$changed_submodule/sfdx-project.json")

#Throw exit 101
if [ -z "$package_id" ]; then
   echo "Failed to get package_id from sfdx-project.json from $changed_submodule."
   exit 101

fi 


package_version=$(git tag)
