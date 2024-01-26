from soma import aims
import numpy as np
import os, sys 
import pandas as pd

##### this file changes information in headers of t2w input files to get them into the format required to run MCRIBS
##### the change solves error that has arisen due to LPI vs RPI change between dHCP release2 and release3

### the below was used before when subject file path was hard coded into the script 
#os.chdir('/neurospin/grip/external_databases/dHCP_CR_JD_2018/Projects/dmri_publication_project/Scripts/anat')

### read in the file containing the list of subject ID and session IDs
subject_file = sys.argv[1]

if os.path.exists(subject_file):
	subjects = pd.read_csv(subject_file, names=['subject_id', 'session_id'])
	print('SUBJECT FILE read\nNumber of subjects to flip:{}'.format(len(subjects)))
else:
	print("Subject file does not exist!")	
	sys.exit()

### loop over subjects
for i, row in subjects.iterrows():
	print('WORKING ON subject {}, session {}'.format(row[0], row[1]))

	iPath =  '/neurospin/grip/external_databases/dHCP_CR_JD_2018/release3/dhcp_anat_pipeline/sub-{}/ses-{}/anat'.format(row.subject_id, row.session_id)
	iT2w = 'sub-{}_ses-{}_desc-restore_T2w.nii.gz'.format(row.subject_id, row.session_id)
	oPath = '/neurospin/grip/external_databases/dHCP_CR_JD_2018/Projects/rel3_dhcp_anat_pipeline_analysis/sub-{}/ses-{}/anat'.format(row.subject_id, row.session_id)
	oT2w_file = 'sub-{}_ses-{}_desc-restore_T2w_RL_flip.nii.gz'.format(row.subject_id, row.session_id)
	
	try:
		in_t2w = aims.read(os.path.join(iPath, iT2w))
		arr_t2w = np.array(in_t2w)
	
		### LPI vs RPI - flipping the array data not necessary if header info is changed
		#arr_t2w = arr_t2w[::-1,:,:,:]

		oT2w = aims.Volume(arr_t2w)
		oT2w.header().update(in_t2w.header())

		### Rewrite header
		sm = in_t2w.header()['storage_to_memory']
		sm2 = np.asarray(sm)
		sm2[0] = sm2[0] * -1
		oT2w.header()['storage_to_memory'] = sm2

		if not os.path.exists(oPath):
    			os.makedirs(oPath)

		if not os.path.exists(os.path.join(oPath, oT2w_file)):
			aims.write(oT2w, os.path.join(oPath, oT2w_file))


		print('FINISHED')

	except IOError:
		print(row[0], row[1], 'DOES NOT HAVE ANAT DATA!')
		pass
print('DONE')



