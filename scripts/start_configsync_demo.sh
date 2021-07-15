#!/usr/bin/env bash
#
# Copyright 2021 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Bash safeties: exit on error, no unset variables, pipelines can't hide errors
set -euo pipefail

# Directory of this script.
ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"

# Shellcheck source=scripts/common.sh
source "$ROOT"/scripts/common.sh

# Source env varibales
source "$ROOT"/scripts/set-env.sh

# Pull manifest for config sync operator into temp folder
gsutil cp gs://config-management-release/released/latest/config-sync-operator.yaml "$ROOT"/scripts/tmp/config-sync-operator.yaml

# Apply config sync operator to cluster
kubectl apply -f "$ROOT"/scripts/tmp/config-sync-operator.yaml

# Create CSR repo and clone into temp folder
# TODO - use terraform to provision repo?
gcloud source repos create config-sync-demo 
gcloud source repos clone config-sync-repo "$ROOT"/scripts/tmp

# Copy config into CSR repo
cp -a "$ROOT"/demos/config-sync/. "$ROOT"/scripts/tmp/config-sync-repo

# Commit and push changes to CSR repo
# TODO - check if git is configured in set-env.sh?
cd "$ROOT"/scripts/tmp/config-sync-rpeo
git add .
git commit -m "Initialize config sync."
git push -u origin master
cd "$ROOT"/scripts

# Set repo URL for config sync
REPO_URL=https://source.developers.google.com/p/${PROJECT}/r/config-sync-repo

# Create config-management.yaml
# TODO - verify cluster scopes
# TODO - change to workload identity
cat << EOF >> "$ROOT"/scripts/tmp/config-management.yaml
apiVersion: configmanagement.gke.io/v1
kind: ConfigManagement
metadata:
 name: config-management
spec:
 sourceFormat: hierarchy
 git:
   syncRepo: $REPO_URL
   syncBranch: master
   secretType: gcenode
   policyDir: "."
EOF

# Apply manifest for configmanagement
kubectl apply -f "$ROOT"/scripts/tmp/config-management.yaml

# Remove the tmp folder
rm -rf "$ROOT"/scripts/tmp