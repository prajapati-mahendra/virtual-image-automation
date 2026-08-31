#!/usr/bin/env bash
#----------------------------
# @author   : 12/08/26:3:33 PM
# @Since    : mahendra.prajapati
#----------------------------

function packer-build() {
	export PACKER_NO_COLOR=1
	export PACKER_LOG=true
	[[ -d ${PWD}/log ]] || mkdir -p "${PWD}/log"
	# TS=$(date +%s%N)
	TS=$(date +"%Y-%m-%d_%H:%M:%S")
	export PACKER_LOG_PATH=${PWD}/log/packer-${TS}.log

	if packer validate "${@}"; then
		packer build "${@}" | tee "packer-${TS}.log"
	fi
}
