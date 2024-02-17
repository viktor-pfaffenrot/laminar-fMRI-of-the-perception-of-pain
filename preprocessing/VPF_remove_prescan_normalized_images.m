function VPF_remove_prescan_normalized_images(inp_path,ISPHASE)
    currdir = pwd;
    
    cd(inp_path)
    if nargin < 2
        ISPHASE = 0;
    end
    list = dir(fullfile(inp_path,'*.IMA'));
    
    if ISPHASE
        vols = numel(list)/3;
        to_delete = 2:2:2*vols;
    
    else
        vols = numel(list)/2;
        to_delete = 2:2:vols;
    end
    
    
    delete(list(to_delete).name);
    cd(currdir)
end