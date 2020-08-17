function [matnwbDir] = getMatnwbDir(varargin)
	% Find the absolute path location of the matnwb directory.
	% started: 2020.07.02 [11:53:52]
	% inputs
		%
	% outputs
		%

	% changelog
		% 2020.07.02 [11:53:58] - Started function, add warnings. - Biafra Ahanonu
	% TODO
		%

	try
		% Get the actual location of the matnwb directory. This assumes "getMatnwbDir" is within the +misc matnwb package folder.
		fnLoc = dbstack('-completenames');
		fnLoc = fnLoc(1).file;
		[fnDir,~,~] = fileparts(fnLoc);
		[matnwbDir,~,~] = fileparts(fnDir);

		% Check directory exists else throw a warning letting the user know.
		dirExists = subfxnDirCheck(matnwbDir,1);
	catch err
		disp(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		disp(repmat('@',1,7))
	end
end
function dirExists = subfxnDirCheck(namespaceDir,dispWarning)
   if exist(namespaceDir,'dir')==7
        dirExists = 1;
   else
        dirExists = 0;
        if dispWarning==1
            warning('Did not find "matnwb" root directory at %s. Using defaults.',namespaceDir)
        end
   end
end