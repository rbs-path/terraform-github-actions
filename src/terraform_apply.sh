#!/bin/bash

function terraformApply {
  # Gather the output of `terraform apply`.
  echo "apply: info: applying Terraform configuration in ${tfWorkingDir}"
  applyOutput=$(terraform apply -auto-approve -input=false ${*} 2>&1)
  applyExitCode=${?}
  applyCommentStatus="Failed"

  # Exit code of 0 indicates success. Print the output and exit.
  if [ ${applyExitCode} -eq 0 ]; then
    echo "apply: info: successfully applied Terraform configuration in ${tfWorkingDir}"
    echo "${applyOutput}"
    echo
    applyCommentStatus="Success"
    gzip -c << EOF |
{
  "eventType":"Deployment",
  "project":"${GITHUB_REPOSITORY}",
  "ref":"${GITHUB_REF}",
  "environment": "${TF_WORKSPACE}",
  "revision": "${GITHUB_SHA::8}",
  "changelog": "https://github.com/${GITHUB_REPOSITORY}/commit/${GITHUB_SHA}/checks",
  "description": "${CI_COMMIT_MESSAGE}",
  "user": "${GITHUB_ACTOR}"
}
EOF
    curl --silent --output /dev/null -X POST -H "Content-Type: application/json" -H "X-Insert-Key: ${NEW_RELIC_INSERT_API_KEY}" -H "Content-Encoding: gzip" https://insights-collector.newrelic.com/v1/accounts/2234100/events --data-binary @-

  fi

  # Exit code of !0 indicates failure.
  if [ ${applyExitCode} -ne 0 ]; then
    echo "apply: error: failed to apply Terraform configuration in ${tfWorkingDir}"
    echo "${applyOutput}"
    echo
  fi

  # Comment on the pull request if necessary.
  if [ "$GITHUB_EVENT_NAME" == "pull_request" ] && [ "${tfComment}" == "1" ]; then
    applyCommentWrapper="#### \`terraform apply\` ${applyCommentStatus}
<details><summary>Show Output</summary>

\`\`\`
${applyOutput}
\`\`\`

</details>

*Workflow: \`${GITHUB_WORKFLOW}\`, Action: \`${GITHUB_ACTION}\`, Working Directory: \`${tfWorkingDir}\`*"

    applyCommentWrapper=$(stripColors "${applyCommentWrapper}")
    echo "apply: info: creating JSON"
    applyPayload=$(echo "${applyCommentWrapper}" | jq -R --slurp '{body: .}')
    applyCommentsURL=$(cat ${GITHUB_EVENT_PATH} | jq -r .pull_request.comments_url)
    echo "apply: info: commenting on the pull request"
    echo "${applyPayload}" | curl -s -S -H "Authorization: token ${GITHUB_TOKEN}" --header "Content-Type: application/json" --data @- "${applyCommentsURL}" > /dev/null
  fi

  exit ${applyExitCode}
}
