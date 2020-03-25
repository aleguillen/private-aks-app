# Set local target repo location
#   cd <--target-repo-location-->
# if no upstream remote created: 
#   git remote add upstream <upstream-repo-url>

git fetch upstream
git merge upstream/master
git push origin master