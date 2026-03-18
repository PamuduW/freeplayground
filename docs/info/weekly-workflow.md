# Weekly branching workflow (FreePlayground)
This repo uses a branch-per-week workflow, merged into `main` at the end of each week using a merge commit.

## Start of week (create branch + draft MR)
```bash
git checkout main
git pull

# example for Week 04
git checkout -b week/04-linux-scripting
git push -u origin week/04-linux-scripting
```

Then create a Draft merge request from `week/NN-...` into `main` on GitLab.
GitLab mirroring pushes the branch to GitHub automatically.

## Start of week (create the week log)
- Create `docs/weekly/week-NN.md` using `docs/info/_template.md` as the base.
- Fill Goal + Must ship + Stretch based on `docs/info/FreePlayground_Game_Plan.md`.

## During week (work normally)
```bash
make qa
git status
git add -A
git commit -m "Week NN: <small change>"
git push
```

I run `make qa` during the week before I push so my branch stays lint-clean.
`make qa` also refreshes `docs/info/tree.md` automatically.
I keep the quality workflow reference in `docs/info/linting-formatting-workflow.md`.

## End of week (merge + tag + clean up)
1. Ensure the "must ship" checklist is complete and `docs/weekly/week-NN.md` has evidence.
2. Merge the MR into `main` using a merge commit.
3. Tag the merge commit:

```bash
git checkout main
git pull
make tag-week WEEK=NN
```

`make tag-week` creates the `week-NN` tag on HEAD and pushes it to all remotes.

### Forgot to tag before starting the next week?
If I already branched into `week/(NN+1)-...` without tagging, I can tag from the week branch:

```bash
make tag-week WEEK=NN
```

This fetches the latest `main` from origin and tags it. No branch switch needed.

### Safety checks built into `make tag-week`
- Rejects if `WEEK` is not provided.
- Rejects if the tag already exists.
- Rejects if the new tag is not exactly one ahead of the latest week tag (no gaps).
- On a week branch: rejects if trying to tag the current or future week.
- A pre-commit hook also blocks commits on `week/NN-...` if `week-(NN-1)` tag is missing.
