#!/bin/bash

########### accepts argument: subject_id, session_id, seed name 

### mask to create
subject=$1
session=$2
seed=$3
echo Creating ${seed} mask

### 
repDWIall_shard=/neurospin/grip/external_databases/dHCP_CR_JD_2018/Projects/rel3_dhcp_dmri_shard_pipeline_analysis
DHCPPREFIX=sub-${subject}_ses-${session}

### save masks to the temp directory which gets removed once the subject is finished!
mkdir -p ${repDWIall_shard}/tmp

### if subcortical, use non-dilated parcellation, else use dilated parcellation
case $seed in
    S1LshMask|S1RshMask|M1LshMask|M1RshMask|ParacentralLshMask|ParacentralRshMask) 
		iPARC=${repDWIall_shard}/sub-${subject}/ses-${session}/${DHCPPREFIX}.dilated.combined.DKT-DRAWEM.volume.shardDMRI.space.nii.gz;;
    *)          iPARC=${repDWIall_shard}/sub-${subject}/ses-${session}/${DHCPPREFIX}.combined.DKT-DRAWEM.volume.shardDMRI.space.nii.gz;;
esac

#echo USING ${iPARC}

### set the labeling scheme == extremely ugly
### thalamus is special case!!! create as such

declare -A hashmap
hashmap["S1LshMask"]="122"
hashmap["S1RshMask"]="222"
hashmap["M1LshMask"]="124"
hashmap["M1RshMask"]="224"
hashmap["ParacentralLshMask"]="117"
hashmap["ParacentralRshMask"]="217"
hashmap["CaudLshMask"]="41"
hashmap["CaudRshMask"]="40"
hashmap["LentiLshMask"]="47"
hashmap["LentiRshMask"]="46"
hashmap["SubthalLshMask"]="45"
hashmap["SubthalRshMask"]="44"
hashmap["BrainstemshMask"]="19"
hashmap["ThalHiLshMask"]="43"
hashmap["ThalHiRshMask"]="42"
hashmap["ThalLiLshMask"]="87"
hashmap["ThalLiRshMask"]="86"


if [ $seed == "ThalfusLshMask" ] ; then 

	### run left thalamus stuff
	highL=${repDWIall_shard}/tmp/${DHCPPREFIX}_mask-ThalHiLsh.nii.gz
	lowL=${repDWIall_shard}/tmp/${DHCPPREFIX}_mask-ThalLiLsh.nii.gz
	AimsThreshold -i ${iPARC} -o ${highL} -m eq -t "${hashmap["ThalHiLshMask"]}" -b
	AimsThreshold -i ${iPARC} -o ${lowL} -m eq -t "${hashmap["ThalLiLshMask"]}" -b
	## fusion 
	cartoLinearComb.py -i ${highL} -i ${lowL} -f 'I1+I2' -o ${repDWIall_shard}/tmp/${DHCPPREFIX}_mask-ThalfusLshMask.nii.gz
	## mask by FA > 0.25
	#AimsMask -i ${repDWIall_shard}/tmp/${DHCPPREFIX}_mask-ThalfusLshMask.nii.gz -o ${repDWIall_shard}/tmp/${DHCPPREFIX}_mask-ThalfusLshMask.nii.gz -m ${repDWIall_shard}/tmp/${DHCPPREFIX}_FAmask.nii.gz --inv

elif [ $seed == "ThalfusRshMask" ]; then

	### run right thalamus stuff
	highR=${repDWIall_shard}/tmp/${DHCPPREFIX}_mask-ThalHiRsh.nii.gz
	lowR=${repDWIall_shard}/tmp/${DHCPPREFIX}_mask-ThalLiRsh.nii.gz
	AimsThreshold -i ${iPARC} -o ${highR} -m eq -t "${hashmap["ThalHiRshMask"]}" -b
	AimsThreshold -i ${iPARC} -o ${lowR} -m eq -t "${hashmap["ThalLiRshMask"]}" -b
	## fusion 
	cartoLinearComb.py -i ${highR} -i ${lowR} -f 'I1+I2' -o ${repDWIall_shard}/tmp/${DHCPPREFIX}_mask-ThalfusRshMask.nii.gz
	## mask by FA > 0.25
	#AimsMask -i ${repDWIall_shard}/tmp/${DHCPPREFIX}_mask-ThalfusRshMask.nii.gz -o ${repDWIall_shard}/tmp/${DHCPPREFIX}_mask-ThalfusRshMask.nii.gz -m ${repDWIall_shard}/tmp/${DHCPPREFIX}_FAmask.nii.gz --inv
	
else
	### run all else 
	AimsThreshold -i ${iPARC} -o ${repDWIall_shard}/tmp/${DHCPPREFIX}_mask-${seed}.nii.gz -m eq -t "${hashmap[${seed}]}" -b

	## mask by FA > 0.25
	#AimsMask -i ${repDWIall_shard}/tmp/${DHCPPREFIX}_mask-${seed}.nii.gz -o ${repDWIall_shard}/tmp/${DHCPPREFIX}_mask-${seed}.nii.gz -m ${repDWIall_shard}/tmp/${DHCPPREFIX}_FAmask.nii.gz --inv

fi











