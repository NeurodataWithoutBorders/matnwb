function nwbTree(nwbfile, options)
    arguments
        nwbfile (1,1) NwbFile
        options.Parent = []
        options.Margin = 20
    end

    if isempty(options.Parent)
        hParent = uifigure('Name', 'NWB Tree');
    else
        hParent = options.Parent;
    end
    tree = uitree(hParent);
       
    M = options.Margin;
    tree.Position = [repmat(options.Margin, 1,2), hParent.Position(3:4) - options.Margin*2];
    traverse_node(nwbfile, tree);

    tree.DoubleClickedFcn = @(src, evt) onDoubleClickOnNode(src, evt, nwbfile);
end


function out = traverse_node(node, tree_node)

if any(strcmp(superclasses(node), 'types.untyped.GroupClass')) || isa(node, 'types.untyped.DataStub')
    propertyNames = string( properties(node)' );
    for propertyName = propertyNames
        if ~isempty(node.(propertyName))
            propertyValue = node.(propertyName);
            if any(strcmp(superclasses(propertyValue), 'types.untyped.GroupClass'))
                new_tree_node = uitreenode(tree_node, 'Text', propertyName, 'NodeData', propertyValue);
                traverse_node(propertyValue, new_tree_node);
            elseif isa(propertyValue, 'types.untyped.Set')
                if propertyValue.Count
                    new_tree_node = uitreenode(tree_node, 'Text', propertyName);
                    traverse_node(propertyValue, new_tree_node);
                end
            elseif isa(propertyValue, 'types.untyped.DataStub')
                new_tree_node = uitreenode(tree_node, 'Text', propertyName, 'NodeData', propertyValue);
                traverse_node(propertyValue, new_tree_node);
            elseif isa(propertyValue, 'char')
                uitreenode(tree_node, 'Text', propertyName + ": " + propertyValue);
            elseif isnumeric(propertyValue)
                if isscalar(propertyValue)
                    uitreenode(tree_node, 'Text', propertyName + ": " + num2str(propertyValue));
                else
                    data_node = uitreenode(tree_node, 'Text', propertyName, 'NodeData', propertyValue);
                    uitreenode(data_node, 'Text', ['shape: [' num2str(size(propertyValue)) ']']);
                    uitreenode(data_node, 'Text', ['class: ' class(propertyValue)]);
                end 
            else
                % new_tree_node = createNode(tree_node, propertyName, node.get(key{1}));

                uitreenode(tree_node, 'Text', propertyName, 'NodeData', propertyValue);
            end
        end
    end
elseif isa(node, 'types.untyped.Set')
    for key = node.keys()
        new_tree_node = createNode(tree_node, key{1}, node.get(key{1}));
        traverse_node(node.get(key{1}), new_tree_node);
    end
end



function [ bytes ] = getMemSize( variable, sizelimit, name, indent )
    if nargin < 2
        sizelimit = -1;
    end
    if nargin < 3
        name = 'variable';       
    end
    if nargin < 4
        indent = '';
    end
    
    strsize = 30;
    
    props = properties(variable); 
    if size(props, 1) < 1
        
        bytes = whos(varname(variable)); 
        bytes = bytes.bytes;
        
        if bytes > sizelimit
            if bytes < 1024
                fprintf('%s%s: %i\n', indent, pad(name, strsize - length(indent)), bytes);
            elseif bytes < 2^20
                fprintf('%s%s: %i Kb\n', indent, pad(name, strsize - length(indent)), round(bytes / 2^10));
            elseif bytes < 2^30
                fprintf('%s%s: %i Mb\n', indent, pad(name, strsize - length(indent)), round(bytes / 2^20));
            else
                fprintf('%s%s: %i Gb [!]\n', indent, pad(name, strsize - length(indent)), round(bytes / 2^30));
            end
        end
    else
        
        fprintf('\n%s[%s] \n\n', indent, name);
        bytes = 0;
        for ii=1:length(props)
            currentProperty = getfield(variable, char(props(ii)));
            pp = props(ii);
            bytes = bytes + getMemSize(currentProperty, sizelimit, pp{1}, [indent, '  ']);
        end                
                
        if isempty(indent)
            fprintf('\n');
            name = 'TOTAL';
            if bytes < 1024
                fprintf('%s%s: %i\n', indent, pad(name, strsize - length(indent)), bytes);
            elseif bytes < 2^20
                fprintf('%s%s: %i Kb\n', indent, pad(name, strsize - length(indent)), round(bytes / 2^10));
            elseif bytes < 2^30
                fprintf('%s%s: %i Mb\n', indent, pad(name, strsize - length(indent)), round(bytes / 2^20));
            else
                fprintf('%s%s: %i Gb [!]\n', indent, pad(name, strsize - length(indent)), round(bytes / 2^30));
            end
        end
    
    end   
        
end


end

function new_tree_node = createNode(parentTreeNode, nodeName, nodeValue)
    nodeLabel = sprintf('%s (%s)', nodeName, class(nodeValue));
    new_tree_node = uitreenode(parentTreeNode, 'Text', nodeLabel, 'NodeData', nodeValue);
    if ~nargout
        clear new_tree_node
    end
end

function onDoubleClickOnNode(src, evt, nwbfile)
    textLabel = evt.Source.SelectedNodes.Text;
    if contains(textLabel, '(')
        name = extractBefore(evt.Source.SelectedNodes.Text, '(');
    else
        name = textLabel;
    end
    name = strtrim(name);
    value = evt.Source.SelectedNodes.NodeData;
    if ~isempty(value)
        if strcmp(name, "")
            keyboard
        end
        assignin('base', name, value)
        eval(sprintf('%s=value', name));
    else
        
    end
    %disp(value)
end
