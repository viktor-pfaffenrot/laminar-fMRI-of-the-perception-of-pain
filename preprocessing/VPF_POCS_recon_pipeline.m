function [] =  VPF_POCS_recon_pipeline(list,PF_factor)

N = size(list,1)/2;
    parfor ii = 1:N
        M = size(list,1)/2;
        mag_file = [list(ii).folder '/' list(ii).name];
        pha_file = [list(ii+M).folder '/' list(ii+M).name];
        VPF_POCS3D_nifti(mag_file,pha_file,PF_factor);
        delete(mag_file);
        delete(pha_file);
    end
    
    %%
    
    for ii = 1:N
        if ii == 1
            tmp = spm_vol([list(ii).folder '/' list(ii).name(1:end-4) '_POCS.nii']);
            mag = repmat(tmp,[N, 1]);
            mag(ii) = tmp;

            tmp = spm_vol([list(ii+N).folder '/' list(ii+N).name(1:end-4) '_POCS.nii']);
            pha = repmat(tmp,[N, 1]);
            pha(ii) = tmp;
        else
            mag(ii) = spm_vol([list(ii).folder '/' list(ii).name(1:end-4) '_POCS.nii']);
            pha(ii) = spm_vol([list(ii+N).folder '/' list(ii+N).name(1:end-4) '_POCS.nii']);
        end
    end
    
    spm_file_merge(mag,'mag_POCS.nii');
    spm_file_merge(pha,'pha_POCS.nii');
    %%
    delete(mag.fname)
    delete(pha.fname)
end