#!/bin/bash

### Date: 2.3.2021
### Author: andrea.gondova@cea.fr


### Script that runs M-CRIB-S parcellation on dHCP surfaces
### loops over subject_id, session_id in a csv
### requires: endswith.json file that specifies ending of the required files
### requires: initialization of freesurfer_init environment outside the script
### run as ./code.sh subtects.csv

# !!! if there are file not found errors it's usually cause endswith.json file is wrong!
# TO DO: install MCRIBS elsewhere so it's not dependent on my ag265252 account (see PATHS)


#############################################################################################
echo Stared at: `date`

## Set up environment (assumes freesurfer_init was run outside)
# export MCRIBS path so I can use it
export PATH=/home/ag265252/bin:$PATH 
export PATH=/home/ag265252/MCRIBS/bin:$PATH

# adding MCRIBS python packages
export PYTHONPATH=$PYTHONPATH:/home/ag265252/lib/python
export PYTHONPATH=$PYTHONPATH:/home/ag265252/MCRIBS/lib/python


## Loop over subjects, assumes subject and session IDs list as csv
while read -r line
do
	subject_id=$(echo "${line}" | cut -d ',' -f1)
	session_id=$(echo "${line}" | cut -d ',' -f2) 
	
	INPUTDIR=/neurospin/grip/external_databases/dHCP_CR_JD_2018/release3/dhcp_anat_pipeline/sub-${subject_id}/ses-${session_id}/anat
	OUTPUTDIR=/neurospin/grip/external_databases/dHCP_CR_JD_2018/Projects/rel3_dhcp_anat_pipeline_analysis/sub-${subject_id}/ses-${session_id}/anat
	
	echo RUNNING subject "${subject_id}" session "${session_id}"
	
	## the below should skip subjects with misssing inputs or who already have been segmented
	if [ -d "$INPUTDIR" ] || [ ! -f $INPUTDIR/sub-${subject_id}_ses-${session_id}_rh.DKT.label.gii ]
	then 
		## make output folders if they do not exist
		mkdir -p /neurospin/grip/external_databases/dHCP_CR_JD_2018/Projects/rel3_dhcp_anat_pipeline_analysis
		mkdir -p /neurospin/grip/external_databases/dHCP_CR_JD_2018/Projects/rel3_dhcp_anat_pipeline_analysis/sub-${subject_id}
		mkdir -p /neurospin/grip/external_databases/dHCP_CR_JD_2018/Projects/rel3_dhcp_anat_pipeline_analysis/sub-${subject_id}/ses-${session_id}
		mkdir -p /neurospin/grip/external_databases/dHCP_CR_JD_2018/Projects/rel3_dhcp_anat_pipeline_analysis/sub-${subject_id}/ses-${session_id}/anat

		
		## set DHCP prefix for given subject
		# get DHCP prefix
		DHCPPREFIX=sub-${subject_id}_ses-${session_id}_
		# sometimes subjects do not have zipped volumes (.nii.gz) so use a different json		
		jason=$([ -f $INPUTDIR/*desc-restore_T2w.nii.gz ] && echo "endswith.json" || echo "alt_endswith.json")

		#jason=endswith.json

		# sometimes subjects do not have zipped volumes (.nii.gz) so use a different json		
		#if [ ! -f $INPUTDIR/*desc-restore_T2w.nii.gz]
		#then
		#	jason=new_endswith.json
		#fi

		## sanity check for inputs 
		echo $INPUTDIR
		echo ${DHCPPREFIX}
		echo ${jason}
		
		### Run the M-CRIB-S pipeline
		# 1. import DHCP data for the subject into MCRIBS format 
		# !!! again this needs to be changes to make it account independent
		/home/ag265252/MCRIBS/bin/adjustedMCRIBDHCPImport "${DHCPPREFIX}" "${jason}" "${INPUTDIR}"
		
		# 2. Run the parcellation pipeline (multiple settings, this runs all of it)
		START=$(date "+%s")		
		/home/ag265252/MCRIBS/bin/MCRIBReconAll --all --noconform --notissueseg --nosurfrecon --nosegstats --nosurfvol --noparcstats --noaparc2aseg "${DHCPPREFIX}" 
		END=$(date "+%s")
		echo ELAPSED TIME: $(echo "($END-$START)/60" | bc -l ) minutes

		# 3. ouput MCRIBS data to DHCP folder
		#/home/ag265252/MCRIBS/bin/adjustedMCRIBDHCPExport "${DHCPPREFIX}" "${OUTPUTDIR}"
		#running the below insead will export only wm and parcellations 
		/home/ag265252/MCRIBS/bin/andrea_adjustedMCRIBDHCPExport "${DHCPPREFIX}" "${OUTPUTDIR}"
		
		# 4. clean up the intermed. files
		rm -r freesurfer/
		rm -r TissueSeg/
		rm -r RawT2RadiologicalIsotropic/
		rm sub*.nii.gz
		rm -r logs




		echo -e "\n***\n***\n***\n"
	else
		if [  -f $INPUTDIR/sub-${subject_id}_ses-${session_id}_rh.DKT.label.gii ]
		then 
			echo MISSING INPUT DATA
		else
			echo PREVIOUS SEGMENTATION FOUND
		fi 
		echo SKIPPING SUBJECT 

	fi 

done < "$1"
echo Finished at: `date`
		

