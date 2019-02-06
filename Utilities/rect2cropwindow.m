function cropwindow = rect2cropwindow(r,imageWidth,imageHeight)
%RECT2CROPWINDOW Convert a matlab rectange to a cropwindow

xmin_px = r(1);
ymin_px = r(2);
width_px = r(3);
height_px = r(4);

xmax_px = xmin_px + width_px;
ymax_px = ymin_px + height_px;

% Convert to ratio
cropwindow_px = [xmin_px xmax_px ymin_px ymax_px];
cropwindow = [cropwindow_px(1:2)./imageWidth ...
    cropwindow_px(3:4)./imageHeight];

end

