function VPF_layer_analysis_stats(subpath,ZTRANS)
if nargin < 2
    ZTRANS = false;
end
layerpath = [subpath '/ses-02/func/layers'];
load([layerpath '/layers.mat'],'layers');

[N_layers,N_ROIS,~,N_runs] = size(layers);
N_contrasts = 20; %one contrast per trial
T = zeros(N_layers,N_ROIS,N_runs,N_contrasts,2); % 2 for no_compcor vs compcor
beta = zeros(N_layers,N_ROIS,N_runs,N_contrasts,2);
T_crit = zeros(N_ROIS,N_runs,N_contrasts,2);
p_max = zeros(N_ROIS,N_runs,N_contrasts,2);
for run = 1:N_runs
    statspath = dir([layerpath '/run' num2str(run) '/func/rwls*']);

    for folder = 1:length(statspath)
        load([statspath(folder).folder '/' statspath(folder).name '/SPM.mat'],'SPM');

        W = SPM.xX.W;
        GLM = SPM.xX.pKX;
        con = zeros(size(GLM,1),1);
        for ROI = 1:N_ROIS
            Y = squeeze(layers(:,ROI,:,run));
            Y = Y(:,any(Y ~= 0, 1));
            if ZTRANS
                %baseline z-transform. I take the volumes corresponding
                % to 0 in the sum of all pain trials as baseline
                idx = find(sum(SPM.xX.X(:,3:22),2)==0);
                m = mean(Y(:,idx),2);
                s = std(Y(:,idx),[],2);
                Y = (Y-m)./s;
            end

            KWY = spm_filter(SPM.xX.K,W*Y.');
            b   = GLM*KWY;

            res      = spm_sp('r',SPM.xX.xKXs,KWY);        %-Residuals
            ResSS    = sum(res.^2);                    %-Residual SSQ
            ResMS = ResSS / SPM.xX.trRV;

            for ii = 1:N_contrasts
            %We always assume a one-sided effect, i.e. for ROIs where
            %the localizer showed a negative effect, we assume that mu < 0.
            
            con(con==1) = 0;
            con(ii+2) = 1;
            [T(:,ROI,run,ii,folder),T_crit(ROI,run,ii,folder),beta(:,ROI,run,ii,folder),p_max(ROI,run,ii,folder)] = VPF_Tmap_from_SPM(SPM,b,ResMS,con,0.05,'FDR');
            end
        end
    end
end

rwls_results = struct('beta',beta,'T',T,'T_crit',T_crit,'p_max',p_max);
save([layerpath '/rwls_results.mat'],'rwls_results');
end