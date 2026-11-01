# Debian build for Sendspin CPP CLI

These packages are provided with absolutely no warranty.
Pl4yrs is not affiliated with the Sendspin project.
Packages publushed here aren't official builds.

## Bumping upstream

```bash
scripts/bump-upstream.sh v0.5.0   # updates UPSTREAM + changelog
```

## Building the deb package

```bash
scripts/build.sh [--debver N] # Builds the package with upstream version and release N
```
