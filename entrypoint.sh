#!/bin/bash

nofetch=""
nocache=""

# Check if the nofetch option has been set
if [ "${1,,}" == "true" ] ;then
    echo "nofetch enabled"
    nofetch="/nofetch"
fi

# Check if the nocache option has been set
if [ "${2,,}" == "true" ] ;then
    echo "nocache enabled"
    nocache="/nocache"
fi

/tools/dotnet-gitversion /github/workspace $nocache $nofetch /output buildserver > /version.txt; result=$?

buildserver="$(cat /version.txt)"

echo "$buildserver"

if [[ $buildserver == *"Could not find a 'develop' or 'master' branch, neither locally nor remotely."* ]] ;then

    echo "
    Fetch the master branch and tags after checkout and before running GitVersion. Use the following GitHub actions steps.

    steps:
    - name: Checkout
      uses: actions/checkout@v1

    - name: Fetch tags and master for GitVersion
      run: |
        git fetch --tags
        git branch --create-reflog master origin/master
        
    - name: GitVersion
      id: gitversion
      uses: roryprimrose/rungitversion
    "

    exit 1

fi

if [[ $buildserver == *"System.InvalidOperationException"* ]] ;then

    exit 1

fi

# It doesn't look like GitVersion.dll returns anything but 0. This is here just in case this changes in the future.
if [ $result -ne 0 ]; then
    echo "Failed to evaluate GitVersion (/output buildserver)"
    exit $result
fi

/tools/dotnet-gitversion /github/workspace $nocache $nofetch /output json > /version.json; result=$?

# It doesn't look like GitVersion.dll returns anything but 0. This is here just in case this changes in the future.
if [ $result -ne 0 ]; then
    echo "Failed to evaluate GitVersion (/output json)"
    exit $result
fi

function OutputValue() {
    # Obtain gitversion generated output in a variable
    gitversion_json="$(cat /version.json)"

    # Capture JSON keys in a bash array
    mapfile -t gitver_arr < <(jq "keys[]" <<< $gitversion_json)
    
    # Log the value to the github action output parameter
    for i in ${gitver_arr[@]}
    do
        name=$i
        value=$(jq .$i <<< $gitversion_json)
        echo "DEBUG Name $name | Value $value"
        echo "::debug::Setting Key: $name to Value: $value"
        echo "::set-output name=$name::$value"
    done    
}

# Let's generate the output values for GitHub Actions
OutputValue
echo "GitVersionJSON: $gitversion_json"
