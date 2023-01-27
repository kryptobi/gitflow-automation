# Gitflow automation

```yaml
name: gitflow-automation
on:
  pull_request:
    types: [closed]
jobs:
  create-auto-pr:
    name: Gitflow Automation
    permissions:
      pull-requests: write
      repository-projects: write
    runs-on: ubuntu-latest
    env:
    steps:
      - name: gitflow-automation
        uses: peoplefund-tech/gitflow-automation@v0.1.1
        env:
          BRANCH_PREFIX: "hotfix"
          TARGET_BRANCH: "develop"
          BASE_BRANCH: "main"
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          MSTEAMS_WH: ${{ secrets.MSTEAMS_WH }}
          BOT_TOKEN: ${{ secrets.BOT_TOKEN }} # optional

```
- `BRANCH_PREFIX`: hotfix prefix
- `TARGET_BRANCH`: target branch
- `BASE_BRANCH`: event that basebranch
- `GITHUB_TOKEN`: your github token
- `MSTEAMS_WH`: your MS Teams webhook-URL
- `BOT_TOKEN`: your repository bot token
