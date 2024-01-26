#!/bin/bash


LD_LIBRARY_PATH="/home_local/ag265252/cudalibs$LD_LIBRARY_PATH"
export CUDIMOT=/home_local/ag265252/NODDI/cuDIMOT/NODDI_Watson
bindir=${CUDIMOT}/bin


while read -r line
do 
	
	subject_id=$(echo "${line}" | cut -d ',' -f1)
	session_id=$(echo "${line}" | cut -d ',' -f2)

	ORIGINAL_DATA=/neurospin/grip/external_databases/dHCP_CR_JD_2018/release3/dhcp_dmri_shard_pipeline/sub-${subject_id}/ses-${session_id}/dwi

	if [ -d "$ORIGINAL_DATA" ]
	then 
		echo Preparing subject directory: $subject_id
		mkdir -p input_dir

		#==================================================== COPY FILES ============================#	
		ln -s ${ORIGINAL_DATA}/sub-${subject_id}_ses-${session_id}_desc-preproc_dwi.nii.gz input_dir/data.nii.gz
		ln -s ${ORIGINAL_DATA}/sub-${subject_id}_ses-${session_id}_desc-brain_mask.nii.gz input_dir/nodif_brain_mask.nii.gz
		ln -s ${ORIGINAL_DATA}/sub-${subject_id}_ses-${session_id}_desc-preproc_dwi.bvec input_dir/bvecs
		### nodi wants integer instead of float bvals, I am using the one created by Sara 
		ln -s /neurospin/grip/external_databases/dHCP_CR_JD_2018/release3/dhcp_dmri_shard_pipeline/sub-CC00136AN13/ses-64201/dwi/sub-CC00136AN13_ses-64201_desc-preproc_dwi.bval input_dir/bvals

	#==================================================== Calculate SO ============================#
	# Calculate S0 with the mean of the volumes with bval<50
#	bvals=`cat input_dir/bvals`
#	mkdir -p input_dir/temporal
#	pos=0
#	for i in $bvals; do 
 #   	if [ $i -le 50 ]; then  
  #     		fslroi input_dir/data input_dir/temporal/volume_$pos $pos 1    
  # 	fi 
  #  	pos=$(($pos + 1))
#	done
#	fslmerge -t input_dir/temporal/S0s input_dir/temporal/volume*
#	fslmaths input_dir/temporal/S0s -Tmean input_dir/S0.nii.gz
#	rm -rf input_dir/temporal

	#======================================== Parameter files ============================#
	### create parameter files 
#	echo Creating CFP 
#	echo input_dir/bvecs > input_dir/CFP
#	echo input_dir/bvals >> input_dir/CFP
	
#	echo Creating FixP
#	echo input_dir/S0.nii.gz > input_dir/FixP


		#======================================== FIT NODDI ============================#
		echo Calling the cudimot AT `date`
		#$CUDIMOT/bin/cudimot_NODDI_Watson.sh input_dir/ --runMCMC --CFP=input_dir/CFP --FixP=input_dir/FixP
		$CUDIMOT/bin/Pipeline_NODDI_Watson.sh input_dir/ --runMCMC --BIC_AIC --getPredictedSignal
		#======================================== CLEAN UP ============================#

		#mv input_dir.NODDI_Watson $subject_id.NODDI_Watson_pipeline
		#rm -rf input_dir 
		OUTPUTDIR=/neurospin/grip/external_databases/dHCP_CR_JD_2018/release3/dhcp_dmri_shard_pipeline/sub-${subject_id}/ses-${session_id}/dwi/NODDI

		mkdir -p $OUTPUTDIR
		### implement copying over of the results and remove the directory
		mv input_dir.NODDI_Watson/*.nii.gz $OUTPUTDIR/

		rm -rf input_dir.NODDI_Watson
		rm -rf input_dir
		echo $subject_id NODDI model finished 
	fi 
done <  "$1"
echo FINISHED AT: `date`


