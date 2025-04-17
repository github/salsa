# 💃 SALSA 💃

Supply-chain Levels for Software Artifacts, or [SLSA](https://slsa.dev/) ("salsa") is a security framework, a checklist of standards and controls to prevent tampering, improve integrity, and secure packages and infrastructure.

This repository contains a set of reusable GitHub Actions workflows to help you build your own SLSA Level 3 compliant pipeline.

The core focus of this project is to provide the tools, knowledge, building blocks, and best practices so that anyone can bring their software supply chain to SLSA Level 3.

## Example 📸

### GoLang SLSA Level 3 Example

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
