#!/bin/bash
# Set local target repo location
#   cd <--target-repo-location-->

# if no upstream remote created: 
#   git remote add upstream <upstream-repo-url>

# Discard local changes
# git reset --hard
BRANCH='master'
BRANCH='feature/ado-vmss-agents'

# git fetch upstream
# git merge upstream/$BRANCH
# git push origin master

git fetch upstream; git merge upstream/$BRANCH; git push origin master