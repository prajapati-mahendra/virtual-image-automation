#!/usr/bin/env bash
set -euo pipefail
source "${CROC}/colors.sh"; load-colors

export inputFile="vm-images.json"
export outputFile="vm-images-versions.json"

# shellcheck disable=SC2120
function test() {
	local osFilter
	local galleriesCount
	local definitionsCount
	local latest

	while [[ "${#}" -gt 0 ]]; do
		case "${1}" in
			--only-latest) latest=0; shift 1;;
			*)
				echo "Unknown param: ${1}"
				return 1
				;;
		esac
	done


	jq --arg outSchema "schema/output.schema.json" '.["$schema"] = $outSchema' "${inputFile}" > "${outputFile}"
	galleriesCount=$(jq ".galleries|length//0" "${outputFile}")
	if [[ ${galleriesCount} -ne 0 ]]; then
		for ((i=0;i<"${galleriesCount}";i++)); do
			gallery="$(jq -r -c ".galleries[${i}].name" "${outputFile}")"
			subscription="$(jq -r -c ".galleries[${i}].subscription" "${outputFile}")"
			resourceGroup="$(jq -r -c ".galleries[${i}].resourceGroup" "${outputFile}")"

			osFilter="$(jq -r -c '.osFilter // "" ' "${outputFile}")"

			_definitionsCount="$(jq -r -c ".galleries[${i}].definitions|length//0" "${outputFile}")"
			if [[ ${_definitionsCount} -eq 0 ]]; then
				if [[ -n "${osFilter}" ]]; then
					definitions=$(az sig image-definition list --gallery-name "${gallery}" --resource-group "${resourceGroup}" --subscription "${subscription}" | jq --arg filter "${osFilter}" '[.[] | select(.name | contains($filter)) | {description, architecture, location, name, osType, identifier}]')
				else
					definitions=$(az sig image-definition list --gallery-name "${gallery}" --resource-group "${resourceGroup}" --subscription "${subscription}" | jq '[.[] | {description, architecture, location, name, osType, identifier}]')
				fi
				output=$(jq --argjson definitions "${definitions}" ".galleries[$i].definitions = \$definitions" "${outputFile}")
				echo "${output}" > "${outputFile}"

				definitionsCount="$(jq -r -c ".galleries[${i}].definitions|length//0" "${outputFile}")"
				if [[ "${definitionsCount}" -ne 0 ]]; then
					for ((j=0;j<"${definitionsCount}";j++)); do
						definition=$(jq -r -c ".galleries[${i}].definitions[${j}].name" "${outputFile}")
						versions=$(az sig image-version list --resource-group "${resourceGroup}" --gallery-name "${gallery}" --gallery-image-definition "${definition}" \
							| jq "sort_by(.publishingProfile.publishedDate) | reverse |[.[${latest}] | {name, location, publishedDate: .publishingProfile.publishedDate, sizeInGB: .storageProfile.osDiskImage.sizeInGB}]")
						output=$(jq --argjson versions "${versions}" ".galleries[$i].definitions[${j}].versions = \$versions" "${outputFile}")
						echo "${output}" > "${outputFile}"
					done
				else
					printf "${Yellow}%s${NC}\n" "No definitions found"
				fi
			else
				# Process given image
				echo ""
			fi
		done
	else
		printf "${Yellow}%s${NC}\n" "No Galleries found"
	fi
}

# shellcheck disable=SC2120
function generateHclVars() {
	local latest=true
	local packerVarFile
	packerVarFile="windows.auto.pkrvars.hcl"
	if [[ ! -f "${packerVarFile}" ]]; then
		touch "${packerVarFile}"
	fi
	version="$(jq -c -r ".galleries[0].definitions[0].versions[0].name" "${outputFile}")"
	major=$(cut -d. -f1 <<< "${version}")
	minor=$(cut -d. -f2 <<< "${version}")
	patch=$(cut -d. -f3 <<< "${version}")
	case "${1}" in
		--major) major=$((major+1)); minor=0; patch=0 ;;
		--minor) minor=$((minor+1)); patch=0 ;;
		--patch) patch=$((patch+1)) ;;
		--release) latest=false
	esac
	targetVersion="${major}.${minor}.${patch}"
	echo -ne "${LC}⏳ Saving to data to ${NC}"
	{
		echo "subscription_id      				= $(jq -c ".galleries[0].subscription" "${outputFile}")"
		echo "resource_group    				= $(jq -c ".galleries[0].resourceGroup" "${outputFile}")"
    echo "gallery_name      				= $(jq -c ".galleries[0].name" "${outputFile}")"
		echo "image_definition  				= $(jq -c ".galleries[0].definitions[0].name" "${outputFile}")"
    echo "image_offer								= $(jq -c ".galleries[0].definitions[0].identifier.offer" "${outputFile}")"
    echo "image_publisher						= $(jq -c ".galleries[0].definitions[0].identifier.publisher" "${outputFile}")"
    echo "image_sku									=	$(jq -c ".galleries[0].definitions[0].identifier.sku" "${outputFile}")"
    echo "image_version     				= $(jq -c ".galleries[0].definitions[0].versions[0].name" "${outputFile}")"
    echo "target_image_version     	= \"${targetVersion}\""
    echo "location          				= $(jq -c ".galleries[0].definitions[0].versions[0].location" "${outputFile}")"
		echo "vm_size           				= \"Standard_D4s_v4\""
    echo "temp_rg           				= \"packer-temp-rg\""
    echo "exclude_from_latest				= ${latest}"
  } > "${packerVarFile}"
  packer fmt "${packerVarFile}"
  echo -ne "${LC}${Green}✅ Processed${NC}"
}

echo -ne "⏳ Fetching the latest version of VM${NC}"
test "${@}"
[[ ${?} -eq 0 ]] && echo -e "${LC}${Green}✅ Images definitions and version are stored${NC}" || {
	echo "${Yellow}⚠️ Unable to process the Image definitions and versions${NC}"
	return 1
}

generateHclVars --major --latest

