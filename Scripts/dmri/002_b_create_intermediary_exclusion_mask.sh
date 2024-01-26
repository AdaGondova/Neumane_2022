#!/bin/bash

### create 3 different initial EXCLUSION mask settings 

subject=$1
session=$2
DHCPPREFIX=sub-${subject}_ses-${session}

echo WORKING ON EXCLUSION MASKS ${subject} ${session}

### temporary directory for masks 
repDWIall_shard=/neurospin/grip/external_databases/dHCP_CR_JD_2018/Projects/rel3_dhcp_dmri_shard_pipeline_analysis
mkdir -p ${repDWIall_shard}/tmp

#== create global CSF mask ==============================================================================
# create global CSF mask: based on MD (this might be a problem for preterms session1 ) & FA threshold (mask_tracto_probtrackx_longiR3.sh)
# CSF mask based on MD threshold >= 0.002 $ FD threshold > 0.25; requires MD and FD b=1000 maps from DTI
# requires MD and FD b=1000 maps from DTI
#========================================================================================================

inMD=/neurospin/grip/external_databases/dHCP_CR_JD_2018/release3/dhcp_dmri_shard_pipeline/sub-${subject}/ses-${session}/dwi/DTI/dtifit_b1000/${DHCPPREFIX}_MD.nii.gz
inFA=/neurospin/grip/external_databases/dHCP_CR_JD_2018/release3/dhcp_dmri_shard_pipeline/sub-${subject}/ses-${session}/dwi/DTI/dtifit_b1000/${DHCPPREFIX}_FA.nii.gz


oCSF=${repDWIall_shard}/tmp/${DHCPPREFIX}_CSFmask.nii.gz

AimsThreshold -i ${inMD} -o ${repDWIall_shard}/tmp/${DHCPPREFIX}_MDmask.nii.gz -m gt -t 0.002 -b
AimsThreshold -i ${inFA} -o ${repDWIall_shard}/tmp/${DHCPPREFIX}_FAmask.nii.gz -m gt -t 0.25 -b
AimsMask -i ${repDWIall_shard}/tmp/${DHCPPREFIX}_MDmask.nii.gz -o ${oCSF} -m ${repDWIall_shard}/tmp/${DHCPPREFIX}_FAmask.nii.gz --inv

echo CSF DONE

#== create global cortical mask =========================================================================
# based on ribbon segmentation - needs to be registered to dmri
#========================================================================================================

inRIBBON=/neurospin/grip/external_databases/dHCP_CR_JD_2018/Projects/rel3_dhcp_dmri_shard_pipeline_analysis/sub-${subject}/ses-${session}/${DHCPPREFIX}_desc-ribbon_dseg_shardDMRI_space.nii.gz
oCORTEX=${repDWIall_shard}/tmp/${DHCPPREFIX}_CRXmask.nii.gz
#LGM = 3
#RGM = 42 
### the u flag does not work needs a rewrite and combination

AimsThreshold -i ${inRIBBON} -o ${repDWIall_shard}/tmp/${DHCPPREFIX}_CRXmask_partial1.nii.gz -m eq -t 3 -b
AimsThreshold -i ${inRIBBON} -o ${repDWIall_shard}/tmp/${DHCPPREFIX}_CRXmask_partial2.nii.gz -m eq -t 42 -b
cartoLinearComb.py -i ${repDWIall_shard}/tmp/${DHCPPREFIX}_CRXmask_partial1.nii.gz -i ${repDWIall_shard}/tmp/${DHCPPREFIX}_CRXmask_partial2.nii.gz -f 'I1+I2' -o ${oCORTEX}
## mask by FA > 0.25
AimsMask -i ${oCORTEX} -o ${oCORTEX} -m ${repDWIall_shard}/tmp/${DHCPPREFIX}_FAmask.nii.gz --inv

echo CRX DONE

#== create global subcortical mask ======================================================================
# NEEDS TO BE TESTED
#========================================================================================================
iPARC=${repDWIall_shard}/sub-${subject}/ses-${session}/${DHCPPREFIX}.combined.DKT-DRAWEM.volume.shardDMRI.space.nii.gz
oSBCX=${repDWIall_shard}/tmp/${DHCPPREFIX}_SBXmask.nii.gz


#hashmap["CaudLshMask"]="41" ### I am removing this manually to initiate the mask
declare -A hashmap
hashmap["CaudRshMask"]="40"
hashmap["LentiLshMask"]="47"
hashmap["LentiRshMask"]="46"
hashmap["SubthalLshMask"]="45"
hashmap["SubthalRshMask"]="44"
hashmap["ThalHiLshMask"]="43"
hashmap["ThalHiRshMask"]="42"
hashmap["ThalLiLshMask"]="87"
hashmap["ThalLiRshMask"]="86"
hashmap["HpcLshMask"]="1"
hashmap["HpcRshMask"]="2"
hashmap["AmgLshMask"]="3"
hashmap["AmgRshMask"]="4"
#hashmap["CCshMask"]="48" ### this should reman included for all? or excluded for other than inter-hemispheric


AimsThreshold -i ${iPARC} -o ${oSBCX} -m eq -t 41 -b
oPartial=${repDWIall_shard}/tmp/${DHCPPREFIX}_sub_parts.nii.gz

for key in ${!hashmap[@]}
do 
	echo Removing subcorticals with call ${key}
	AimsThreshold -i ${iPARC} -o ${oPartial} -m eq -t "${hashmap[${key}]}" -b
	cartoLinearComb.py -i ${oSBCX} -i ${oPartial} -f 'I1+I2' -o ${oSBCX}	
done

## mask by FA > 0.25
echo Masking subcorticals with FA
AimsMask -i ${oSBCX} -o ${oSBCX} -m ${repDWIall_shard}/tmp/${DHCPPREFIX}_FAmask.nii.gz --inv

# loop over cerebellum & brainstem, we do not want to have them thresholded with FA
declare -A others
others["BrainstemshMask"]="19"
others["CblLshMask"]="17"
others["CblRshMask"]="18"

for key in ${!others[@]}
do 
	echo Removing subcorticals with call ${key}
	AimsThreshold -i ${iPARC} -o ${oPartial} -m eq -t "${others[${key}]}" -b
	cartoLinearComb.py -i ${oSBCX} -i ${oPartial} -f 'I1+I2' -o ${oSBCX}	
done

echo SBX DONE

#== create global hemispheres mask ======================================================================
#LGM = 3, LWM = 2
#RGM = 42, RWM = 41
#========================================================================================================
 
oL=${repDWIall_shard}/tmp/${DHCPPREFIX}_Lmask.nii.gz
oR=${repDWIall_shard}/tmp/${DHCPPREFIX}_Rmask.nii.gz

### the u flag does not work needs a rewrite and combination

AimsThreshold -i ${inRIBBON} -o ${repDWIall_shard}/tmp/${DHCPPREFIX}_hemi_mask_partial1.nii.gz -m eq -t 2 -b
AimsThreshold -i ${inRIBBON} -o ${repDWIall_shard}/tmp/${DHCPPREFIX}_hemi_mask_partial2.nii.gz -m eq -t 41 -b

cartoLinearComb.py -i ${repDWIall_shard}/tmp/${DHCPPREFIX}_CRXmask_partial1.nii.gz -i ${repDWIall_shard}/tmp/${DHCPPREFIX}_hemi_mask_partial1.nii.gz -f 'I1+I2' -o ${oL}
cartoLinearComb.py -i ${repDWIall_shard}/tmp/${DHCPPREFIX}_CRXmask_partial2.nii.gz -i ${repDWIall_shard}/tmp/${DHCPPREFIX}_hemi_mask_partial2.nii.gz -f 'I1+I2' -o ${oR}

echo HEMI DONE

#== create CC mask ======================================================================
#
#========================================================================================================

#hashmap["CCshMask"]="48" ### this should reman included for all? or excluded for other than inter-hemispheric

oCC=${repDWIall_shard}/tmp/${DHCPPREFIX}_CC.nii.gz
AimsThreshold -i ${iPARC} -o ${oCC} -m eq -t 48 -b


################################## FINALEXCLUSION MASK CREATION ##################################################

#== setting 1: Inter-hemispheric cortical regions ======================================================
# 1. CSF mask: based on MD (this might be a problem for preterms session1 )& FA threshold (mask_tracto_probtrackx_longiR3.sh)
# 2. Removing un-dilated cortical structures other than the 2 regions 
# 3. Remove subcortical structures (+ all the other ones not in the subset – check that no structure is overlapping the corpus callosum – label 48 – make sure it’s not in the exclusion mask, subtract from the mask to make sure it’s in) 
#=======================================================================================================

oFirst=${repDWIall_shard}/tmp/${DHCPPREFIX}_1setting.nii.gz
cartoLinearComb.py -i ${oCSF} -i ${oCORTEX} -i ${oSBCX} -f 'I1+I2+I3' -o ${oFirst}

#to make sure CC is gone 
AimsMask -i ${oFirst} -o ${oFirst} -m ${oCC} --inv


#== setting 2: Intra-hemispheric cortical regions LEFT (remove right hemi mask)=========================
# 1. CSF mask: based on MD & FA threshold 
# 2. Remove the opposite hemisphere (GM & WM) 
# 3. Remove non-dilated cortical from the same hemisphere other than the 2 regions 
# 4. Remove subcortical GM structures (additional CC step not required)
#=======================================================================================================
 
oSecond=${repDWIall_shard}/tmp/${DHCPPREFIX}_2setting.nii.gz

AimsMask -i ${oFirst} -o ${oSecond} -m ${oR} --inv
cartoLinearComb.py -i ${oSecond} -i ${oR} -f 'I1+I2' -o ${oSecond}

#to make sure CC is gone 
AimsMask -i ${oSecond} -o ${oSecond} -m ${oCC} --inv

## this step is unnecessary, CC is now not in the subcortical mask
#remove CC 
#oCC=${repDWIall_shard}/tmp/${DHCPPREFIX}_CCmask.nii.gz
#AimsThreshold -i ${iParc} -o ${oCC} -m eq -t 48 -b
#cartoLinearComb.py -i ${oSecond} -i ${oCC}  -f 'I1-I2' -o ${oSecond}

#== setting 3: Intra-hemispheric cortical regions RIGHT (remove left mask)=============================

oThird=${repDWIall_shard}/tmp/${DHCPPREFIX}_3setting.nii.gz
AimsMask -i ${oFirst} -o ${oThird} -m ${oL} --inv
cartoLinearComb.py -i ${oThird} -i ${oL} -f 'I1+I2' -o ${oThird}

#to make sure CC is gone 
AimsMask -i ${oThird} -o ${oThird} -m ${oCC} --inv

#== setting 4: Ipsi-cortico-subcortical LEFT (remove R hemi) =========================================================== 
# 1. CSF mask: based on MD & FA threshold 
# 2. Remove the opposite hemisphere (GM & WM)  
# 3. Remove non-dilated cortical regions from the same hemisphere other than the seed region 
# 4. Remove subcortical GM other than the seed 
#=======================================================================================================

#### this affect the brain stem little bit where the hemi mask is not perfect, make sure to substract it! this is done when brainstem is in the pair so it's OK
#### this is the same as setting 2 but additionaly remove brainstem from exclusion mask (this will be dealt with when the pipeline is being run)

#== setting 5: Ipsi-cortico-subcortical RIGHT ================================================================  





