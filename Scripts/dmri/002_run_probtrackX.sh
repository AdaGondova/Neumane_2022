#!/bin/bash

# skeleton 530,628

### set working directory 
cd /neurospin/grip/external_databases/dHCP_CR_JD_2018/Projects/dmri_publication_project/Scripts/dmri/
##### for subject in the file 
while read -r line
do 
	
	subject_id=$(echo "${line}" | cut -d ',' -f1)
	session_id=$(echo "${line}" | cut -d ',' -f2)
	DHCPPREFIX=sub-${subject_id}_ses-${session_id}
	
	
	repDWIbedpostxSh=/neurospin/grip/external_databases/dHCP_CR_JD_2018/release3/dhcp_dmri_shard_pipeline/sub-${subject_id}/ses-${session_id}/dwi/bedpostX_input.bedpostX
	
	
	if [ -d "$repDWIbedpostxSh" ]
	then 
		echo Working on SUBJECT ${subject_id} ${session_id} bedpostX folder

		maskFolder=/neurospin/grip/external_databases/dHCP_CR_JD_2018/Projects/rel3_dhcp_dmri_shard_pipeline_analysis/tmp	
	
		# clean up old if exists
		#if [ -d "$maskFolder" ]; then rm -Rf $maskFolder; fi

		### Create global exclusion masks	
		echo Creating global exclusion masks
	
		./002_b_create_intermediary_exclusion_mask.sh ${subject_id} ${session_id}
	
		if [ -d "$maskFolder" ]
		then 
			ls ${maskFolder}
		else 
			echo problem with exclusion mask creation	
		fi


		#### for pair in the list 
		while read -r line
		do
			seed1=$(echo "${line}" | cut -d ',' -f1)
			seed2=$(echo "${line}" | cut -d ',' -f2)
			exclusion_mode=$(echo "${line}" | cut -d ',' -f3)

			echo ${seed1} ${seed2} ${exclusion_mode}
		
			### Create seed1 mask 
			seed1_mask=${maskFolder}/${DHCPPREFIX}_mask-${seed1}.nii.gz
		
			if [ ! -e "$seed1_mask" ]
			then 
				./002_a_create_seed_masks.sh ${subject_id} ${session_id} ${seed1}
			else 
				echo ${seed1} mask exists
			fi		

			### Create seed2 mask 
			seed2_mask=${maskFolder}/${DHCPPREFIX}_mask-${seed2}.nii.gz
		
			if [ ! -e "$seed2_mask" ]
			then 
				./002_a_create_seed_masks.sh ${subject_id} ${session_id} ${seed2}
			else 
				echo ${seed2} mask exists
			fi
		
			### Create exclusion mask based on the nature of the pair 
			base_mask=${maskFolder}/${DHCPPREFIX}_${exclusion_mode}setting.nii.gz

			AimsMask -i ${base_mask} -o ${maskFolder}/final_exclusion_mask.nii.gz -m ${seed1_mask} --inv
			AimsMask -i ${maskFolder}/final_exclusion_mask.nii.gz -o ${maskFolder}/final_exclusion_mask.nii.gz -m ${seed2_mask} --inv

		
			### run probtrakX-gpu 		

			# create input region file
			echo "${seed1_mask}" > region_pairs_sh2.txt;
			echo "${seed2_mask}" >> region_pairs_sh2.txt;
			
			output_dir=/neurospin/grip/external_databases/dHCP_CR_JD_2018/release3/dhcp_dmri_shard_pipeline/sub-${subject_id}/ses-${session_id}/dwi/probtrakX_results
			
			#echo running tractography...
	
			probtrackx2_gpu --network -x region_pairs_sh2.txt -l --onewaycondition -c 0.2 -S 2000 --steplength=0.5 -P 5000 --fibthresh=0.01 --distthresh=0.0 --sampvox=0.0 --ompl --avoid=${maskFolder}/final_exclusion_mask.nii.gz --forcedir --opd -s ${repDWIbedpostxSh}/merged -m ${repDWIbedpostxSh}/nodif_brain_mask --dir=${output_dir}/ROIbyROI-2x2_${seed1}-${seed2}_sh

			rm -f region_pairs_sh2.txt
		
		
		done < "$2"
		echo All pairs finished.
		if [ -d "$maskFolder" ]; then rm -Rf $maskFolder; fi
	else
		echo BedpostX SUBJECT ${subject_id} ${session_id} DOES NOT EXIST
	fi
	
	
done <  "$1"
echo FINISHED AT: `date`



