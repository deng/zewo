#!/usr/bin/env bash
# Build wrapper that unsets proxy and sets Flutter package mirrors for
# environments where pub.dev is unreachable (e.g. China mainland,
# corporate firewall).
#
# Usage:
#   ./tool/flutter_build_no_proxy.sh [flutter build|run arguments...]

unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY
unset all_proxy ALL_PROXY no_proxy NO_PROXY

export PUB_HOSTED_URL=https://pub.flutter-io.cn
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn

flutter "$@"
