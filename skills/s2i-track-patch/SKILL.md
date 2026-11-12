---
name: s2i-track-patch
description: Track an OpenDev (Gerrit) patch through the S2I container pipeline — upstream branch, s2i-openstack-containers source pin, published images, downstream packaging repo pin, and Konflux build. Arguments are the Gerrit change and the target release branch.
argument-hint: "<gerrit-change-url | change-number | Change-Id> [release-branch] [--downstream <path>] [--workspace <dir>] [--upstream-only]"
user-invocable: true
allowed-tools: ["Bash", "Read", "Grep", "Glob"]
context: fork
---

## User Input

```text
$ARGUMENTS
```

Answer one question for the engineer: **where is this patch right now, and what has to
happen next for it to reach a product container?**

The patch starts as an OpenDev (Gerrit) change on `review.opendev.org` and ends as a layer
in a container image built from the downstream packaging repository. Report the state of
every hop in between, using read-only operations.

## Pre-flight

Run this before parsing anything else and show the result as a short readiness table.

Local clones are the supported setup, not an optimisation. With the three repositories on
disk a full run needs one Gerrit request and a couple of `gh` calls for open-PR state;
without them the same run becomes dozens of API round trips, each a chance to hit a rate
limit, a proxy, or an offline network.

### Tools

```bash
git --version                                   # required
curl --version | head -1                        # required: Gerrit REST
gh --version && gh auth status 2>&1 | head -3   # open PR state, and API fallback
git review --version 2>/dev/null                # optional: the cherry-pick action
glab --version 2>/dev/null                      # optional: open downstream import MRs
skopeo --version 2>/dev/null                    # optional: confirm a published image tag
```

`git` and `curl` are required. `gh` is required whenever a clone is missing, and for stage 3d
and stage 4 regardless, since open-PR state has no local equivalent. The last three only
widen what the report can confirm; their absence is a `SKIPPED` line under **Not verified**,
never a blocked run.

### Repositories

| Repo | Role | Resolved from |
|------|------|---------------|
| upstream project source (opendev) | merged SHA for a `Change-Id`, every ancestry test | `--src`, `$S2I_PROJECT_REPO`, `<workspace>/<project>`, else the GitHub mirror |
| `s2i-openstack-containers` | tracked branch, pins, pin-bump history, image targets | `--s2i`, `$S2I_UPSTREAM_REPO`, `<workspace>/s2i-openstack-containers`, else `gh` |
| downstream packaging repo | downstream pin, submodule gitlink, Konflux components | `--downstream`, `$S2I_DOWNSTREAM_REPO`, else asked for once downstream is in scope |

`<workspace>` is `--workspace` or `$S2I_WORKSPACE` — a directory the user names that holds
their upstream clones. Looking inside it is not discovery: the user pointed at it. The
project clone is resolved once stage 1 names the project.

The downstream repo is never searched for and never cloned by this skill. Take the path from
the flag, the environment, or the user.

Validate every path by comparing the worktree root against the path itself. A bare
`rev-parse` is not enough: inside an uninitialised submodule or any subdirectory, `git -C`
silently answers for the enclosing repository and the run then reports another repo's
history as fact.

```bash
test "$(git -C <path> rev-parse --show-toplevel)" = "$(cd <path> && pwd -P)"
test -d <downstream>/source2image          # downstream only
```

Confirm each upstream clone is the repository it claims to be, and resolve its remote name at
the same time — a clone may call the canonical repository `origin`, `upstream`, or a fork
name, so no later command may hardcode `origin`:

```bash
git -C <s2i> remote -v \
  | awk '/openstack-k8s-operators\/s2i-openstack-containers/ {print $1; exit}'
git -C <src> remote -v | awk '/\/<project>(\.git)?[[:space:]]/ {print $1; exit}'
```

An empty result means the path is a different repository: say so and ask for a corrected one.
Carry the resolved names as `<s2i-remote>` and `<src-remote>` through every later stage.

If a check fails, say what was expected and ask for a corrected path.

### Readiness and setup

Report what is ready, what is missing, and what each gap costs:

```markdown
| Item | State | Effect if missing |
|------|-------|-------------------|
| git, curl | ready | — |
| gh (authenticated) | ready | stages 3d and 4 unavailable |
| s2i clone | missing | falls back to the GitHub API |
| project clone | missing | ancestry falls back to the mirror's compare API |
| downstream clone | not supplied | asked for if downstream is in scope, never skipped silently |
| git review, glab, skopeo | optional | fewer checks confirmed |
```

Offer to close the gaps, and ask before running anything that writes to disk:

```bash
git clone https://github.com/openstack-k8s-operators/s2i-openstack-containers.git \
  <workspace>/s2i-openstack-containers
git clone https://opendev.org/openstack/<project>.git <workspace>/<project>
```

Never offer to clone the downstream repo — the user clones it in advance, from a remote this
skill does not name.

Refresh the public clones before trusting them, and leave the downstream clone alone:

```bash
git -C <s2i> fetch --quiet <s2i-remote>
git -C <src> fetch --quiet <src-remote>
# downstream: report staleness instead of fetching
git -C <downstream> log -1 --format='%cr' <target_branch>
```

A downstream clone whose target branch is weeks old produces a stale stage 6. Say how old it
is and let the user refresh it; never fetch from that remote on their behalf.

Stop here only when something required for the agreed scope is missing and the user cannot
supply it. Everything else proceeds with the fallback noted in the report.

## Parsing the arguments

| Argument | Required | Meaning |
|----------|----------|---------|
| Gerrit change | yes | `https://review.opendev.org/c/openstack/<project>/+/<number>`, a bare change number, or a `Change-Id` (`I` + 40 hex chars) |
| Target branch | no | release branch of the downstream packaging repo, as named in that repo |
| `--project <name>` | no | s2i container directory, when it differs from the Gerrit project name |
| `--stream <name>` | no | `sources.txt` stream, default `master` |
| `--workspace <dir>` | no | directory holding the upstream clones; see [Pre-flight](#pre-flight) |
| `--s2i <path>` | no | clone of `s2i-openstack-containers`, overriding the workspace lookup |
| `--src <path>` | no | clone of the upstream project source, overriding the workspace lookup |
| `--downstream <path>` | for downstream stages | clone of the downstream packaging repo, cloned by the user in advance |
| `--upstream-only` | no | stop the report at the quay.io boundary |

If no Gerrit change is given, ask for one before doing anything else.

These arguments settle part of how far the run goes, and never the whole of it: a target
branch still needs a downstream clone, and an absent branch settles nothing. See [Settle the
scope](#settle-the-scope).

## Settle the scope

The scope is a prerequisite of the run, not a default it falls back to. No stage executes
until it is settled as one of:

- **upstream only** — stages 1-5, ending at the quay.io boundary, or
- **upstream and downstream** — the above plus one or more named release branches.

Settling the scope and having the inputs to execute it are two different things. A target
branch on the command line settles that downstream **is** in scope; it does not supply the
clone that scope needs. Treat the two separately:

| Given | Scope | Then |
|-------|-------|------|
| `--upstream-only` | upstream only | run stages 1-5, ask nothing |
| branch + `--downstream` | upstream and downstream | run everything, ask nothing |
| branch, no `--downstream` | upstream and downstream | **ask for the path** before stage 1 |
| `--downstream`, no branch | undecided | ask the scope question below |
| neither | undecided | ask the scope question below |

`--upstream-only` together with a target branch is contradictory: say so and ask which was
meant rather than silently honouring one.

**A branch argument never degrades to an upstream-only report.** When downstream is in scope
and no validated path exists, ask for one:

> Tracking `<branch>` needs a clone of the downstream packaging repo. Path?

Only an explicit refusal turns stages 6-8 into `UNKNOWN`. Reaching the report with those rows
unexplained, having never asked, is a defect — the user named a branch, which is a request for
the downstream half.

Where the scope itself is undecided, ask before stage 1, in one round, with the host's menu
tool — `AskUserQuestion` on the CLI platform, `AskQuestion` in Cursor, and in OpenCode a
numbered list followed by a wait for the reply.

With a downstream path already supplied, the options are:

- **Upstream only** — stages 1-5, ending at the quay.io boundary.
- **Upstream and downstream (<branch>)** — when that clone's version-shaped branch list holds
  exactly one entry, name it in the label so one answer settles both questions.
- **Upstream and downstream (choose branch)** — when the list holds several; follow with a
  second question listing them, accepting more than one answer where the menu tool supports
  it, and let the user name the branches.

With no downstream path supplied, the options are **Upstream only** and **Give me the path to
a downstream clone**. Take the second answer as the path itself, validate it, then ask the
branch question.

Build the branch list from the supplied clone. Only release branches are tracking targets —
version-shaped names such as `X.Y.Z`:

```bash
# release branches only, local and remote, deduplicated
git -C <downstream> branch -a --format='%(refname:short)' \
  | sed 's#^[^/]*/##' | sort -u | grep -E '^[0-9]+(\.[0-9]+)+$'
```

`main`, `master`, and the `konflux/` and `mintmaker/` branches are build plumbing, not
releases: never offer them and never track against them. Topic branches are equally
irrelevant. If the pattern matches nothing, say so and ask the user to name the branch
rather than listing whatever else the clone happens to carry.

Never infer the scope from what happens to be reachable. Supplying a downstream path is not
by itself a request to track downstream, and a lone release branch inside that clone is not a
request to track that branch: both are offered as answers, never applied on their own.

A report covering only stages 1-5 states which reason applies — the user chose upstream-only,
or they declined to supply a clone. In the second case keep stages 6-8 in the table as
`UNKNOWN` (no downstream clone provided) and record it under **Not verified**; only
`--upstream-only` removes those rows.

The gate holds on every platform. Without a menu tool, print the numbered options and wait —
silence is not an answer, and no stage runs until one arrives.

## The pipeline

```text
Upstream OpenDev
  [1] change merged on master
  [2] cherry-picked to the tracked branch (e.g. stable/2026.2)
        │
Upstream openstack-k8s-operators (s2i-openstack-containers)
  [3] pin bump: daily `update-sources` PR (auto/update-sources) — or a manual PR
      when the change cannot wait for the daily run
  [4] per-component validation jobs + human review → PR merged to main
  [5] post-merge Zuul job pushes images to quay.io/openstack-s2i-containers
        │
Downstream (packaging repo, Konflux)
  [6] import MR: s2i content sync + submodule/pin update on the release branch,
      manual or periodic
  [7] Konflux pull-request pipeline builds and tests the MR + human review
  [8] on merge, the push pipeline publishes a new component build
  [9] the weekly bundle rolls all component updates up for downstream testing
```

A patch sits at exactly one boundary: the last stage that contains it, waiting on the next.

## Vocabulary

| Term | Meaning |
|------|---------|
| **Pin** | Commit hash in column 5 of `sources.txt`. Images build from this commit, not from branch tips. |
| **Stream** | Column 1 of `sources.txt` (usually `master`). Selects which pins a build uses and the Quay tag prefix. |
| **Tracked branch** | Column 4 of `sources.txt` (e.g. `stable/2026.2`). The branch the daily `update-sources` job follows. A change on any other branch never reaches the pin. |
| **Image target** | A `<project>/<image>` build target such as `cinder/cinder-api`. One project can produce several. |
| **Component** | Konflux component in the downstream repo, named after the image and release branch, wired by a `.tekton/` PipelineRun. |
| **Bundle** | Weekly downstream roll-up of component builds. |

`sources.txt` has the same columns in both repositories:

```text
<stream> <name> <git_url> <tracked_branch> <pinned_sha> <version>
```

Upstream it lives at `containers/<project>/sources.txt`, downstream at
`source2image/<project>/sources.txt`. Downstream, each source tree is also a git submodule
at `source2image/<project>/src/<name>`; the submodule gitlink is what Konflux builds, and
the two are expected to agree.

## Stage 1 — Resolve the Gerrit change

One query returns the master change and all of its cherry-picks:

```bash
WORKDIR=/tmp/s2i-track-patch/<change_number>
mkdir -p "${WORKDIR}"
curl -sS "https://review.opendev.org/changes/?q=change:<CHANGE_ID_OR_NUMBER>&o=CURRENT_REVISION&o=CURRENT_COMMIT" \
  | sed "1s/^)]}'//" > "${WORKDIR}/gerrit.json"
```

Strip the `)]}'` XSSI prefix before parsing. Read `_number`, `project`, `branch`, `status`,
`subject`, `change_id`, and `current_revision` from each returned change, and record the
project (`openstack/<name>`) — it drives every later lookup.

A change still in `NEW` cannot be contained anywhere downstream of it. Report stage 1 as in
flight, skip the ancestry checks, and still report where the tracked branch sits so the
engineer sees what they are waiting for.

**Merged SHA caveat.** `current_revision` is the last patchset's commit; when Gerrit submits
with a cherry-pick or rebase strategy the merged SHA differs. Resolve the real one from the
project clone, which is authoritative and needs no API:

```bash
git -C <src> log --grep "<CHANGE_ID>" --format=%H "<src-remote>/<tracked_branch>"
```

Without a clone, fall back to the GitHub mirror — verify the revision exists, and if it
404s, search the branch for the `Change-Id` trailer:

```bash
gh api "repos/openstack/<name>/commits/<SHA>" --jq '.sha'
gh api "repos/openstack/<name>/commits?sha=<tracked_branch>&per_page=100" \
  --jq '.[] | select(.commit.message | contains("<CHANGE_ID>")) | .sha'
```

Use the SHA **on the tracked branch** for the ancestry checks; the master SHA does not feed
the pin.

## Stage 2 — Cherry-pick onto the tracked branch

Read the tracked branch from the s2i `sources.txt` of the project (stage 3 resolves that
path; either order works), then:

- a merged change with this `Change-Id` on the tracked branch → stage 2 is done;
- merged only on `master` → the patch is **blocked** and reaches no image until it is
  cherry-picked. Say so, and give the action: `git review -x <change_number>` on the tracked
  branch, or the Gerrit *Cherry pick* button;
- a cherry-pick that is still `NEW` → report its change number and URL as in flight.

Changes on other branches (older stables, unmaintained) are context, never progress.

## Stage 3 — Source pin in s2i-openstack-containers

### 3a. Map the project to a container directory

Try `containers/<name>` first and confirm the git URL appears in its `sources.txt`:

```bash
# from the clone — one grep covers every project at once
grep -rn "opendev.org/openstack/<name>.git" <s2i>/containers/*/sources.txt

# without a clone
gh api "repos/openstack-k8s-operators/s2i-openstack-containers/contents/containers/<name>/sources.txt?ref=main" \
  --jq '.content' | base64 -d
```

The repo name is column 2 and can appear under several projects — multi-source projects such
as Horizon pin their dashboards next to the main repo. Track **every** directory that pins
the project; they build different images.

Two cases need their own wording:

- **No git pin.** `containers/openstackclient` lists only `upper-constraints`; clients install
  from PyPI through `pythondeps.txt`. Such a patch reaches the image through a PyPI release
  plus an `upper-constraints` bump, not a source pin. Report the remaining stages as NOT
  APPLICABLE and name the release the patch needs.
- **Project pinned nowhere.** The service is not built by S2I. Say so and stop.

### 3b. Read the pin and test containment

```bash
awk -v s="<stream>" -v n="<name>" '$1==s && $2==n {print $5}' <s2i>/containers/<project>/sources.txt
```

Is the patch commit an ancestor of the pin? From the project clone:

```bash
git -C <src> merge-base --is-ancestor <PATCH_SHA> <PIN_SHA> && echo contained
```

Without a clone, the mirror answers the same question — `status` of `behind` or `identical`
means the pin **contains** the patch, `ahead` or `diverged` means it does not:

```bash
gh api "repos/openstack/<name>/compare/<PIN_SHA>...<PATCH_SHA>" --jq '{status,ahead_by,behind_by}'
```

Use one or the other consistently within a run, and name which one in the Evidence column
(`merge-base` or `compare=<status>`). The commit distance for stage 6 comes from
`git rev-list --count <PIN_SHA>..<DOWNSTREAM_SHA>` or the `compare` call's `ahead_by`.

### 3c. Contained — find the bump that introduced it

Walk the history of that `sources.txt`, newest first, and find the oldest commit whose pin
already contains the patch:

```bash
# from the clone: history, then the pin recorded at any one commit
git -C <s2i> log --format='%H %ad %s' --date=short "<s2i-remote>/main" \
  -- "containers/<project>/sources.txt"
git -C <s2i> show "<SHA>:containers/<project>/sources.txt" \
  | awk -v s="<stream>" -v n="<name>" '$1==s && $2==n {print $5}'

# without a clone
gh api "repos/openstack-k8s-operators/s2i-openstack-containers/commits?path=containers/<project>/sources.txt&per_page=30" \
  --jq '.[] | "\(.sha) \(.commit.author.date) \(.commit.message | split("\n")[0])"'
gh api "repos/openstack-k8s-operators/s2i-openstack-containers/contents/containers/<project>/sources.txt?ref=<SHA>" \
  --jq '.content' | base64 -d | awk -v s="<stream>" -v n="<name>" '$1==s && $2==n {print $5}'
```

Stop at the first commit whose pin no longer contains the patch; the next newer commit is the
bump. Resolve its PR:

```bash
gh api "repos/openstack-k8s-operators/s2i-openstack-containers/commits/<SHA>/pulls" \
  --jq '.[] | "#\(.number) \(.title) merged=\(.mergedAt)"'
```

Daily bumps are commits titled `Update sources (YYYY-MM-DD)` from the rolling
`auto/update-sources` PR.

### 3d. Not contained — find the bump in flight

```bash
gh pr list --repo openstack-k8s-operators/s2i-openstack-containers --state open \
  --json number,title,headRefName,updatedAt
gh pr diff <PR> --patch | grep -A2 "containers/<project>/sources.txt"
```

Test any pin found in an open PR for containment as in 3b, and report the PR number, its CI
state (`gh pr checks <PR>`), and what it waits on.

If no open PR carries the patch, the next daily `update-sources` run (05:17 UTC) picks it up,
provided stage 2 is done. When the engineer cannot wait, the escape hatch is a manual pin-bump
PR against `main` — the "can wait? no" branch of the flow.

## Stage 4 — Validation and merge

```bash
gh pr checks <PR>
gh pr view <PR> --json state,mergedAt,reviewDecision
```

A merged bump PR completes stages 3 and 4 together.

## Stage 5 — Images on quay.io

Post-merge Zuul jobs publish to `quay.io/openstack-s2i-containers/openstack-<image>`, tagged
with the stream prefix (`master-latest`, plus per-build `master-<sha>` tags). A project's
image targets are its image subdirectories:

```bash
# from the clone
ls -d <s2i>/containers/<project>/*/ | xargs -n1 basename

# without a clone
gh api "repos/openstack-k8s-operators/s2i-openstack-containers/contents/containers/<project>" \
  --jq '.[] | select(.type=="dir") | .name'
```

Map each target to the `OpenStackVersion` field an engineer overrides for a test deployment,
reading `containers/image-mappings.yaml` from the clone, or through the API when there is
none:

```bash
grep -A3 "<project>/<image>:" <s2i>/containers/image-mappings.yaml
```

Confirm a published tag only with a tool the user already has, for example
`skopeo inspect docker://quay.io/openstack-s2i-containers/openstack-<image>:master-latest`.
Without such a tool or without network access, report the expected image reference and mark
the stage EXPECTED rather than guessing.

## Stage 6 — Downstream pin in the packaging repo

Everything here runs against the user's local clone and the release branch they named. Refer
to it as "the downstream packaging repo" — keep its remote URL, host, namespace, and any
credentials out of the report and out of every file you write.

```bash
BR=<target_branch>        # the release branch, or <remote>/<release-branch>
git -C <downstream> show "${BR}:source2image/<project>/sources.txt" \
  | awk -v s="<stream>" -v n="<name>" '$1==s && $2==n {print $5}'

git -C <downstream> ls-tree "$BR" "source2image/<project>/src/<name>"
```

Run the containment test from 3b against the downstream pin, and report three things:

1. whether the downstream pin contains the patch,
2. whether the pin and the submodule gitlink agree — a mismatch means an incomplete import,
   and the build follows the gitlink,
3. how far the downstream pin trails the s2i pin, as the commit count from the `compare`
   call, so the engineer can judge the size of the next import.

Identify the last import on that branch:

```bash
git -C <downstream> log --oneline -10 "$BR" -- "source2image/<project>/"
```

Import commits name the s2i commit they synced from. If the patch is in s2i `main` but not
downstream, the pending action is an import MR for that project: the repo ships
`sync_upstream_project.sh <s2i-repo> <downstream-repo> <project>` for the content sync, plus a
submodule bump to the new pin.

When the user has `glab` configured for that repo, open import MRs can be listed with
`glab mr list -R <repo>`. Treat its absence as "not checked", not as "none".

## Stages 7-9 — Konflux build and bundle

The branch slug replaces dots with dashes (`X.Y.Z` → `X-Y-Z`). PipelineRun definitions name
the components:

```bash
git -C <downstream> ls-tree --name-only "$BR" .tekton/ | grep -- "-<slug>-push.yaml"
git -C <downstream> show "${BR}:.tekton/openstack-<image>-openstack-<slug>-push.yaml" \
  | grep -A1 "name: output-image"
```

Read the published image from the `output-image` parameter instead of reconstructing it.
Report the component(s) the patch would land in, the downstream commit that triggers them (the
import merge commit, once it exists), and that the weekly bundle rolls merged component builds
up for downstream testing. Build results live in the Konflux UI, which this skill does not
query — give the component name and triggering commit so the engineer can look them up.

## Report format

Keep it tight. The table is the answer; everything else supports it. A filled-in report is
under [Examples](#examples).

```markdown
# S2I Patch Tracking — <project> change <number>

**Change:** <subject>
**Gerrit:** <change url> (<status>, <branch>)
**Change-Id:** <change id>
**Tracked branch:** stable/<YYYY.N>  **Stream:** <stream>  **Target branch:** <release-branch>

## Pipeline status

| # | Stage | State | Evidence |
|---|-------|-------|----------|
| 1 | Merged upstream (master) | <state> | <sha>, <date> |
| 2 | Cherry-picked to <tracked branch> | <state> | change <number>, merged <date> |
| 3 | Pinned in s2i-openstack-containers | <state> | pin <sha>; bump <title> #<pr>; compare=<status> |
| 4 | Validation + merge to main | <state> | #<pr> merged <date>, checks <result> |
| 5 | Image published to quay.io | <state> | <how confirmed>: <image>:<tag> |
| 6 | Imported downstream (<release-branch>) | <state> | pin <sha> vs gitlink <sha>; compare=<status> |
| 7 | Konflux build | <state> | component <component> |
| 8 | Weekly bundle | <state> | <what it waits on> |

## Where it is now

<one or two sentences: the last stage that contains the patch, and what it waits on>

## Next action

<the single concrete thing the engineer or the pipeline must do next, with the command, PR,
or MR. If the wait is automatic, name what runs and when.>

## Images affected

| Image target | Quay image | OpenStackVersion field | Konflux component |
|--------------|-----------|------------------------|-------------------|
| <project>/<image> | <quay image> | <field> | <component> |

## Not verified

- <check> — <what was missing>

## Notes

<multi-source projects, pin/gitlink mismatches, PyPI-only projects>
```

State values: `DONE`, `IN FLIGHT`, `PENDING`, `BLOCKED`, `VERIFIED`/`EXPECTED` (stage 5),
`NOT APPLICABLE`, and `UNKNOWN` — checked but undetermined, always with the reason.

Every row carries evidence: the sha, PR or MR number, `compare` status, date, or failed
command that establishes its state. A row with no evidence is `UNKNOWN`, never `DONE`.

Never omit a stage row. A stage the run did not reach is `BLOCKED` with the stage it waits
on; a stage it could not evaluate is `UNKNOWN` with the reason — including the case where the
user was asked for a downstream clone and declined, which also goes under **Not verified**.
`UNKNOWN` for stages 6-8 is only valid after that question was asked.

Omit stages 6-8 only when `--upstream-only` was passed, and then say in one line that the
report stops at the quay.io boundary by request.

When more than one release branch was selected, number the downstream rows per branch —
`6.1`/`7.1`/`8.1`, then `6.2`/`7.2`/`8.2` — and name the branch in each Stage cell. Stages
1-5 are shared and appear once.

Under **Not verified**, list only checks that could not run, each naming what was missing —
a tool, a clone, a credential. Write `All stages verified.` when there is nothing to list.

## Operating principles

- **Read-only.** Never push, never open a PR or MR, never comment on Gerrit, GitHub, or the
  downstream review platform. Report state and name the action; the engineer takes it.
- **Keep internal details out of the report.** Do not print the downstream remote URL, host,
  private namespaces, or tokens, and do not write them into any file.
- **Leave no downstream artifact on disk.** The only file this skill writes is
  `${WORKDIR}/gerrit.json`, which holds public Gerrit data. Downstream state is read with
  `git show` / `git ls-tree` and stays in the session — never copy downstream sources,
  diffs, or pipeline definitions into a scratch directory.
- **Never invent SHAs, PR numbers, or dates.** Every value comes from a command that ran. A
  check you could not run is `UNKNOWN` with the reason.
- **Brace every variable before a colon** in `git show` arguments — write
  `"${BR}:path/file"`, never `"$BR:path/file"`. In zsh the bare form is parsed as a history
  modifier and `git show` then returns a different object without erroring.
- **Ancestry decides containment, not dates.** A pin bumped after the merge date may still not
  contain the patch, because the bump follows a different branch. Always run the `compare` or
  `merge-base` check.
- **Local clones are the supported path.** Read pins, history, and ancestry with `git`
  against the clones confirmed in pre-flight. `gh` and `curl` are fallbacks for what has no
  local equivalent — Gerrit metadata, open PR state, and any repo the user has not cloned.
- **Do not fetch patches or HTML pages through a summarizing fetch tool** — details get
  dropped. Use `curl` for the Gerrit REST API and `gh` for GitHub.
- **One project per run.** If the change touches a repo pinned by several s2i projects, report
  all of them, but do not expand into unrelated services.

## Examples

### Invocations

```bash
# Full track, upstream through the downstream release branch
/s2i-track-patch https://review.opendev.org/c/openstack/cinder/+/961234 <release-branch>

# Bare change number, pick the release branch interactively
/s2i-track-patch 961234

# Change-Id, explicit clones
/s2i-track-patch I0123456789abcdef0123456789abcdef01234567 <release-branch> \
  --s2i ~/src/s2i-openstack-containers --downstream ~/src/<packaging-repo>

# Stop at the quay.io boundary
/s2i-track-patch 961234 --upstream-only
```

### Sample report

Shas below are synthetic; the release branch and slug stay as placeholders.

```markdown
# S2I Patch Tracking — cinder change 961234

**Change:** Fix volume attachment race on retype
**Gerrit:** https://review.opendev.org/c/openstack/cinder/+/961234 (MERGED, stable/2026.2)
**Change-Id:** I0123456789abcdef0123456789abcdef01234567
**Tracked branch:** stable/2026.2  **Stream:** master  **Target branch:** <release-branch>

## Pipeline status

| # | Stage | State | Evidence |
|---|-------|-------|----------|
| 1 | Merged upstream (master) | DONE | a1b2c3d, 2026-10-02 |
| 2 | Cherry-picked to stable/2026.2 | DONE | change 961890, merged 2026-10-23 |
| 3 | Pinned in s2i-openstack-containers | DONE | pin 4e5f6a7; bump "Update sources (2026-10-25)" #293; compare=behind |
| 4 | Validation + merge to main | DONE | #293 merged 2026-10-25, checks green |
| 5 | Image published to quay.io | EXPECTED | no skopeo; openstack-cinder-api:master-latest |
| 6 | Imported downstream (<release-branch>) | PENDING | pin 8b9c0d1 = gitlink; compare=ahead by 1 |
| 7 | Konflux build | BLOCKED | waits on stage 6 — component openstack-cinder-api-openstack-<slug> |
| 8 | Weekly bundle | BLOCKED | waits on stage 7 |

## Where it is now

The patch is in s2i `main` and in the published `master-latest` images. The downstream
packaging repo still pins the previous commit, so no product container carries it yet.

## Next action

Open an import MR for `cinder` on the release branch: run `sync_upstream_project.sh` for the
project, bump the `source2image/cinder/src/cinder` submodule to 4e5f6a7, and let the Konflux
pull-request pipeline build it.

## Images affected

| Image target | Quay image | OpenStackVersion field | Konflux component |
|--------------|-----------|------------------------|-------------------|
| cinder/cinder-api | openstack-cinder-api | cinderAPIImage | openstack-cinder-api-openstack-<slug> |
| cinder/cinder-volume | openstack-cinder-volume | cinderVolumeImages map | openstack-cinder-volume-openstack-<slug> |

## Not verified

- image publication — `skopeo` not available; expected tag reported
- open import MRs — `glab` not configured for that repo

## Notes

- cinder builds four images from one source tree; all four follow the same pin.
```
