#!/bin/bash
# Build wrapper that sets Flutter package mirrors for environments
# where pub.dev is unreachable (e.g. China mainland, corporate firewall).
#
# Usage:
#   ./tool/flutter_build_no_proxy.sh [flutter build|run arguments...]

export PUB_HOSTED_URL=https://pub.flutter-io.cn
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn

flutter "$@"
