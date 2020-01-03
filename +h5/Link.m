classdef Link < h5.interface.IsObject
    %LINK HDF5 link
    
    methods (Static)
        function Link = create(Parent, name, path, varargin)
            assert(isa(Parent, 'h5.interface.HasId'),...
                'NWB:H5:Link:Create:InvalidArgument',...
                '`Parent` must be a H5 Object with an ID.');
            assert(ischar(name),...
                'NWB:H5:Link:Create:InvalidArgument',...
                'name must be a character array.')
            assert(ischar(path),...
                'NWB:H5:Link:Create:InvalidArgument',...
                '`path` must be a character array.');
            
            p = inputParser;
            p.addParameter('filename', '');
            p.parse(varargin{:});
            filename = p.Results.filename;
            
            if isempty(filename)
                Link = h5.link.SoftLink.create(Parent, name,...
                    'path', path);
            else
                assert(ischar(filename),...
                'NWB:H5:Link:Create:InvalidArgument',...
                '`filename` should be a character array.');
                Link = h5.link.ExternalLink.create(Parent, name,...
                    'path', path,...
                    'filename', filename);
            end
        end
        
        function Link = open(Parent, name)
            lapl = 'H5P_DEFAULT';
            LinkInfo = H5L.get_info(Parent.get_id(), name, lapl);
            switch LinkInfo.type
                case h5.const.LinkType.External
                    Link = h5.link.ExternalLink.open(Parent, name);
                case h5.const.LinkType.Soft
                    Link = h5.link.SoftLink.open(Parent, name);
                otherwise
                    error('NWB:H5:Link:Open:UnsupportedLinkType',...
                        'Link type `%d` currently not supported at this time.',...
                        LinkInfo.type);
            end
        end
    end
    
    properties (Access = protected)
        parent;
        id;
    end
    
    properties (SetAccess = private)
        name;
        path;
    end
    
    methods (Access = protected)
        function obj = Link(Parent, name, id)
            obj.parent = Parent;
            obj.name = name;
            obj.id = id;
        end
    end
    
    methods % lifecycle
        function delete(obj)
            H5O.close(obj.id);
        end
    end
    
    methods % HasId
        function id = get_id(obj)
            id = obj.id;
        end
    end
    
    methods % IsNamed
        function name = get_name(obj)
            name = obj.name;
        end
    end
end

