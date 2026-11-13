function VPF_POCS3D_nifti(mag_file,pha_file,PF_factor)
%function to reconstruct partial Fourier data retrospectively using POCS to
%regain some resolution. Using IcePAT, the vendor PF recon is zerofilling
%and POCS is disabled. Input data must be complex (magnitude and phase).
%They should be saved using prescan normalize, save unfiltered and
%AdaptiveCoilCombineAlgo 9. Unfiltered magnitude images should be used in
%the recon.

%Works on 3D and 4D data, assumes that the PF dimension is the 2nd and
%requires SPM12 to read in the nifti files.

%INPUT:

%mag_file       [string]        name of magnitude nifti
%pha_file       [string]        name of phase nifti
%PF_factor      [value]         PF factor

%OUTPUT:

% Magnitude nifti with 'POCS' before extension


% The POCS algorithm was implemented by Michael Völker. If you use this
% reconstruction, please cite him as:

% Michael Völker (2022). MRI Partial Fourier reconstruction with POCS
% (https://www.mathworks.com/matlabcentral/fileexchange/39350-mri-partial-fourier-reconstruction-with-pocs),
% MATLAB Central File Exchange.

% Example: VPF_POCS3D_nifti('mag.nii','pha.nii',6/8)

Niter = 3;
% read in nifti data
mag_hdr = spm_vol(mag_file);
mag = single(spm_read_vols(mag_hdr));
pha_hdr = spm_vol(pha_file);
pha  = spm_read_vols(pha_hdr);

% convert phase to radians and combine magnitude and phase
mpha = max(pha(:));
pha = pha./mpha.*pi;
pha = single(pha);
img = mag.*exp(1i.*pha);

clear mag

%get size
sz = size(img);

% transform from image space to k-space
fimg = zeros(sz,'like',img);
if numel(sz) == 4
    for ii = 1:sz(end)
        fimg(:,:,:,ii) = VPF_FFT(VPF_FFT(VPF_FFT(img(:,:,:,ii),1),2),3);
    end
elseif numel(sz) == 3
    fimg = VPF_FFT(VPF_FFT(VPF_FFT(img,1),2),3);
end

clear img

%get size and center coordinate
start_sym = floor(sz(2)-sz(2)*PF_factor+1);
end_sym = ceil(2*sz(2)*PF_factor-sz(2) + start_sym - 1);

% need to check on which side of the PE dimension are the non-acquired data
% Since the non-acquired portion is not really 0 but has noise on top of it
% I compare the average of data before the symmetrical center with that
% after the symmetrical center

avg_1st_half = mean(abs(fimg(floor(sz(1)/2),1:start_sym-1,1,1)),2);
avg_2nd_half = mean(abs(fimg(floor(sz(1)/2),end_sym+1:end,1,1)),2);



if avg_1st_half > avg_2nd_half
    fimg(:,end_sym+1:end,:,:) = 0;
else
    fimg(:,1:start_sym-1,:,:) = 0;
end

% run POCS algorithm
if numel(sz) == 4
    out = zeros([sz(end) sz(1:3)],'like',fimg);
    for ii = 1:sz(end)
        [~,tmp] = pocs_download(permute(fimg(:,:,:,ii), [4 2 1 3]), Niter);

        if any(size(tmp)~=size(out(1,:,:,:)))
%             dims = size(tmp)~=size(out(1,:,:,:));
            out(ii,:,:,:) = permute(tmp,[1 3 2 4]);
        else
            out(ii,:,:,:) = tmp;
        end
    end
    if any(size(tmp)~=size(out(1,:,:,:)))
    out = permute(out,[1 3 2 4]);
    end
elseif numel(sz) == 3
    [~,out] = pocs_download(permute(fimg, [4 2 1 3]), Niter);
end

    out = permute(out, [3 2 4 1]);

clear fimg

% save to nifti

pha = angle(out)./pi.*mpha;

if numel(sz) == 4
    for ii = 1:sz(end)
        mag_hdr(ii).fname = [mag_hdr(ii).fname(1:end-4) '_POCS.nii'];
        mag_hdr(ii).n = [ii 1];
        spm_write_vol(mag_hdr(ii),abs(out(:,:,:,ii)));

        pha_hdr(ii).fname = [pha_hdr(ii).fname(1:end-4) '_POCS.nii'];
        pha_hdr(ii).n = [ii 1];

        spm_write_vol(pha_hdr(ii),pha(:,:,:,ii));        
    end
elseif numel(sz) == 3
    mag_hdr.fname = [mag_hdr.fname(1:end-4) '_POCS.nii'];
    spm_write_vol(mag_hdr,abs(out));

    pha_hdr.fname = [pha_hdr.fname(1:end-4) '_POCS.nii'];
    spm_write_vol(pha_hdr,pha);
    
end
end

function out = VPF_FFT(data,dim)
for k = 1:dim
    out = fftshift(fft(fftshift(data,k),[],k),k);
end
end

