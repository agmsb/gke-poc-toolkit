#!/usr/bin/env bash
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

# shellcheck source=scripts/common.sh
source "$ROOT"/scripts/common.sh

# Delete the CSR resources.
echo "Deleting config sync repo"
yes | gcloud source repos delete config-sync-repo

# Delete the K8s resources.
echo "Deleting Kubernetes resources managed by config-sync"
kubectl delete ns team-foo
kubectl delete ns team-bar
kubectl delete -f "$ROOT"/demos/config-sync/cluster/rbac-viewer-clusterrole.yaml
kubectl delete config-management
gsutil cp gs://config-management-release/released/latest/config-sync-operator.yaml "$ROOT"/scripts/tmp/config-sync-operator.yaml
kubectl delete -f "$ROOT"/scripts/tmp/config-sync-operator.yaml
rm "$ROOT"/scripts/tmp