#!/bin/bash

function msg() {
    printf '%b\n' "$1"
}

function error() {
    msg "\33[31m[✘] ${1}\33[0m"
    exit 1
}

function protect_csv() {
    csv=$1
    channel=$2
    operator_name=$3

    if [ -z "${csv}" ]; then
        error "No CSV defined for ${channel} channel"
    fi

    csv_version=$(echo ${csv} | sed -e "s|${operator_name}.v||")
    # check unstaged changes
    for file in $(git diff --name-only); do
        if [[ "${file}" =~ ^deploy/olm-catalog/${operator_name}/${csv_version}/.* ]]; then
            error "Protected channel resource cannot be modified: ${file}"
        fi
    done

    # check staged changes
    for file in $(git diff --name-only --cached); do
        if [[ "${file}" =~ ^deploy/olm-catalog/${operator_name}/${csv_version}/.* ]]; then
            error "Protected channel resource cannot be modified: ${file}"
        fi
    done
}

if [ ! -f "$(which yq 2> /dev/null)" ]; then
    error "yq command not found"
fi

DEPLOY_DIR=${DEPLOY_DIR:-deploy}
OPERATOR_NAME=$(ls ${DEPLOY_DIR}/olm-catalog | head -1)
PACKAGE_FILE=$(find ${DEPLOY_DIR} -name '*.package.yaml' | head -1)

if [ ! -f "${PACKAGE_FILE}" ]; then
    error "Missing package yaml file"
fi

# protect stable-v1 channel
STABLE_CSV=$(yq r ${PACKAGE_FILE} "channels.(name==stable-v1).currentCSV")
protect_csv ${STABLE_CSV} "stable-v1" ${OPERATOR_NAME}

# protect beta channel
BETA_CSV=$(yq r ${PACKAGE_FILE} "channels.(name==beta).currentCSV")
protect_csv ${BETA_CSV} "beta" ${OPERATOR_NAME}
