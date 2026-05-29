# Makefile for running cvs2svn-ng via Docker with hardened defaults.
#
# This workspace uses cvs2svn-ng (Python 3) as the default conversion tool.
#
# Targets:
#   docker-test   - run the unit/integration tests
#   docker-build  - build the runtime image
#   docker-run    - run cvs2git inside the container with hardened defaults
#
# Required variables for docker-run:
#   CVS_REPO_DIR=/abs/path/to/cvs-repo
#   CFG_DIR=/abs/path/to/config
#   OUT_DIR=/abs/path/to/out
# Optional:
#   TMP_DIR=/abs/path/to/tmp   (if omitted, /tmp is tmpfs)
#   CVS2GIT_ARGS='--options=/cfg/cvs2git.options.py'

IMAGE ?= cvs2svn-ng

.PHONY: docker-build docker-test docker-run

docker-build:
	docker build -t $(IMAGE) .

docker-test:
	docker run --rm \
	  --network none \
	  --cap-drop ALL \
	  --security-opt no-new-privileges \
	  --pids-limit 512 \
	  --memory 4g \
	  --cpus 4 \
	  --mount 'type=tmpfs,dst=/tmp' \
	  --workdir /app \
	  --entrypoint /usr/local/bin/python \
	  $(IMAGE) \
	  ./run-tests.py

docker-run:
	@test -n "$(CVS_REPO_DIR)" || (echo "CVS_REPO_DIR is required" >&2; exit 2)
	@test -n "$(CFG_DIR)" || (echo "CFG_DIR is required" >&2; exit 2)
	@test -n "$(OUT_DIR)" || (echo "OUT_DIR is required" >&2; exit 2)
	@mkdir -p "$(OUT_DIR)"
	@if test -n "$(TMP_DIR)"; then mkdir -p "$(TMP_DIR)"; fi
	@TMP_MOUNT="--tmpfs /tmp:rw,noexec,nosuid,nodev,size=35g"; \
	if test -n "$(TMP_DIR)"; then TMP_MOUNT="--mount type=bind,src=$(TMP_DIR),dst=/tmp"; fi; \
	docker run -it --rm \
	  --network none \
	  --read-only \
	  --cap-drop ALL \
	  --security-opt no-new-privileges \
	  --pids-limit 512 \
	  --memory 16g \
	  --cpus 4 \
	  --user $$(id -u):$$(id -g) \
	  --workdir /work \
	  --mount type=bind,src=$(CVS_REPO_DIR),dst=/cvs,readonly \
	  --mount type=bind,src=$(CFG_DIR),dst=/cfg,readonly \
	  --mount type=bind,src=$(OUT_DIR),dst=/out \
	  $$TMP_MOUNT \
	  --entrypoint /app/.venv/bin/cvs2git \
	  $(IMAGE) \
	  $(CVS2GIT_ARGS)
