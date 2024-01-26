import numpy as np
import pandas as pd
from soma import aims
import os, datetime, subprocess, sys
from scipy.ndimage import distance_transform_edt


### Combine MCRIBS parcelation and DRAWEM subcortical regions parcellation. Dilate the labels into WM for the subsequent tractography. 
### Date: 1/9/2021
### Author: Andrea Gondova
### requires brainvisa env
### COMMENT: PATHS ARE ABSOLUTELY HIDEOUS THIS NEEDS A REWORK!

def check_inputs_exist(subject_id, session_id):

	iMCRIBS = '/neurospin/grip/external_databases/dHCP_CR_JD_2018/Projects/rel3_dhcp_anat_pipeline_analysis/sub-{}/ses-{}/anat/sub-{}_ses-{}.combined.DKT.volume.nii.gz'.format(subject_id, session_id,subject_id, session_id)
	iDRAWEM = '/neurospin/grip/external_databases/dHCP_CR_JD_2018/release3/dhcp_anat_pipeline/sub-{}/ses-{}/anat/sub-{}_ses-{}_desc-drawem87_dseg.nii.gz'.format(subject_id, session_id,subject_id, session_id)
	iMASK = '/neurospin/grip/external_databases/dHCP_CR_JD_2018/release3/dhcp_anat_pipeline/sub-{}/ses-{}/anat/sub-{}_ses-{}_desc-drawem9_dseg.nii.gz'.format(subject_id, session_id,subject_id, session_id)

	for f in [iMCRIBS, iDRAWEM, iMASK]:
		if not os.path.isfile(f):
			print()
			
	if all(list(map(os.path.isfile, [iMCRIBS, iDRAWEM, iMASK]))):
		return True
	else:
		print('Inputs not found. Skipping subject: {}'.format(subject_id))
		return False

def expand_labels(volume, distance =2):

    distances, nearest_label_coords = distance_transform_edt( volume == 0 , return_indices=True)
    labels_out = np.zeros_like(volume)
    dilate_mask = distances <= distance

    masked_nearest_label_coords = [
        dimension_indices[dilate_mask]
        for dimension_indices in nearest_label_coords
                ]

    nearest_labels = volume[tuple(masked_nearest_label_coords)]
    labels_out[dilate_mask] = nearest_labels
    
    return labels_out



def combine_parcelations(subject_id, session_id):
	
	iMCRIBS = '/neurospin/grip/external_databases/dHCP_CR_JD_2018/Projects/rel3_dhcp_anat_pipeline_analysis/sub-{}/ses-{}/anat/sub-{}_ses-{}.combined.DKT.volume.nii.gz'.format(subject_id, session_id,subject_id, session_id)
	iDRAWEM = '/neurospin/grip/external_databases/dHCP_CR_JD_2018/release3/dhcp_anat_pipeline/sub-{}/ses-{}/anat/sub-{}_ses-{}_desc-drawem87_dseg.nii.gz'.format(subject_id, session_id,subject_id, session_id)

	oCOMBINED = '/neurospin/grip/external_databases/dHCP_CR_JD_2018/Projects/rel3_dhcp_anat_pipeline_analysis/sub-{}/ses-{}/anat/sub-{}_ses-{}.combined.DKT-DRAWEM.volume.nii.gz'.format(subject_id, session_id,subject_id, session_id)

	cortex_parc = aims.read(iMCRIBS)
	cortex_a = np.array(cortex_parc.arraydata(), dtype=int)

	drawem_parc = aims.read(iDRAWEM)
	drawem_a = np.array(drawem_parc.arraydata(), dtype=int)
	## keep only subcortical segmentation 
	sub_regions = [1,2,3,4,17,18,19,40,41,42,43,44,45,46,47,48,86,87]
	drawem_a[~np.isin(drawem_a, sub_regions)] = 0

	# combine the segmentations
	combinedV = cortex_a + drawem_a
	combinedV = combinedV.astype(np.int16)

	# save
	oCV = aims.Volume(combinedV)
	oCV.header().update(cortex_parc.header())
	aims.write(oCV, oCOMBINED)

	if os.path.isfile(oCOMBINED):
		print('Parcellations COMBINED')

def dilate_parcellations(subject_id, session_id):
	oCOMBINED = '/neurospin/grip/external_databases/dHCP_CR_JD_2018/Projects/rel3_dhcp_anat_pipeline_analysis/sub-{}/ses-{}/anat/sub-{}_ses-{}.combined.DKT-DRAWEM.volume.nii.gz'.format(subject_id, session_id,subject_id, session_id)
	iMASK = '/neurospin/grip/external_databases/dHCP_CR_JD_2018/release3/dhcp_anat_pipeline/sub-{}/ses-{}/anat/sub-{}_ses-{}_desc-drawem9_dseg.nii.gz'.format(subject_id, session_id,subject_id, session_id)
	oDILATED = '/neurospin/grip/external_databases/dHCP_CR_JD_2018/Projects/rel3_dhcp_anat_pipeline_analysis/sub-{}/ses-{}/anat/sub-{}_ses-{}.dilated.combined.DKT-DRAWEM.volume.nii.gz'.format(subject_id, session_id,subject_id, session_id)

	cortex_parc = aims.read(oCOMBINED)
	cortex_a = np.array(cortex_parc.arraydata(), dtype=int)

	# get mask for cleaning up (want to dilate into towards the inside of the brain)
	mask = aims.read(iMASK)
	mask_a = np.array(mask.arraydata(), dtype=int)
	to_keep = [2,3,6,7,8,9]
	mask_a[~np.isin(mask_a, to_keep)] = 0
	mask_a[mask_a != 0] = 1
	
	# the labels
	expanded = expand_labels(cortex_a[0], distance =2)
	expanded_out = expanded * mask_a
	
	# save the dilated 
	expanded_out = expanded_out.astype(np.int16)
	oDV = aims.Volume(expanded_out)
	oDV.header().update(cortex_parc.header())
	aims.write(oDV, oDILATED)

	if os.path.isfile(oDILATED):
		print('Parcellations DILATED')


if __name__ == "__main__":
	print('START at: {}'.format(datetime.datetime.now()))

	
	### read in the file containing the list of subject ID and session IDs
	if len(sys.argv) < 2:
		print("You must provide subject file!")
		sys.exit()
	else:
		subject_file = sys.argv[1]

	subjects = pd.read_csv(subject_file, names=['subject_id', 'session_id'])

	for i, row in subjects.iterrows():
		
		subject_id = row.subject_id
		session_id = row.session_id

		print('Working on Subject {}, session{}'.format(subject_id, session_id))
		if check_inputs_exist(subject_id, session_id):
			
			combine_parcelations(subject_id, session_id)
			dilate_parcellations(subject_id, session_id)

	print('END at: {}'.format(datetime.datetime.now()))



