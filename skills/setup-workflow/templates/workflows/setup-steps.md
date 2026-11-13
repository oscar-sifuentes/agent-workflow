# Setup steps for pr-checks.yml

`/setup-workflow` replaces `{{SETUP_STEPS}}` with the block for the project's stack. Pin the action versions the repo already uses elsewhere, if any.

## Node (npm, yarn, pnpm)

```yaml
      - name: Set up Node
        uses: actions/setup-node@v4
        with:
          node-version-file: .nvmrc   # or node-version: <version in package.json engines>
          cache: npm                  # yarn | pnpm
```

For pnpm, add `pnpm/action-setup@v4` before it.

## Python

```yaml
      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version-file: .python-version   # or python-version: "3.x"
```

## Go

```yaml
      - name: Set up Go
        uses: actions/setup-go@v5
        with:
          go-version-file: go.mod
```
