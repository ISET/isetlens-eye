% Simple utility, not quite as fancy as what's in isetlens but it'll do for
% now. 
function writeRealisticEyeLensFile(lensMatrix,filename,A)

focalLength = 1 / (60.6061 + A) * 10 ^ 3; % mm
fid = fopen(filename,'w');

str = sprintf('# Focal length (mm) \n');
fprintf(fid,'%s',str);
str = sprintf('%.3f\n',focalLength);
fprintf(fid,'%s',str);
str = sprintf(['# radiusX radiusY thickness materialIndex semiDiameter' ...
    ' conicConstantX conicConstantY\n']);
fprintf(fid,'%s',str);
for ii=1:size(lensMatrix,1)
    fprintf(fid,'%f\t%f\t%f\t%f\t%f\t%f\t%f\n', ...
        lensMatrix(ii,1), lensMatrix(ii, 2), lensMatrix(ii,3), ...
        lensMatrix(ii,4), lensMatrix(ii,5), lensMatrix(ii,6), ...
        lensMatrix(ii,7));
end
fclose(fid);

end

