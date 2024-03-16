clear;clc;

pipepath = '/media/pfaffenrot/My Passport1/pain_layers/main_project/derivatives/pipeline';
subid = 7356;
ISPHASE = 1;
paths = {
         [pipepath '/' num2str(subid) '/ses-02/func/WM_localizer/run1/fmap'];...
         [pipepath '/' num2str(subid) '/ses-02/func/WM_localizer/run1/func'];...
         }.';

dummies = 3;
PF_factor = 7/8;

for inp = paths
    mypath = inp{:};
    %back in the days I also took the gmap from the scanner for NORDIC. 
    %If you have a folder called gmap in your path, it'll process it as well
    if any(strcmp({dir(mypath).name}, 'gmap'))
        fprintf('Processing gmap....\n')
        VPF_pain_study_dcm2nii([mypath '/gmap']);
        list = dir([mypath '/gmap/*.nii']);
        movefile([list.folder '/' list.name],[list.folder '/gmap.nii']);
        delete([list.folder '/*.IMA'])
    end

    fprintf('remove prescan normalized images....\n')
    VPF_remove_prescan_normalized_images(mypath,ISPHASE);

    fprintf('convert to 3D nifties....\n')
    VPF_dcm2nii(mypath,dummies);


    fprintf('run POCS partial Fourier recon....\n')
    VPF_POCS_recon_pipeline(dir([mypath '/f*nii']),PF_factor);


    delete([mypath '/*.IMA'])
    %rename and compress files
    fprintf('saving....\n')
    run = char(regexp(mypath, 'run(\d+)', 'tokens', 'once'));
    in_name = 'mag_POCS';
    if any(strfind(mypath,'/fmap'))
        out_name = 'mag_fmap_POCS';
        movefile([mypath '/' in_name '.nii'],[mypath '/' out_name '_r' run '.nii']);
        system(['pigz ' '"' mypath '/' out_name '_r' run '.nii' '"']);
    else
        movefile([mypath '/' in_name '.nii'],[mypath '/' in_name '_r' run '.nii']);
        system(['pigz ' '"' mypath '/' in_name '_r' run '.nii' '"']);
    end

    
    system(['pigz ' '"' mypath '/pha_POCS.nii' '"']);


    fprintf('Done \n')
end