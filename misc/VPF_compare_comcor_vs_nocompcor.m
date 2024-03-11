clear;clc;

mainpath = '/home/pfaffenrot/work/postdoc/projects/ANT_workdir';

runs = dir([mainpath '/*mag_POCS_r*']);
for run = 1:length(runs)

    betas = dir([runs(run).folder '/' runs(run).name '/rwls_stats_compcor/beta*.nii']);
    for val = 3:22
        tmp = load_nifti([betas(val).folder '/' betas(val).name]);
        if run == 1 && val == 3
            beta = zeros([size(tmp.vol), 20, length(runs)]);
        end
        beta(:,:,:,val-2,run) = tmp.vol;
    end
end
beta = mean(mean(beta,5),4);
