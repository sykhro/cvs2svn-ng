# cvs2svn-ng

This tool converts CVS repositories to Subversion, Git, Mercurial, or Bazaar.
It is a fork of `cvs2svn` that supports Python 3.

## Requirements

- **Python**: 3.11 or later.
- **CVS**: `cvs` executable must be in your PATH.
- **Target VCS**: `git`, `svn`, `hg`, or `bzr` (depending on your target).

You can use the Docker image to avoid installing the dependencies locally:

```bash
docker build -t cvs2svn .
```

## Installation / Usage

You can run the tools directly using `uv`:

```bash
uv run cvs2git --help
```

Or install them into a virtual environment:

```bash
uv pip install .
```

## Usage (CVS to Git)

Generate a Git fast-import dump:

```bash
cvs2git --blobfile=git-blob.dat --dumpfile=git-dump.dat \
    --username=cvs2git /path/to/cvsrepo/module
```

Import into a new Git repository:

```bash
git init
cat git-blob.dat git-dump.dat | git fast-import
git checkout master
```

## Docker

Build:

```bash
docker build -t cvs2svn .
```

Run:

```bash
docker run -v /path/to/local/cvsrepo:/cvs -v $(pwd):/work -w /work cvs2svn \
    cvs2git --blobfile=blob.dat --dumpfile=dump.dat --username=cvs2git /cvs/module
```

