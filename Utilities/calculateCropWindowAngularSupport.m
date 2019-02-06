function [x_crop,y_crop] = calculateCropWindowAngularSupport(x_full,y_full,cropwindow,cropimage)
%RESAMPLEAXESWITHCROPWINDOW Given a vector of angular support for a given
%image size, determine the axes for the given crop window. 
%
% Input:
%      x_orig, y_orig = the angular support of the full image
%      cropWindow     = the 4 value crop window vector given to PBRT
%      cropImage      = the cropped image, used to determine the right
%                       length for x_crop and y_crop
%
% Output:
%     x_crop, y_crop = the angular support for the cropImage
%
% Example: We have an image of 8092x8092 resolution, we have it's angular
% support calculated as a vector of 8092 values (e.g. from -10 to 10 deg).
% However, we rendered the image with a crop window of [0 0.25 0 0.25] and
% a resolution of 400x400. We want to display this cropped image with the
% right angular support of 400 values (e.g. from -10 to -5 deg.) This
% function calculates the right angular support vector. 

%% Determine the angular support range of the crop window

cropwindow_px = round(cropwindow.*...
    [length(x_full) length(x_full) length(y_full) length(y_full)]);
x_crop = x_full(cropwindow_px(1):cropwindow_px(2));
y_crop = y_full(cropwindow_px(3):cropwindow_px(4));

%% Resample it to match the cropImage resolution

x1 = linspace(0,1,length(x_crop));
x2 = linspace(0,1,size(cropimage,2));
x_crop = interp1(x1,x_crop,x2);

y1 = linspace(0,1,length(y_crop));
y2 = linspace(0,1,size(cropimage,1));
y_crop = interp1(y1,y_crop,y2);


end



