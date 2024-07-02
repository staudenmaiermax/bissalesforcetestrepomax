changedSubmodule=$(git diff-tree --no-commit-id --name-only -r HEAD | grep '^packages/' | cut -d'/' -f1-2)
package_versionRaw=$(jq -r '.packageDirectories[] | select(.path == "src/packaged") | .versionNumber' "$changedSubmodule/sfdx-project.json")
      echo "Package Version Raw: $package_versionRaw"
 # Remove last 5 characters (".NEXT")
      versionName="${package_versionRaw::-5}"
      echo "Version Name: $versionName"