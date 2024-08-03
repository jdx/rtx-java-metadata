#!/usr/bin/env bash

# shellcheck source=./bin/functions.bash
source "../bin/functions.bash"

testNormalizeNonSemanticVersions() {
  assertEquals "17.0.0" "$(normalize_version "17")"
  assertEquals "18.0.0" "$(normalize_version "18")"
  assertEquals "18.0.0+37" "$(normalize_version "18+37")"
  assertEquals "21.0.0" "$(normalize_version "21")"
  assertEquals "22.0.0" "$(normalize_version "22")"
  assertEquals "23.0.0-loom+2-48" "$(normalize_version "23-loom+2-48")"
  assertEquals "23.0.0-ea+35" "$(normalize_version "23-ea+35")"
  assertEquals "20.0.0-snapshot.35" "$(normalize_version "20-snapshot.35")"
}

testNormalizeSemanticVersions() {
  assertEquals "17.0.0" "$(normalize_version "17.0.0")"
  assertEquals "18.0.0+37" "$(normalize_version "18.0.0+37")"
  assertEquals "20.0.2.9.1" "$(normalize_version "20.0.2.9.1")"
  assertEquals "23.0.0-loom+2-48" "$(normalize_version "23.0.0-loom+2-48")"
  assertEquals "20.0.0-snapshot.35" "$(normalize_version "20.0.0-snapshot.35")"
}

. ./shunit2/shunit2
