%% lcaExample.m
% Plot a scene that shows the effect of LCA in the retinal image. The scene
% consists of three letters at different distances. We accommodate the eye
% at each distance.

%% Initialize
ieInit;

%% Load the data
% We have two sets of data, one where the letters are placed at 1.8 1.2 0.6
% dpt.

accom = [1.8 1.2 0.6];
r_Azoom_px = [121   240    56    56];
r_Bzoom_px = [317   293    56    56];
r_Czoom_px = [560   335    56    56];
        
dirName = 'lcaExample_far'; % far data
dataDir = ileFetchDir(dirName);

if(strcmp(dirName,'lcaExample_far'))
    
    for ii = 1:length(accom)
        
        fullImages{ii} = load(fullfile(dataDir,...
            sprintf('lettersAtDepth_%0.2fdpt.mat',accom(ii))));
       
        % We've rendered the zoomed in rectangles defined above (e.g.
        % r_Azoom_px) with a higher resolution, so we'll load those directly
        % instead of cropping the full image.
        for jj = 1:3
            cropImages{ii,jj} = load(fullfile(dataDir,...
                sprintf('lettersAtDepth_%0.2fdpt_%i.mat',accom(ii),jj)));
            % Note: the angular support on these cropped optical images is
            % not correct. This is a bug that needs to be fixed; it wasn't
            % set correctly during rendering.
        end
        
        % Show the optical images
        % ieAddObject(fullImages{ii});
        % oiWindow;
        
    end
    
end


%% Put figure together
% Each row is a different focus/accommodation. Each column is a different
% zoomed in portion fo the scene.

% Should be the same for all images
full_angSupport = fullImages{1}.scene3d.angularSupport;

[r_Azoom_deg, Azoom_x, Azoom_y] = convertRectPx2Ang(r_Azoom_px,full_angSupport);
[r_Bzoom_deg, Bzoom_x, Bzoom_y] = convertRectPx2Ang(r_Bzoom_px,full_angSupport);
[r_Czoom_deg, Czoom_x, Czoom_y] = convertRectPx2Ang(r_Czoom_px,full_angSupport);
r_zoom_inDeg = [r_Azoom_deg; r_Bzoom_deg; r_Czoom_deg];
r_zoom_angSupport_x = [Azoom_x; Bzoom_x; Czoom_x];
r_zoom_angSupport_y = [Azoom_y; Bzoom_y; Czoom_y];

figure(1); clf;
k = 1;
for ii = 1:length(accom)
    
    fullRGB = oiGet(fullImages{ii}.oi,'rgb');
    subplot(length(accom),4,k); k = k+1;
    image(full_angSupport,full_angSupport,fullRGB);
    axis image; xlabel('deg');
    rectangle('Position',r_Azoom_deg,'EdgeColor','r','LineWidth',2)
    rectangle('Position',r_Bzoom_deg,'EdgeColor','g','LineWidth',2)
    rectangle('Position',r_Czoom_deg,'EdgeColor','m','LineWidth',2)
    
    rectColors = {'r','g','m'};
    for jj = 1:3
        
        cropRGB = oiGet(cropImages{ii,jj}.oi,'rgb');
        
        subplot(length(accom),4,k); k = k+1;
        
        % We have to resample this because when we rendered we didn't set
        % the angular support correctly. This is kind of hack.
        curr_angSupport_x = r_zoom_angSupport_x(jj,:);
        x1 = linspace(0,1,length(curr_angSupport_x));
        x2 = linspace(0,1,size(cropRGB,2));
        curr_angSupport_x = interp1(x1,curr_angSupport_x,x2);
        
        curr_angSupport_y = r_zoom_angSupport_y(jj,:);
        y1 = linspace(0,1,length(curr_angSupport_y));
        y2 = linspace(0,1,size(cropRGB,1));
        curr_angSupport_y = interp1(y1,curr_angSupport_y,y2);
        
        image(curr_angSupport_x,curr_angSupport_y,cropRGB);
        axis image; xlabel('deg');
        rectangle('Position',r_zoom_inDeg(jj,:),...
                  'EdgeColor',rectColors{jj},...
                  'LineWidth',4)

    end
    
end

%{
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
%}

% Increase font size
set(findall(gcf,'-property','FontSize'),'FontSize',14)