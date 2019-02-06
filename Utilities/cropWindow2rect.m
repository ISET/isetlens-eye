function r = cropWindow2rect(cropWindow,imageWidth,imageHeight)
%CROPWINDOW2RECT Convert a PBRT crop window vector to a matlab rectangle

cropWindow_px = zeros(size(cropWindow));
cropWindow_px(1:2) = round(cropWindow(1:2).*imageWidth);
cropWindow_px(3:4) = round(cropWindow(3:4).*imageHeight);

r_width = cropWindow_px(2) - cropWindow_px(1);
r_height = cropWindow_px(4) - cropWindow_px(3);
r = [cropWindow_px(1) cropWindow_px(2) r_width r_height];

end

