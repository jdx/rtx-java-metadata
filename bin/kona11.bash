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

VENDOR='kona'
METADATA_DIR="${1}/${VENDOR}"

ensure_directory "${METADATA_DIR}"

function download {
	local tag_name="${1}"
	local asset_name="${2}"
	local filename="${asset_name}"

	local url="https://github.com/Tencent/TencentKona-11/releases/download/${tag_name}/${asset_name}"
	local metadata_file="${METADATA_DIR}/${filename}.json"
	local archive="${TEMP_DIR}/${filename}"

	if [[ -f "${metadata_file}" ]]
	then
		echo "Skipping ${filename}"
	else
		download_file "${url}" "${archive}" || return 1

		local VERSION=""
		local JAVA_VERSION=""
		local RELEASE_TYPE="ga"
		local OS=""
		local ARCH=""
		local EXT=""
		local FEATURES=""

		local regex
		if [[ "${filename}" = TencentKona-* ]];
		then
			# shellcheck disable=SC2016
			regex='s/^TencentKona-([0-9b.]{1,})[-_]jdk_(fiber)?_?(linux|macosx|windows)-(aarch64|x86_64).*\.(tar\.gz|zip)$/VERSION="$1" OS="$3" ARCH="$4" JAVA_VERSION="$1" FEATURES="$2" EXT="$5"/g'
		else
			# shellcheck disable=SC2016
			regex='s/^TencentKona([0-9b.]+)\.tgz$/VERSION="$1" JAVA_VERSION="$1"/g'
			OS="linux"
			ARCH="x86_64"
			EXT="tgz"
		fi


		# Parse meta-data from file name
		eval "$(perl -pe "${regex}" <<< "${asset_name}")"

		if [[ -z "${VERSION}" ]]
		then
			echo "Unable to parse ${asset_name}"
			return 1
		fi

		local json
		json="$(metadata_json \
			"${VENDOR}" \
			"${filename}" \
			"${RELEASE_TYPE}" \
			"${VERSION}" \
			"${JAVA_VERSION}" \
			'hotspot' \
			"$(normalize_os "${OS}")" \
			"$(normalize_arch "${ARCH}")" \
			"${EXT}" \
			'jdk' \
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

RELEASE_FILE="${TEMP_DIR}/releases-${VENDOR}-11.json"
download_github_releases 'Tencent' 'TencentKona-11' "${RELEASE_FILE}"

versions=$(jq -r '.[].tag_name' "${RELEASE_FILE}" | sort -V)
for version in ${versions}
do
	assets=$(jq -r  ".[] | select(.tag_name == \"${version}\") | .assets[] | select(.content_type | startswith(\"application\")) | select(.name | contains(\"_source\") | not) | select(.name | endswith(\"md5\") | not) | .name" "${RELEASE_FILE}")
	for asset in ${assets}
	do
		download "${version}" "${asset}" || echo "Cannot download ${asset}"
	done
done

jq -s -S . "${METADATA_DIR}"/Tencent*.json > "${METADATA_DIR}/all.json"
