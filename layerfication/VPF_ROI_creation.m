function [] = VPF_ROI_creation(subid,pipe_path,fs_path)

WM_path = [pipe_path '/' subid '/ses-02/func/WM_localizer/rwls_stats'];

%if the post calibration does not show anything reasonable, try using pain_calib
pain_path = [pipe_path '/' subid '/ses-02/func/post_calib/rwls_stats'];

fs_path = [fs_path '/' subid '/mri'];

%used for working memory localizer
aparc     = [fs_path '/aparc+aseg.mgz'];
[~,~,aparc_ext] = fileparts(aparc);

%used for pain localizer
aparc2009 =  [fs_path '/aparc.a2009s+aseg.mgz'];

% thresholding (t>1)
t_thres = 1;
%% transform atlases into native subject space and from .mgz to .nii.gz
fs_base = ['export FREESURFER_HOME=/usr/local/freesurfer/6.0.0; ' ...
    'export SUBJECTS_DIR=' fs_path '; '...
    'source $FREESURFER_HOME/SetUpFreeSurfer.sh; '];

%aparc
cmd = ['mri_label2vol --seg ' '"' aparc '"' ' --temp ' '"' fs_path '/rawavg.mgz" --o '...
    '"' fs_path '/aparc' aparc_ext '"' ' --regheader ' '"' fs_path '/aseg.mgz"'];
system([fs_base cmd]);

cmd = ['mri_convert ' '"' fs_path '/aparc.mgz" ' '"' fs_path '/aparc.nii.gz"'];
system([fs_base cmd]);
aparc = [fs_path  '/aparc.nii.gz'];

%aparc2009
cmd = ['mri_label2vol --seg ' '"' aparc2009 '"' ' --temp ' '"' fs_path '/rawavg.mgz" --o '...
    '"' fs_path '/aparc2009' aparc_ext '"' ' --regheader ' '"' fs_path '/aseg.mgz"'];
system([fs_base cmd]);

cmd = ['mri_convert ' '"' fs_path '/aparc2009.mgz" ' '"' fs_path '/aparc2009.nii.gz"'];
system([fs_base cmd]);
aparc2009 = [fs_path '/aparc2009.nii.gz'];


%% working memory localizer
%load smoothed t-map
if ~isfile([WM_path '/sspmT_0001.nii'])
    spm_smooth([WM_path '/spmT_0001.nii'],[WM_path '/sspmT_0001.nii'],[4.5 4.5 4.5]);
end
WM_localizer_t_hdr = load_nifti([WM_path '/sspmT_0001.nii']);
WM_localizer_t = WM_localizer_t_hdr.vol;

% intersect with anatomical masks coming from Freesurfer's aparc atlas (fist number = left hemisphere, 2nd = right)
ROI_idx = {1003,2003;1008,2008;1024,2024;1027,2027;1028,2028;1028,2028;1029,2029};
atlas = load_nifti(aparc).vol;

ROIs = size(ROI_idx,1);
for ROI = 1:ROIs
    tmp = zeros(size(WM_localizer_t));
    tmp(atlas==ROI_idx{ROI,1}) = WM_localizer_t(atlas==ROI_idx{ROI,1});
    tmp(atlas==ROI_idx{ROI,2}) = WM_localizer_t(atlas==ROI_idx{ROI,2});

    for ii = [1,-1] %threshold positive and negative t-values seperately
        mask = zeros(size(WM_localizer_t),'logical');
        if ii == 1
            mask(tmp>t_thres) = true;
        else
            mask(tmp<-t_thres) = true;
        end

        WM_localizer_t_hdr.vol = mask;
        tmp_name = num2str(ROI_idx{ROI,1});
        if ii == 1
            outname = [WM_path '/WM_localizer_ROI' tmp_name(2:end) '_pos.nii'];
        else
            outname = [WM_path '/WM_localizer_ROI' tmp_name(2:end) '_neg.nii'];
        end
        save_nifti(WM_localizer_t_hdr,outname);
    end
end

%% pain localizer
%load smoothed t-map
if ~isfile([pain_path '/sspmT_0001.nii'])
    spm_smooth([pain_path '/spmT_0001.nii'],[pain_path '/sspmT_0001.nii'],[4.5 4.5 4.5]);
end
pain_localizer_t_hdr = load_nifti([pain_path '/sspmT_0001.nii']);
pain_localizer_t = pain_localizer_t_hdr.vol;

% intersect with anatomical masks coming from Freesurfer's aparc2009 atlas
%the last 4 ROIs will be merged into 2 ROIs
ROI_idx = {11104,12104;11106,12106;11107,12107;11128,12128;11168,12168;...
    11117,12117;11149,12149;...
    11118,12118;11150,12150};

atlas = load_nifti(aparc2009).vol;

ROIs = size(ROI_idx,1);
for ROI = 1:ROIs-4
    tmp = zeros(size(pain_localizer_t));
    tmp(atlas==ROI_idx{ROI,1}) = pain_localizer_t(atlas==ROI_idx{ROI,1});
    tmp(atlas==ROI_idx{ROI,2}) = pain_localizer_t(atlas==ROI_idx{ROI,2});

    for ii = [1,-1]%threshold positive and negative t-values seperately
        mask = zeros(size(pain_localizer_t),'logical');
        if ii == 1
            mask(tmp>t_thres) = true;
        else
            mask(tmp<-t_thres) = true;
        end

        pain_localizer_t_hdr.vol = mask;
        tmp_name = num2str(ROI_idx{ROI,1});
        if ii == 1
            outname = [pain_path '/pain_localizer_ROI' tmp_name(2:end) '_pos.nii'];
        else
            outname = [pain_path '/pain_localizer_ROI' tmp_name(2:end) '_neg.nii'];
        end
        save_nifti(pain_localizer_t_hdr,outname);
    end
end

for ROI = ROIs-3:2:ROIs
    tmp = zeros(size(pain_localizer_t));
    tmp(atlas==ROI_idx{ROI,1}) = pain_localizer_t(atlas==ROI_idx{ROI,1});
    tmp(atlas==ROI_idx{ROI,2}) = pain_localizer_t(atlas==ROI_idx{ROI,2});

    tmp(atlas==ROI_idx{ROI+1,1}) = pain_localizer_t(atlas==ROI_idx{ROI+1,1});
    tmp(atlas==ROI_idx{ROI+1,2}) = pain_localizer_t(atlas==ROI_idx{ROI+1,2});

    for ii = [1,-1]%threshold positive and negative t-values seperately
        mask = zeros(size(pain_localizer_t),'logical');
        if ii == 1
            mask(tmp>t_thres) = true;
        else
            mask(tmp<-t_thres) = true;
        end

        pain_localizer_t_hdr.vol = mask;
        tmp_name = num2str(ROI_idx{ROI,1});
        if ii == 1
            outname = [pain_path '/pain_localizer_ROI' tmp_name(2:end) '_pos.nii'];
        else
            outname = [pain_path '/pain_localizer_ROI' tmp_name(2:end) '_neg.nii'];
        end
        save_nifti(pain_localizer_t_hdr,outname);
    end
end