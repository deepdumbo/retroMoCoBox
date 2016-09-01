%%% The data for this demo can be downloaded from: http://goo.gl/ERULZA (32 Mb)

% Change these lines to match your paths:
exampleData = load('/Users/danielg/data/fatnavs_examples/reconTest/example_retroMocoData.mat');
addpath(genpath('~/retroMoCoBox/'))

% The NUFFT uses Prof J. Fessler's toolbox
% (http://web.eecs.umich.edu/~fessler/code/index.html)
run('~/matlabdownloads/fessler/setup.m')


%% Create the image without MoCo

% raw data was acquired with 3/4 partial Fourier in both PE directions, so
% extend the k-space before the Fourier transform for the no-Moco image
image_noMoco = exampleData.newData;
hxyz = size(image_noMoco); Hxyz = exampleData.Hxyz;
image_noMoco(Hxyz(1),Hxyz(2),Hxyz(3)) = 0; % extend to new size
image_noMoco = circshift(image_noMoco,double([Hxyz(1)-hxyz(1) Hxyz(2)-hxyz(2) 0]));              
image_noMoco = ifft3s(image_noMoco);
        
image_noMoco = image_noMoco / percentile(abs(image_noMoco),95);

%% Do the MoCo

rawData = exampleData.newData; % the original raw data 
% In this example it is the principal component of the SVD coil combination
% so that a single virtual coil channel can be used to have coverage over
% most of the brain. The combination was performed *after* the GRAPPA
% reconstruction of the original undersampled data. It is also only the
% data for the second inversion time for MP2RAGE, and because the first
% inversion time is missing then the final image does not have as good a
% contrast as the combined 'UNI' image would have. However, there is enough
% contrast to see that the MoCo is working!

fitMats = exampleData.fitMats_mm_toApply; % the motion parameters
% These are the affine matrices describing the estimated motion. In this
% case they were derived from SPMs 'realign' function (SPM was used as it
% appears to be good for maintining accuracy for sub-pixel alignments of
% the same image). It is very important to remap the output from SPM into
% the coordinate system of the data to be corrected - with the centre of
% the coordinate system at the centre of the FOV so that the rotations will
% be applied properly. 
% As this data was also acquired with GRAPPA acceleration, the 'trick' has
% been used of interpolating the motion parameters from neighbouring
% acquired k-space lines to create 'virtual' motion parameters for the
% unacquired lines. This is perhaps not as stupid as it might seem at
% first, as it leads to a kind of interpolation of the new k-space
% positions. To see how this was implemented, look inside reconstructSiemensMP2RAGEwithFatNavs.m

alignDim = exampleData.alignDim; % the dimension of the raw data that corresponds to chronological time
% This data was acquired with a simple looping hierarchy. The code can also
% cope with more complicated reordering schemes - although this has not
% been tested exhaustively.

alignIndices = exampleData.alignIndices; 
% allow for the fact that time could be running in a positive or negative
% direction in the k-space matrix - and also encode a 2D reordering if
% necessary.

hostVoxDim_mm = exampleData.hostVoxDim_mm;
% This is necessary both to scale the translations appropriately - as well
% as dealing with anisotropic FOVs (again not tested exhaustively
% though...)

Hxyz = exampleData.Hxyz; % The full matrix size of the reconstructed image

kspaceCentre_xyz = exampleData.kspaceCentre_xyz; 
% The centre coordinates for the acquired k-space (needed to know where to rotate around in k-space)


%%% And actually do the MoCo: 
tic
image_withMoco = applyRetroMC_nufft(rawData,fitMats,alignDim,alignIndices,11,hostVoxDim_mm,Hxyz,kspaceCentre_xyz);
toc     
        
image_withMoco = image_withMoco / percentile(abs(image_withMoco),95);

%% View the result

ov1 = orthoview(image_noMoco,'drawIms',0);
ov2 = orthoview(image_withMoco,'drawIms',0);

figure
set(gcf,'Position',[ 76         143        1048         757])
clims = [0 1.8];
subplot1(2,2)
subplot1(1)
imab(ov1.oneIm,clims)
title('No MoCo')
subplot1(3)
imab(ov2.oneIm,clims)
title('With MoCo')

yrange = 122:212;
zrange = 138:241;
subplot1(2)
imab(ov1.im3(yrange,zrange))
subplot1(4)
imab(ov2.im3(yrange,zrange))
fontScale(1.4)
colormap(gray)


%% And view the motion parameters that were used 

fitpars_trans = squeeze(fitMats(1:3,4,:));
fitpars_rot = rotmat2euler(fitMats(1:3,1:3,:));

plotFitPars(cat(1,fitpars_trans,fitpars_rot))

