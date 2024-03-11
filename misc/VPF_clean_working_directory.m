function VPF_clean_working_directory(inppath,outpath)
outpath = [outpath '/ses-02/func/layers'];
run = extractBefore(inppath,'_split');
run = run(end);

stats_folders = dir([inppath '/rwls_*']);

%copy every folder with 'rwls' in its name to hard drive
for folder = 1:length(stats_folders)
    source = [stats_folders(folder).folder '/' stats_folders(folder).name];
    target = [outpath '/run' run '/func/' stats_folders(folder).name];
    system(['mv ' source ' "' target '"']);
end

%copy compcor file to hard drive
compcor_file = dir([inppath '/compcor_regressors*.txt']);
system(['cp ' compcor_file.folder '/' compcor_file.name ' "' outpath '/run' run '/func"']);

%delete content of working directory
system(['rm -r ' inppath '/*']);
end