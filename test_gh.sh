#!/bin/bash

# リポジトリ情報を設定
REPO_OWNER="zakkii-k"
REPO_NAME="history_sample"

# 出力ディレクトリを設定
OUTPUT_DIR="github_data"


# サンプルデータの確認
gh api "repos/$REPO_OWNER/$REPO_NAME/commits" --paginate -q '.[]' | head -n 1 | jq .
gh api "repos/$REPO_OWNER/$REPO_NAME/branches" --paginate -q '.[]' | head -n 1 | jq .
gh api "repos/$REPO_OWNER/$REPO_NAME/pulls" --paginate -q '.[]' | head -n 1 | jq .


