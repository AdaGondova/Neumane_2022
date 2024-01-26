#!/bin/bash


#### run DTI on the shard dMRI
# similar to eddy dHCP pipeline: https://git.fmrib.ox.ac.uk/matteob/dHCP_neo_dMRI_pipeline_release/-/blob/master/dHCP_neo_dMRI_runPostProc.sh 
while read -r line
do 
	
	subject_id=$(echo "${line}" | cut -d ',' -f1)
	session_id=$(echo "${line}" | cut -d ',' -f2)

	INPUTDIR=/neurospin/grip/external_databases/dHCP_CR_JD_2018/release3/dhcp_dmri_shard_pipeline/sub-${subject_id}/ses-${session_id}/dwi
	echo ${INPUTDIR}
	diffFolder=${INPUTDIR}/DTI

	if [ -d "$INPUTDIR" ]		
	then 
		echo Working on ${subject_id} session ${session_id}
		
		mkdir -p ${diffFolder}

		# create links to the input data
		ln -s ${INPUTDIR}/sub-${subject_id}_ses-${session_id}_desc-preproc_dwi.nii.gz ${diffFolder}/data.nii.gz
		ln -s ${INPUTDIR}/sub-${subject_id}_ses-${session_id}_desc-brain_mask.nii.gz ${diffFolder}/nodif_brain_mask.nii.gz
		ln -s ${INPUTDIR}/sub-${subject_id}_ses-${session_id}_desc-preproc_dwi.bval ${diffFolder}/bvals

		if [ -f "${INPUTDIR}/sub-${subject_id}_ses-${session_id}_desc-preproc_dwi_original.bvec" ] 
		then
			ln -s ${INPUTDIR}/sub-${subject_id}_ses-${session_id}_desc-preproc_dwi_original.bvec ${diffFolder}/bvecs
		else 
			ln -s ${INPUTDIR}/sub-${subject_id}_ses-${session_id}_desc-preproc_dwi.bvec ${diffFolder}/bvecs
		fi	

		echo Input creation finished
		echo Running DTI... 

		start_date=`date`

		#============================================================================
		# Get the brain mask using BET, average shell data and attenuation profiles.
		# Fit diffusion tensor to each shell separately
		#============================================================================

		#uniqueBvals=(`cat ${diffFolder}/bvals`)

		#for b in "${uniqueBvals[@]}"
		#do
   	 		#select_dwi_vols ${diffFolder}/data ${diffFolder}/bvals ${diffFolder}/mean_b${b} ${b} -m
   			
			#echo "Fitting DT to b=${b} shell..."
		        #mkdir -p ${diffFolder}/dtifit_b${b}
	
		        #select_dwi_vols ${diffFolder}/data ${diffFolder}/bvals ${diffFolder}/dtifit_b${b}/b${b} 0 -b ${b} -obv ${diffFolder}/bvecs 
        		#dtifit -k ${diffFolder}/dtifit_b${b}/b${b} -o ${diffFolder}/dtifit_b${b}/dti -m ${diffFolder}/nodif_brain_mask -r ${diffFolder}/dtifit_b${b}/b${b}.bvec -b ${diffFolder}/dtifit_b${b}/b${b}.bval --sse --save_tensor
        		#fslmaths ${diffFolder}/mean_b${b} -div ${diffFolder}/mean_b0 -mul ${diffFolder}/nodif_brain_mask ${diffFolder}/att_b${b}
    			
    			#fslmaths ${diffFolder}/mean_b${b} -mul ${diffFolder}/nodif_brain_mask ${diffFolder}/mean_b${b}
		#done

		#============================================================================
		# Run only on 0 and 1000b
		#
		#============================================================================
		uniqueBvals=(`cat ./shells`)
		
		for b in "${uniqueBvals[@]}"
		do

		if [ $b == 0 ] || [ $b == 1000 ]
		then	
   	 		select_dwi_vols ${diffFolder}/data ${diffFolder}/bvals ${diffFolder}/mean_b${b} ${b} -m
   			
			echo "Fitting DT to b=${b} shell..."
		        mkdir -p ${diffFolder}/dtifit_b${b}
	
		        select_dwi_vols ${diffFolder}/data ${diffFolder}/bvals ${diffFolder}/dtifit_b${b}/b${b} 0 -b ${b} -obv ${diffFolder}/bvecs 
        		dtifit -k ${diffFolder}/dtifit_b${b}/b${b} -o ${diffFolder}/dtifit_b${b}/sub-${subject_id}_ses-${session_id} -m ${diffFolder}/nodif_brain_mask -r ${diffFolder}/dtifit_b${b}/b${b}.bvec -b ${diffFolder}/dtifit_b${b}/b${b}.bval --sse --save_tensor
        		fslmaths ${diffFolder}/mean_b${b} -div ${diffFolder}/mean_b0 -mul ${diffFolder}/nodif_brain_mask ${diffFolder}/att_b${b}
    			fslmaths ${diffFolder}/mean_b${b} -mul ${diffFolder}/nodif_brain_mask ${diffFolder}/mean_b${b}
		fi
		done
		
		#============================================================================
		# Fit Kurtosis model.
		#============================================================================

		#echo "Multi-shell data: fitting DK to all shells..."
		#mkdir -p ${diffFolder}/dkifit
		#dtifit -k ${diffFolder}/data -o ${diffFolder}/dkifit/dki -m ${diffFolder}/nodif_brain_mask -r ${diffFolder}/bvecs -b ${diffFolder}/bvals --sse --save_tensor --kurt --kurtdir


	echo ${subject_id} finished. Start time: ${stard_date}. End time: `date`
	fi		
done <  "$1"
echo FINISHED AT: `date`
