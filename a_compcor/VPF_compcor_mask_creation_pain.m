function mask = VPF_compcor_mask_creation_pain(structpath)
%Function to create WM mask for compcor. Uses the pain ROIs as seeds. Saves
% the mask as .nii.gz.

%INPUT:
%structpath [str]        : path to presurf_UNI

%OUTPUT:
%mask [logical]     : 3D mask of WM around the functional ROIs

subpath = extractBefore(structpath,'/ses-');

T1 = [structpath '/UNI_MoCo_MPRAGEised_biascorrected_masked.nii'];
T1_dir = dir(T1);

if isempty(T1_dir)
    T1 = [structpath '/UNI_MoCo_MPRAGEised_biascorrected.nii'];
end

% load WM propability map and threshold at 90 %
tmp = load_nifti([structpath '/UNI_MoCo_MPRAGEised_class2.nii']).vol;
WM_mask = zeros(size(tmp),'logical');
WM_mask(tmp>0.9) = true;

%get all the positive pain localizer ROIs
mask_dir = [subpath '/ses-02/func/post_calib/rwls_stats'];
masks = dir([mask_dir '/pain_localizer_ROI*_pos.nii']);

if exist([mask_dir '/compcor_mask.nii.gz'],'file') == 2
    return
end

%create one mask out of all ROIs
T1_hdr = load_nifti(T1,1);
mask = zeros(T1_hdr.dim(2:4).','logical');
for ii = 1:length(masks)
    tmp = load_nifti([masks(ii).folder '/' masks(ii).name]).vol;
    tmp(isnan(tmp)) = 0;
    tmp = logical(tmp);
    mask(tmp) = tmp(tmp);
end

%heavily dilate, intersect with WM mask and erode to make sure that WM close
%to the ROIs but no GM is within the mask
for ii = 1:size(mask,3)
    mask(:,:,ii) = imdilate(mask(:,:,ii),strel('disk',12));
end

mask(WM_mask==0) = false;

for ii = 1:size(mask,3)
    mask(:,:,ii) = imerode(mask(:,:,ii),strel('disk',2));
end

%save
T1_hdr.vol = mask;
save_nifti(T1_hdr,[mask_dir '/compcor_mask.nii']);
system(['pigz -f ' '"' mask_dir '/compcor_mask.nii"']);
end