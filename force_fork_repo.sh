# Set local target repo location
#   cd <--target-repo-location-->
# if no upstream remote created: 
#   git remote add upstream <upstream-repo-url>

git fetch upstream
# Discard local changes
# git reset --hard
git merge upstream/master
git push origin master