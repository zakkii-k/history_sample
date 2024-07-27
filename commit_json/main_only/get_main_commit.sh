#!/bin/zsh

# Create a directory for storing commit JSON files
mkdir -p commits

# Fetch all commit SHAs and store detailed commit information in JSON files
gh api "repos/zakkii-k/history_sample/commits?sha=main" --paginate -q '.[] | .sha' | while read sha; do
  gh api "repos/zakkii-k/history_sample/commits/$sha" > commits/$sha.json
done

# Create a combined JSON file for all commits
echo "[" > all_commits.json
for file in commits/*.json; do
  cat $file | jq '.' >> all_commits.json
  echo "," >> all_commits.json
done
# Remove the last comma and close the JSON array
truncate -s-2 all_commits.json
echo "]" >> all_commits.json

# Format the combined JSON file and sort by commit date
cat all_commits.json | jq 'sort_by(.commit.author.date)' > formatted_commits.json

# Cleanup temporary directory and intermediate files
rm -rf commits all_commits.json

echo "Formatted and sorted commits have been saved to formatted_commits.json"

