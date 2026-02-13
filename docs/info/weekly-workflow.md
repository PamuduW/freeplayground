# Weekly branching workflow (FreePlayground)

This repo uses a branch-per-week workflow, merged into `main` at the end of each week using a merge commit.

## Start of week (create branch + draft MR)
```bash
git checkout main
git pull

# example for Week 02
git checkout -b week/02-docker
git push -u gitlab week/02-docker
git push -u github week/02-docker
```

Then create a Draft merge request from `week/NN-...` into `main`.

## During week (work normally)
```bash
git status
git add -A
git commit -m "Week NN: <small change>"
git push
```

## End of week (merge + clean up)
1) Ensure the "must ship" checklist is complete and docs/weekly/week-NN.md has evidence.

2) Merge the MR into `main` using a merge commit.

3) Delete the source branch after merge.

Optional: create a tag `week-NN` on the merge commit.
