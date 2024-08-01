#!/usr/bin/env bash

testNormalizeMetadata_GA_Linux_MacOS() {
  for os in "linux" "macosx"; do
    for arch in "aarch64" "x86_64" "i686"; do
      # Check for non-semantic unsuffixed versions 
      # e.g. "version": "11"
      unsuffixed_file="../docs/metadata/ga/${os}/${arch}.json"
      unsuffixed=`jq '[.[] | select(.version | test("^\\\\d+$"))] | length' < $unsuffixed_file`
      assertEquals "$unsufixed_file contains wrong version." 0 "$unsuffixed"
      # Check for non-semantic suffixed versions 
      # e.g. "version": "11-SNAPSHOT.32"
      suffixed_file="../docs/metadata/ga/${os}/${arch}.json"
      suffixed=`jq '[.[] | select(.version | test("^\\\\d+[-+].+?"))] | length' < $suffixed_file`
      assertEquals "$suffixed_file contains wrong suffixed version." 0 "$suffixed"
    done
  done
}

# testNormalizeMetadata_Vendor() {
#   for file in ../docs/metadata/vendor/*/all.json; do
#     # Check for non-semantic unsuffixed versions 
#     # e.g. "version": "11" 
#     unsuffixed=`jq '[.[] | select(.version | test("^\\\\d+$"))] | length' < $file`
#     assertEquals "$file contains wrong version." 0 "$unsuffixed"
#     # Check for non-semantic suffixed versions 
#     # e.g. "version": "11-SNAPSHOT.32" 
#     suffixed=`jq '[.[] | select(.version | test("^\\\\d+[-+].+?"))] | length' < $file`
#     assertEquals "$file contains wrong suffixed version." 0 "$suffixed"
#   done
# }

# shellcheck source=./tests/shunit2/shunit2
. ./shunit2/shunit2
