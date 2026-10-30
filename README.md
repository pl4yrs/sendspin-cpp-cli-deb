# Debian build for Sendspin CPP CLI

## Bumping upstream

```bash
scripts/bump-upstream.sh v0.5.0   # updates UPSTREAM + changelog
```

## Building the deb package

```bash
scripts/build.sh [--debver N] # Builds the package with upstream version and release N
```
