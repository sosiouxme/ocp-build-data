#!/bin/bash

set -euxo pipefail

build="$1"
branch="${2:-rhaos-3.11-rhel-7}"

mkdir -p sources && cd sources
exclusions="./.oit .git ./container.yaml ./content-sets.yml ./sources ./additional-tags"
exclude=""
for exc in ${EXCLUSIONS:-$exclusions}; do
  exclude="$exclude --exclude=$exc"
done

# response looks like:
# Source: git://pkgs.devel.redhat.com/containers/foo#deadbeef1234
source=$(brew buildinfo "$build" | grep '^Source:')
source="${source##* }"  # keep  just the repo def
repo="${source/\#*/}"   # the part before the "#"
commit="${source##*#}"  # the part after the "#"

[ -d "$build" ] || git clone --single-branch -b "$branch" "$repo" "$build"
cd "$build"
git checkout "$commit"
tar zfc ../"$build".tar.gz $exclude .




#!/bin/bash

set -euxo pipefail

declare -a dgs=(
  grafana
  cluster-monitoring-operator
  configmap-reload
  openshift-enterprise-console
  kube-rbac-proxy
  kube-state-metrics
  prometheus-config-reloader
  prometheus-operator
)

if ! [ -d distgits ]; then
  mkdir -p distgits
  for dg in dgs; do
    rhpkg clone -b rhaos-3.11-rhel-7 containers/$dg distgits/$dg
  done
fi

declare -a builds=(
  grafana-container-v3.11.16-3
  cluster-monitoring-operator-container-v3.11.16-3
  configmap-reload-container-v3.11.16-3
  openshift-enterprise-console-container-v3.11.16-3
  kube-rbac-proxy-container-v3.11.16-3
  kube-state-metrics-container-v3.11.16-3
  prometheus-config-reloader-container-v3.11.16-3
  prometheus-operator-container-v3.11.16-3
)

mkdir -p sources

exclusions="--exclude=./.oit --exclude=.git --exclude=./container.yaml --exclude=./content-sets.yml --exclude=./sources --exclude=./additional-tags"
for build in "${builds[@]}"; do
  source=$(brew buildinfo "$build" | grep '^Source:')
  # Source: git://pkgs.devel.redhat.com/containers/foo#deadbeef1234
  dg=$(expr match "$source" '.*pkgs.devel.redhat.com/containers/\([^#]\+\)')
  commit=$(echo "$source" | cut '-d#' -f 2)
  pushd distgits/$dg
    git checkout "$commit"
    tar zfc ../../sources/"$build".tar.gz $exclusions .
  popd
done

