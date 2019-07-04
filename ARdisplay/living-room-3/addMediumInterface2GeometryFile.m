function outFile = addMediumInterface2GeometryFile(inFile,outFile,materialName,mediumInterfaceLine)
%ADDMEDIUMINTERFACE2GEOMETRYFILE Cinema4D doesn't understand medium
% interfaces. Here we attach a medium interface to a specific material.

% Example usage:
%
% addMediumInterface2GeometryFile(inFile,outFile,'RedGlass','MediumInterface "red_absorb" ""')
% 
% This will change:
%
%     	AttributeBegin
%     		NamedMaterial "Glass"
%     		Shape "trianglemesh"  "integer indices" [0 1 2 3 0 2 4 3 2 5 4 2 6 5 2 7 6 2 8 7 2 1 8 2 0 9 10 1 0 10 8 1 10 11 8?'
%     	AttributeEnd
%
% to
%
%     	AttributeBegin
%     		MediumInterface "red_absorb" ""
%     		NamedMaterial "Glass"
%     		Shape "trianglemesh"  "integer indices" [0 1 2 3 0 2 4 3 2 5 4 2 6 5 2 7 6 2 8 7 2 1 8 2 0 9 10 1 0 10 8 1 10 11 8?'
%     	AttributeEnd

fileID = fopen(inFile);
tmp = textscan(fileID,'%s','Delimiter','\n','whitespace', '');
txtLines = tmp{1};
fclose(fileID);

count = 0;
indexJumpAhead = 0;
materialLine = sprintf('NamedMaterial "%s"',materialName);
for ii = 1:length(txtLines)
    if(indexJumpAhead > ii)
        % We just added an additional line. Let's skip ahead a line so we
        % don't reread it.
        ii = indexJumpAhead;
    end
    if(piContains(txtLines{ii},materialLine))
        % Add a line before
        cellBefore = txtLines(1:ii-1);
        cellAfter = txtLines(ii:end);
        additionalLine = strrep(txtLines{ii},materialLine,mediumInterfaceLine);
        txtLines = [cellBefore; additionalLine; cellAfter];
        indexJumpAhead = ii+2;
        count = count+1;
    end
end
fprintf('Added %d lines. \n',count);

% Write out
fileID = fopen(outFile,'w');
for ii = 1:length(txtLines)
      fprintf(fileID,'%s\n',txtLines{ii});
end
fclose(fileID);

fprintf('File written out to %s. \n',outFile)

end

