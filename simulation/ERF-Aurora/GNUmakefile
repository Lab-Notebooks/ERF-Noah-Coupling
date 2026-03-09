# Wrapper GNUmakefile for building ERF on Aurora without CMake.
#
# This runs the canonical ERF GNUmake build in $(ERF_HOME)/Exec/ABL and then
# stages the resulting AMReX-style executable (ERF*.ex) into this case's
# tmp_build_dir with a stable name expected by run_erf.sh.

SHELL := /bin/bash

.PHONY: all build stage clean

BUILD_DIR ?= tmp_build_dir
STAGE_DIR := $(BUILD_DIR)/Exec/ABL
STAGE_EXE := $(STAGE_DIR)/erf_abl

ifndef ERF_HOME
$(error ERF_HOME is not set. Source environment.sh (jobrunner setup) first.)
endif

ABL_DIR := $(ERF_HOME)/Exec/ABL

JOBS ?=
ifneq ($(strip $(JOBS)),)
MAKE_JOBS := -j $(JOBS)
else
MAKE_JOBS := -j
endif

ERF_MAKE_OVERRIDES := \
  USE_MPI=TRUE USE_OMP=FALSE \
  USE_CUDA=FALSE USE_HIP=FALSE \
  USE_SYCL=TRUE \
  USE_PARTICLES=TRUE \
  USE_NETCDF=TRUE \
  TEST=FALSE DEBUG=FALSE

all: build stage

build:
	$(MAKE) -C "$(ABL_DIR)" $(MAKE_JOBS) $(ERF_MAKE_OVERRIDES)

stage:
	@mkdir -p "$(STAGE_DIR)"
	@set -euo pipefail; \
	  exe=$$(ls -t "$(ABL_DIR)"/ERF*.ex 2>/dev/null | head -n 1); \
	  if [[ -z "$$exe" ]]; then \
	    echo "ERROR: No ERF*.ex produced in $(ABL_DIR)" >&2; \
	    exit 1; \
	  fi; \
	  cp -f "$$exe" "$(STAGE_EXE)"; \
	  chmod u+x "$(STAGE_EXE)"; \
	  echo "Staged $$(basename "$$exe") -> $(STAGE_EXE)"

clean:
	$(MAKE) -C "$(ABL_DIR)" clean
	$(RM) -f "$(STAGE_EXE)"
