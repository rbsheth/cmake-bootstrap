#!/bin/bash

# Usage: ./update_subrepo.sh "subrepo_name"

set -ex

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
pushd "$SCRIPT_DIR/../" # monorepo/

if [ "$1" == "polly" ]; then
    subrepo_path="hunter/polly"
    remote_repo="https://github.com/cpp-pm/polly.git"
elif [ "$1" == "gate" ]; then
    subrepo_path="hunter/gate"
    remote_repo="https://github.com/cpp-pm/gate.git"
elif [ "$1" == "cmrc" ]; then
    subrepo_path="cmake/cmrc"
    remote_repo="https://github.com/vector-of-bool/cmrc.git"
fi
# Add other subrepos here.

if [ -z "$subrepo_path" ]; then
    echo "Subrepo name $1 not recognized"
    exit 1
fi

if [ -z "$(which git-subrepo)" ]; then
    echo "Installing subrepo to $TEMP from https://github.com/ingydotnet/git-subrepo#installation"
    subrepo_source_location="$TEMP/git-subrepo"
    git clone https://github.com/ingydotnet/git-subrepo "$subrepo_source_location"

    # Source for usage now.
    source "$subrepo_source_location/.rc"
fi

# Clones the remote repo into the chosen relative directory. Force means it overwrites anything
# that is present in that directory.
git subrepo clone "$remote_repo" "$subrepo_path" --force

# Subrepo doesn't play nicely with submodules inside it. For now, we can remove
# them. Later, we may want to add an option that converts them to nested subrepos.
if [ -f "$subrepo_path/.gitmodules" ]; then
    # If the subrepo has git submodules in it, they are in the form:
    # [submodule "hunter/polly"]
    #         path = hunter/polly
    #         url = git@github.com:cpp-pm/polly.git
    #
    # This parses out just the path component, so the above would give:
    #   hunter/polly
    subrepo_submodules=$(git config --file "$subrepo_path/.gitmodules" --get-regexp path | awk '{ print $2 }')

    # Caputure the existing commit message. Subrepo clone commits the results, and adds useful metadata
    # to the commit message that we want to preserve.
    commit_msg=$(git log --format=%B -n1)

    # For each submodule in the subrepo, remove it. If no submodules are found, this command does nothing.
    echo "$subrepo_submodules" | xargs -n 1 -I "{}" git rm "$subrepo_path/{}"

    # Remove the submodules file from the subrepo. If not found, prevent an error and just print a message.
    git rm "$subrepo_path/.gitmodules" || echo "No .gitmodules found in $subrepo_path"

    # Add a line to the subrepo-generated commit message, noting which submodules were removed.
    # There will be a line outputted for each file added, so filter that.
    git commit --amend -m "$commit_msg" -m "Removing submodules at $subrepo_submodules" | grep -v "create mode"
fi

popd
