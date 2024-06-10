#!/usr/bin/env bash
set -e
set -Euo pipefail

TEMP_DIR=$(mktemp -d)
trap 'rm -rf ${TEMP_DIR}' EXIT

if [[ "$#" -lt 2 ]]
then
	echo "Usage: ${0} metadata-directory checksum-directory"
	exit 1
fi

# shellcheck source=bin/functions.bash
source "$(dirname "${0}")/functions.bash"

VENDOR='openjdk'
METADATA_DIR="${1}/${VENDOR}"
CHECKSUM_DIR="${2}/${VENDOR}"

ensure_directory "${METADATA_DIR}"
ensure_directory "${CHECKSUM_DIR}"

function normalize_release_type {
	case "${1}" in
	*-ea*) echo 'ea'
		;;
	*) echo 'ga'
		;;
	esac
}

# shellcheck disable=SC2016
REGEX='s/^openjdk-([0-9]{1,}[^_]*)_(linux|osx|macos|windows)-(aarch64|x64-musl|x64)_bin\.(tar\.gz|zip)$/VERSION="$1" OS="$2" ARCH="$3" EXT="$4"/g'

INDEX_ARCHIVE="${TEMP_DIR}/index-archive.html"
INDEX_21="${TEMP_DIR}/index-21.html"
INDEX_22="${TEMP_DIR}/index-22.html"
INDEX_23="${TEMP_DIR}/index-23.html"

download_file 'http://jdk.java.net/archive/' "${INDEX_ARCHIVE}"
download_file 'http://jdk.java.net/21/' "${INDEX_21}"
download_file 'http://jdk.java.net/22/' "${INDEX_22}"
download_file 'http://jdk.java.net/23/' "${INDEX_23}"

URLS=$(grep -h -o -E 'href="https://download.java.net/java/.*/[^/]*\.(tar\.gz|zip)"' "${INDEX_ARCHIVE}" "${INDEX_21}" "${INDEX_22}" "${INDEX_23}" | perl -pe 's/href="(.+)"/$1/g' | sort -V)
for URL in ${URLS}
do
	FILE="$(perl -pe 's/https.*\/([^\/]+)/$1/g' <<< "${URL}")"
	METADATA_FILE="${METADATA_DIR}/${FILE}.json"
	ARCHIVE="${TEMP_DIR}/${FILE}"
	if [[ -f "${METADATA_FILE}" ]]
	then
		echo "Skipping ${FILE}"
	else
		download_file "${URL}" "${ARCHIVE}"
		VERSION=""
		OS=""
		ARCH=""
		EXT=""

		# Parse meta-data from file name
		eval "$(perl -pe "${REGEX}" <<< "${FILE}")"

		FEATURES=""
		if [[ "${ARCH}" =~ "x64-musl" ]]
		then
			ARCH="x64"
			FEATURES="musl"
		fi

		METADATA_JSON="$(metadata_json \
			"${VENDOR}" \
			"${FILE}" \
			"$(normalize_release_type "${VERSION}")" \
			"$(normalize_version "${VERSION}")" \
			"${VERSION}" \
			'hotspot' \
			"$(normalize_os "${OS}")" \
			"$(normalize_arch "${ARCH}")" \
			"${EXT}" \
			"jdk" \
			"${FEATURES}" \
			"${URL}" \
			"$(hash_file 'md5' "${ARCHIVE}" "${CHECKSUM_DIR}")" \
			"$(hash_file 'sha1' "${ARCHIVE}" "${CHECKSUM_DIR}")" \
			"$(hash_file 'sha256' "${ARCHIVE}" "${CHECKSUM_DIR}")" \
			"$(hash_file 'sha512' "${ARCHIVE}" "${CHECKSUM_DIR}")" \
			"$(file_size "${ARCHIVE}")" \
			"${FILE}"
		)"

		echo "${METADATA_JSON}" > "${METADATA_FILE}"
		rm -f "${ARCHIVE}"
	fi
done

jq -s -S . "${METADATA_DIR}"/openjdk-*.json > "${METADATA_DIR}/all.json"
