setup() {
    # Source script under test
    source scripts/helpers/shell/package-rollout.sh

    # export test environment variables
    export PARAM_DEVHUB_ORG="test@example.com"
    export PARAM_EXPORT_VARIABLE_NAME="SUBSCRIBER_PACKAGE_VERSION_ID"
    
    # Backup the original sfdx-project.json
    cp "packages/testsubrepo1/sfdx-project.json" "packages/testsubrepo1/sfdx-project.json.bak"
    
    # Override with mocked sfdx-project.json
    cat scripts/helpers/data/mock-sfdx-project.json > "packages/testsubrepo1/sfdx-project.json"

    # mock the CircleCI BASH_ENV and create an empty file there
    mkdir -p ~/circleci_bash_env
    export BASH_ENV=~/circleci_bash_env/mocked_bash_env.txt
    >"$BASH_ENV"
}

teardown() {
    # Restore the original sfdx-project.json
    mv "packages/testsubrepo1/sfdx-project.json.bak" "packages/testsubrepo1/sfdx-project.json"
   
    # Unset environment variables to clean up the environment
    unset PARAM_PATH
    unset PARAM_SUBSCRIBER_VERSION_EXPORT

    # reset mocked CircleCI bash env
    rm -f $BASH_ENV
}

@test "No submodule changed > Exit 0" {
    # Arrange
    check_changed_submodule() {
        echo ""
    }

    # Act
    run main

    # Assert
    echo "$output"
    [ "$status" -eq 0 ]
    [[ "$output" == "No submodule commited. Exiting with 0." ]]
}

@test "Package submodule changed > Exports subscriber version id" {
    # Arrange
    check_changed_submodule() {
        echo "packages/testsubrepo1"
    }
    query_package_subscriber_id() {
        echo "04t000000000001AAA"
    }

    # Act
    run main
    exportedBashEnv=$(< "$BASH_ENV")
    echo "$output"
    echo "BASH_ENV: $exportedBashEnv"

    # Assert
    [ "$status" -eq 0 ]
    [[ "$output" == *"Changed submodule detected: packages/testsubrepo1"* ]]
    [[ "$output" == *"Package Id: 0Ho000000000000AAA"* ]]
    [[ "$output" == *"Identified package version: 5.0.1"* ]]
    [[ "$output" == *"Package2Id = '0Ho000000000000AAA' AND MajorVersion = 5 AND MinorVersion = 0 AND PatchVersion = 1 AND IsReleased = true"* ]]
    [[ "$output" == *"Subscriber Package Id: 04t000000000001AAA"* ]]
    [ -f "$BASH_ENV" ]
    # found mocked subscriber package version id
    [[ "$output" == *"Exporting release version 04t000000000001AAA to SUBSCRIBER_PACKAGE_VERSION_ID"* ]]
    [[ $exportedBashEnv == 'export SUBSCRIBER_PACKAGE_VERSION_ID=04t000000000001AAA' ]]
}

@test "Changed submodule is not a valid sfdx-project > exit with error" {
    # Arrange
    rm -f packages/testsubrepo1/sfdx-project.json
    check_changed_submodule() {
        echo "packages/testsubrepo1"
    }

    # Act
    run main

    # Assert
    [ "$status" -eq 0 ]
    [[ "$output" == *"Changed submodule detected: packages/testsubrepo1"* ]]
    [[ "$output" == *"The submodule packages/testsubrepo1 is not a valid sfdx project. Missing sfdx-project.json."* ]]
}

@test "Fail if packageId cannot be extracted" {
    skip
    # Arrange
    PARAM_PATH="packages/testsubrepo1"
    jq '.packageAliases["mockpackage"] = ""' "$PARAM_PATH/sfdx-project.json" > "$PARAM_PATH/sfdx-project.json.tmp" && mv "$PARAM_PATH/sfdx-project.json.tmp" "$PARAM_PATH/sfdx-project.json"

    # Act
    run main

    # Assert
    echo "Status: $status"
    echo "Output: $output"
    [ "$status" -eq 101 ]
    [[ "$output" == *"Failed to get packageId from sfdx-project.json from"* ]]
}

@test "Fail if subscriberVersionId cannot be retrieved" {
    skip
    # Arrange
    export changedSubmodule="packages/testsubrepo1"
    verify_subscriber_package_id=""
    
    query_package_subscriber_id() {
        subscriberVersionId=""
    }

    #parameter_verification() {
    #    subscriberVersionId=""
    # }
    
    # Act
    run main

    # Assert
    echo "Status: $status"
    echo "Output: $output"
    
    [ "$status" -eq 102 ]
    [[ "$output" == *"Failed to get subscriberVersionId for package"* ]]
}

@test "Fail if subscriberVersionId format is incorrect" {
    skip
    # Arrange
    PARAM_PATH="packages/testsubrepo1"
    verify_subscriber_package_id="07a0000000001"
    export changedSubmodule="packages/testsubrepo2"
    
    query_package_subscriber_id() {
        subscriberVersionId="invalidID"
    }

    # Act
    run main

    # Assert
    echo "Status: $status"
    echo "Output: $output"
    
    [ "$status" -eq 103 ]
    [[ "$output" == *"Unexpected format for subscriberVersionId"* ]]
}

@test "Fail if PARAM_DEVHUB_ORG is not set correctly" {
    skip
    # Arrange
    export PARAM_DEVHUB_ORG="admin-salesforce@mobilityhouse.com"
    orig_PARAM_DEVHUB_ORG="$PARAM_DEVHUB_ORG" 

    echo "Before unset: $PARAM_DEVHUB_ORG"
    

    # Act
    run main

    # Assert
    echo "Status: $status"
    echo "Output: $output"
    
    [ "$status" -eq 201 ]
    [[ "$output" == *"There is no DevHub Org parameter"* ]]

    # Restore original PARAM_DEVHUB_ORG
    export PARAM_DEVHUB_ORG="$orig_PARAM_DEVHUB_ORG"
    unset PARAM_DEVHUB_ORG  


}

@test "Fail if subscriberVersionId cannot be exported" {
    skip
    # Arrange
    query_package_subscriber_id() {
        subscriberVersionId=""
    }

    # Act
    run main

    # Assert
    echo "Status: $status"
    echo "Output: $output"
    [ "$status" -eq 202 ]
    [[ "$output" == *"There is no subscriber version export parameter"* ]]
}
