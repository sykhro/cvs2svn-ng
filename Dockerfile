# Use a Python image that matches the CI environment
FROM python:3.11-slim

# Install system dependencies required by cvs2svn and its tests
# (subversion, cvs, mercurial, rcs)
RUN apt-get update && apt-get install -y \
    subversion \
    cvs \
    mercurial \
    rcs \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install uv for dependency management
COPY --from=ghcr.io/astral-sh/uv:latest /uv /bin/uv

# Set working directory
WORKDIR /app

# Copy dependency definition to cache dependencies
COPY pyproject.toml uv.lock README.md ./
# Copy version file required for dynamic versioning
COPY cvs2svn_lib/version.py cvs2svn_lib/version.py

# Install dependencies
RUN uv sync --frozen

# Copy the rest of the application
COPY . .

# Set the environment variable to ensure commands run with the virtualenv
ENV PATH="/app/.venv/bin:$PATH"

# The CVS repository can be mounted here:
VOLUME ["/cvs"]

# Default to showing help
CMD ["cvs2svn", "--help"]
