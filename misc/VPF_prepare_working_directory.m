function VPF_prepare_working_directory(outpath,structpath)

subpath = extractBefore(structpath,'/ses-');
run = extractBefore(outpath,'_split');
run = run(end);

inppath = [subpath '/ses-02/func/layers'];

%copy timing file .csv of each condition from sub-* to run folder in working dir
csv_file = dir([inppath '/sub*/eachcondition/*run-0' run '.csv']);
system(['cp "' csv_file.folder '/' csv_file.name '" ' outpath]);

%copy motion file
motion_file = dir([inppath '/run' run '/func/*_MoCorr.txt']);
system(['cp "' motion_file.folder '/' motion_file.name '" ' outpath]);

%copy data and decompress
data = dir([inppath '/run' run '/func/*Warped-to-Anat.*']);

for file = 1:length(data)
    filename = [data(file).folder '/' data(file).name];
    system(['cp "' filename '" ' outpath]);
    [~,~,ext] = fileparts(filename);
    if strcmp(ext,'.gz')
        system(['pigz -d ' outpath '/' data(file).name]);
    end
end
end