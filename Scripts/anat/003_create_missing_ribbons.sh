#!/bin/bash

### Date: 29.6.2021
### Author: andrea.gondova@cea.fr

### The file recreates missing ribbons for the dHCP release 3 subjects
### Assumes subject csv files containing <subject_id>,<session_id>/row
### Usage instructions:  
### 1. fsl_init
### 2. within the env set up path to tools . /volatile/dhcp-structural-pipeline/parameters/path.sh  == not the best solution as requires access to my own installation on volatile, in the future find better place
### requires wb_command, fsl & mirtk

### run ./run_create_missing_ribbon_files_release3.sh <subjects.csv>
 

#########################################################################################

echo Stared at: `date`

### SET output labels
LeftGreyRibbonValue="3"
LeftGreyRibbonValueIn="2"
RightGreyRibbonValue="42"
RightGreyRibbonValueIn="41"
CSF_label="1"
CGM_label="2"

# for indermediary files	
mkdir -p rib_tmp

## subject info / line 
while read -r line
do
	subj_id=$(echo "${line}" | cut -d ',' -f1)
	ses_id=$(echo "${line}" | cut -d ',' -f2)

	echo CHECKING RIBBON FILE SUBJECT: "$subj_id", session "$ses_id"

	INPUTDIR=/neurospin/grip/external_databases/dHCP_CR_JD_2018/release3/dhcp_anat_pipeline/sub-${subj_id}/ses-${ses_id}/anat
	
	if [  -f $INPUTDIR/sub-${subj_id}_ses-${ses_id}_desc-ribbon_dseg.nii.gz ]
	then 
		echo RIBBON OK
	else
		echo MISSING 

		iT2=${INPUTDIR}/sub-${subj_id}_ses-${ses_id}_desc-restore_T2w.nii.gz
		iLab=${INPUTDIR}/sub-${subj_id}_ses-${ses_id}_desc-drawem9_dseg.nii.gz
		oRib=${INPUTDIR}/sub-${subj_id}_ses-${ses_id}_desc-ribbon_dseg.nii.gz

		echo CREATING "${oRib}"
		
		### needs to be done for the 2 hemispheres		
		for h in left right
		do
			echo Preparing labels "$h" hemi...		
			iPial=${INPUTDIR}/sub-${subj_id}_ses-${ses_id}_hemi-${h}_pial.surf.gii
			oDist=rib_tmp/sub-${subj_id}_ses-${ses_id}_dist_${h}.nii.gz
			#			
			wb_command -create-signed-distance-volume $iPial $iT2 $oDist
			fslmaths $oDist -uthr 0 -abs -bin $oDist	
			fslmaths $iLab -mul $oDist rib_tmp/sub-${subj_id}_ses-${ses_id}_tissue_labels_${h}.nii.gz 
			#
			
		done	
		
		### LEFT 
		echo Working on the LEFT hemi...
		L_tissue_labels=rib_tmp/sub-${subj_id}_ses-${ses_id}_tissue_labels_left.nii.gz
		#
		mirtk padding $L_tissue_labels $L_tissue_labels rib_tmp/sub-${subj_id}_ses-${ses_id}_in_L.nii.gz 2 $CSF_label $CGM_label 0
		fslmaths rib_tmp/sub-${subj_id}_ses-${ses_id}_in_L.nii.gz -bin -mul $LeftGreyRibbonValueIn rib_tmp/sub-${subj_id}_ses-${ses_id}_in_L.nii.gz
		fslmaths $L_tissue_labels -thr $CGM_label -uthr $CGM_label -bin -mul $LeftGreyRibbonValue rib_tmp/sub-${subj_id}_ses-${ses_id}_out_L.nii.gz
		#
		
		### RIGHT 
		echo Working on the RIGHT hemi...
		R_tissue_labels=rib_tmp/sub-${subj_id}_ses-${ses_id}_tissue_labels_right.nii.gz
		#
		mirtk padding $R_tissue_labels $R_tissue_labels rib_tmp/sub-${subj_id}_ses-${ses_id}_in_R.nii.gz 2 $CSF_label $CGM_label 0
		fslmaths rib_tmp/sub-${subj_id}_ses-${ses_id}_in_R.nii.gz -bin -mul $RightGreyRibbonValueIn rib_tmp/sub-${subj_id}_ses-${ses_id}_in_R.nii.gz
		fslmaths $R_tissue_labels -thr $CGM_label -uthr $CGM_label -bin -mul $RightGreyRibbonValue rib_tmp/sub-${subj_id}_ses-${ses_id}_out_R.nii.gz
		#

		### COMBINE HEMISPHERES 
		echo Combining LEFT and RIGHT...
		#
		fslmaths rib_tmp/sub-${subj_id}_ses-${ses_id}_in_L.nii.gz -add rib_tmp/sub-${subj_id}_ses-${ses_id}_in_R.nii.gz -add rib_tmp/sub-${subj_id}_ses-${ses_id}_out_L.nii.gz -add rib_tmp/sub-${subj_id}_ses-${ses_id}_out_R.nii.gz $oRib
		#
		echo FINISHED SUBJECT: "$subj_id", session "$ses_id"
		echo "***"
	
	fi

done < "$1"

#cleanup
rm -r rib_tmp
echo Finished at: `date`






