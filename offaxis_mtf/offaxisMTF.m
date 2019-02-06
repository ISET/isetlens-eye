%% Calculate the off-axis MTF through the ISET3d rendered image

%% Initialize
ieInit;
rng(1);

MTFfig = vcNewGraphWin;

% Save directory
saveDir = fullfile(isetlenseyeRootPath,'outputImages','MTF_offAxis');
if(~exist(saveDir,'dir'))
    mkdir(saveDir);
end

%% Load PBRT rendered slanted line
% We load a rendered image of a slanted bar. We use ISO12233 to calculate
% the MTF from this image. 

% The rendered data is located on the RemoteDataToolbox because it is a
% large file. If it doesn't already exist, we download it here and put it
% into a local data folder.
dataDir = ileFetchDir('slantedBar_HQ_12deg');
slantedBar = fullfile(dataDir,'slantedBar_12deg.mat');
load(slantedBar);

% Check optical image
ieAddObject(oi);
oiWindow;

%% Calculate MTF at 5 deg location

diff = abs(scene3d.angularSupport-4.3);
i_low = find((diff == min(diff)));
diff = abs(scene3d.angularSupport-5.7);
i_high = find((diff == min(diff)));

rgb = oiGet(oi,'rgb');
figure(); image(rgb); hold on;

% Line across the retinal image
origin = [1536 1536]; p2 = [2295 2862];
m = (p2(2) - origin(2))/(p2(1) - origin(1));
xx = 1:3072;
yy = m*xx + (-1.1474e+03);
plot(xx,yy);

x_low = [i_low 1536];
x_high = [i_high 1536];
dist_low = sqrt(sum((x_low - origin).^2));
dist_high = sqrt(sum((x_high - origin).^2));

theta = atand((p2(1) - origin(1))/(p2(2) - origin(2)));

y = dist_low*cosd(theta);
x = dist_low*sind(theta);
i_low_slant = origin + [x y];

y = dist_high*cosd(theta);
x = dist_high*sind(theta);
i_high_slant = origin + [x y];

% Make the width slightly larger
% i_low_slant(1) = i_low_slant(1) - 100;
% i_high_slant(1) = i_high_slant(1) + 100;

plot(i_low_slant(1),i_low_slant(2),'rx');
plot(i_high_slant(1),i_high_slant(2),'rx');

% Draw a rectangle around the crop area
sz = round(i_high_slant - i_low_slant);
max_sz = max(sz);
addPx = round((max(sz) - min(sz))/2);

% Make it square
i_low_slant(1) = i_low_slant(1) - addPx;
i_high_slant(1) = i_high_slant(1) + addPx;
sz = round(i_high_slant - i_low_slant);

r = round([i_low_slant(1) i_low_slant(2) sz(1) sz(2)]);
rectangle('Position',r);

oi = oiCrop(oi,r);
ieAddObject(oi);
oiWindow;

%% Calculate MTF

figure(MTFfig);
grid on;

[freq,mtf,barImage] = calculateMTFfromSlantedBar(oi,...
    'cropFlag',false,...
    'targetWavelength',589);

plot(freq,mtf);

title(sprintf('5-deg MTF \n (6 mm pupil, 589 nm)'))
xlabel('Spatial Frequency (cycles/deg)');
ylabel('Contrast Reduction (SFR)');
xlim([0 60])
set(findall(gca,'-property','FontSize'),'FontSize',24)
set(findall(gca,'-property','LineWidth'),'LineWidth',3)


