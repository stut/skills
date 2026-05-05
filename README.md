# stut

A [Claude Code plugin](https://docs.claude.com/en/docs/claude-code/plugins) bundling skills by [Stuart Dallas](mailto:stuart@stut.net).

## Skills

| Skill | What it does |
|---|---|
| [tech-interview](skills/tech-interview/) | Pose a calibrated technical interview question, run the session as a neutral interviewer, then probe and evaluate the candidate. |

## Install

### As a plugin (recommended)

Add the repo as a plugin marketplace, then install:

```text
/plugin marketplace add stut/skills
/plugin install stut@skills
```

Skills are then available namespaced — e.g. `/stut:tech-interview`.

### As raw skills (no plugin system)

If you'd rather drop skills directly into `~/.claude/skills/`, run the install script:

```sh
./scripts/install-for-claude.sh
```

By default, skills are symlinked so updates from this repo flow through. Pass `--copy` if you'd prefer copies (useful on Windows without Developer Mode, or if you want to pin to a snapshot). The script asks before overwriting any existing installs. Override the target with `CLAUDE_SKILLS_DIR=/some/other/path ./scripts/install-for-claude.sh`.

To install manually instead:

```sh
ln -s "$(pwd)/skills/tech-interview" ~/.claude/skills/tech-interview   # symlink
cp -R skills/tech-interview ~/.claude/skills/tech-interview             # or copy
```

Restart Claude Code (or the host client) to pick up new skills.

## Repo layout

```
stut/
├── .claude-plugin/
│   └── plugin.json        # plugin manifest
├── skills/
│   └── tech-interview/    # one skill per subdirectory
│       ├── SKILL.md
│       └── README.md
├── scripts/
│   └── install-for-claude.sh
├── LICENSE
└── README.md
```

## Contributing

Issues and PRs welcome. Each skill has its own README with usage details and known limitations.

## License

MIT — see [LICENSE](LICENSE).
