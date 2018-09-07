function refobj = parseReference(did, tid, data)
numref = size(data, 2);
if H5T.equal(tid, 'H5T_STD_REF_OBJ')
    reftype = H5ML.get_constant_value('H5R_OBJECT');
    refobj = types.untyped.ObjectView.empty(numref,0);
else
    reftype = H5ML.get_constant_value('H5R_DATASET_REGION');
    refobj = types.untyped.RegionView.empty(numref,0);
end

for i=1:numref
    refobj(i) = parseSingleRef(did, reftype, data(:,i));
end
end

function refobj = parseSingleRef(did, reftype, data)
target = H5R.get_name(did, reftype, data);

if isempty(target)
    %if data is all zeros or if the ref does not exist, this is possible.
    % this can happen on normal use (say, selecting out of a dataset of
    % references
    refobj = [];
    return;
end
%% H5R_OBJECT
if reftype == H5ML.get_constant_value('H5R_OBJECT')
    refobj = types.untyped.ObjectView(target);
    return;
end

%% H5R_DATASET_REGION
region = [];
sid = H5R.get_region(did, reftype, data);
sel_type = H5S.get_select_type(sid);
switch sel_type
    %At the time of writing, nwb doesn't seem to use point selection,
    %instead opting for size-one hyperslabs for indexing.
    %However, since the format documentation doesn't specify which one
    %will be used, I'll leave the point selection functionality intact.
    %In the event of point-selection being the norm for nwb, you will
    %only have to implement a way to export the regionview.
    case {H5ML.get_constant_value('H5S_SEL_POINTS')...
            H5ML.get_constant_value('H5S_SEL_HYPERSLABS')}
        if sel_type == H5ML.get_constant_value('H5S_SEL_POINTS')
            getnum = @H5S.get_select_elem_npoints;
            getlist = @H5S.get_select_elem_pointlist;
        else
            getnum = @H5S.get_select_hyper_nblocks;
            getlist = @H5S.get_select_hyper_blocklist;
        end
        
        region = rot90(getlist(sid, 0, getnum(sid)), -1);
        region = mat2cell(region, ones(size(region,1)/2,1)+1);
    case {H5ML.get_constant_value('H5S_SEL_ALL')...
            H5ML.get_constant_value('H5S_SEL_NONE')}
        region = {};
end
H5S.close(sid);
refobj = types.untyped.RegionView(target, region);
end