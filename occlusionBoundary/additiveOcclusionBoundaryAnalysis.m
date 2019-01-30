%% additiveOcclusionBoundaryAnalysis.m
% Compare the blur at an occlusion boundary between two checkerboard planes
% placed at different depths.
% (1) In the first case, we render both planes together.
% (2) In the second case, we render each plane individually and then add up
% the optical images.
%
% We don't expect the blur to be additive, so the second method will
% produce errors at the boundary.
%
% TL 2018

%% Initialize
ieInit;

%% Fetch data
% Prerendered data is saved on RDT. This data was generated using
% s_occlusionTexture.m
dataDir = ileFetchDir('occlusionBoundary_512res');

% saveDir = fullfile(isetlenseyeRootPath,'outputImages','occlusion');
saveDir = '/Users/trishalian/Google Drive/Figures/occlusions';
if(~exist(saveDir,'dir'))
    mkdir(saveDir);
end

%% For each plane distance and accommodation load the right data set

topDepthsAll = [0.5];

% The back plane is always fixed to 2 meters
bottomDepth = 2;

for tp = 1:length(topDepthsAll)
    topDepth = topDepthsAll(tp);
    
    for acc = [1/topDepth 1/bottomDepth]
        
        topDepth = topDepthsAll(tp);
        basename = sprintf('occlusion_%0.2f_%0.2f_%0.2fdpt',...
            topDepth,bottomDepth,acc);
        
        % ---------------
        % Load the optical image where both planes were rendered together
        
        load(fullfile(dataDir,...
            sprintf('%s.mat',basename)));
        
        oiTogether = oi; % rename the oi
        
        ieAddObject(oiTogether);
        % oiWindow;
        
        rgbTogether = oiGet(oiTogether,'rgb');
        
        % ---------------
        % Load the optical images with only a single plane
        
        % Load top plane
        load(fullfile(dataDir,...
            sprintf('%s_Top.mat',basename)));
        oiTop = oi; % rename the oi
       
        depthTop = oiGet(oiTop,'depth map');
        
        
        ieAddObject(oiTop);
        % oiWindow;
        
        rgbTop = oiGet(oiTop,'rgb');
        
        % Load bottom plane
        load(fullfile(dataDir,...
            sprintf('%s_Bottom.mat',basename)));
        oiBottom = oi; % rename the oi
        
        depthBottom = oiGet(oiBottom,'depth map');
        rgbBottom = oiGet(oiBottom,'rgb');
        
        % Plot the depth map
        %{
        figure();
        subplot(1,2,1);
        imagesc(depthTop,[0 3]); 
        axis off; axis square;
        colorbar; colormap(flipud(gray)); 
        title('Front Plane Depth')
        subplot(1,2,2);
        imagesc(depthBottom,[0 3]);
        axis off; axis square;
        colorbar; colormap(flipud(gray)); 
        title('Back Plane Depth')
        set(gcf,'Position',[1000 864 1339 474]);
        %}
        
        % ---------------
        % Add the photons from oiTop and oiBottom together
        oiSum = oiAdd(oiTop, oiBottom, [1 1]);
        ieAddObject(oiSum);
        % oiWindow;
        
        rgbSum = oiGet(oiSum,'rgb');
        
        % ---------------
        % Plot the RGB images
        
        x = scene3d.angularSupport;
        
        % zoom in
        %{
        r = [226   223    73    68];
        [X,Y] = meshgrid(x,x);
        X = imcrop(X,r);
        Y = imcrop(Y,r);
        TL = [X(1,1) Y(1,1)];
        BR = [X(1,end)-X(1,1) Y(end,1)-Y(1,1)];
        r_deg = [TL BR];
        %}
        r_deg = x;
        
%         figure();
%         subplot(4,2,1);
        H = figure();
        image(x,x,rgbTop); hold on; axis image;
        xlabel('degrees')
        ylabel('degrees')
        %title(sprintf('Plane: %0.2f m \n Accom: %0.2f dpt',topDepth, acc),...
        %    'FontSize',16);
        set(findall(gcf,'-property','FontSize'),'FontSize',18)
        saveas(H,fullfile(saveDir,...
            sprintf('TopPlane_%0.2f_%0.2f_%0.2fdpt.png',...
            topDepth,bottomDepth,acc)));
        
%         subplot(4,2,2);
        H = figure();
        image(x,x,rgbBottom); axis image;
        xlabel('degrees')
        ylabel('degrees')
        % title(sprintf('Plane: %0.2f m \n Accom: %0.2f dpt', bottomDepth, acc),...
        %   'FontSize',16);
        set(findall(gcf,'-property','FontSize'),'FontSize',18)
        saveas(H,fullfile(saveDir,...
            sprintf('BottomPlane_%0.2f_%0.2f_%0.2fdpt.png',...
            topDepth,bottomDepth,acc)));
        
%         subplot(4,2,3);
        H = figure();
        image(x,x,rgbSum); axis image;
        xlabel('degrees')
        ylabel('degrees')
        % title('Additive Image','FontSize',16);
        set(findall(gcf,'-property','FontSize'),'FontSize',18)
        saveas(H,fullfile(saveDir,...
            sprintf('AdditiveImage_%0.2f_%0.2f_%0.2fdpt.png',...
            topDepth,bottomDepth,acc)));
        
%         subplot(4,2,5);
        H = figure();
        image(x,x,rgbTogether); axis image;
        xlabel('degrees')
        ylabel('degrees')
        %title('Full Rendering','FontSize',16);
        set(findall(gcf,'-property','FontSize'),'FontSize',18)
        saveas(H,fullfile(saveDir,...
            sprintf('FullRender_%0.2f_%0.2f_%0.2fdpt.png',...
            topDepth,bottomDepth,acc)));
        
        % Difference image 
        % I was going to take the photon difference here, but wasn't sure
        % how we'd convert negative photon differences to RGB. For now i'm
        % going to take the RGB difference and take a mean across channels.
        %{
        rgbDiff = abs(rgbTogether - rgbSum);
        rgbDiff = max(rgbDiff,[],3);
        subplot(1,5,5); 
        imagesc(rgbDiff); colorbar; axis image; axis off;
        title('abs(Full Rendering - Additive Image)');
        %}
        
        % Try taking the absolute value of the photon difference
        % Important that we match scales
        oldPhotons = oiGet(oiTogether,'photons');
        oiTogether = oiSet(oiTogether,'mean illuminance',10);
        newPhotons = oiGet(oiTogether,'photons');
        photonRatio = newPhotons./oldPhotons;
        scalingFactor = mode(photonRatio(:));
        oiSum = oiSet(oiSum,'photons',oiGet(oiSum,'photons').*scalingFactor);

        photonDiff = abs(oiGet(oiTogether,'photons')-oiGet(oiSum,'photons'));
        %subplot(4,2,7);
        H = figure();
        imagesc(sum(photonDiff,3)); axis image; axis off;
        % title(sprintf('Absolute Irradiance Difference \n (summed across wavelengths)'));
        h = colorbar; 
        ylabel(h, 'Irradiance (q/s/m^2/nm)','FontSize',18)
        set(findall(gcf,'-property','FontSize'),'FontSize',18)
        saveas(H,fullfile(saveDir,...
            sprintf('DiffImage_%0.2f_%0.2f_%0.2fdpt.png',...
            topDepth,bottomDepth,acc)));
        
        % Zoom in
        %{
        x = X(1,:);
        y = Y(:,1);
        subplot(2,4,5);
        image(x,y,imcrop(rgbTop,r)); axis image;
        xlabel('degrees')
        subplot(2,4,6);
        image(x,y,imcrop(rgbBottom,r)); axis image;
        xlabel('degrees')
        subplot(2,4,7);
        image(x,y,imcrop(rgbSum,r)); axis image;
        xlabel('degrees')
        subplot(2,4,8);
        image(x,y,imcrop(rgbTogether,r)); axis image;
        xlabel('degrees')
        set(gcf,'Position',[673 473 1491 822]);
        %}
        
        % Increase font size
        % set(findall(gcf,'-property','FontSize'),'FontSize',16)
        
    end
    
end



%% Old analysis code
% The below was analysis to understand why the back plane was darker when
% it was rendered individually. We discovered that it was due to a
% combination of the environment lighting (we switched to distant lighting)
% and the scaling applied in piRender (we now have sceneEye default to a
% scaling of 1.)
% I'm keeping this code around, since it may come in handy if we run into a
% similar bug again.

%{
%% Why is the back plane darker?


% We haven't scaled the photons yet, so why is the back plane darker in the
% combined render?
% First let's check that the number of photons is different

% Get a rectangular patch for back plane
whitePatchRect = [446.0000  275.0000   29.0000   30.0000];

% Show rectangle for each case
figure();
title('Patch to Analyze')
img = oiGet(oiTogether,'rgb');
subplot(1,2,1)
imshow(img);
rectangle('Position',whitePatchRect);
img = oiGet(oiBottom,'rgb');
subplot(1,2,2)
imshow(img);
rectangle('Position',whitePatchRect);

oiWhitePatch_together = oiCrop(oiTogether,whitePatchRect);
patchPhotons_together = oiGet(oiWhitePatch_together,'photons');
[m,n,w] = size(patchPhotons_together);
patchPhotons_together = reshape(patchPhotons_together,[m*n w]);
patch_together_mean = squeeze(mean(patchPhotons_together,1));
patch_together_std = std(patchPhotons_together,1);

oiWhitePatch_bottom = oiCrop(oiBottom,whitePatchRect);
patchPhotons_bottom = oiGet(oiWhitePatch_bottom,'photons');
[m,n,w] = size(patchPhotons_bottom);
patchPhotons_bottom = reshape(patchPhotons_bottom,[m*n w]);
patch_bottom_mean = squeeze(mean(patchPhotons_bottom,1));
patch_bottom_std = std(patchPhotons_bottom,1);

% Compare the mean SPD in the patch
figure(); hold on;
title('White Patch Comparison (Bottom Plane)')
wave = oiGet(oiTogether,'wave');
errorbar(wave,patch_together_mean,patch_together_std,'r');
errorbar(wave,patch_bottom_mean,patch_bottom_std,'b');
legend('Together','Only Bottom')

% TODO:
% Given the error bars, it's not a noise issue...
% So why is there this difference? Need to debug carefully in PBRT.
% We hypothesize this might have to do with the front plane blocking rays
% from the back plane.

%% Do we see the same thing in the front plane?
% Answer: Nope...

% Get a rectangular patch for front plane
whitePatchRect = [268.0000  385.0000   30.0000   31.0000];

% Show rectangle for each case
figure();
title('Patch to Analyze')
img = oiGet(oiTogether,'rgb');
subplot(1,2,1)
imshow(img);
rectangle('Position',whitePatchRect);
img = oiGet(oiTop,'rgb');
subplot(1,2,2)
imshow(img);
rectangle('Position',whitePatchRect);

oiWhitePatch_together = oiCrop(oiTogether,whitePatchRect);
patchPhotons_together = oiGet(oiWhitePatch_together,'photons');
[m,n,w] = size(patchPhotons_together);
patchPhotons_together = reshape(patchPhotons_together,[m*n w]);
patch_together_mean = squeeze(mean(patchPhotons_together,1));
patch_together_std = std(patchPhotons_together,1);

oiWhitePatch_top = oiCrop(oiTop,whitePatchRect);
patchPhotons_top = oiGet(oiWhitePatch_top,'photons');
[m,n,w] = size(patchPhotons_top);
patchPhotons_top = reshape(patchPhotons_top,[m*n w]);
patch_bottom_mean = squeeze(mean(patchPhotons_top,1));
patch_bottom_std = std(patchPhotons_top,1);

% Compare the mean SPD in the patch
figure(); hold on;
title('White Patch Comparison (Top Plane)')
wave = oiGet(oiTogether,'wave');
errorbar(wave,patch_together_mean,patch_together_std,'r');
errorbar(wave,patch_bottom_mean,patch_bottom_std,'b');
legend('Together','Only Top')

%% For now let's scale using the white patch

scalingFactor = patch_together_mean(wave == 550)/patch_bottom_mean(wave == 550);
photonsBottom = oiGet(oiBottom,'photons');
photonsBottom = photonsBottom.*scalingFactor;
oiBottom = oiSet(oiBottom,'photons',photonsBottom);
ieAddObject(oiBottom);
oiWindow;

% Check the SPD after scaling
figure(); hold on;
title('White Patch Comparison (Bottom Plane Scaled)')
wave = oiGet(oiTogether,'wave');
plot(wave,patch_together_mean,'r');
plot(wave,patch_bottom_mean.*scalingFactor,'b');
legend('Together','Only Bottom')

% Now add them
oiSum = oiAdd(oiTop, oiBottom, [1 1]);
ieAddObject(oiSum);
oiWindow;
%}




