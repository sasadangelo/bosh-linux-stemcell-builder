#!/usr/bin/env bash

set -eu

fly -t production set-pipeline \
  -p bosh:stemcells:3363.x -c ci/pipeline.yml \
  -l <(lpass show --note "concourse:production pipeline:bosh:stemcells") \
