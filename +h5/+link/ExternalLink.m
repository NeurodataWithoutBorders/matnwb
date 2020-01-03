classdef ExternalLink < h5.Link
    %EXTERNALLINK link to external file H5 Space
    
    methods (Static)
        function ExternalLink = create(Parent, name, varargin)
            assert(isa(Parent, 'h5.interface.HasId'),...
                'NWB:H5:ExternalLink:Create:InvalidArgument',...
                '`Parent` object must have an ID.');
            assert(ischar(name),...
                'NWB:H5:ExternalLink:Create:InvalidArgument',...
                '`name` must be a character array.');
            
            p = inputParser;
            p.addParameter('filename', '');
            p.addParameter('path', '');
            p.parse(varargin{:});
            
            filename = p.Results.filename;
            path = p.Results.path;
            
            assert(~isempty(obj.filename),...
                'NWB:H5:ExternalLink:Create:MissingArgument',...
                'External Links require a reference to another filename');
            assert(~isempty(obj.path),...
                'NWB:H5:ExternalLink:Create:MissingArgument',...
                'External Links require a path to the object in the other file');
            
            lcpl = 'H5P_DEFAULT';
            lapl = 'H5P_DEFAULT';
            H5L.create_external(filename, path, Parent.get_id(), name, lcpl, lapl);
            lid = H5O.open(Parent.get_id(), name, lapl);
            ExternalLink = h5.link.ExternalLink(Parent, name, lid);
        end
        
        function ExternalLink = open(Parent, name)
            assert(isa(Parent, 'h5.interface.HasId'),...
                'NWB:H5:ExternalLink:Open:InvalidArgument',...
                '`Parent` object must have an ID.');
            assert(ischar(name),...
                'NWB:H5:ExternalLink:Open:InvalidArgument',...
                '`name` must be a character array.');
            
            lapl = 'H5P_DEFAULT';
            lid = H5O.open(Parent.get_id(), name, lapl);
            ObjInfo = H5O.get_info(lid);
            assert(ObjInfo.type == h5.const.ObjectType.Link,...
                'NWB:H5:ExternalLink:Open:InvalidObject',...
                '`%s` doesn''t refer to a valid Link.', name);
            ExternalLink = h5.link.ExternalLink(Parent, name, lid);
        end
    end
    
    properties (SetAccess = private, Dependent)
        filename;
        path;
    end
    
    methods % set/get
        function filename = get.filename(obj)
            data = H5L.get_val(obj.parent.get_id(), name, 'H5P_DEFAULT');
            filename = data{1};
        end
        
        function path = get.path(obj)
            data = H5L.get_val(obj.parent.get_id(), name, 'H5P_DEFAULT');
            path = data{2};
        end
    end
end

