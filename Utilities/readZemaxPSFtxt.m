function [x_um,y] = readZemaxPSFtxt(filename)

if(~exist(filename,'file'))
    error('Cannot find file.');
end

fid = fopen(filename, 'rt');  %the 't' is important!
C = cell2mat(textscan(fid,'%f%f%f','HeaderLines',16));
fclose(fid);

x_um = C(:,2);
y = C(:,3);

end

