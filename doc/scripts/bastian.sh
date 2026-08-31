#!/usr/bin/env bash
function bastionConnection() {

	printf "${Yellow}%s${NC}}\n" "Please make sure that 'Contributor' Role is active"
	printf "${LC}${Yellow}%s${NC}" "⏳ Checking the GlobalProtect VPN Gateway..."
	if ! scutil --dns | grep -q "172.28.239.1"; then
		printf "${LC}${Red}%s${NC}\n" "❌ Please connect to 'India North' Gateway in GlobalProtect"
		return 1
	fi
	if [[ -f ${CROC}/colors.sh ]]; then load-colors; fi
	printf "${LC}${Green}%s${NC}\n" "✅ Connected to 'India North' Gateway"

	subscriptions=$(az account subscription list)
	subscriptionName=$(echo "${subscriptions}" | jq -r -c '.[].displayName' | fzf -i +s --height=10 --border=dashed --prompt "Select Subscription: ")
#	subscriptionId="$(echo "${subscriptions}" | jq -r ".[] | select(.displayName == \"${subscriptionName}\")" | jq -r -c '.subscriptionId')"
	case ${subscriptionName:-"tas-prod-internal-vdi"} in
		"tas-prod-external-rad-cll")
				bastionName="tcs-prod-ext-rad-cll-core-cus-bastion"
				resourceGroup="tcs-prod-ext-rad-cll-core-cus-rg"
			;;
		"tas-prod-internal-vdi")
				bastionName="tcs-prod-int-vdi-core-cus-bastion"
  			resourceGroup="tcs-prod-int-vdi-core-cus-rg"
			;;
	esac
	vmData=$(az graph query -q "resources | where type =~ 'microsoft.compute/virtualmachines' | project resourceGroup, name, id" | jq '.data')
#	vmName=$(az graph query -q "resources | where type =~ 'microsoft.compute/virtualmachines' | project resourceGroup, name" | jq -r -c '.data[] | "\(.name):\(.resourceGroup)"' | fzf --prompt="Select VM: ")
	vmName=$(echo $vmData | jq -r -c '.[].name' | fzf -i +s --height=10 --border=dashed --prompt="Select VM: ")
	vmInfo=$(echo $vmData | jq -r ".[] | select(.name == \"${vmName}\")")
	vmId=$(echo ${vmInfo} | jq -r -c '.id')
	vmRG=$(echo ${vmInfo} | jq -r -c '.resourceGroup')

	printf "${Blue}%s\t: %s${NC}\n" "subscription" "tas-prod-internal-vdi (d658f392-d9ce-4934-b4b8-2f4de1e8b45a)"
	printf "${Blue}%s\t: %s${NC}\n" "resourceGroup" "tcs-prod-int-vdi-core-cus-rg"
	printf "${Blue}%s\t: %s${NC}\n" "bastionName" "tcs-prod-int-vdi-core-cus-bastion"
	printf "${Blue}%s:${NC}\n" "VM Details"
	printf "${Blue}  %s: %s${NC}\n" "Name" "${vmName}"
	printf "${Blue}  %s: %s${NC}\n" "ID" "${vmId}"
	printf "${Blue}  %s: %s${NC}\n" "RG" "${vmRG}"

	if [[ -n "${1}" ]]; then
		if [[ "${1}" =~ "^[0-9]+[:][0-9]+$" ]]; then
    	localhostPort=$(cut -d':' -f1 <<< "${1}")
    	vmPort=$(cut -d':' -f2 <<< "${1}")
    else
    	printf "${Red}❌ %s${NC}" "Please provide ports in localhostPort:vmPort format."
    	return 1
    fi
	else
		printf "${Yellow}%s\n${NC}" "Switching to default ports 13389:3389"
    localhostPort=13389
    vmPort=3389
  fi

	: "${bastionName:?bastionName is empty}"
	: "${resourceGroup:?resourceGroup is empty}"
	: "${subscriptionName:?subscriptionName is empty}"
	: "${localhostPort:?localhostPort is empty}"
	: "${vmPort:?vmPort is empty}"
	: "${vmId:?vmId is empty}"

	echo "Localhost RDP port: ${localhostPort}"
	echo "VM RDP port: ${vmPort}"
	az network bastion tunnel \
		--name "${bastionName}" \
		--resource-group "${resourceGroup}" \
		--subscription "${subscriptionName}" \
		--port "${localhostPort}" \
		--resource-port "${vmPort}" \
		--target-resource-id "${vmId}"

}