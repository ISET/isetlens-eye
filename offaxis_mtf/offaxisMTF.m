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

diff = abs(scene3d.angularSupport-5);
i_5deg = find((diff == min(diff)));

% Draw the rectangle
x = scene3d.angularSupport;
rgb = oiGet(oi,'rgb');
figure(); image(rgb); hold on;
rectangle('Position',r);

% Line across the retinal image
origin = [1536 1536]; p2 = [2295 2862];
m = (p2(2) - origin(2))/(p2(1) - origin(1));
xx = 1:3072;
yy = m*xx + (-1.1474e+03);
plot(xx,yy);

x_5deg = [2815 1536];
dist = sqrt(sum((x_5deg - origin).^2));

plot(x_5deg(1),x_5deg(2),'rx');

theta = atand((p2(1) - origin(1))/(p2(2) - origin(2)));
x = dist*cosd(theta);
y = dist*sind(theta);

i_5deg_slant = origin + [x y];


% oi = oiCrop(oi,'r');
