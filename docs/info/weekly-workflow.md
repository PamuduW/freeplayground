# Weekly branching workflow (FreePlayground)

This repo uses a branch-per-week workflow, merged into `main` at the end of each week using a merge commit.

## Start of week (create branch + draft MR)

```bash
git checkout main
git pull

# example for Week 03
git checkout -b week/03-docker-compose
git push -u gitlab week/03-docker-compose
git push -u github week/03-docker-compose
```

Then create a Draft merge request from `week/NN-...` into `main`.

## Start of week (create the week log)

- Create `docs/weekly/week-NN.md` using `docs/info/_template.md` as the base.
- Fill Goal + Must ship + Stretch based on `docs/info/FreePlayground_Game_Plan_v3.md`.

## During week (work normally)

```bash
git status
git add -A
git commit -m "Week NN: <small change>"
git push
```

## End of week (merge + clean up)

1. Ensure the "must ship" checklist is complete and `docs/weekly/week-NN.md` has evidence.

2. Merge the MR into `main` using a merge commit.

3. Delete the source branch after merge.

Optional: create a tag `week-NN` on the merge commit.
