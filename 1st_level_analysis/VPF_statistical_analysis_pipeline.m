%this script performes robust weighted linear least squares analysis on
%multiple subjects and estimates the correspoding SPM.mat.

%The output will be a folder named rwls_stats for each experiment (WM_localizer,
%pain_calib, post_calib, layers) and subject. In this folder, the SPM.mat and
%beta maps are saved.

%In case of the main experiment, the design matrix is different. Hence, it
%is treated seperately. To speed things up, data are copied to a working
%directory before running the analysis. The resulting SPM.mat file can then
%be used to run GLM on layers. See VPF_layer_analysis_stats.m.
clear;clc;
subjects = {7402,7403,7404,7405};
% experiments = [cellstr('WM_localizer'),cellstr('pain_calib'),cellstr('post_calib')]; 
experiments = [cellstr('layers')];
if any(strcmp(experiments,'layers'))
    pipepath = '/home/pfaffenrot/work/postdoc/projects/ANT_workdir/';
else
    pipepath = '/media/pfaffenrot/My Passport1/pain_layers/main_project/derivatives/pipeline/';

end

for subject = subjects
    for experiment = experiments
        if strcmp(experiment{:},'layers')
            if subject{:} <= 7405
                structpath_base = '/media/pfaffenrot/My Passport1/pain_layers/main_project/derivatives/pipeline/';
            else
                structpath_base = '/media/pfaffenrot/My Passport2/main_project/derivatives/pipeline/';
            end
            structpath = [structpath_base '/' num2str(subject{:}) '/ses-01/anat/presurf_MPRAGEise/presurf_UNI'];

            %create WM mask for compcor
            VPF_compcor_mask_creation_pain(structpath);

            rundir = dir([pipepath '/*_r*_split']);
            runs = length(rundir);

            for run = 1:runs
                inppath = [rundir(run).folder '/' rundir(run).name];

                %copy data to working directory
                VPF_prepare_working_directory(inppath,structpath);

                %run compcor
                VPF_compcor_pain(inppath,structpath)

                %run 1st level analysis on voxel space
                for DO_COMPCOR = [true,false]
                    VPF_execute_SPM_batch_layers_main(inppath,structpath,DO_COMPCOR);
                end

                %clean working directory
                VPF_clean_working_directory(inppath,[structpath_base '/' num2str(subject{:})]);
            end
            %run 1st level analysis on layer level
            VPF_layer_analysis_stats([structpath_base '/' num2str(subject{:})]);

        else %all but layers. Done on harddrive, not working drive

            %run 1st level analysis on voxel space
            VPF_execute_SPM_batch(pipepath,subject{:},experiment{:});

            %compress the used nifies to save space
            experiment_path = [pipepath num2str(subject{:}) '/ses-02/func/' experiment{:}];
            Nruns = length(dir([experiment_path '/run*']));

            for run = 1:Nruns
                dat_path = [experiment_path '/run' num2str(run) '/func/'];
                files = dir([dat_path '/*Warped-to-Anat.nii']);

                for ii = 1:length(files)
                    file = [files(ii).folder '/' files(ii).name];
                    system(['pigz ' '"' file '"']);
                end
            end
        end
    end
end


