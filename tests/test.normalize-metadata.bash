#!/usr/bin/env bash

testNormalizeMetadata() {
  for os in "linux" "macosx"; do
    for arch in "aarch64" "x86_64" "i686"; do
      # Check for non-semantic unsuffixed versions 
      # e.g. "version": "11" 
      assertEquals "0" "$(jq '[.[] | select(.version | test("^\\\\d+$"))] | length' < ../docs/metadata/ga/${os}/${arch}.json)"
      # Check for non-semantic suffixed versions 
      # e.g. "version": "11-SNAPSHOT.32" 
      assertEquals "0" "$(jq '[.[] | select(.version | test("^\\\\d+[-+].+?"))] | length' < ../docs/metadata/ga/${os}/${arch}.json)"
    done
  done
}

# shellcheck source=./tests/shunit2/shunit2
. ./shunit2/shunit2
