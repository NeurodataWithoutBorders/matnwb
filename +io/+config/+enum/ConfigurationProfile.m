classdef ConfigurationProfile < handle
%CONFIGURATIONPROFILE Dataset configuration profiles recognised by MatNWB.
%
%  Use these enumeration members when selecting chunking/compression presets
%  via NwbFile.applyDatasetSettingsProfile, or nwbExport.  Profiles map to 
%  JSON files in the ``configuration`` folder:
%
%    * ``default`` – general-purpose balance of size and performance.
%    * ``cloud`` – tuned for object storage and remote streaming access.
%    * ``archive`` – favors compact, long-term storage.
%    * ``none`` – opt out of applying a profile entirely.

    enumeration
        none
        default
        cloud
        archive
    end
end
