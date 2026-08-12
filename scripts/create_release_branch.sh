#!/bin/bash
# Copyright Advanced Micro Devices, Inc.
# SPDX-License-Identifier: MIT

set -euox pipefail

BRANCH_NAME="release/bkc/therock-10.1-20260811"
SSH_PUSH_CONFIG="url.git@github.com:.pushInsteadOf=https://github.com/"
REPOSITORY_PATHS=(
    "."
    "rocm-libraries"
    "rocm-systems"
    "compiler/amd-llvm"
    "debug-tools/rocgdb/source"
)

for repository_path in "${REPOSITORY_PATHS[@]}"; do
    # Create the branch in the current repository, reset if it already exists
    git \
        -C "${repository_path}" \
        branch -f "${BRANCH_NAME}"

    # Push from local to remote using SSH
    git \
        -c "${SSH_PUSH_CONFIG}" \
        -C "${repository_path}" \
        push -u origin "${BRANCH_NAME}:${BRANCH_NAME}"
done
