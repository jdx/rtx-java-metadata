#!/usr/bin/env bash
set -e
set -Euo pipefail

TEMP_DIR=$(mktemp -d)
trap 'rm -rf ${TEMP_DIR}' EXIT

if [[ "$#" -lt 1 ]]
then
	echo "Usage: ${0} metadata-directory"
	exit 1
fi

# shellcheck source=bin/functions.bash
source "$(dirname "${0}")/functions.bash"

VENDOR='graalvm'
METADATA_DIR="${1}/${VENDOR}"

ensure_directory "${METADATA_DIR}"

function download {
	local tag_name="${1}"
	local asset_name="${2}"
	local filename="${asset_name}"

	local url="https://github.com/graalvm/graalvm-ce-builds/releases/download/${tag_name}/${asset_name}"
	local metadata_file="${METADATA_DIR}/${filename}.json"
	local archive="${TEMP_DIR}/${filename}"

	if [[ -f "${metadata_file}" ]]
	then
		echo "Skipping ${filename}"
	else
		# Prior graalvm 23         : graalvm-ce-java17-darwin-amd64-22.3.2.tar.gz
		# shellcheck disable=SC2016
		local regex='s/^graalvm-ce-(?:complete-)?java([0-9]{1,2})-(linux|darwin|windows)-(aarch64|amd64)-([0-9+.]{2,})\.(zip|tar\.gz)$/JAVA_VERSION="$1" OS="$2" ARCH="$3" VERSION="$4" EXT="$5"/g'

		local JAVA_VERSION=""
		local OS=""
		local ARCH=""
		local VERSION=""
		local EXT=""

		# Parse meta-data from file name
		eval "$(echo "${asset_name}" | perl -pe "${regex}")"

		download_file "${url}" "${archive}" || return 1

		local json
		json="$(metadata_json \
			"${VENDOR}" \
			"${filename}" \
			'ga' \
			"${VERSION}+java${JAVA_VERSION}" \
			"${JAVA_VERSION}" \
			'graalvm' \
			"$(normalize_os "${OS}")" \
			"$(normalize_arch "${ARCH}")" \
			"${EXT}" \
			'jdk' \
			'' \
			"${url}" \
			"$(hash_file 'md5' "${archive}")" \
			"$(hash_file 'sha1' "${archive}")" \
			"$(hash_file 'sha256' "${archive}")" \
			"$(hash_file 'sha512' "${archive}")" \
			"$(file_size "${archive}")" \
			"${filename}"
		)"

		echo "${json}" > "${metadata_file}"
		rm -f "${archive}"
	fi
}

download_github_releases 'graalvm' 'graalvm-ce-builds' "${TEMP_DIR}/releases-graalvm.json"

versions=$(jq -r '.[].tag_name' "${TEMP_DIR}/releases-graalvm.json" | sort -V)
for version in ${versions}
do
	assets=$(jq -r  ".[] | select(.tag_name == \"${version}\") | .assets[].name | select(startswith(\"graalvm-ce\")) | select(endswith(\"tar.gz\") or endswith(\"zip\"))" "${TEMP_DIR}/releases-graalvm.json")
	for asset in ${assets}
	do
		download "${version}" "${asset}" || echo "Cannot download ${asset}"
	done
done

jq -s -S . "${METADATA_DIR}"/graalvm-ce-*.json > "${METADATA_DIR}/all.json"
