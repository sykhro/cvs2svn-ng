# cvs2svn-ng (Python 3) runtime image.
#
# The container is expected to be run with hardening flags (see workspace README).
#
# Pins:
# - Python base image is pinned by digest for reproducible builds.
# - uv is pinned by digest (copied from the official uv image).
FROM python:3.13-slim@sha256:2c285c669cc837aa3bcf1af23ea1932b7b5214f9c9d3aad22417446ad91cb4fb AS run

# Install system dependencies required by cvs2svn-ng.
# Keep the image minimal and avoid recommended packages.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        subversion \
        cvs \
        mercurial \
        rcs \
        git \
    && rm -rf /var/lib/apt/lists/*

# Install uv for dependency management.
COPY --from=ghcr.io/astral-sh/uv:0.8.0@sha256:e590846f4776907b254ac0f44b5b380347af5d90d668138ca7938d1b0c2f98d3 /uv /bin/uv

WORKDIR /app

# Copy dependency definition to cache dependencies.
COPY pyproject.toml uv.lock README.md ./
# Copy version file required for dynamic versioning.
COPY cvs2svn_lib/version.py cvs2svn_lib/version.py

# Install dependencies.
RUN uv sync --frozen

# Copy the rest of the application.
COPY . .

# Ensure commands run with the virtualenv.
ENV PATH="/app/.venv/bin:$PATH"

# The CVS repository can be mounted here:
VOLUME ["/cvs"]

# Default to showing help.
CMD ["cvs2svn", "--help"]

FROM run AS test
CMD ["python", "./run-tests.py"]
