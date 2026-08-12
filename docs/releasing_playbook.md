# Releasing Playbook

## Nightly releases for default branches

TODO

## Creating release branches

To create branches that preserve the source code for a release or to accept
cherry-picks while iterating on release candidates, we create release branches
with the same name across each main repository. Additional repositories from
[TheRock's `.gitmodules` file](https://github.com/ROCm/TheRock/blob/main/.gitmodules)
may be included as needed.

Repository | Example branch
-- | --
https://github.com/ROCm/TheRock | [`release/therock-10.0`](https://github.com/ROCm/TheRock/tree/release/therock-10.0)
https://github.com/ROCm/llvm-project | [`release/therock-10.0`](https://github.com/ROCm/llvm-project/tree/release/therock-10.0)
https://github.com/ROCm/rocm-systems | [`release/therock-10.0`](https://github.com/ROCm/rocm-systems/tree/release/therock-10.0)
https://github.com/ROCm/rocm-libraries | [`release/therock-10.0`](https://github.com/ROCm/rocm-libraries/tree/release/therock-10.0)
https://github.com/ROCm/rocgdb | [`release/therock-10.0`](https://github.com/ROCm/rocgdb/tree/release/therock-10.0)
https://github.com/ROCm/libhipcxx | Only created if needed
(Others) | Only created if needed


For example, to branch from the nightly release with ROCm version
`10.1.0a20260811`:
1. Find the workflow run that produced that release: https://github.com/ROCm/rockrel/actions/runs/31444849807
2. Check the commit manifest or logs to find the associated TheRock commit: https://github.com/ROCm/TheRock/commit/03e3f2eba205f9a8f554a24d5e76925b39efab7a
    * For example: https://therock-nightly-artifacts.s3.amazonaws.com/31444849807-linux/manifests/therock_manifest.json

        ```json
        {
          "the_rock_commit": "03e3f2eba205f9a8f554a24d5e76925b39efab7a",
          "github_job": "build_stage",
          "github_run_id": "31444849807",
          "rocm_package_version": "10.1.0a20260811",
          "rocm_version": "10.1.0",
          "submodules": [
            ...
            {
              "submodule_name": "llvm-project",
              "submodule_path": "compiler/amd-llvm",
              "submodule_url": "https://github.com/ROCm/llvm-project.git",
              "pin_sha": "0240d7087e183944016616b505eba935efe59157",
              "patches": []
            },
            ...
        ```
3. Checkout sources, without applying patches:

    ```bash
    cd TheRock
    git checkout 03e3f2eba205f9a8f554a24d5e76925b39efab7a
    python build_tools/fetch_sources.py --no-apply-patches

    # Note: explicitly include rocgdb on Windows
    python build_tools/fetch_sources.py --no-apply-patches --debug-tools=rocgdb
    ```
4. Check that each submodule is set to the commits you expect from the manifest/logs

    ```bash
    # Check all at once:
    git submodule status
    #  207ee58595a64b5c4a70df221f1e6e704b807811 base/half (rocm-6.4.1-1-g207ee58)
    #  10155d7272ea1bf79f6b5a9dbc339657af1aa372 base/rocm-cmake (mock-tag-test-6-g10155d7)
    #  0240d7087e183944016616b505eba935efe59157 compiler/amd-llvm (llvmorg-23-init-567091-g0240d7087e18)
    #  1c0fdf11502f06c4b4e978e35a1135240ea38e6f compiler/hipify (therock-7.14-2-g1c0fdf11)
    #  ddeda6468d45cf1e888a0e81e50bc170756a335b compiler/spirv-llvm-translator (therock-7.14-66-gddeda646)
    #  5a74aaa2a1fcd1437cb5f97d35f5b88e53e97043 debug-tools/rocgdb/source (therock-7.14-46-g5a74aaa2a1f)
    #  34e124071332781a6968d765afa5dbd9f8aac7d4 math-libs/libhipcxx (therock-7.14-7-g34e124071)
    #  67811f1ee5242e82539446e5fdcb87fb87100061 rocm-libraries (therock-7.13-7473-g67811f1ee52)
    #  5bc651a82683b2ae21acf14ffc9af35f5c2722ae rocm-systems (hip-version_10.1.62220-42-g5bc651a8268)
    # -75b4d6b0b4bdd0a8d61468f8e6faf4aa7309342f third-party/sysdeps/linux/amd-mesa/mesa-fork

    # Or check individually:
    git -C compiler/amd-llvm rev-parse HEAD
    # 0240d7087e183944016616b505eba935efe59157
    ```

    Note how compiler/amd-llvm uses `0240d7087e183944016616b505eba935efe59157`.

5. Choose your new branch name, e.g. `release/bkc/therock-10.1-20260811`
6. Create branches in each repository and push them. The command-scoped
   `pushInsteadOf` setting uses SSH for HTTPS GitHub remotes without changing
   the repositories' configured remote URLs:

    ```bash
    # From TheRock
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
      git -C "${repository_path}" branch "${BRANCH_NAME}"
      git -c "${SSH_PUSH_CONFIG}" -C "${repository_path}" push -u origin \
        "${BRANCH_NAME}:${BRANCH_NAME}"
    done
    ```

    Or, with the loop unrolled:

    ```bash
    # From TheRock
    BRANCH_NAME="release/bkc/therock-10.1-20260811"
    SSH_PUSH_CONFIG="url.git@github.com:.pushInsteadOf=https://github.com/"
    git -C . branch "${BRANCH_NAME}" && git -c "${SSH_PUSH_CONFIG}" -C . push -u origin "${BRANCH_NAME}:${BRANCH_NAME}"
    git -C rocm-libraries branch "${BRANCH_NAME}" && git -c "${SSH_PUSH_CONFIG}" -C rocm-libraries push -u origin "${BRANCH_NAME}:${BRANCH_NAME}"
    git -C rocm-systems branch "${BRANCH_NAME}" && git -c "${SSH_PUSH_CONFIG}" -C rocm-systems push -u origin "${BRANCH_NAME}:${BRANCH_NAME}"
    git -C compiler/amd-llvm branch "${BRANCH_NAME}" && git -c "${SSH_PUSH_CONFIG}" -C compiler/amd-llvm push -u origin "${BRANCH_NAME}:${BRANCH_NAME}"
    git -C debug-tools/rocgdb/source branch "${BRANCH_NAME}" && git -c "${SSH_PUSH_CONFIG}" -C debug-tools/rocgdb/source push -u origin "${BRANCH_NAME}:${BRANCH_NAME}"
    ```
