#!/bin/bash

# リポジトリ情報を設定
REPO_OWNER="zakkii-k"
REPO_NAME="history_sample"

# 出力ディレクトリを設定
OUTPUT_DIR="github_data"

# 出力ディレクトリを作成
mkdir -p $OUTPUT_DIR

# コミット情報の取得
echo "Fetching commits..."
gh api "repos/$REPO_OWNER/$REPO_NAME/commits" --paginate | jq '.' > "$OUTPUT_DIR/commits.json"

# ブランチ情報の取得
echo "Fetching branches..."
gh api "repos/$REPO_OWNER/$REPO_NAME/branches" --paginate | jq '.' > "$OUTPUT_DIR/branches.json"

# 各ブランチのコミット情報を取得し、各コミットにブランチ情報を追加
echo "Fetching branch-specific commit details and adding branch info..."
rm -f "$OUTPUT_DIR/commits_detailed_tmp.json"
jq -r '.[].name' "$OUTPUT_DIR/branches.json" | while read branch; do
  gh api "repos/$REPO_OWNER/$REPO_NAME/commits?sha=$branch" --paginate | jq --arg branch "$branch" '.[] | .branch = $branch' | jq '.' >> "$OUTPUT_DIR/commits_detailed_tmp.json"
done

# JSONファイルを配列形式に整形
jq -s '.' "$OUTPUT_DIR/commits_detailed_tmp.json" > "$OUTPUT_DIR/commits_detailed.json"
rm "$OUTPUT_DIR/commits_detailed_tmp.json"

# 重複するコミットの中で最も古いブランチの情報のみを残す
echo "Removing duplicate commits, keeping the oldest branch info..."
jq 'group_by(.sha) | map(sort_by(.commit.author.date) | .[0]) | .[]' "$OUTPUT_DIR/commits_detailed.json" > "$OUTPUT_DIR/commits_detailed_final.json"
mv "$OUTPUT_DIR/commits_detailed_final.json" "$OUTPUT_DIR/commits_detailed.json"

# プルリクエスト情報の取得（オープンおよびクローズ）
echo "Fetching pull requests (open and closed)..."
gh api "repos/$REPO_OWNER/$REPO_NAME/pulls?state=all" --paginate | jq '.' > "$OUTPUT_DIR/pull_requests.json"

# リポジトリのイベント情報の取得
echo "Fetching repository events..."
gh api "repos/$REPO_OWNER/$REPO_NAME/events" --paginate | jq '.' > "$OUTPUT_DIR/events.json"

# ブランチ作成イベントの抽出
echo "Extracting branch creation events..."
jq '.[] | select(.type == "CreateEvent" and .payload.ref_type == "branch")' "$OUTPUT_DIR/events.json" > "$OUTPUT_DIR/branch_creation_events.json"

echo "Data fetch and format complete."

