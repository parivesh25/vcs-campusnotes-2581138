# Troubleshoot a commit that unexpectedly succeeds

If a commit succeeds when you expected the pre-commit hook to block it, check which hook directory Git uses, whether the hook is executable, and what you actually staged.

## 1. Check the hook setup

From inside your clone, run:

```bash
cd "$(git rev-parse --show-toplevel)"
git config --show-origin --get core.hooksPath
git ls-files --stage -- .githooks/pre-commit .githooks/commit-msg
```

`.githooks` is the directory where this project keeps its shared hook scripts. Each new clone needs to be configured to use it. If the first check prints nothing or shows a different path, run:

```bash
git config --local core.hooksPath .githooks
git config --get core.hooksPath
```

The expected output is `.githooks`. In the `git ls-files --stage` output, each hook should have mode `100755`. This means Git tracks it as a regular file with its executable bit set. Mode `100644` means the executable bit is missing. If either hook is missing from the listing, check that you are on the branch containing the shared hooks.

## 2. Test the pre-commit hook with one disposable file

Run `git status --short` first. Use a clean working tree so the test commit includes only the probe. Confirm that `hook-probe.txt` is available, then run:

```bash
printf 'TO%s\n' DO > hook-probe.txt
git add -- hook-probe.txt
git diff --cached -- hook-probe.txt
git commit -m "test: verify rejection of an unfinished-work marker"
```

The `printf` command generates an unfinished-work marker at runtime. The staged diff shows exactly what the hook should inspect. The commit message uses a valid prefix so you can test the pre-commit hook separately from the commit-message hook.

**Expected result:** The pre-commit hook rejects the commit and identifies the marker. The probe stays staged because Git stopped before creating a commit. Clean it up with:

```bash
git restore --staged -- hook-probe.txt
rm -- hook-probe.txt
git status --short
```

A clean working tree produces no output from the final command.

## 3. If the probe commit succeeds

Keep the probe commit local. Run `git show -1 --oneline --patch -- hook-probe.txt` to confirm the commit actually contains the generated marker. Recheck the hook path and executable mode from step 1. Also check whether you used `git commit --no-verify`, which skips the pre-commit and commit-message hooks.

If the marker is in the commit and the setup looks correct, open `.githooks/pre-commit` and check which file types and staged lines it scans. If it only checks certain file extensions, repeat the test using a disposable file with a covered extension.

To remove a probe that was successfully committed, run:

```bash
git rm -- hook-probe.txt
git commit -m "chore: remove temporary hook probe"
git status --short
```