#!/usr/bin/env bash

# Copyright 2019 Google
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

set -eo pipefail

EXIT_STATUS=0

if [[ ! -z $encrypted_2858fa01aa14_key ]]; then
    (xcodebuild \
      -workspace ${SAMPLE}/${SAMPLE}Example.xcworkspace \
      -scheme ${SAMPLE}Example${SWIFT_SUFFIX} \
      -sdk iphonesimulator \
      -destination 'platform=iOS Simulator,name=iPhone 11' \
      build \
      test \
      ONLY_ACTIVE_ARCH=YES \
      | xcpretty) || EXIT_STATUS=$?
else
    # Skip running tests if GoogleService-Info.plist's weren't decoded.
    (xcodebuild \
      -workspace ${SAMPLE}/${SAMPLE}Example.xcworkspace \
      -scheme ${SAMPLE}Example${SWIFT_SUFFIX} \
      -sdk iphonesimulator \
      -destination 'platform=iOS Simulator,name=iPhone 11' \
      build \
      ONLY_ACTIVE_ARCH=YES \
      | xcpretty) || EXIT_STATUS=$?
fi

  exit $EXIT_STATUS
