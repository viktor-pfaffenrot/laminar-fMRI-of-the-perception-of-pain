function VPF_execute_SPM_batch_layers_main(inppath,structpath,DO_COMPCOR)


%load the corresponding timing file. Used to fill in the onset and duration fields of the SPM batch
timing_csv = dir([inppath '/*_run-*.csv']);
timing_info_file = readtable([timing_csv.folder '/' timing_csv.name]);

%create the statistics output path
if DO_COMPCOR == true
    stats_path = [inppath '/rwls_stats_compcor'];
else
    stats_path = [inppath '/rwls_stats'];
end
if ~(isfolder(stats_path))
    mkdir(stats_path)
end



%load the data as filenames in a struct
tmp = dir([inppath '/*_Warped-to-Anat.nii']);
scanfiles = cell(size(tmp));
for jj = 1:numel(scanfiles)
    scanfiles(jj) = cellstr([tmp(jj).folder '/' tmp(jj).name ',1']);
end
scans = scanfiles;



%run the SPM batch
inputs = cell(0, 1);
spm('defaults', 'FMRI');
spm_jobman('run', batch_to_execute(stats_path,scans,timing_info_file,structpath,DO_COMPCOR), inputs{:});
end

function matlabbatch = batch_to_execute(stats_path,scans,timing_info,structpath,DO_COMPCOR)

%-----------------------------------------------------------------------
% Job saved on 31-Jan-2023 12:18:03 by cfg_util (rev $Rev: 7345 $)
% spm SPM - SPM12 (7771)
% cfg_basicio BasicIO - Unknown
%-----------------------------------------------------------------------

inppath = fileparts(scans{1});

matlabbatch{1}.spm.tools.rwls.fmri_rwls_spec.dir = {stats_path};
matlabbatch{1}.spm.tools.rwls.fmri_rwls_spec.timing.units = 'secs';
matlabbatch{1}.spm.tools.rwls.fmri_rwls_spec.timing.RT = 3;
matlabbatch{1}.spm.tools.rwls.fmri_rwls_spec.timing.fmri_t = 16;
matlabbatch{1}.spm.tools.rwls.fmri_rwls_spec.timing.fmri_t0 = 8;
%%


trial_types = unique(timing_info.trial_type);

matlabbatch{1}.spm.tools.rwls.fmri_rwls_spec.sess(1).scans = scans;
last_idx = 0;
for ii = 1:length(trial_types)
    trial_type = trial_types{ii};
    onset = [timing_info.onset(strcmp(timing_info.trial_type,trial_type))];
    duration = [timing_info.duration(strcmp(timing_info.trial_type,trial_type))];

    if contains(trial_type,'pain')
        N_trials = length(onset);
        idx = last_idx + 1:last_idx + N_trials;
        for trial = 1:N_trials
            matlabbatch{1}.spm.tools.rwls.fmri_rwls_spec.sess(1).cond(idx(trial)).name = [trial_type '_' num2str(trial)];
            matlabbatch{1}.spm.tools.rwls.fmri_rwls_spec.sess(1).cond(idx(trial)).onset = onset(trial);
            matlabbatch{1}.spm.tools.rwls.fmri_rwls_spec.sess(1).cond(idx(trial)).duration = duration(trial);
            matlabbatch{1}.spm.tools.rwls.fmri_rwls_spec.sess(1).cond(idx(trial)).tmod = 0;
            matlabbatch{1}.spm.tools.rwls.fmri_rwls_spec.sess(1).cond(idx(trial)).pmod = struct('name', {}, 'param', {}, 'poly', {});
            matlabbatch{1}.spm.tools.rwls.fmri_rwls_spec.sess(1).cond(idx(trial)).orth = 1;
        end
    else
        matlabbatch{1}.spm.tools.rwls.fmri_rwls_spec.sess(1).cond(last_idx+1).name = trial_type;
        matlabbatch{1}.spm.tools.rwls.fmri_rwls_spec.sess(1).cond(last_idx+1).onset = onset;
        matlabbatch{1}.spm.tools.rwls.fmri_rwls_spec.sess(1).cond(last_idx+1).duration = duration;
        matlabbatch{1}.spm.tools.rwls.fmri_rwls_spec.sess(1).cond(last_idx+1).tmod = 0;
        matlabbatch{1}.spm.tools.rwls.fmri_rwls_spec.sess(1).cond(last_idx+1).pmod = struct('name', {}, 'param', {}, 'poly', {});
        matlabbatch{1}.spm.tools.rwls.fmri_rwls_spec.sess(1).cond(last_idx+1).orth = 1;
    end


    %matlabbatch{1}.spm.tools.rwls.fmri_rwls_spec.sess(1).multi = {''};
    %matlabbatch{1}.spm.tools.rwls.fmri_rwls_spec.sess(1).regress = struct('name', {}, 'val', {});
    last_idx = length(matlabbatch{1}.spm.tools.rwls.fmri_rwls_spec.sess(1).cond);
end
motion_file = dir([inppath '/*_MoCorr.txt']);
if isempty(motion_file)
    motion_file = dir([inppath '/*_MoCorr.txt']);
    [~,motion_file_name] = fileparts(motion_file.name);
    movefile([motion_file.folder '/' motion_file.name],[motion_file.folder '/' motion_file_name '.txt']);
end
motion_file = [motion_file.folder '/' motion_file.name];

multi_regfile = [cellstr(motion_file)];

if DO_COMPCOR == true
    compcor_file = dir([inppath '/compcor*.txt']);
    compcor_file = [compcor_file.folder '/' compcor_file.name];
    multi_regfile = [multi_regfile; cellstr(compcor_file)];
end

matlabbatch{1}.spm.tools.rwls.fmri_rwls_spec.sess(1).multi_reg = multi_regfile;
matlabbatch{1}.spm.tools.rwls.fmri_rwls_spec.sess(1).hpf = 400;

matlabbatch{1}.spm.tools.rwls.fmri_rwls_spec.fact = struct('name', {}, 'levels', {});
matlabbatch{1}.spm.tools.rwls.fmri_rwls_spec.bases.hrf.derivs = [0 0];
matlabbatch{1}.spm.tools.rwls.fmri_rwls_spec.volt = 1;
matlabbatch{1}.spm.tools.rwls.fmri_rwls_spec.global = 'None';
matlabbatch{1}.spm.tools.rwls.fmri_rwls_spec.mthresh = 0;
matlabbatch{1}.spm.tools.rwls.fmri_rwls_spec.mask = {[structpath '/UNI_MoCo_MPRAGEised_brainmask.nii']};
matlabbatch{1}.spm.tools.rwls.fmri_rwls_spec.cvi = 'wls';

matlabbatch{2}.spm.tools.rwls.fmri_rwls_est.spmmat(1) = cfg_dep('fMRI model specification: SPM.mat File', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','spmmat'));
matlabbatch{2}.spm.tools.rwls.fmri_rwls_est.method.Classical = 1;
end