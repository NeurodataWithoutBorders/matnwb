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
                varargin = [{'nwb_version'} {'1.2.0'}];
            end
            obj = obj@types.core.NWBFile(varargin{:});
        end
        
        function export(obj, filename)
            if exist(filename, 'file')
                warning('Overwriting %s', filename);
                delete(filename);
            end
            fid = H5F.create(filename);
            refs = export@types.core.NWBFile(obj, fid, '/', containers.Map);
            H5F.close(fid);
            
            if isempty(obj.file_create_date)
                h5write(filename, '/file_create_date', datestr(datetime, 30));
            end
            
            if isempty(obj.nwb_version)
                h5write(filename, '/nwb_version', {'1.2.0'});
            end
        end
        
        function o = resolve(obj, path)
            o = io.resolvePath(obj, path);
        end
    end
end