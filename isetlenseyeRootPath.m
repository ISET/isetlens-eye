function rootPath = isetlenseyeRootPath()
% Return the path to the root directory

%% Get path to this function
pathToMe = mfilename('fullpath');

%% Walk back up the chain
rootPath = fileparts(pathToMe);

return


