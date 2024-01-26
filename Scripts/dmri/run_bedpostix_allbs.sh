#!/bin/sh

### Date 18/11/2021
### Script runs bedpostX on all b-s diffusion data on kraken 
### requires: initialize environment (see recipes file)
### requires: file to loop over containing subject_id amd session_id 


echo Started at: `date`


#########
### This will run
#########
while read -r line
do 
	
	subject_id=$(echo "${line}" | cut -d ',' -f1)
	session_id=$(echo "${line}" | cut -d ',' -f2)

	INPUTDIR=/neurospin/grip/external_databases/dHCP_CR_JD_2018/release3/dhcp_dmri_shard_pipeline/sub-${subject_id}/ses-${session_id}/dwi
	BEDPOSTX_INPUT=${INPUTDIR}/bedpostX_input

	if [ -d "$INPUTDIR" ]
	then 
		echo Copying over ${subject_id} session ${session_id}
		if [ -d "$BEDPOSTX_INPUT" ]
		then  
			rm -r ${BEDPOSTX_INPUT}
		fi

		###
		mkdir -p ${BEDPOSTX_INPUT}
		
		ln -s ${INPUTDIR}/sub-${subject_id}_ses-${session_id}_desc-preproc_dwi.nii.gz ${BEDPOSTX_INPUT}/data.nii.gz
		ln -s ${INPUTDIR}/sub-${subject_id}_ses-${session_id}_desc-brain_mask.nii.gz ${BEDPOSTX_INPUT}/nodif_brain_mask.nii.gz
		ln -s ${INPUTDIR}/sub-${subject_id}_ses-${session_id}_desc-preproc_dwi.bval ${BEDPOSTX_INPUT}/bvals

		### THIS REALLY REALLY SHOULD BE BVALS!!!!!!!!!!!! DOES THIS NEED TO BE RERUN?
		if [ -f "${INPUTDIR}/sub-${subject_id}_ses-${session_id}_desc-preproc_dwi_original.bvec" ] 
		then
			ln -s ${INPUTDIR}/sub-${subject_id}_ses-${session_id}_desc-preproc_dwi_original.bvec ${BEDPOSTX_INPUT}/bvecs
		else 
			ln -s ${INPUTDIR}/sub-${subject_id}_ses-${session_id}_desc-preproc_dwi.bvec ${BEDPOSTX_INPUT}/bvecs
		fi	
		echo Copying finished
		echo Running BedpostX 

		start_date=`date`
		
		bedpostx_gpu ${BEDPOSTX_INPUT}/ -model 3
		
		echo ${subject_id} session ${session_id} STARTED at: ${start_date} FINISHED at: `date`
		echo ***
	fi		
done <  "$1"
echo FINISHED AT: `date`

