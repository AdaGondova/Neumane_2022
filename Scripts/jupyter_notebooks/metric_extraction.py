import pandas as pd 
import numpy as np 
#from soma import aims
import matplotlib.pyplot as plt
import os

from scipy.signal import find_peaks

## NOISE REMOVAL 
#from skimage.filters.rank import median 
from scipy.ndimage import median_filter, gaussian_filter, generic_filter
from skimage.morphology import disk, ball, cube
from scipy.stats import trim_mean

def get_tract_label(folder_name):
    label = folder_name.split('2x2_')[-1]
    label = label.split('Mask')
    label = label[0] + label[1] 
    label = label.replace('sh', '')
    return label

def extract_bundle_metric(tract, metric_map):
    
    # remove metric 0 voxels from both arrays   
    tract[np.where(metric_map == 0)] = 0

    # remove tracts 0 voxels from both arrays
    metric_map = metric_map[np.where(tract != 0)]
    tract = tract[np.where(tract != 0)]

    # sanity check 
    if len(metric_map) == len(tract):
        return np.sum(np.multiply(metric_map, tract))/np.sum(tract)
    
    else: 
        print('tract and metric map do not match')
        return np.nan
    
def read_in_DTI_metric_map(subject_id, session_id, metric):
    
    iDir = '/neurospin/grip/external_databases/dHCP_CR_JD_2018/release3/dhcp_dmri_shard_pipeline/sub-{}/ses-{}/dwi/'.format(
                        subject_id, session_id)
    
    if metric == 'FA':
        iPath = os.path.join(iDir, 'DTI/dtifit_b1000/sub-{}_ses-{}_{}.nii.gz'.format(
                                    subject_id, session_id, metric)) 
        metric_map = aims.read(iPath).arraydata()[0]
    
        
    if metric == 'AD':
        iPath = os.path.join(iDir, 'DTI/dtifit_b1000/sub-{}_ses-{}_L1.nii.gz'.format(
                                    subject_id, session_id)) 
        metric_map = aims.read(iPath).arraydata()[0]
        
    elif metric == 'RD':
        iPath2 = os.path.join(iDir, 'DTI/dtifit_b1000/sub-{}_ses-{}_L2.nii.gz'.format(
                                    subject_id, session_id)) 
        iPath3 = os.path.join(iDir, 'DTI/dtifit_b1000/sub-{}_ses-{}_L3.nii.gz'.format(
                                    subject_id, session_id)) 
        a2 = aims.read(iPath2).arraydata()[0]
        a3 = aims.read(iPath3).arraydata()[0]
        
        metric_map = (a2 + a3)/2
        
    elif metric == 'MD':
        iPath1 = os.path.join(iDir, 'DTI/dtifit_b1000/sub-{}_ses-{}_L1.nii.gz'.format(
                                    subject_id, session_id))
        iPath2 = os.path.join(iDir, 'DTI/dtifit_b1000/sub-{}_ses-{}_L2.nii.gz'.format(
                                    subject_id, session_id)) 
        iPath3 = os.path.join(iDir, 'DTI/dtifit_b1000/sub-{}_ses-{}_L3.nii.gz'.format(
                                    subject_id, session_id)) 
        
        a1 = aims.read(iPath1).arraydata()[0]
        a2 = aims.read(iPath2).arraydata()[0]
        a3 = aims.read(iPath3).arraydata()[0]
        
        metric_map =( a1 + a2 + a3)/3
    return metric_map
        
def clean_tracts(tract, threshold):
    limit = np.round(np.max(tract.ravel())*threshold,2)
    tract[tract < limit] = 0
    
    return tract
    

def read_in_NODDI_metric_map(subject_id, session_id, metric):
    
    if metric == 'ODI':
        metric = 'OD'
        
    else:
        metric = 'mean_fintra'

    iDir = '/neurospin/grip/external_databases/dHCP_CR_JD_2018/release3/dhcp_dmri_shard_pipeline/sub-{}/ses-{}/dwi/'.format(
                        subject_id, session_id)
    
    

    iPath = os.path.join(iDir, 'NODDI/{}.nii'.format( metric))
    
    return aims.read(iPath).arraydata()[0]
    
    
### NODDI cleaning
def get_groove(metric_map):
    his, bin_edges = np.histogram(metric_map.ravel(), bins=np.arange(0.01,1.01,0.01))
    peaks, _ = find_peaks(his*-1, distance=25)
    first_peak = round(bin_edges[peaks[0]],3)
    
    return first_peak

def calculate_corrected_number(y, first_peak):
    inp = y.copy()
    middleIdx = int(len(inp)/2)
    
    if (0 < inp[middleIdx] < first_peak) or (inp[middleIdx] > 0.95):
        inp.sort()
        inp = inp[(inp >= first_peak) & (inp < 0.95)]
        
        if len(inp) <= 1:
            return 2000

        elif 1 < len(inp) < 3:
            return 1000
        
        else: 
            idx = int(len(inp)/2)
            return 1000
            #return np.mean(inp)
    else: 
        return inp[middleIdx]
    
def alpha_trim_only_outside_range(y, first_peak):
    inp = y.copy()
    middleIdx = int(len(inp)/2)
    
    if (0< inp[middleIdx] < first_peak) or (inp[middleIdx] > 0.95):
        inp.sort()
        inp = inp[(inp >= first_peak) & (inp < 0.95)]
        
        if len(inp) <= 1:
            return np.nan
    
        elif 1 < len(inp) < 3:
            return np.mean(inp)
        
        else: 
            idx = int(len(inp)/2)
            return np.mean(inp[idx-1:idx+2])
            #return np.mean(inp)
    else: 
        return inp[middleIdx]
    
def denoise_NDI(NDI_image, arg):
    im_NDI = NDI_image.copy()
    #new_NDI = NDI_image.copy()
    for i in range(len(arg[0])):
        idx = (arg[0][i], arg[1][i], arg[2][i])
        #print(im_NDI[idx])
        if im_NDI[idx] > 0:
        
    
            cube = im_NDI[idx[0]-1:idx[0]+2,idx[1]-1:idx[1]+2,idx[2]-1:idx[2]+2 ]
            inp = cube.ravel()
            middleIdx = int(len(inp)/2)
            inp.sort()
            if len(inp[middleIdx-1:middleIdx+2]) == 3:
                im_NDI[idx] = np.mean(inp[middleIdx-1:middleIdx+2])
            else:
                im_NDI[idx] = im_NDI[idx] 
            #new_NDI[idx] = np.mean(inp[1:-1])
    
            #print(np.mean(inp[middleIdx-1:middleIdx+2]))
            #print(np.mean(inp[1:-1]))
            #print(inp)
    
        #else: 
         #   new_NDI[idx] = im_NDI[idx]
            #print(im_NDI[idx])
        
    return im_NDI

def clean_NODDI(ODI_vol, NDI_vol):
    
    # get peak 
    first_peak = get_groove(ODI_vol)
    #get cleaning ODI indices
    denoised = generic_filter(ODI_vol, calculate_corrected_number, size=2, extra_arguments=(first_peak,))
    
    ### Correct ODI
    denoised_ODI = generic_filter(ODI_vol, alpha_trim_only_outside_range, size=2, extra_arguments=(first_peak,))
    denoised_ODI[ np.isnan(denoised_ODI)] = 0
    
    ### Correct NDI
    
    arg = np.where(denoised == 1000)
    #print(np.shape(arg[0]))
    denoised_NDI = denoise_NDI(NDI_image = NDI_vol, arg = arg)
    
    #denoised_NDI_turned_off = denoised_NDI.copy()
    #denoised_NDI_turned_off[np.where(denoised == 2000)] = 0
    denoised_NDI[np.where(denoised == 2000)] = 0
    
    return denoised_ODI, denoised_NDI
    
    
#controls = pd.read_csv('../../DerivedData/control_group_list.csv', header=None)
preterms = pd.read_csv('../../DerivedData/preterm_group_list.csv', header=None)

df_DTI = pd.DataFrame()
for i, row in preterms.iterrows():
    print(row[0])
    #df_subj = pd.DataFrame()
    iDir = '/neurospin/grip/external_databases/dHCP_CR_JD_2018/release3/dhcp_dmri_shard_pipeline/sub-{}/ses-{}/dwi/probtrakX_results'.format(
                    row[0], row[1])
    # ceck that the diffusion directory exists 
    if os.path.isdir(iDir):
        # DTI
        for metric in ['FA', 'AD', 'RD', 'MD']:
        
            metric_map = read_in_DTI_metric_map(subject_id=row[0], session_id=row[1], metric=metric)

            folders = [folder for folder in os.listdir(iDir) if 'ROIbyROI' in folder]
            for folder in folders:
                label = get_tract_label(folder)
                #print(label)
        
                iTract = aims.read(os.path.join(iDir, folder, 'fdt_paths.nii.gz'))
                tract = iTract.arraydata()[0]
        
                ### needs tract cleaning here, unless inter-hemispheric, the cleaning thresholds is 5 %
                if label not in ['S1L-S1R', 'M1L-M1R', 'ParacentralL-ParacentralR' ]:
                    tract = clean_tracts(tract=tract, threshold=0.05)
            
                metric_value = extract_bundle_metric(metric_map=metric_map, tract=tract)
            
                #print(row[0], label, metric, metric_value)
            
                df_DTI.loc[i, 'subject_id'] = row[0]
                df_DTI.loc[i, 'session_id'] = int(row[1])
                df_DTI.loc[i, label+'_'+metric] = metric_value
            
        # NODDI 
        ### pre-cleaning 
        for metric in ['NDI', 'ODI']:
            metric_map = read_in_NODDI_metric_map(subject_id=row[0], session_id=row[1], metric = metric)
        
    
            folders = [folder for folder in os.listdir(iDir) if 'ROIbyROI' in folder]
            for folder in folders:
                label = get_tract_label(folder)
                #print(label)
        
                iTract = aims.read(os.path.join(iDir, folder, 'fdt_paths.nii.gz'))
                tract = iTract.arraydata()[0]
        
                ### needs tract cleaning here, unless inter-hemispheric, the cleaning thresholds is 5 %
                if label not in ['S1L-S1R', 'M1L-M1R', 'ParacentralL-ParacentralR' ]:
                    tract = clean_tracts(tract=tract, threshold=0.05)
            
                metric_value = extract_bundle_metric(metric_map=metric_map, tract=tract)
            
                    #print(row[0], label, metric, metric_value)
                
                df_DTI.loc[i, 'subject_id'] = row[0]
                df_DTI.loc[i, 'session_id'] = int(row[1])
                df_DTI.loc[i, label+'_'+metric+'_pre'] = metric_value
        
    
        ## after cleaning 
        ODI_map = read_in_NODDI_metric_map(subject_id=row[0], session_id=row[1], metric = 'ODI')
        NDI_map = read_in_NODDI_metric_map(subject_id=row[0], session_id=row[1], metric = 'NDI')
    
        ODI_map, NDI_map = clean_NODDI(ODI_vol= ODI_map, NDI_vol=NDI_map)
        folders = [folder for folder in os.listdir(iDir) if 'ROIbyROI' in folder]
        for folder in folders:
            label = get_tract_label(folder)
            #print(label)
        
            iTract = aims.read(os.path.join(iDir, folder, 'fdt_paths.nii.gz'))
            tract = iTract.arraydata()[0]
        
            ### needs tract cleaning here, unless inter-hemispheric, the cleaning thresholds is 5 %
            if label not in ['S1L-S1R', 'M1L-M1R', 'ParacentralL-ParacentralR' ]:
                tract = clean_tracts(tract=tract, threshold=0.05)
            
            metric_value_ODI = extract_bundle_metric(metric_map=ODI_map, tract=tract)
        
            #print(label, np.sum(NDI_map))
            metric_value_NDI = extract_bundle_metric(metric_map=NDI_map, tract=tract)

            
                    #print(row[0], label, metric, metric_value)
            
            df_DTI.loc[i, 'subject_id'] = row[0]
            df_DTI.loc[i, 'session_id'] = int(row[1])
            df_DTI.loc[i, label+'_ODI_post'] = metric_value_ODI
            df_DTI.loc[i, label+'_NDI_post'] = metric_value_NDI
    
    
df_DTI['session_id'] = df_DTI['session_id'].astype(int)

df_DTI.to_csv('../../DerivedData/extracted_diffusion_metrics_preterm_group.csv')
