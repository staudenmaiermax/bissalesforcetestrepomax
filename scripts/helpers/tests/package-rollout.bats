setup() {
    # source script under test
    source scripts/helpers/shell/package-rollout.sh

    # mock environment variables
    export PARAM_PATH="packages/testsubrepo1"
    zwischenspeicher="packages/testsubrepo1"
    # override with mocked sfdx-project.json
    cat scripts/helpers/data/mock-sfdx-project.json > $PARAM_PATH/sfdx-project.json
}

teardown() {
   cat $zwischenspeicher > $PARAM_PATH/sfdx-project.json

    # Unset environment variables to clean up the environment
    unset PARAM_PATH
    unset PARAM_SUBSCRIBER_VERSION_EXPORT
    unset subscriberVersionId
    unset changedSubmodule
}

@test "Exit script if no submodule changed" {
    # Arrange
    # Set up environment variables and simulate no submodule change
    

    # Act
    run main

    # Debug output
    echo "Output: $output"
    echo "Status: $status"

    # Assert
    [ "$status" -eq 0 ]
    [[ "$output" == *"There is no changed submodule. Exit script without errors."* ]]
}

@test "Fail if packageId cannot be extracted" {
    # Arrange
    changedSubmodule="src/packaged"  # Use an existing submodule path
  
    
    # Update the sfdx-project.json with wrong package using jq
    jq '.packageAliases.wrongPackage = "04t000000000001"' "$PARAM_PATH/sfdx-project.json" > "$PARAM_PATH/sfdx-project.json.tmp" && mv "$PARAM_PATH/sfdx-project.json.tmp" "$PARAM_PATH/sfdx-project.json"

    # Act
    run main

    # Debug output
    echo "Output: $output"
    echo "Status: $status"

    # Assert
    [ "$status" -eq 101 ]
    [[ "$output" == *"Failed to get packageId from sfdx-project.json from $changedSubmodule."* ]]
}