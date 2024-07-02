setup() {
    # source script under test
    source scripts/helpers/shell/package-rollout.sh

    # mock environment variables
    export PARAM_PATH="packages/testsubrepo1"

    # override with mocked sfdx-project.json
    cat scripts/helpers/data/mock-sfdx-project.json > $PARAM_PATH/sfdx-project.json
}

teardown() {
    # Reset the sfdx-project.json to its original state for all relevant subrepos
    for submodule in "$PARAM_PATH"/*/; do
        # Check if the submodule directory exists
        if [ -d "$submodule" ]; then
            cd "$submodule"
            # Check if sfdx-project.json exists before checking it out
            if [ -f sfdx-project.json ]; then
                git checkout sfdx-project.json
            fi
        fi
    done

    # Unset environment variables to clean up the environment
    unset PARAM_PATH
    unset PARAM_SUBSCRIBER_VERSION_EXPORT
    unset subscriberVersionId
    unset changedSubmodule
}

@test "Exit script if no submodule changed" {
    # Arrange
    # Set up environment variables and simulate no submodule change
    export changedSubmodule=""

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
    subscriberVersionId="someValue"  # Initialize the variable with a value
    changedSubmodule="src/packaged"  # Use an existing submodule path
    export PARAM_SUBSCRIBER_VERSION_EXPORT="$subscriberVersionId"
    
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