# 💃 SALSA 💃

![SLSA Level 3](./docs/assets/slsa-level3.svg)
[![ruby-test](https://github.com/github/salsa/actions/workflows/ruby-test.yml/badge.svg)](https://github.com/github/salsa/actions/workflows/ruby-test.yml)
[![ruby-test-non-defaults](https://github.com/github/salsa/actions/workflows/ruby-test-non-defaults.yml/badge.svg)](https://github.com/github/salsa/actions/workflows/ruby-test-non-defaults.yml)
[![acceptance-multiple-artifacts](https://github.com/github/salsa/actions/workflows/acceptance-multi.yml/badge.svg)](https://github.com/github/salsa/actions/workflows/acceptance-multi.yml)
[![acceptance-single-artifact](https://github.com/github/salsa/actions/workflows/acceptance-single.yml/badge.svg)](https://github.com/github/salsa/actions/workflows/acceptance-single.yml)
[![acceptance-single-artifact-dir](https://github.com/github/salsa/actions/workflows/acceptance-single-dir.yml/badge.svg)](https://github.com/github/salsa/actions/workflows/acceptance-single-dir.yml)
[![acceptance-single-artifact-file](https://github.com/github/salsa/actions/workflows/acceptance-single-file.yml/badge.svg)](https://github.com/github/salsa/actions/workflows/acceptance-single-file.yml)
[![acceptance-single-artifact-id-only](https://github.com/github/salsa/actions/workflows/acceptance-artifact-id-only.yml/badge.svg)](https://github.com/github/salsa/actions/workflows/acceptance-artifact-id-only.yml)
[![CodeQL](https://github.com/github/salsa/actions/workflows/github-code-scanning/codeql/badge.svg)](https://github.com/github/salsa/actions/workflows/github-code-scanning/codeql)
[![Dependabot Updates](https://github.com/github/salsa/actions/workflows/dependabot/dependabot-updates/badge.svg)](https://github.com/github/salsa/actions/workflows/dependabot/dependabot-updates)

Supply-chain Levels for Software Artifacts, or [SLSA](https://slsa.dev/) ("salsa") is a security framework, a checklist of standards and controls to prevent tampering, improve integrity, and secure packages and infrastructure.

This repository contains a set of reusable GitHub Actions workflows to help you build your own SLSA Level 3 compliant pipeline.

The core focus of this project is to provide the tools, knowledge, building blocks, and best practices so that anyone can bring their software supply chain to SLSA Level 3.

## SLSA Levels 🪜

- **Level 0**: No security guarantees
- **Level 1**: Provenance exists for traceability, but minimal tamper resistance
- **Level 2**: Provenance signed by a managed build platform, deterring simple tampering
- **Level 3**: Provenance from a hardened, tamper-resistant build platform, ensuring high security against compromise

## Hitting SLSA Level 3 🎯

> *Reaching SLSA Level 3 may seem complex, but GitHub’s Artifact Attestations feature makes it remarkably straightforward. Generating build provenance puts you at [SLSA Level 1](https://slsa.dev/spec/v1.0/levels#build-l1), and by using GitHub Artifact Attestations on GitHub-hosted runners, you reach [SLSA Level 2](https://slsa.dev/spec/v1.0/levels#build-l2) by default.*
> [github.blog](https://github.blog/enterprise-software/devsecops/enhance-build-security-and-reach-slsa-level-3-with-github-artifact-attestations/)

What this breaks down to is that by using GitHub Actions, and GitHub Artifact Attestations you can reach SLSA Level 2 by default. To reach SLSA Level 3, you need to ensure that your build and release process is not susceptible to tampering through the use of a shared cache or shared environment.

This means that you need to do the following:

1. **Have an isolated build environment**: The build job must not use the Actions cache, as this can be poisoned by an attacker. This means that you need to ensure that the build job does not use the Actions cache or other shared resources.
2. **Use a separate job for signing**: The signing job must not run in the same environment as the build job. This is to ensure that the signing material is not in the same environment as the release job.
3. **Use immutable versions of actions**: This is to ensure that the actions you are using are not modified by an attacker. This means that you need to pin the actions you are using to a specific commit or tag.
4. **Use immutable versions of artifacts**: If you are using GitHub Actions to upload build artifacts and then later download them for signing, you need to ensure that the artifacts are immutable and have not been tampered with. This means downloading by the artifact ID and not by the name of the artifact.

This project provides a set of reusable workflows to help you achieve all of these goals, and even with your existing workflows.

## Examples 📸

> All of the following examples demonstrate SLSA level 3 compliance. If you have an example of your own, please feel free to submit a PR and we will add it to the list.

To start off the example section, it is best to look at a pseudo-code example of a stripped down workflow that shows the basic structure of a SLSA Level 3 compliant workflow.

```yaml
# Example pseudo-code of a SLSA Level 3 compliant workflow
jobs:
  # define your build job here
  build:
    steps:
      # ...

  # use the reusable workflow to sign the artifacts
  sign:
    needs: build
    uses: github/salsa/.github/workflows/sign-artifact.yml@main # optionally pin to a specific commit or tag

  # optionally verify the artifacts
  verify:
    needs: [release, sign] # ensure that you require all the jobs to run before this one
    uses: github/salsa/.github/workflows/verify.yml@main # optionally pin to a specific commit or tag
```

As you can see above, the workflow is really just composed of three jobs:

1. **Build**: This is where you build your project and create the artifacts. This job should not use the Actions cache or any shared resources. It should be has isolated, hardened, and tamper-resistant as possible.
2. **Sign**: This job uses the `github/salsa/.github/workflows/sign-artifact.yml` workflow to sign the artifacts created in the build job. This job run in a separate job (a fresh environment in Actions) to ensure that the signing material is not in the same environment as the release job.
3. **Verify**: This job uses the `github/salsa/.github/workflows/verify.yml` workflow to verify the artifacts that were signed in the sign job. This is an optional step, but it is a good practice to verify the artifacts after signing to ensure they are valid as your clients will be doing the same.

Now let's look at a little more filled out example of a release workflow:

```yaml
name: release-slsa-level-3

on:
  push:
    tags:
      - "*"

permissions: {}

jobs:
  release:
    permissions:
      contents: write # required for creating releases on GitHub
    runs-on: ubuntu-latest
    outputs:
      artifact-id: ${{ steps.upload-artifact.outputs.artifact-id }} # used below

    steps:
      # checkout your project's code
      - name: checkout
        uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683 # pin@v4
        with:
          persist-credentials: false

      # run some build steps
      # in this example, some script builds a project and outputs many artifacts to the dist/ dir
      - name: build
        run: script/build --output=dist/

      # Upload the artifacts to be used in other jobs
      - name: upload artifact
        uses: actions/upload-artifact@4.6.2 # this is using an immutable version of the action 
        id: upload-artifact # set an ID to reference this step in the outputs
        with:
          path: dist/

  # The sign job runs in a separate job to ensure the signing material is not in the same environment as the release job
  # It uses the `github/salsa/.github/workflows/sign-artifact.yml` workflow to sign the artifacts
  # It then uploads attestations via the actions/attest-build-provenance action
  sign:
    needs: release # ensure that the release job has completed before this one
    permissions:
      id-token: write
      attestations: write
      contents: read
    uses: github/salsa/.github/workflows/sign-artifact.yml@main # optionally pin to a specific commit or tag
    with:
      artifact-ids: ${{ needs.release.outputs.artifact-id }} # download the artifacts from the release job
      artifact-path: "." # this says look at the current dir (now the contents of the dist/ dir from the release job) and sign the artifacts in there

  # This step is optional but recommended
  # It uses the `github/salsa/.github/workflows/verify.yml` workflow to verify the artifacts that were signed in the sign job
  # It is a good practice to verify the artifacts after signing to ensure they are valid as your clients will be doing the same
  verify:
    permissions: {}
    needs: [release, sign] # ensure that you require all the jobs to run before this one
    uses: github/salsa/.github/workflows/verify.yml@main # optionally pin to a specific commit or tag
    with:
      artifact-ids: ${{ needs.release.outputs.artifact-id }} # download the artifacts from the release job
      artifact-path: "." # look in the current dir and verify all the artifacts in there
```

### Ruby

This project comes with a pre-built reusable workflow specifically catered towards building Ruby Gems. Here is how you can use it:

```yaml
name: release

on:
  workflow_dispatch:
  push:
    branches:
      - main
    paths:
      - lib/version.rb # example of a file that would trigger a release

permissions: {}

jobs:
  release:
    permissions:
      contents: write
      id-token: write
      packages: write
      attestations: write
    uses: github/salsa/.github/workflows/ruby.yml@8dcc6862bc15683d9841f2da7cba5ad7570e2c38 # pin@v0.3.0
    with:
      bootstrap_script: script/bootstrap # path to the script that bootstraps the project (optional)
      build_script: script/build # path to the script that builds the gem
      auto_setup_ruby: true # whether or not to automatically call the setup-ruby action
      setup_ruby_action_version: v1 # the version of https://github.com/ruby/setup-ruby to use
      ruby_version: 3.4 # the version of Ruby to use with the setup-ruby action (or it reads from .ruby-version if unset)
      publish_rubygems: true # whether or not to publish the gem to rubygems.org
      publish_github_packages: true # whether or not to publish the gem to GitHub Packages
      push_github_release: true # whether or not to push a release to GitHub
      sign: true # whether or not to sign the gem
      verify: true # whether or not to verify the gem after it is signed
    secrets:
      RUBYGEMS_API_KEY: ${{ secrets.RUBYGEMS_API_KEY }} # required for publishing to rubygems.org
```

Example of a custom `script/bootstrap` script:

```bash
#! /usr/bin/env bash
set -e

bundle install
```

Example of a custom `script/build` script:

```bash
#! /usr/bin/env bash

set -e

GEM_NAME=$(ls | grep gemspec | cut -d. -f1)
GEM_VERSION=$(gem build $GEM_NAME.gemspec 2>&1 | grep Version | cut -d':' -f 2 | tr -d " \t\n\r")

# IMPORTANT: this script MUST export for the following outputs:
# gem_name: the name of the gem - ex: "my-cool-gem"
# gem_version: the version of the gem - ex: "1.0.0"
# gem_path: the path/filename of the gem - ex: "my-cool-gem-1.0.0.gem"
# Here is an example doing exactly that:
if [[ "$CI" == "true" ]]; then
  echo "gem_name=$GEM_NAME" >> $GITHUB_OUTPUT
  echo "gem_version=$GEM_VERSION" >> $GITHUB_OUTPUT
  echo "gem_path=$GEM_NAME-$GEM_VERSION.gem" >> $GITHUB_OUTPUT
fi

echo -e "📦 ${GREEN}successfully${OFF} built ${PURPLE}$GEM_NAME-$GEM_VERSION.gem${OFF}"
```

An important note about the `script/build` script and this pre-built Ruby workflow is that it makes the following assumptions:

- The `gemspec` file should be in the root of the repository
- The resulting `.gem` file that gets built should be in the root of the repository
- The `script/build` script should export the following variables to `$GITHUB_OUTPUT`:
  - `gem_name`: the name of the gem (ex: `my-cool-gem`)
  - `gem_version`: the version of the gem (ex: `1.0.0`)
  - `gem_path`: the path/filename of the gem (ex: `my-cool-gem-1.0.0.gem`) (remember, in the root of the repo)
- Only one Gem is built (this is a limitation of the current implementation)

Here is a live example of this custom Ruby SLSA Level 3 releaser in Action: [grantbirki/net-http-ext](https://github.com/GrantBirki/net-http-ext/blob/439b511908bde9bd448cc473d9a34968ea224061/.github/workflows/release.yml)

### GoLang

The following example shows how a GoLang project can adopt these workflows into an existing release workflow to achieve SLSA Level 3 compliance.

See the [gh-combine](https://github.com/github/gh-combine/blob/6b7641b08b24158dcafccbf78f5383a8014afce6/.github/workflows/release.yml) repo for a live example of this in action.

```yaml
name: release

on:
  push:
    tags:
      - "*"

permissions: {}

jobs:
  release:
    permissions:
      contents: write # required for creating releases on GitHub
    runs-on: ubuntu-latest
    outputs:
      artifact-id: ${{ steps.upload-artifact.outputs.artifact-id }} # used below

    steps:
      # checkout your project's code
      - name: checkout
        uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683 # pin@v4
        with:
          persist-credentials: false

      # bootstrap your Go project
      - name: setup go
        uses: actions/setup-go@0aaccfd150d50ccaeb58ebd88d36e91967a5f35b # pin@v5
        with:
          go-version-file: "go.mod"
          cache: false # SLSA Level 3 cannot use the Actions cache due to the risk of cache poisoning

      # In this example, we are using GoReleaser to build and release our project
      - name: goreleaser
        uses: goreleaser/goreleaser-action@9c156ee8a17a598857849441385a2041ef570552 # pin@v6
        with:
          args: release --clean
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

      # Upload the artifacts (created by GoReleaser in the dist/ dir) as an artifact
      - name: upload artifact
        uses: actions/upload-artifact@4.6.2 # this is using an immutable version of the action 
        id: upload-artifact # set an ID to reference this step in the outputs
        with:
          path: dist/

  # The sign job runs in a separate job to ensure the signing material is not in the same environment as the release job
  # It uses the `github/salsa/.github/workflows/sign-artifact.yml` workflow to sign the artifacts
  # It then uploads attestations via the actions/attest-build-provenance action
  sign:
    needs: release # ensure that the release job has completed before this one
    permissions:
      id-token: write
      attestations: write
      contents: read
    uses: github/salsa/.github/workflows/sign-artifact.yml@main # optionally pin to a specific commit or tag
    with:
      artifact-ids: ${{ needs.release.outputs.artifact-id }} # download the artifacts from the release job
      artifact-path: "." # this says look at the current dir (now the contents of the dist/ dir from the release job) and sign the artifacts in there

  # This step is optional but recommended
  # It uses the `github/salsa/.github/workflows/verify.yml` workflow to verify the artifacts that were signed in the sign job
  # It is a good practice to verify the artifacts after signing to ensure they are valid as your clients will be doing the same
  verify:
    permissions: {}
    needs: [release, sign] # ensure that you require all the jobs to run before this one
    uses: github/salsa/.github/workflows/verify.yml@main # optionally pin to a specific commit or tag
    with:
      artifact-ids: ${{ needs.release.outputs.artifact-id }} # download the artifacts from the release job
      artifact-path: "." # look in the current dir and verify all the artifacts in there
```
