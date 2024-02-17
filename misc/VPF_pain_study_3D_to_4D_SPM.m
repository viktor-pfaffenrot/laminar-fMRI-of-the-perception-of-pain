function VPF_pain_study_3D_to_4D_SPM(mypath)
    list = dir([mypath '/f*.nii']);
    N = size(list,1);
   
    volumes = {list.name}.';
    for ii = 1:N
        volumes(ii) = {[list(1).folder '/' volumes{ii}]};
    end

    VPF_3D_to_4D_SPM(volumes(1:N/2),'mag.nii');
    VPF_3D_to_4D_SPM(volumes(N/2+1:N),'pha.nii'); 
end
