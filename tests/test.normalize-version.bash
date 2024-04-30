#!/usr/bin/env bash

# shellcheck source=./bin/functions.bash
source "../bin/functions.bash"

testNormalizeNonSemanticVersions() {
  assertEquals "liberica-jre-javafx-18.0.0+37" "$(normalize_version "liberica-jre-javafx-18+37")"
  assertEquals "openjdk-17.0.0" "$(normalize_version "openjdk-17")"
  assertEquals "openjdk-23.0.0-loom+2-48" "$(normalize_version "openjdk-23-loom+2-48")"
  assertEquals "oracle-18.0.0" "$(normalize_version "oracle-18")"
  assertEquals "oracle-graalvm-21.0.0" "$(normalize_version "oracle-graalvm-21")"
  assertEquals "sapmachine-22.0.0" "$(normalize_version "sapmachine-22")"
  assertEquals "sapmachine-20.0.0-snapshot.35" "$(normalize_version "sapmachine-20-snapshot.35")"
}

testNormalizeSemanticVersions() {
  assertEquals "corretto-20.0.2.9.1" "$(normalize_version "corretto-20.0.2.9.1")"
  assertEquals "openjdk-17.0.0" "$(normalize_version "openjdk-17.0.0")"
  assertEquals "sapmachine-jre-17.0.0" "$(normalize_version "sapmachine-jre-17.0.0")"
}

. ./shunit2/shunit2
