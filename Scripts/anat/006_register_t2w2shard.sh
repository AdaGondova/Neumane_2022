#!/bin/bash

### Scripts registers (applies available transofrmation matrix) parcellations from native anat space to shard dmri space for future diffusion processing using FLIRT 
### Requires: initialize fsl outside: fsl_init
### input subject csv file

########################################################
echo Started at: `date`
while read -r line
do
	subject=$(echo "${line}" | cut -d ',' -f1)
	session=$(echo "${line}" | cut -d ',' -f2)

	iParcDKT=/neurospin/grip/external_databases/dHCP_CR_JD_2018/Projects/rel3_dhcp_anat_pipeline_analysis/sub-${subject}/ses-${session}/anat/sub-${subject}_ses-${session}.combined.DKT.volume.nii.gz
	iParcDKT_dHCP_dil=/neurospin/grip/external_databases/dHCP_CR_JD_2018/Projects/rel3_dhcp_anat_pipeline_analysis/sub-${subject}/ses-${session}/anat/sub-${subject}_ses-${session}.dilated.combined.DKT-DRAWEM.volume.nii.gz
	iParcDKT_dHCP_non_dil_sub=/neurospin/grip/external_databases/dHCP_CR_JD_2018/Projects/rel3_dhcp_anat_pipeline_analysis/sub-${subject}/ses-${session}/anat/sub-${subject}_ses-${session}.combined.DKT-DRAWEM.volume.nii.gz
	iRibbon=/neurospin/grip/external_databases/dHCP_CR_JD_2018/release3/dhcp_anat_pipeline/sub-${subject}/ses-${session}/anat/sub-${subject}_ses-${session}_desc-ribbon_dseg.nii.gz
	
	iWarp=/neurospin/grip/external_databases/dHCP_CR_JD_2018/release3/dhcp_dmri_shard_pipeline/sub-${subject}/ses-${session}/xfm/sub-${subject}_ses-${session}_from-T2w_to-dwi_mode-image.mat
	#iRef=/neurospin/grip/external_databases/dHCP_CR_JD_2018/release3/dhcp_dmri_shard_pipeline/sub-${subject}/ses-${session}/dwi/DWI_sorted/sub-${subject}_ses-${session}_FA.nii.gz 
	iRef=/neurospin/grip/external_databases/dHCP_CR_JD_2018/release3/dhcp_dmri_shard_pipeline/sub-${subject}/ses-${session}/dwi/sub-${subject}_ses-${session}_desc-brain_mask.nii.gz 
	#iMASK=/neurospin/grip/external_databases/dHCP_CR_JD_2018/Projects/rel3_dhcp_anat_pipeline_analysis/sub-${subject}/ses-${session}/anat/sub-${subject}_ses-${session}_test_CSF_mask.nii.gz
	oDir=/neurospin/grip/external_databases/dHCP_CR_JD_2018/Projects/rel3_dhcp_dmri_shard_pipeline_analysis/sub-${subject}/ses-${session}
	

	echo "$oDir"
	if [ ! -d "$oDir" ]
	then 
		## make output folders if they do not exist		
		mkdir -p /neurospin/grip/external_databases/dHCP_CR_JD_2018/Projects/rel3_dhcp_dmri_shard_pipeline_analysis
		mkdir -p /neurospin/grip/external_databases/dHCP_CR_JD_2018/Projects/rel3_dhcp_dmri_shard_pipeline_analysis/sub-${subject}
		mkdir -p /neurospin/grip/external_databases/dHCP_CR_JD_2018/Projects/rel3_dhcp_dmri_shard_pipeline_analysis/sub-${subject}/ses-${session}
	
	fi 


	oParcDKT=${oDir}/sub-${subject}_ses-${session}.combined.DKT.volume.shardDMRI.space.nii.gz
	oParcDKT_dHCP_dil=${oDir}/sub-${subject}_ses-${session}.dilated.combined.DKT-DRAWEM.volume.shardDMRI.space.nii.gz
	oParcDKT_dHCP_non_dil_sub=${oDir}/sub-${subject}_ses-${session}.combined.DKT-DRAWEM.volume.shardDMRI.space.nii.gz
	oRibbon=${oDir}/sub-${subject}_ses-${session}_desc-ribbon_dseg_shardDMRI_space.nii.gz
	#oMASK=${oDir}/sub-${subject}_ses-${session}_test_anatCSF_mask_shardDMRI_space.nii.gz
 
	#MCRIBS
	flirt -in ${iParcDKT} -ref ${iRef} -out ${oParcDKT} -init ${iWarp} -applyxfm -interp nearestneighbour
	flirt -in ${iParcDKT_dHCP_dil} -ref ${iRef} -out ${oParcDKT_dHCP_dil} -init ${iWarp} -applyxfm -interp nearestneighbour
	flirt -in ${iParcDKT_dHCP_non_dil_sub} -ref ${iRef} -out ${oParcDKT_dHCP_non_dil_sub} -init ${iWarp} -applyxfm -interp nearestneighbour
	flirt -in ${iRibbon} -ref ${iRef} -out ${oRibbon} -init ${iWarp} -applyxfm -interp nearestneighbour
	###flirt -in ${iMASK} -ref ${iRef} -out ${oMASK} -init ${iWarp} -applyxfm -interp nearestneighbour

	
done < "$1"

echo Finished at: `date`
