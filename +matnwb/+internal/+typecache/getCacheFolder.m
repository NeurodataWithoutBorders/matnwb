function cacheFolder = getCacheFolder()
% getCacheFolder - Get the folder that stores generated types for reuse.
%
%   cacheFolder = matnwb.internal.typecache.getCacheFolder() returns the
%   folder where generated classes are kept, one subfolder per namespace
%   version. The folder is set by the "GeneratedTypesCacheFolder"
%   preference in the "matnwb" group. Without the preference, the folder
%   is "generated-types-cache" in the matnwb root directory.
%
%   Example - Keep the cache outside the matnwb installation:
%
%       setpref("matnwb", "GeneratedTypesCacheFolder", fullfile(userpath, "matnwb-types"))

    defaultFolder = fullfile(misc.getMatnwbDir(), "generated-types-cache");
    cacheFolder = string(getpref("matnwb", "GeneratedTypesCacheFolder", defaultFolder));
end
