import os, datetime, subprocess, sys, io
import pandas as pd 
import numpy as np 
from soma import aims


### Date: 29/6/2021
### Author: Andrea Gondova

### script to transform dhcp surfaces to work with AIMS that converts surface parcellations to volumes
### not pretty but works

### COMMENT: PATHS ARE ABSOLUTELY HIDEOUS THIS NEEDS A REWORK!

def get_trm_file(subject_id, session_id):

	t2w = '/neurospin/grip/external_databases/dHCP_CR_JD_2018/release3/dhcp_anat_pipeline/sub-{}/ses-{}/anat/sub-{}_ses-{}_T2w.nii.gz'.format(subject_id, session_id,subject_id, session_id)
	conv_out = '/neurospin/grip/external_databases/dHCP_CR_JD_2018/Projects/rel3_dhcp_anat_pipeline_analysis/sub-{}/ses-{}/anat/sub-{}_ses-{}_T2w.ima'.format(subject_id, session_id, subject_id, session_id)
	
	## first needs converting to older image type to get transform info
	command = subprocess.Popen(['AimsFileConvert',
                             '-i',
                              t2w,
                             '-o',
                              conv_out], shell=False)
	
	command.wait()
	if os.path.isfile(conv_out+'.minf'):
		file = io.open(conv_out+'.minf', 'r', encoding = "ISO-8859-1")
	else:
		print('{} {} info file not created, something is wrong!'.format(subject_id, session_id))
		return
	
	
	for line in file.readlines():
		if 'transformations' in line:
			line = line.strip()
			line = line[line.find('[')+3 : line.find(']')]
			trm =  np.asarray([np.float64(x) for x in line.split(',')]).reshape(4,4)[:-1]
			trm = np.insert(trm[:,:-1], 0, trm[:,-1], 0) 
    	
			to_save = '/neurospin/grip/external_databases/dHCP_CR_JD_2018/Projects/rel3_dhcp_anat_pipeline_analysis/sub-{}/ses-{}/anat/sub-{}_ses-{}.trm'.format(subject_id,session_id, subject_id, session_id)
			np.savetxt(to_save, trm, delimiter=" ", fmt='%1.16f')
            
			if os.path.isfile(to_save):
				print('TRM SAVED')
			else: 
				print('Something went wrong.')
 
	file.close()
	return to_save

def transform_surfaces(subject_id, session_id, path_to_trm):
	
	Rwhite = '/neurospin/grip/external_databases/dHCP_CR_JD_2018/release3/dhcp_anat_pipeline/sub-{}/ses-{}/anat/sub-{}_ses-{}_hemi-right_wm.surf.gii'.format(subject_id, session_id,
			subject_id, session_id)
	Rhemi = '/neurospin/grip/external_databases/dHCP_CR_JD_2018/release3/dhcp_anat_pipeline/sub-{}/ses-{}/anat/sub-{}_ses-{}_hemi-right_pial.surf.gii'.format(subject_id, session_id,
			subject_id, session_id)
	Lwhite = '/neurospin/grip/external_databases/dHCP_CR_JD_2018/release3/dhcp_anat_pipeline/sub-{}/ses-{}/anat/sub-{}_ses-{}_hemi-left_wm.surf.gii'.format(subject_id, session_id,
			subject_id, session_id)
	Lhemi = '/neurospin/grip/external_databases/dHCP_CR_JD_2018/release3/dhcp_anat_pipeline/sub-{}/ses-{}/anat/sub-{}_ses-{}_hemi-left_pial.surf.gii'.format(row.subject_id, row.session_id,
			subject_id, session_id)

	to_save = '/neurospin/grip/external_databases/dHCP_CR_JD_2018/Projects/rel3_dhcp_anat_pipeline_analysis/sub-{}/ses-{}/anat/sub-{}_ses-{}.trm'.format(subject_id,session_id, subject_id, session_id)
	
	surfaces = [Rwhite, Rhemi, Lwhite, Lhemi]
	out_names = [
	'/neurospin/grip/external_databases/dHCP_CR_JD_2018/Projects/rel3_dhcp_anat_pipeline_analysis/sub-{}/ses-{}/anat/sub-{}_ses-{}_T2w_Rwhite_transformed.gii'.format(subject_id,session_id, subject_id, session_id),
	'/neurospin/grip/external_databases/dHCP_CR_JD_2018/Projects/rel3_dhcp_anat_pipeline_analysis/sub-{}/ses-{}/anat/sub-{}_ses-{}_T2w_Rhemi_transformed.gii'.format(subject_id,session_id, subject_id, session_id),
	'/neurospin/grip/external_databases/dHCP_CR_JD_2018/Projects/rel3_dhcp_anat_pipeline_analysis/sub-{}/ses-{}/anat/sub-{}_ses-{}_T2w_Lwhite_transformed.gii'.format(subject_id,session_id, subject_id, session_id),
	'/neurospin/grip/external_databases/dHCP_CR_JD_2018/Projects/rel3_dhcp_anat_pipeline_analysis/sub-{}/ses-{}/anat/sub-{}_ses-{}_T2w_Lhemi_transformed.gii'.format(subject_id,session_id, subject_id, session_id)	
	]
	
	for file, output in zip(surfaces, out_names):
		print('Transforming {} ...'.format(file))
		command = subprocess.Popen(['AimsMeshTransform',
                             '-i',
                              file,
                             '-o',
                             output,
                             '-t',
                            to_save ], shell=False)
		command.wait()
	
	if os.path.isfile(out_names[0]):
		print('{} {} DONE'.format(subject_id, session_id))
		return True
	else:
		print('Transformation did not work! INVESTIGATE')
		return False

def mesh2vol(subject_id, session_id):
	oDir = '/neurospin/grip/external_databases/dHCP_CR_JD_2018/Projects/rel3_dhcp_anat_pipeline_analysis/sub-{}/ses-{}/anat/'.format(subject_id, session_id)
	#check how the ribbon relates to the t2w flipped! but with the surfaces it should be ok!
	iRib = '/neurospin/grip/external_databases/dHCP_CR_JD_2018/release3/dhcp_anat_pipeline/sub-{}/ses-{}/anat/sub-{}_ses-{}_desc-ribbon_dseg.nii.gz'.format(subject_id, row.session_id,row.subject_id, session_id)
	
	print('***\nSURF2VOL\n***')
	for hemi, hemi_lab in zip(['l', 'r'], ['L', 'R']):
		if hemi == 'l':
			label = str(3)
		elif hemi == 'r': 
			label = str(42)
		print('Hemishere: ', hemi_lab)

		iParc = os.path.join(oDir, 'sub-{}_ses-{}_{}h.DKT.label.gii'.format(subject_id, session_id, hemi))
		iSurf = os.path.join(oDir, 'sub-{}_ses-{}_T2w_{}hemi_transformed.gii'.format(subject_id, session_id, hemi_lab))
		oVol = os.path.join(oDir, 'sub-{}_ses-{}_{}hemi.DKT.{}label.volume.nii.gz'.format(subject_id, session_id, hemi, label))
		print('CONVERTING subject {}; hemisphere: {}, DKT'.format(row.subject_id, hemi))
		command = subprocess.Popen(['AimsTex2Vol','-i',iRib, '-g', label,'-o', oVol, '-t', iParc, '-m', iSurf], shell=False)
		command.wait()

		if os.path.isfile(oVol):	
			print('SURF2VOL finished: subject {}; hemisphere: {}, DKT'.format(row.subject_id, hemi))
	
	print('SUBJECT {} ses {} DONE'.format(row.subject_id, row.session_id)) 
	

def combined_hemispheres(subject_id, session_id):
	print('Combining hemispheres...')

	oDir = '/neurospin/grip/external_databases/dHCP_CR_JD_2018/Projects/rel3_dhcp_anat_pipeline_analysis/sub-{}/ses-{}/anat/'.format(subject_id, session_id)
	iLh = os.path.join(oDir, 'sub-{}_ses-{}_lhemi.DKT.3label.volume.nii.gz'.format(subject_id, session_id))
	iRh = os.path.join(oDir, 'sub-{}_ses-{}_rhemi.DKT.42label.volume.nii.gz'.format(subject_id, session_id))
	oVol = os.path.join(oDir, 'sub-{}_ses-{}.combined.DKT.volume.nii.gz'.format(subject_id, session_id))
	
	## Left hemi to array
	Lh_vol = aims.read(iLh)
	Lh_vol_in = np.array(Lh_vol.arraydata(), dtype=int)
	# to solve label being the same in Lh and Rh
	Lh_vol_in = np.where(Lh_vol_in == 0, Lh_vol_in, Lh_vol_in+100)
	Lh_vol_in[Lh_vol_in == 0] = 1

	## Right hemi to array
	Rh_vol = aims.read(iRh)
	Rh_vol_in = np.array(Rh_vol.arraydata(), dtype=int)
	## to solve label being the same in Lh and Rh
	Rh_vol_in = np.where(Rh_vol_in == 0, Rh_vol_in, Rh_vol_in+200)
	Rh_vol_in[Rh_vol_in == 0] = 1
	
	## merge & relabel
	merged_vol = Lh_vol_in * Rh_vol_in
	merged_vol[merged_vol==1] = 0
	merged_vol = merged_vol.astype(np.int16)

	#merged_vol = np.array(merged_vol, order='F')
	merged = aims.Volume(merged_vol)
	merged.header().update(Lh_vol.header())

	aims.write(merged, oVol)
	
	if os.path.isfile(oVol):
		print('Parcellations merged')
		print('***\n***\n***\n')

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
		
		print('WORKING ON SUBJECT {}, ID {}'.format(subject_id, session_id))
		# transform surfaces
		path_to_trm = get_trm_file(subject_id, session_id)
		## this is strange!
		if path_to_trm is not None:
			transform = transform_surfaces(subject_id, session_id, path_to_trm)

		if transform is True:
			mesh2vol(subject_id, session_id)
			combined_hemispheres(subject_id, session_id)
			
		
	print('END at: {}'.format(datetime.datetime.now()))	






	


	
	


