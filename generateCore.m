function varargout = generateCore(core, varargin)
[c, ~, ~] = yaml.genFromNamespace(core); %should not be any namespace dependencies
[varargout{1:nargout}] = generateExtensions(c, varargin{:});
end