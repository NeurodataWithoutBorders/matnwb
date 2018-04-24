classdef nwbfile < types.core.NWBFile
    % nwbfile Root object representing data read from an NWB file.
    %
    % Requires that core and extension NWB types have been generated
    % and reside in a 'types' package on the matlab path.
    %
    % Example. Construct an object from scratch for export:
    %    nwb = nwbfile;
    %    nwb.epochs = types.untyped.Group;
    %    nwb.epochs.stim = types.Epoch;
    %    nwbExport(nwb, 'epoch.nwb');
    %
    % See also NWBREAD, GENERATECORE, GENERATEEXTENSIONS
    methods
        function obj = nwbfile(varargin)
            p = inputParser;
            p.KeepUnmatched = true;
            p.PartialMatching = false;
            p.StructExpand = false;
            addParameter(p, 'nwb_version', []);
            addParameter(p, 'file_create_date', []);
            parse(p, varargin{:});
            if any(strcmp('nwb_version', p.UsingDefaults))
                varargin = [{'nwb_version'} {'1.0.2'}];
            end
            if any(strcmp('file_create_date', p.UsingDefaults))
                varargin = [{'file_create_date'} {''}];
            end
            obj = obj@types.core.NWBFile(varargin{:});
        end
        
        function export(obj, filename)
            if exist(filename, 'file')
                warning('Overwriting %s', filename);
                delete(filename);
            end
            fid = H5F.create(filename);
            export@types.core.NWBFile(obj, fid);
            H5F.close(fid);
            
            if isempty(obj.file_create_date)
                h5write(filename, '/file_create_date', datestr(datetime, 30));
            end
        end
    end
    
    methods(Access=protected)
        function out = subsref(obj, s)
            out = {};
            if ischar(s.subs) || iscellstr(s.subs) || isstring(s.subs)
                subs = obj.merge_stringtypes(s.subs);
                
                if length(subs) == 1 && any(strcmp(subs{1}, properties(obj)))
                    out = obj.(subs{1});
                    return;
                end
                for i=1:length(subs)
                    sub = subs{i};
                    if isKey(obj.map, sub)
                        out = [out; obj.map(sub)];
                    end
                end
            end
            
            switch length(out)
                case 1
                    out = out{1};
                case 0
                    out = [];
            end
        end
    end
end