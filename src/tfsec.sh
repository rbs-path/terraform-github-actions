#!/bin/bash

function tfsec {
  # Gather the output of `terraform tfsec`.
  echo "tfsec: info: Running TFsec on ${tfWorkingDir}"
  tfsecOutput=$(/usr/local/bin/tfsec ${tfWorkingDir} 2>&1)
  tfsecExitCode=${?}

  # Exit code of 0 indicates success. Print the output and exit.
  if [ ${tfsecExitCode} -eq 0 ]; then
    echo "tfsec: info: successfully run TFSec on ${tfWorkingDir}"
    echo "${tfsecOutput}"
    echo
    exit ${tfsecExitCode}
  fi

  # Exit code of !0 indicates failure.
  echo "tfsec: error: failed to run TFSec on ${tfWorkingDir}"
  echo "${tfsecOutput}"
  echo

  # Comment on the pull request if necessary.
  if [ "$GITHUB_EVENT_NAME" == "pull_request" ] && [ "${tfComment}" == "1" ]; then
    initCommentWrapper="#### \`tfsec\` Failed

\`\`\`
${tfsecOutput}
\`\`\`

*Workflow: \`${GITHUB_WORKFLOW}\`, Action: \`${GITHUB_ACTION}\`, Working Directory: \`${tfWorkingDir}\`*"

    initCommentWrapper=$(stripColors "${initCommentWrapper}")
    echo "tfsec: info: creating JSON"
    initPayload=$(echo "${initCommentWrapper}" | jq -R --slurp '{body: .}')
    initCommentsURL=$(cat ${GITHUB_EVENT_PATH} | jq -r .pull_request.comments_url)
    echo "tfsec: info: commenting on the pull request"
    echo "${initPayload}" | curl -s -S -H "Authorization: token ${GITHUB_TOKEN}" --header "Content-Type: application/json" --data @- "${initCommentsURL}" > /dev/null
  fi

  exit ${tfsecExitCode}
}
