clear;clc;
subids = {'7349'};
subpath = '/media/pfaffenrot/My Passport1/pain_layers/main_project/derivatives/pipeline';

for subid = subids
    %create compcor mask
    mask = VPF_compcor_mask_creation_pain(subid{:},subpath);

    rundir = dir([subpath '/' subid{:} '/ses-02/func/layers/run*']);
    runs = length(rundir);

    % load the data into memory. To save space, mask and vectorize them
    structpath = [subpath '/' subid{:} '/ses-01/anat/presurf_MPRAGEise/presurf_UNI'];
    WM_mask = load_nifti([structpath '/UNI_MoCo_MPRAGEised_class2.nii']).vol;
    WM_mask = WM_mask>0.9;

    mask = mask(WM_mask);
    for run = 1:runs
        data = dir([rundir(run).folder '/' rundir(run).name '/func/*Warped-to-Anat*']);
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
        confounds = importdata([data(1).folder '/mag_POCS_r' num2str(run) '_MoCorr.txt']);
        %call fmri_compcor, specify mask and extract 5 principle components
        X = fmri_compcor(img,{mask},5,'confounds',confounds);

        writematrix(X,[rundir(run).folder '/' rundir(run).name '/func/compcor_regressors_r' num2str(run) '.txt'],'Delimiter',' ')

    end
end
