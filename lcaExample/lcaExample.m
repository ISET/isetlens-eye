%% lcaExample.m
% Plot a scene that shows the effect of LCA in the retinal image. The scene
% consists of three letters at different distances. We accommodate the eye
% at each distance.

%% Initialize
ieInit;

%% Load the data
% We have two sets of data, one where the letters are placed far (1.8 1.2
% 0.6 dpt) and another one where the letters are placed closer (8.33, 4.55,
% 3.12 dpt)
% Not sure yet which one shows LCA better.

dirName = 'lcaExample_far'; % far data
% dirName = 'lcaExample_close'; % close data
datadir = ileFetchDir(dirName);

if(strcmp(dirName,'lcaExample_close'))
    
     % Close
    focusA = load(fullfile(dataDir,...
        'lettersAtDepth_8.33dpt.mat'));
    focusB = load(fullfile(dataDir,...
        'lettersAtDepth_4.55dpt.mat'));
    focusC = load(fullfile(dataDir,...
        'lettersAtDepth_3.12dpt.mat'));
    r_Azoom_px = [129   243    70    70];
    r_Bzoom_px = [340   310    70    70];
    r_Czoom_px = [574   334    70    70];
    
elseif(strcmp(dirName,'lcaExample_far'))
    
    % Far
    focusA = load(fullfile(dataDir,...
        'lettersAtDepth_1.80dpt.mat'));
    focusB = load(fullfile(dataDir,...
        'lettersAtDepth_1.20dpt.mat'));
    focusC = load(fullfile(dataDir,...
        'lettersAtDepth_0.60dpt.mat'));
    r_Azoom_px = [121   240    56    56];
    r_Bzoom_px = [317   293    56    56];
    r_Czoom_px = [560   335    56    56];
    
end

% Show the optical images
% ieAddObject(focusA.oi);
% ieAddObject(focusB.oi);
% ieAddObject(focusC.oi);
% oiWindow;

%% Make figures with cropped views

x = focusA.scene3d.angularSupport;

% Crop rectanges
[r_Azoom_deg, Azoom_x, Azoom_y] = convertRectPx2Ang(r_Azoom_px,x);
[r_Bzoom_deg, Bzoom_x, Bzoom_y] = convertRectPx2Ang(r_Bzoom_px,x);
[r_Czoom_deg, Czoom_x, Czoom_y] = convertRectPx2Ang(r_Czoom_px,x);

rgbFocusA = oiGet(focusA.oi,'rgb');
rgbFocusA_CropA = imcrop(rgbFocusA,r_Azoom_px);
rgbFocusA_CropB = imcrop(rgbFocusA,r_Bzoom_px);
rgbFocusA_CropC = imcrop(rgbFocusA,r_Czoom_px);

rgbFocusB = oiGet(focusB.oi,'rgb');
rgbFocusB_CropA = imcrop(rgbFocusB,r_Azoom_px);
rgbFocusB_CropB = imcrop(rgbFocusB,r_Bzoom_px);
rgbFocusB_CropC = imcrop(rgbFocusB,r_Czoom_px);

rgbFocusC = oiGet(focusC.oi,'rgb');
rgbFocusC_CropA = imcrop(rgbFocusC,r_Azoom_px);
rgbFocusC_CropB = imcrop(rgbFocusC,r_Bzoom_px);
rgbFocusC_CropC = imcrop(rgbFocusC,r_Czoom_px);

figure(1);
subplot(3,4,1);
image(x,x,rgbFocusA); 
title('Focus on "A"');
axis image; xlabel('deg');
rectangle('Position',r_Azoom_deg,'EdgeColor','r','LineWidth',2)
rectangle('Position',r_Bzoom_deg,'EdgeColor','g','LineWidth',2)
rectangle('Position',r_Czoom_deg,'EdgeColor','m','LineWidth',2)
subplot(3,4,2);
image(Azoom_x,Azoom_y,rgbFocusA_CropA); 
axis image; xlabel('deg');
rectangle('Position',r_Azoom_deg,'EdgeColor','r','LineWidth',4)
subplot(3,4,3);
image(Bzoom_x,Bzoom_y,rgbFocusA_CropB);
axis image; xlabel('deg');
rectangle('Position',r_Bzoom_deg,'EdgeColor','g','LineWidth',4)
subplot(3,4,4);
image(Czoom_x,Czoom_y,rgbFocusA_CropC);
axis image; xlabel('deg');
rectangle('Position',r_Czoom_deg,'EdgeColor','m','LineWidth',4)

subplot(3,4,5);
image(x,x,rgbFocusB); 
title('Focus on "B"');
axis image; xlabel('deg');
rectangle('Position',r_Azoom_deg,'EdgeColor','r','LineWidth',2)
rectangle('Position',r_Bzoom_deg,'EdgeColor','g','LineWidth',2)
rectangle('Position',r_Czoom_deg,'EdgeColor','m','LineWidth',2)
subplot(3,4,6);
image(Azoom_x,Azoom_y,rgbFocusB_CropA); 
axis image; xlabel('deg');
rectangle('Position',r_Azoom_deg,'EdgeColor','r','LineWidth',4)
subplot(3,4,7);
image(Bzoom_x,Bzoom_y,rgbFocusB_CropB);
axis image; xlabel('deg');
rectangle('Position',r_Bzoom_deg,'EdgeColor','g','LineWidth',4)
subplot(3,4,8);
image(Czoom_x,Czoom_y,rgbFocusB_CropC);
axis image; xlabel('deg');
rectangle('Position',r_Czoom_deg,'EdgeColor','m','LineWidth',4)

subplot(3,4,9);
image(x,x,rgbFocusC); 
title('Focus on "C"');
axis image; xlabel('deg');
rectangle('Position',r_Azoom_deg,'EdgeColor','r','LineWidth',2)
rectangle('Position',r_Bzoom_deg,'EdgeColor','g','LineWidth',2)
rectangle('Position',r_Czoom_deg,'EdgeColor','m','LineWidth',2)
subplot(3,4,10);
image(Azoom_x,Azoom_y,rgbFocusC_CropA); 
axis image; xlabel('deg');
rectangle('Position',r_Azoom_deg,'EdgeColor','r','LineWidth',4)
subplot(3,4,11);
image(Bzoom_x,Bzoom_y,rgbFocusC_CropB);
axis image; xlabel('deg');
rectangle('Position',r_Bzoom_deg,'EdgeColor','g','LineWidth',4)
subplot(3,4,12);
image(Czoom_x,Czoom_y,rgbFocusC_CropC);
axis image; xlabel('deg');
rectangle('Position',r_Czoom_deg,'EdgeColor','m','LineWidth',4)

% Increase font size
set(findall(gcf,'-property','FontSize'),'FontSize',14)