setup() {
    # source script under test
    source scripts/helpers/shell/bump-package-version.sh

    # mock environment variables
    export PARAM_PATH="packages/testsubrepo1"

    # override with mocked sfdx-project.json
    cat scripts/helpers/data/mock-sfdx-project.json > $PARAM_PATH/sfdx-project.json
}

teardown() {
    cd $PARAM_PATH
    git checkout sfdx-project.json
}

@test "Bump package PATCH version > commits with PATCH bumped" {
    # Arrange
    export PARAM_SEMVER_BUMP="PATCH"

    # Act
    run main

    # Assert
    echo "Actual output"
    echo "$output"
    echo "Actual status: $status"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Current version is: 1.2.3"* ]]
    [[ "$output" == *"Applying PATCH increment"* ]]
    [[ "$output" == *"New version is: 1.2.4"* ]]
    newVersionOutput=$(jq -r '.packageDirectories[] | select(.path == "src/packaged") | .versionNumber' "$PARAM_PATH"/sfdx-project.json)
    [ "$newVersionOutput" == "1.2.4.NEXT" ]
}

@test "Bump package MINOR version > commits with MINOR bumped" {
    # Arrange
    export PARAM_SEMVER_BUMP="MINOR"

    # Act
    run main

    # Assert
    echo "Actual output"
    echo "$output"
    echo "Actual status: $status"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Current version is: 1.2.3"* ]]
    [[ "$output" == *"Applying MINOR increment"* ]]
    [[ "$output" == *"New version is: 1.3.0"* ]]
    newVersionOutput=$(jq -r '.packageDirectories[] | select(.path == "src/packaged") | .versionNumber' "$PARAM_PATH"/sfdx-project.json)
    [ "$newVersionOutput" == "1.3.0.NEXT" ]
}

@test "Bump package MAJOR version > commits with MAJOR bumped" {
    # Arrange
    export PARAM_SEMVER_BUMP="MAJOR"

    # Act
    run main

    # Assert
    echo "Actual output"
    echo "$output"
    echo "Actual status: $status"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Current version is: 1.2.3"* ]]
    [[ "$output" == *"Applying MAJOR increment"* ]]
    [[ "$output" == *"New version is: 2.0.0"* ]]
    newVersionOutput=$(jq -r '.packageDirectories[] | select(.path == "src/packaged") | .versionNumber' "$PARAM_PATH"/sfdx-project.json)
    [ "$newVersionOutput" == "2.0.0.NEXT" ]
}

@test "Bump package with invalid semver tag > exits with error 100" {
    # Arrange
    export PARAM_SEMVER_BUMP="SOMETHING"

    # Act
    run main

    # Assert
    echo "Actual output"
    echo "$output"
    echo "Actual status: $status"
    [ "$status" -eq 100 ]
    [[ "$output" == *"Invalid SEMVER tag SOMETHING"* ]]
    newVersionOutput=$(jq -r '.packageDirectories[] | select(.path == "src/packaged") | .versionNumber' "$PARAM_PATH"/sfdx-project.json)
    [ "$newVersionOutput" == "1.2.3.NEXT" ]
}
