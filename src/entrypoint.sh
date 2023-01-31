#!/bin/bash

set -e

echo "Start Creating PR action"

##### CONSTANCE
OUTPUT_PATH=".output"

##### VARIABLE
IS_NEED_APPROVE="false"

##### WEBHOOK
function webhook() {
    WEBHOOK_URL="${MSTEAMS_WH}"

    TITLE=$1

    COLOR="d7000b"

    TEXT=$2

    MESSAGE=$( echo ${TEXT} | sed 's/"/\"/g' | sed "s/'/\'/g" | sed 's/*/ /g' )
    JSON="{\"title\": \"${TITLE}\", \"themeColor\": \"${COLOR}\", \"text\": \"${MESSAGE}\" }"

    curl -H "Content-Type: application/json" -d "${JSON}" "${WEBHOOK_URL}"
}

##### FUNCTION
function create_pr()
{
  echo "."
  TITLE="hotfix auto merged by $(jq -r ".pull_request.head.user.login" "$GITHUB_EVENT_PATH" | head -1)."
  echo "."
  REPO_FULLNAME=$(jq -r ".repository.full_name" "$GITHUB_EVENT_PATH")
  echo "."
  ASSIGNES=$(jq -r ".pull_request.assignees" "$GITHUB_EVENT_PATH")
  echo "."
  RESPONSE_CODE=$(curl -v -o $OUTPUT_PATH -s -w "%{http_code}\n" \
    --data "{\"title\":\"$TITLE\", \"head\": \"$BASE_BRANCH\", \"base\": \"$TARGET_BRANCH\"}" \
    -X POST \
    -H "Authorization: Bearer $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "https://api.github.com/repos/$REPO_FULLNAME/pulls")
  echo "."
  PULL_NUMBER="$(jq -r ".number" "$OUTPUT_PATH" | head -1)"
  echo "."
  LINK="https://github.com/$REPO_FULLNAME/pull/$PULL_NUMBER"
  echo "head: $BASE_BRANCH, base: $TARGET_BRANCH"
  echo "Create PR Response:"
  echo "Code : $RESPONSE_CODE"
  if [[ "$RESPONSE_CODE" -ne "201" ]];
  then  
    echo "Could not create PR";
    title="Error:${RESPONSE_CODE}";
    text="Error*$RESPONSE_CODE*while*creating*PR\n$LINK\nAssignes:*$ASSIGNES\nBranch:*";
    #text=${echo -e "Error*$RESPONSE_CODE*while*creating*PR\n$LINK\nAssignes:$ASSIGNES\nBranch:$LINK"};
    webhook $title $text;
    exit 1;
  else  echo "Created PR";
  fi
}

function merge_pr()
{
  REPO_FULLNAME=$(jq -r ".repository.full_name" "$GITHUB_EVENT_PATH")
  COMMIT_TITLE="$(jq -r ".title" "$OUTPUT_PATH" | head -1)"
  COMMIT_MESSAGE="$(jq -r ".body.head_commit.message" "$OUTPUT_PATH" | head -1)"
  HEAD_SHA="$(jq -r ".head.sha" "$OUTPUT_PATH" | head -1)"
  MERGE_METHOD="merge"
  PULL_NUMBER="$(jq -r ".number" "$OUTPUT_PATH" | head -1)"
  LINK="https://github.com/$REPO_FULLNAME/pull/$PULL_NUMBER"
  RESPONSE_CODE=$(curl -o $OUTPUT_PATH -s -w "%{http_code}\n" \
    --data "{\"commit_title\":\"$COMMIT_TITLE\", \"commit_message\":\"$COMMIT_MESSAGE\", \"sha\": \"$HEAD_SHA\", \"merge_method\": \"$MERGE_METHOD\"}" \
    -X PUT \
    -H "Authorization: Bearer $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "https://api.github.com/repos/$REPO_FULLNAME/pulls/$PULL_NUMBER/merge")
  if [[ "$RESPONSE_CODE" -ne "200" ]];
  then  
    echo "Could not merge PR";
    title="Error:${RESPONSE_CODE}";
    text="Error*$RESPONSE_CODE*while*creating*PR\n$LINK\nAssignes:$ASSIGNES\nBranch:$LINK";
    #text=${echo -e "Error*$RESPONSE_CODE*while*creating*PR\n$LINK\nAssignes:$ASSIGNES\nBranch:$LINK"};
    webhook $title $text;
    exit 1;
  else  echo "Merged PR";
  fi
}

function approve_pr()
{
  REPO_FULLNAME=$(jq -r ".repository.full_name" "$GITHUB_EVENT_PATH")
  PULL_NUMBER="$(jq -r ".number" "$OUTPUT_PATH" | head -1)"
  RESPONSE_CODE=$(curl -s -o /dev/null -w "%{http_code}\n" \
    --data "{\"event\":\"APPROVE\"}" \
    -X POST \
    -H "Authorization: Bearer $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "https://api.github.com/repos/$REPO_FULLNAME/pulls/$PULL_NUMBER/reviews")
  echo "Approve PR Response:"
  echo "Code : $RESPONSE_CODE"
}

function check_token_is_defined()
{
  if [[ -z "$GITHUB_TOKEN" ]];
  then
    echo "Undefined GITHUB_TOKEN environment variable."
    exit 1
  fi
}

function check_bot_token_is_defined()
{
  if [[ "$BOT_TOKEN" != null ]];
  then
    echo "Bot Token Avaliable"
    IS_NEED_APPROVE=true    
  else
    echo "Bot Token not Avaliable"
  fi
}

function check_is_pr_is_merged()
{
  echo "$(jq -r ".pull_request.merged" "$GITHUB_EVENT_PATH")"
  if [[ "$(jq -r ".pull_request.merged" "$GITHUB_EVENT_PATH")" == "false" ]];
  then
    echo "This PR has not merged event."
    exit 0
  fi
}

function check_is_pr_branch_has_prefix()
{
  echo "$(jq -r ".pull_request.head.ref" "$GITHUB_EVENT_PATH")"
  if [[ "$(jq -r ".pull_request.head.ref" "$GITHUB_EVENT_PATH")" != "$BRANCH_PREFIX"* ]];
  then
    echo "This PR head branch do not have prefix."
    exit 0
  fi
}

function check_is_merged_base_branch_is_trigger()
{
  echo "$(jq -r ".pull_request.base.ref" "$GITHUB_EVENT_PATH")"
  if [[ "$(jq -r ".pull_request.base.ref" "$GITHUB_EVENT_PATH")" != "$BASE_BRANCH"* ]];
  then
    echo "This PR base branch is not base branch."
    exit 0
  fi

}

function check_validate() 
{
  check_token_is_defined
  check_bot_token_is_defined
  check_is_pr_is_merged
  check_is_pr_branch_has_prefix
  check_is_merged_base_branch_is_trigger
}

##### MAIN
function main()
{
  check_validate
  create_pr 
  if [[ "$IS_NEED_APPROVE" == "true" ]];
  then
    approve_pr
  fi
  merge_pr
}

##### EXECUTE
main
