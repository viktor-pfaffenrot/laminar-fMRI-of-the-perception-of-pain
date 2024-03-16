function VPF_compcor_pain(inppath,structpath)

subpath = extractBefore(structpath,'/ses-');
ru = extractBefore(inppath,'_split');
ru = ru(end);

if exist([inppath '/compcor_regressors_r' ru '.txt'],'file')~=0
    return
end

% load the data into memory. To save space, mask and vectorize them
WM_mask = load_nifti([structpath '/UNI_MoCo_MPRAGEised_class2.nii']).vol;
WM_mask = WM_mask>0.9;

mask = load_nifti([subpath '/ses-02/func/post_calib/rwls_stats/compcor_mask.nii.gz']).vol;
mask = logical(mask(WM_mask));

data = dir([inppath '/*Warped-to-Anat*']);
vols = length(data);

for vol = 1:vols
    hdr = load_nifti([data(vol).folder '/' data(vol).name]);
    if vol == 1
        tmp = hdr.vol(WM_mask);
        img = zeros(length(tmp),vols);
        img(:,vol) = tmp;

    else
        img(:,vol) = hdr.vol(WM_mask);
    end
end
%add in motion parameters as confounds. compcor will orthogonalize the regressors
%wrt the confounds such that in the final GLM, compcor + motion regressors will
%be more predictive
confounds = dir([inppath '/*MoCorr.txt']);
confounds = importdata([confounds.folder '/' confounds.name]);
%call fmri_compcor, specify mask and extract 5 principle components
X = fmri_compcor(img,{mask},5,'confounds',confounds);

writematrix(X,[inppath '/compcor_regressors_r' ru '.txt'],'Delimiter',' ')

end