import pandas as pd 
import numpy as np
import random, maths

'''
Initial script for control-preterm matching on sex and scan at age. Should be adapted to incorporate condition that
the neurodevelopmental outcome should be available. 

??? this is matching all preterms (radiology score <= 3) with longitudinal data (second session). 
??? Should I use the list with subjects with shard available instead?
'''

path_to_release3 = '/neurospin/grip/external_databases/dHCP_CR_JD_2018/Projects/Neumane_2022/SourceData/release3_subject_info.tsv'
path_to_longitudinal = '/neurospin/grip/external_databases/dHCP_CR_JD_2018/Projects/Neumane_2022/SourceData/longitudinal_subjects_2nd_session.csv'


### read in the subject info sets 
### release3 
df = pd.read_csv(path_to_release3, sep = '\t')
### longitudinal 
preterm_2nd = pd.read_csv(path_to_longitudinal, header=None)

## need to strip the blank space at the end of subject ids
df['participant_id '] = df['participant_id '].str.strip()
## get preterm , 2nd session table
sess_id = np.array([session.split('-')[-1] for session in preterm_2nd[1].values])
preterm_df = df[ (df['participant_id '].isin(preterm_2nd[0].values)) &  (df['session_id '].isin(sess_id))]
preterm_df = preterm_df[preterm_df['radiology_score '] <= 3]
### controls 
controls = df[ ~ df['participant_id '].isin(preterm_2nd[0].values)]

print('Number of preterms with radiological score <= 3: ', len(preterm_df))
print('Number of controls for matching: ', len(controls))


def find_nearest(array,value):
    idx = np.searchsorted(array, value, side="left")
    if idx > 0 and (idx == len(array) or math.fabs(value - array[idx-1]) < math.fabs(value - array[idx])):
        #return array[idx-1]
        return idx-1
    else:
        #return array[idx]
        return idx


num = 0
out_match = pd.DataFrame(columns = ['preterm_ID', 'preterm_session','preterm_sex', 'preterm_scan_age', 
                                    'matched_ID', 'matched_session', 'matched_sex', 'matched_scan_age' ])
for sex in ['female ', 'male ']:
    

    fem_prema = preterm_df[preterm_df['sex '] == sex][['participant_id ', 'scan_age ', 'session_id ']]
    fem_control = controls[controls['sex '] == sex][['participant_id ', 'scan_age ', 'session_id ']]
    
    fem_prema.sort_values(by = ['scan_age '], inplace=True)
    fem_prema = fem_prema.reset_index()
    fem_control.sort_values(by = ['scan_age '], inplace=True)
    fem_control= fem_control.reset_index()
    
    
    for i, row in fem_prema.iterrows():
        age_arr = fem_control['scan_age '].values
        idx =  find_nearest(age_arr, row['scan_age '])
        out_match.loc[num] = [row['participant_id '],  row['session_id '], sex, row['scan_age '],
            fem_control.iloc[idx]['participant_id '], fem_control.iloc[idx]['session_id '], 
                           sex, fem_control.iloc[idx]['scan_age ']]
              
        age_arr[idx] = 0
        num += 1

out_match.to_csv('/neurospin/grip/external_databases/dHCP_CR_JD_2018/Projects/Neumane_2022/DerivedData/preterm_control_subjects_sex_scanage_match.csv')


