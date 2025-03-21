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

VENDOR='sapmachine'
METADATA_DIR="${1}/${VENDOR}"

ensure_directory "${METADATA_DIR}"

function get_release_type {
	case "${1}" in
	*ea*) echo 'ea'
		;;
	*) echo 'ga'
		;;
	esac
}

function download {
	local tag_name="${1}"
	local asset_name="${2}"
	local filename="${asset_name}"

	local url="https://github.com/SAP/SapMachine/releases/download/${tag_name}/${asset_name}"
	local metadata_file="${METADATA_DIR}/${filename}.json"
	local archive="${TEMP_DIR}/${filename}"

	if [[ -f "${metadata_file}" ]]
	then
		echo "Skipping ${filename}"
	else
		local regex
		if echo "${asset_name}" | grep -q 'rpm$'
		then
			# shellcheck disable=SC2016
			regex='s/^sapmachine-(jdk|jre)-([0-9].+)\.(aarch64|ppc64le|x86_64)\.rpm$/IMAGE_TYPE="$1" VERSION="$2" OS="linux" ARCH="$3" EXT="rpm"/g'
		else
			# shellcheck disable=SC2016
			regex='s/^sapmachine-(jdk|jre)-([0-9].+)_(aix|linux|macos|osx|windows)-(x64|aarch64|ppc64|ppc64le|x64)-?(.*)_bin\.(.+)$/IMAGE_TYPE="$1" VERSION="$2" OS="$3" ARCH="$4" FEATURES="$5" EXT="$6"/g'
		fi

		local IMAGE_TYPE=""
		local VERSION=""
		local OS=""
		local ARCH=""
		local FEATURES=""
		local EXT=""

		# Parse meta-data from file name
		eval "$(echo "${asset_name}" | perl -pe "${regex}")"

		download_file "${url}" "${archive}" || return 1

		local json
		json="$(metadata_json \
			"${VENDOR}" \
			"${filename}" \
			"$(get_release_type "${VERSION}")" \
			"$(normalize_version "${VERSION}")" \
			"${VERSION}" \
			'hotspot' \
			"$(normalize_os "${OS}")" \
			"$(normalize_arch "${ARCH}")" \
			"${EXT}" \
			"${IMAGE_TYPE}" \
			"${FEATURES}" \
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

download_github_releases 'SAP' 'SapMachine' "${TEMP_DIR}/releases-${VENDOR}.json"

versions=$(jq -r '.[].tag_name' "${TEMP_DIR}/releases-${VENDOR}.json" | sort -V)
for version in ${versions}
do
	assets=$(jq -r  ".[] | select(.tag_name == \"${version}\") | .assets[] | select(.content_type | startswith(\"application\")) | select(.name | contains(\"symbols\") | not)| .name" "${TEMP_DIR}/releases-${VENDOR}.json")
	for asset in ${assets}
	do
		download "${version}" "${asset}" || echo "Cannot download ${asset}"
	done
done

jq -s -S . "${METADATA_DIR}"/sapmachine-*.json > "${METADATA_DIR}/all.json"
