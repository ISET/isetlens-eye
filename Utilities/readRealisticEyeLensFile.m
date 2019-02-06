function C = readRealisticEyeLensFile(filename)

if(~exist(filename,'file'))
    error('Cannot find file.');
end

fid = fopen(filename, 'rt');  %the 't' is important!
C = cell2mat(textscan(fid,'%f%f%f%f%f%f%f','HeaderLines',3));
fclose(fid);

end

