---
name: github-repo-config
description: Configure a GitHub repository's branch-protection ruleset, pull-request, and merge settings through the gh CLI with a guided Q&A and sensible defaults. Use when the user wants to set up or change branch protection / rulesets, required reviews, merge methods (squash/merge/rebase), auto-delete branches, or conversation resolution on a GitHub repo.
---

# GitHub Repo Config

Configure a repository's merge settings and branch-protection **ruleset** through `gh`. Run **preflight** to confirm access, show current settings, walk the user through each setting (recommended defaults, explain-on-demand), confirm the plan, then apply.

## Input

- **Target repo** *(optional)*: `owner/repo`. If omitted, use the current directory's repo (`gh repo view --json nameWithOwner`).

## Workflow

### 1. Preflight — confirm access before asking anything

Do all of this before touching settings. If any check fails, stop and print the exact fix; do not continue.

1. **Authenticated:** `gh auth status`. If not logged in → `gh auth login`.
2. **Scope:** the token needs `repo` scope (rulesets require it). If the scope list from `gh auth status` lacks `repo` → `gh auth refresh -s repo`.
3. **Resolve target:** `gh repo view <repo> --json nameWithOwner,defaultBranchRef,visibility` → capture `owner/repo` and the default branch name. The ruleset targets the **default branch** unless the user names another.
4. **Admin:** `gh api repos/{owner}/{repo} --jq .permissions.admin` must be `true`. If `false`, the user lacks admin; stop and say so.

State the resolved repo and default branch in one line. Note: on a **private** repo, rulesets may need a paid plan — the apply call surfaces that if so.

### 2. Show current settings

Before the first question, print the repo's current merge settings and any existing rulesets on the default branch (see **Reading current state**). Show it as a compact summary so the user sees the starting point the recommended defaults will change.

### 3. Run the Q&A

Open by offering three paths:
- **Apply all recommended defaults** → skip to step 4 with every setting at its recommended value.
- **Go setting by setting** → walk the catalog below in order.
- **Cancel.**

When going setting by setting, ask **one setting per turn**. Present the options as a **numbered list** so the user can just type a number; mark the **recommended** option and note the current value. End each prompt with `(reply with a number, or "explain" for details)`. Keep prompts to a few lines. Do not use `?` as the affordance — it triggers the host's help.

Branch-protection settings apply only to the **target branch** (the default branch unless the user named another). Name that branch in every branch-protection prompt so the scope is never ambiguous — merge settings, by contrast, are repo-wide.

- If the user replies "explain" (or "help"), give the catalog explanation, then re-ask.
- "Keep the rest as recommended" at any point → resolve all remaining settings to recommended values and go to step 4.
- **Solo-repo guard:** if the repo has only one collaborator who can approve (see **Reading current state**), a nonzero **Required approvals** is a trap — the sole author can't approve their own PR, so nothing can merge without an admin bypass. Recommend **0** for a solo repo. If the user picks nonzero anyway, remind them of the solo aspect and offer concrete numbered choices — keep the nonzero value, set it to 0, or enter a different number — rather than an open-ended "change it"; only continue once they pick one.

**Completion criterion:** every setting in the catalog has a resolved value before step 4.

### 4. Confirm

Show the full resolved config as a compact list grouped Merge / Branch-protection ruleset, and state it will be applied over the current settings. Get an explicit go-ahead. If the user turned every branch-protection setting off, note that an existing ruleset is left untouched unless they ask to remove it.

### 5. Apply & report

Apply the merge settings and the ruleset (see **Apply recipes**). Report each outcome separately — on failure, show the error and continue with the other rather than aborting silently.

## Settings catalog

Recommended defaults favour a clean, linear history with lightweight review.

### Merge settings (repo-level)

| Setting | Recommended | Explanation (options & effects) |
|---|---|---|
| Allowed merge methods | Squash only | **Squash** = one tidy commit per PR, linear history. **Merge commit** = keeps every branch commit plus a merge commit. **Rebase** = replays commits onto base, no merge commit. At least one must stay enabled. |
| Squash commit message *(if squash on)* | PR title + description | Source of the squashed commit's title/body: the **PR title & description**, the branch's **commit messages**, or a **blank** body. |
| Auto-delete head branches | On | Deletes the source branch automatically once its PR merges, keeping the branch list tidy. |
| Allow auto-merge | On | Lets a PR be queued to merge itself once all required checks and reviews pass. |
| Suggest updating branches | On | Shows an "Update branch" button to pull the base branch into a PR that has fallen behind. |

### Branch-protection ruleset (default branch)

| Setting | Recommended | Explanation (options & effects) |
|---|---|---|
| Enforcement | Active | **Active** = rules enforced. **Disabled** = ruleset saved but not applied. (**Evaluate** = report-only; needs an org on Team/Enterprise.) |
| Require a pull request before merging | On | Changes to the branch must go through a PR, not a direct push. Off drops the review settings below. |
| Required approvals | 1 *(0 on a solo repo)* | Approving reviews a PR needs before merging (0–6). See the solo-repo guard above. |
| Dismiss stale approvals | On | A new push to a PR invalidates earlier approvals, forcing re-review. |
| Require Code Owner review | Off *(On if CODEOWNERS exists)* | Requires approval from the owners named in `CODEOWNERS`. |
| Require conversation resolution | On | All PR review comments must be resolved before merge. |
| Require status checks | Off *(no checks to require)* | When on, name the checks that must pass; **strict** also requires the branch be up to date with base first. With no CI workflows there's nothing to require — say so; if workflows exist, offer their names as candidates. |
| Require linear history | On | Forbids merge commits on the branch — pairs with squash/rebase-only merging. |
| Block force pushes | On | Prevents force-pushes that rewrite the branch's history. Off allows them. |
| Block branch deletion | On | Prevents the protected branch from being deleted. Off allows it. |
| Allow admins to bypass | Off | Off = everyone, admins included, is bound by the ruleset. On = repo admins can bypass it. |

## Reading current state

**Merge settings:**

```sh
gh api repos/{owner}/{repo} --jq '{allow_squash_merge, allow_merge_commit, allow_rebase_merge, delete_branch_on_merge, allow_auto_merge, allow_update_branch, squash_merge_commit_title, squash_merge_commit_message}'
```

**Solo repo?** — count collaborators who can approve (push access or higher). `1` means solo:

```sh
gh api "repos/{owner}/{repo}/collaborators?permission=push" --jq 'length'
```

**CI workflows?** — informs the status-checks recommendation and offers check names as candidates:

```sh
gh api repos/{owner}/{repo}/actions/workflows --jq '.workflows[] | .name'
```

**Rulesets** — list, then expand any targeting the default branch:

```sh
gh api repos/{owner}/{repo}/rulesets --jq '.[] | {id, name, enforcement}'
gh api repos/{owner}/{repo}/rulesets/{id} --jq '{name, enforcement, bypass_actors, refs: .conditions.ref_name.include, rules: [.rules[].type]}'
```

## Apply recipes

**Merge settings** — one PATCH. `-F` sends typed booleans, `-f` sends strings. Include the squash-message fields only when squash is enabled:

```sh
gh api -X PATCH repos/{owner}/{repo} \
  -F allow_squash_merge=true -F allow_merge_commit=false -F allow_rebase_merge=false \
  -F delete_branch_on_merge=true -F allow_auto_merge=true -F allow_update_branch=true \
  -f squash_merge_commit_title=PR_TITLE -f squash_merge_commit_message=PR_BODY
```

Squash message values: title `PR_TITLE` | `COMMIT_OR_PR_TITLE`; message `PR_BODY` | `COMMIT_MESSAGES` | `BLANK`.

**Branch-protection ruleset** — write the JSON to the scratchpad, then create or update by name (idempotent):

```sh
# find an existing ruleset this skill manages
id=$(gh api repos/{owner}/{repo}/rulesets --jq '.[] | select(.name=="Default branch protection") | .id')
# create if absent, else update in place
gh api -X POST repos/{owner}/{repo}/rulesets --input <file>            # when id is empty
gh api -X PUT  repos/{owner}/{repo}/rulesets/$id --input <file>        # when id is set
```

Ruleset body. A rule's **presence enforces it**; omit a rule to allow that action. `~DEFAULT_BRANCH` auto-targets whatever the default branch is (or use `refs/heads/<branch>` for a specific one):

```json
{
  "name": "Default branch protection",
  "target": "branch",
  "enforcement": "active",
  "bypass_actors": [],
  "conditions": { "ref_name": { "include": ["~DEFAULT_BRANCH"], "exclude": [] } },
  "rules": [
    {
      "type": "pull_request",
      "parameters": {
        "required_approving_review_count": 1,
        "dismiss_stale_reviews_on_push": true,
        "require_code_owner_review": false,
        "require_last_push_approval": false,
        "required_review_thread_resolution": true
      }
    },
    { "type": "required_linear_history" },
    { "type": "non_fast_forward" },
    { "type": "deletion" }
  ]
}
```

Assemble `rules` from the user's choices:
- **PR not required** → drop the `pull_request` rule.
- **Status checks on** → add `{ "type": "required_status_checks", "parameters": { "strict_required_status_checks_policy": true, "required_status_checks": [ {"context": "build"} ] } }`.
- **Block force pushes / deletion off** → drop the `non_fast_forward` / `deletion` rule.
- **Require linear history off** → drop the `required_linear_history` rule.
- **Allow admins to bypass on** → `"bypass_actors": [ { "actor_id": 5, "actor_type": "RepositoryRole", "bypass_mode": "always" } ]` (`5` = repo admin role).

**Remove protection** (only if the user asks) → `gh api -X DELETE repos/{owner}/{repo}/rulesets/$id`.
