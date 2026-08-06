set shell := ["bash", "-eu", "-o", "pipefail", "-c"]

image := "repo-settings-sync:test"

# Run the checks expected to pass on every pull request.
default: test

# Run all non-lint validation and smoke tests.
test: validate docker-smoke

# Validate action metadata and supporting JSON files.
validate:
    ruby scripts/validate-action-metadata.rb
    jq empty error-matcher.json metadata.json
    git diff --check

# Build the packaged Docker action.
docker-build:
    docker build --tag {{image}} .

# Start the packaged action without making GitHub API requests.
docker-smoke: docker-build
    docker run --rm \
      -e GITHUB_REPOSITORY=cerebruminc/github-action-repo-settings-sync \
      -e GITHUB_API_URL=https://api.github.invalid \
      -e INPUT_REPOSITORIES= \
      -e INPUT_ALLOW_ISSUES=true \
      -e INPUT_ALLOW_PROJECTS=true \
      -e INPUT_ALLOW_WIKI=true \
      -e INPUT_SQUASH_MERGE=true \
      -e INPUT_MERGE_COMMIT=true \
      -e INPUT_REBASE_MERGE=true \
      -e INPUT_AUTO_MERGE=false \
      -e INPUT_DELETE_HEAD=false \
      -e INPUT_BRANCH_PROTECTION_ENABLED=false \
      -e INPUT_BRANCH_PROTECTION_NAME=main \
      -e INPUT_BRANCH_PROTECTION_REQUIRED_REVIEWERS=1 \
      -e INPUT_BRANCH_PROTECTION_DISMISS=true \
      -e INPUT_BRANCH_PROTECTION_CODE_OWNERS=true \
      -e INPUT_BRANCH_PROTECTION_ENFORCE_ADMINS=false \
      -e INPUT_BRANCH_PROTECTION_REQUIRED_STATUS_CHECKS=false \
      -e INPUT_BRANCH_PROTECTION_REQUIRE_SIGNED_COMMITS=false \
      -e INPUT_BRANCH_PROTECTION_RESTRICT_PUSHES_TEAM_ALLOWED=maintainers \
      -e INPUT_TOKEN=dummy \
      {{image}} | sed 's/^::/docker-action: ::/'

# Lint the shell entrypoint. This initially exposes existing findings.
shellcheck:
    shellcheck -x entrypoint.sh

# Run every CI target, including ShellCheck.
ci: test shellcheck
