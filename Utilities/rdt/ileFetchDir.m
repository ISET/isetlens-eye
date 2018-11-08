% Simple helper function for isetlens-eye. We check if the directory name
% given is in the isetlenseyeRootPath/data folder. If not, we fetch it
% using the RemoteDataToolbox.

function dataDir = ileFetchDir(dirName)

dataDir = fullfile(isetlenseyeRootPath,'data',dirName);

if(~exist(dataDir,'dir'))
    fprintf('Fetching data...\n');
    piPBRTFetch(dirName,...
        'remotedirectory','/resources/isetlensdata',...
        'destinationfolder',fullfile(isetlenseyeRootPath,'data'),...
        'delete zip', true);
    fprintf('Data fetched! New data directory added: \n');
    fprintf('%s \n', dataDir);
else
    fprintf('Data directory already exists, no need to fetch from RDT. \n')
end

end