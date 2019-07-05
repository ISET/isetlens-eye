%% 
% Compare ray by ray tracing over wavelength with Zemax.

%% Load PBRT data

wave = [450 650];

load(fullfile(isetlenseyeRootPath,'SanityChecks',...
    'rayTraceOverWave','pbrtRayTraceData.mat'));

pbrt{1} = pbrt450(:,2:end);
pbrt{2} = pbrt500(:,2:end);
pbrt{3} = pbrt550(:,2:end);
pbrt{4} = pbrt600(:,2:end);
pbrt{5} = pbrt650(:,2:end);

%% Compare with Zemax

diff = cell(length(wave),1);

for ii = 1:length(wave)
    
rayData = readZemaxRayTrace(fullfile(isetlenseyeRootPath,'SanityChecks',...
    'rayTraceOverWave','RayDebugWave',sprintf('rayTrace_%dnm.txt',wave(ii))));

% Since we trace from retina to scene, we flip the rayData
intersections = flipud(rayData.intersection);
normal = flipud(rayData.normal);
surface_number = flipud(rayData.surface_number);

% Flip the z-axis as well
intersections(:,3) = -1*intersections(:,3);
normal(:,3) = -1*normal(:,3);

% Calculate directions from intersection
clear directions
directions = intersections(2:end,:) - intersections(1:end-1,:);
directions = directions./repmat(sqrt(sum(directions.^2,2)),[1 3]);
directions(end+1,:) = [0 0 0];

zemax{ii} = [intersections directions];

% Compare with Zemax
diff{ii} = abs(zemax{ii} - pbrt{ii});

end

%% Print differences
for ii = 1:length(wave)
    fprintf('------- \n')
    fprintf('%d nm \n',wave(ii))
    fprintf('------- \n')
    diff{ii}
end
