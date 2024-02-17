
function VPF_pain_study_dcm2nii(mypath,dummies)
if nargin < 2 
    dummies = 0;
end
    list = dir(fullfile(mypath,'*.IMA'));
    N = size(list,1)/2;
    list = cat(1,list(dummies+1:N),list(N+dummies+1:end));

    headers = cell(numel(list),1);
    for ii = 1:numel(list)
        headers(ii) = spm_dicom_headers([mypath '/' list(ii).name],true);
    end
    %this gives you .niis with a long file names for each volume and each
    %echo
    spm_dicom_convert(headers,'all','flat',spm_get_defaults('images.format'),mypath);
end