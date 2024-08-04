#!/usr/bin/env bash

verify_object() {
  local file=$1
  # Check for non-semantic unsuffixed versions
  # e.g. "version": "11"
  unsuffixed=`jq '[. | select(.version | test("^\\\\d+$"))] | length' < $file`
  assertEquals "$file contains wrong version." 0 "$unsuffixed"
  # Check for non-semantic suffixed versions
  # e.g. "version": "11-SNAPSHOT.32"
  suffixed=`jq '[. | select(.version | test("^\\\\d+[-+].[^\\"]+?"))] | length' < $file`
  assertEquals "$file contains wrong suffixed version." 0 "$suffixed"
}

verify_array() {
  local file=$1
  # Check for non-semantic unsuffixed versions
  # e.g. "version": "11"
  unsuffixed=`jq '[.[] | select(.version | test("^\\\\d+$"))] | length' < $file`
  assertEquals "$file contains wrong version." 0 "$unsuffixed"
  # Check for non-semantic suffixed versions
  # e.g. "version": "11-SNAPSHOT.32"
  suffixed=`jq '[.[] | select(.version | test("^\\\\d+[-+].[^\\"]+?"))] | length' < $file`
  assertEquals "$file contains wrong suffixed version." 0 "$suffixed"
}

testNormalizeMetadata_Vendor_All() {
  for file in ../docs/metadata/vendor/*/all.json; do
    verify_array "$file"
  done
}

testNormalizeMetadata_Vendor_Changed() {
  for file in `git diff --name-only HEAD ../docs`; do
    # skip all.json files as we tests them in testNormalizeMetadata_Vendor_All
    if [[ $file == */all.json ]]; then
      continue
    fi
    # if the file is in a vendor directory, check object
    if [[ $file == */vendor/* ]]; then
      verify_object "../$file"
    fi
    # if the file is in a ea or ga directory, check array
    if [[ $file == */ea/* || $file == */ga/* ]]; then
      verify_array "../$file"
    fi
  done
}

testNormalizeMetadata_Aggregations_GA_Os_Arch() {
  for os in "linux" "macosx"; do
    for arch in "aarch64" "arm32" "x86_64"; do
      verify_array "../docs/metadata/ga/${os}/${arch}.json"
    done
  done
}

# shellcheck source=./tests/shunit2/shunit2
. ./shunit2/shunit2
