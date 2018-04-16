classdef nwbfile < handle
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
      obj = obj@types.core.NWBFile(varargin{:});
    end
    
    function export(obj, filename)
      validateattributes(filename, {'string', 'char'}, {'scalartext'});
      if exist(filename, 'file')
        warning('Overwriting %s', filename);
        delete(filename);
      end
      fid = H5F.create(filename);
      export@types.NWBFile(obj, fid);
      H5F.close(fid);
    end
  end
end