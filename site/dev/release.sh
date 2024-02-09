#!/usr/bin/env bash
#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

source dev/common.sh
set -e

# Updates version information within the mkdocs.yml file for a specified ICEBERG_VERSION.
# Arguments:
#   $1: ICEBERG_VERSION - The version number used for updating the mkdocs.yml file.
update_version () {
  echo " --> update version"

  local ICEBERG_VERSION="$1"

  # Ensure ICEBERG_VERSION is not empty
  assert_not_empty "${ICEBERG_VERSION}"  

  # Update version information within the mkdocs.yml file using sed commands
  if [ "$(uname)" == "Darwin" ]
  then
    sed -i '' -E "s/(^site\_name:[[:space:]]+docs\/).*$/\1${ICEBERG_VERSION}/" ${ICEBERG_VERSION}/mkdocs.yml
    sed -i '' -E "s/(^[[:space:]]*-[[:space:]]+Javadoc:.*\/javadoc\/).*$/\1${ICEBERG_VERSION}/" ${ICEBERG_VERSION}/mkdocs.yml
  elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]
  then
    sed -i'' -E "s/(^site_name:[[:space:]]+docs\/)[^[:space:]]+/\1${ICEBERG_VERSION}/" "${ICEBERG_VERSION}/mkdocs.yml"
    sed -i'' -E "s/(^[[:space:]]*-[[:space:]]+Javadoc:.*\/javadoc\/).*$/\1${ICEBERG_VERSION}/" "${ICEBERG_VERSION}/mkdocs.yml"
  fi

}

# Excludes versioned documentation from search indexing by modifying .md files.
# Arguments:
#   $1: ICEBERG_VERSION - The version number of the documentation to exclude from search indexing.
search_exclude_versioned_docs () {
  echo " --> search exclude version docs"
  local ICEBERG_VERSION="$1"

  # Ensure ICEBERG_VERSION is not empty
  assert_not_empty "${ICEBERG_VERSION}"  

  cd "${ICEBERG_VERSION}/docs/"

  # Modify .md files to exclude versioned documentation from search indexing
  python3 -c "import os
for f in filter(lambda x: x.endswith('.md'), os.listdir()): lines = open(f).readlines(); open(f, 'w').writelines(lines[:2] + ['search:\n', '  exclude: true\n'] + lines[2:]);"

  cd -
}

ICEBERG_VERSION=1.5.0

assert_not_empty "${ICEBERG_VERSION}"

make build

#
# Deploy latest docs
# 

# navigate to docs root to execute commands on docs worktree
cd "$(git_root)/site/docs/docs/"

cp -r "$(git_root)/docs/" "./${ICEBERG_VERSION}"

update_version "${ICEBERG_VERSION}"
search_exclude_versioned_docs "${ICEBERG_VERSION}"
 
git add "./${ICEBERG_VERSION}" 
git commit -m "Deploy ${ICEBERG_VERSION} to ${DOCS_BRANCH} branch"
git push "${REMOTE} ${DOCS_BRANCH}"

#
# Deploy latest javadoc
# 

# build javadoc
cd "$(git_root)"
./gradlew refreshJavadoc

# navigate to docs root to execute commands on docs worktree
cd "$(git_root)/site/docs/javadoc/"

git add "./${ICEBERG_VERSION}" 
git commit -m "Deploy ${ICEBERG_VERSION} to ${JAVADOC_BRANCH} branch"
git push "${REMOTE} ${JAVADOC_BRANCH}"

make clean

#
# Update and deploy new version to main branch
# 

cd "$(git_root)"

# Update mkdocs.yaml and nav.yaml versions to current.
# TODO

git add .
git commit -m "Update to Iceberg Version to ${ICEBERG_VERSION}."
git push "${REMOTE}" main

