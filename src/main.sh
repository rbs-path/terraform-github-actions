#!/bin/bash

function stripColors {
  echo "${1}" | sed 's/\x1b\[[0-9;]*m//g'
}

function hasPrefix {
  case ${2} in
    "${1}"*)
      true
      ;;
    *)
      false
      ;;
  esac
}

function parseInputs {
  # Required inputs
  if [ "${INPUT_TF_ACTIONS_VERSION}" != "" ]; then
    tfVersion=${INPUT_TF_ACTIONS_VERSION}
  else
    echo "Input terraform_version cannot be empty"
    exit 1
  fi

  if [ "${INPUT_TF_ACTIONS_SUBCOMMAND}" != "" ]; then
    tfSubcommand=${INPUT_TF_ACTIONS_SUBCOMMAND}
  else
    echo "Input terraform_subcommand cannot be empty"
    exit 1
  fi

  # Optional inputs
  tfWorkingDir="."
  if [ "${INPUT_TF_ACTIONS_WORKING_DIR}" != "" ] || [ "${INPUT_TF_ACTIONS_WORKING_DIR}" != "." ]; then
    tfWorkingDir=${INPUT_TF_ACTIONS_WORKING_DIR}
  fi

  tfComment=0
  if [ "${INPUT_TF_ACTIONS_COMMENT}" == "1" ] || [ "${INPUT_TF_ACTIONS_COMMENT}" == "true" ]; then
    tfComment=1
  fi

  tfCLICredentialsHostname=""
  if [ "${INPUT_TF_ACTIONS_CLI_CREDENTIALS_HOSTNAME}" != "" ]; then
    tfCLICredentialsHostname=${INPUT_TF_ACTIONS_CLI_CREDENTIALS_HOSTNAME}
  fi

  tfCLICredentialsToken=""
  if [ "${INPUT_TF_ACTIONS_CLI_CREDENTIALS_TOKEN}" != "" ]; then
    tfCLICredentialsToken=${INPUT_TF_ACTIONS_CLI_CREDENTIALS_TOKEN}
  fi
}

function configureCLICredentials {
  if [[ ! -f "${HOME}/.terraformrc" ]] && [[ "${tfCLICredentialsToken}" != "" ]]; then
    cat > ${HOME}/.terraformrc << EOF
credentials "${tfCLICredentialsHostname}" {
  token = "${tfCLICredentialsToken}"
}
EOF
  fi
}

function addSSHFiles {
  mkdir -p /root/.ssh
  echo "${TF_MODULES_GIT_SSH_PRIVATE_KEY}" >> /root/.ssh/id_rsa
  chmod 600 /root/.ssh/id_rsa
  ssh-keyscan github.com >> /root/.ssh/known_hosts 2>/dev/null
  ssh-keyscan gitlab.com >> /root/.ssh/known_hosts 2>/dev/null
  cat >> /root/.ssh/config << EOF
Host github.com
  User git
  HostName github.com
  PreferredAuthentications publickey
  IdentityFile /root/.ssh/id_rsa
Host gitlab.com
  User git
  HostName gitlab.com
  PreferredAuthentications publickey
  IdentityFile /root/.ssh/id_rsa
EOF
}

function installTerraform {
  if [[ "${tfVersion}" == "latest" ]]; then
    echo "Checking the latest version of Terraform"
    tfVersion=$(curl -sL https://releases.hashicorp.com/terraform/index.json | jq -r '.versions[].version' | grep -v '[-].*' | sort -rV | head -n 1)

    if [[ -z "${tfVersion}" ]]; then
      echo "Failed to fetch the latest version"
      exit 1
    fi
  fi

  url="https://releases.hashicorp.com/terraform/${tfVersion}/terraform_${tfVersion}_linux_amd64.zip"

  echo "Downloading Terraform v${tfVersion}"
  curl -s -S -L -o /tmp/terraform_${tfVersion} ${url}
  if [ "${?}" -ne 0 ]; then
    echo "Failed to download Terraform v${tfVersion}"
    exit 1
  fi
  echo "Successfully downloaded Terraform v${tfVersion}"

  echo "Unzipping Terraform v${tfVersion}"
  unzip -d /usr/local/bin /tmp/terraform_${tfVersion} &> /dev/null
  if [ "${?}" -ne 0 ]; then
    echo "Failed to unzip Terraform v${tfVersion}"
    exit 1
  fi
  echo "Successfully unzipped Terraform v${tfVersion}"
}

function installTfsec {
  echo "Downloading TFSec v0.19.0"
  curl -sSL -o /usr/local/bin/tfsec https://github.com/liamg/tfsec/releases/download/v0.19.0/tfsec-linux-amd64
  chmod +x /usr/local/bin/tfsec
  if [ "${?}" -ne 0 ]; then
    echo "Failed to download TFSec"
    exit 1
  fi
  echo "Successfully downloaded TFSec"
}

function main {
  # Source the other files to gain access to their functions
  scriptDir=$(dirname ${0})
  source ${scriptDir}/terraform_fmt.sh
  source ${scriptDir}/terraform_init.sh
  source ${scriptDir}/terraform_validate.sh
  source ${scriptDir}/terraform_plan.sh
  source ${scriptDir}/terraform_apply.sh
  source ${scriptDir}/terraform_destroy.sh
  source ${scriptDir}/terraform_output.sh
  source ${scriptDir}/terraform_import.sh
  source ${scriptDir}/tfsec.sh

  parseInputs
  configureCLICredentials
  addSSHFiles
  cd ${GITHUB_WORKSPACE}/${tfWorkingDir}

  case "${tfSubcommand}" in
    fmt)
      installTerraform
      terraformFmt ${*}
      ;;
    init)
      installTerraform
      terraformInit ${*}
      ;;
    validate)
      installTerraform
      terraformValidate ${*}
      ;;
    plan)
      installTerraform
      terraformPlan ${*}
      ;;
    apply)
      installTerraform
      terraformApply ${*}
      ;;
    destroy)
      installTerraform
      terraformDestroy ${*}
      ;;
    output)
      installTerraform
      terraformOutput ${*}
      ;;
    import)
      installTerraform
      terraformImport ${*}
      ;;
    tfsec)
      installTfsec
      tfsec ${*}
      ;;
    *)
      echo "Error: Must provide a valid value for terraform_subcommand"
      exit 1
      ;;
  esac
}

main "${*}"
