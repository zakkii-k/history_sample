#!/bin/bash

# リポジトリ情報
OWNER="zakkii-k"
REPO="history_sample"

# コミット情報の取得
gh api repos/$OWNER/$REPO/commits --paginate > commits.json

# ブランチ情報の取得
gh api repos/$OWNER/$REPO/branches > branches.json

# Pull Request情報の取得
gh api repos/$OWNER/$REPO/pulls --paginate > pulls.json

# コミット情報の整形
jq -c '.[] | {type: "commit", sha: .sha, author: .commit.author.name, date: .commit.author.date, message: .commit.message, files: []}' commits.json > commits_parsed.json

# ファイルの変更情報を各コミットに追加
echo "[" > commits_with_files.json
first=true
while read -r commit; do
  sha=$(echo $commit | jq -r '.sha')
  files=$(gh api repos/$OWNER/$REPO/commits/$sha | jq '.files')
  commit_with_files=$(echo $commit | jq --argjson files "$files" '.files = $files')
  if [ "$first" = true ]; then
    echo "$commit_with_files" >> commits_with_files.json
    first=false
  else
    echo ",$commit_with_files" >> commits_with_files.json
  fi
done < commits_parsed.json
echo "]" >> commits_with_files.json

# ブランチ情報の整形と生成時刻の推定
echo "[" > branches_with_dates.json
first=true
while read -r branch; do
  branch_name=$(echo $branch | jq -r '.name')
  commit_sha=$(echo $branch | jq -r '.commit.sha')
  # ブランチの最初のコミットを取得
  first_commit=$(gh api repos/$OWNER/$REPO/commits?sha=$branch_name --paginate | jq -s '.[-1]')
  commit_date=$(echo $first_commit | jq -r '.commit.author.date')
  branch_info=$(echo $branch | jq --arg date "$commit_date" '. + {date: $date}')
  if [ "$first" = true ]; then
    echo "$branch_info" >> branches_with_dates.json
    first=false
  else
    echo ",$branch_info" >> branches_with_dates.json
  fi
done < <(jq -c '.[]' branches.json)
echo "]" >> branches_with_dates.json

# Pull Request情報の整形
jq -c '.[] | {type: "pull_request", number: .number, state: .state, title: .title, user: .user.login, created_at: .created_at, updated_at: .updated_at, closed_at: .closed_at, merged_at: .merged_at, merge_commit_sha: .merge_commit_sha}' pulls.json > pulls_parsed.json

# マージコミットをコミット情報から特定し、マージコミットのメタデータを追加
jq 'map(if (.type == "commit" and (.message | test("^Merge branch"))) then .type = "merge_commit" else . end)' commits_with_files.json > commits_with_files_and_merge.json

# データの統合
jq -s '.[0] + .[1] + .[2]' commits_with_files_and_merge.json branches_with_dates.json pulls_parsed.json > combined.json

# 時系列でソート
jq 'sort_by(.date // .created_at)' combined.json > sorted.json

# 結果をhistory.jsonに保存
mv sorted.json history.json

# 一時ファイルの削除
rm commits.json branches.json pulls.json commits_parsed.json commits_with_files.json branches_with_dates.json pulls_parsed.json combined.json commits_with_files_and_merge.json

echo "情報の取得と処理が完了しました。結果はhistory.jsonに保存されました。"

