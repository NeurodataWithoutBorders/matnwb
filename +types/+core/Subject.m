classdef Subject < types.core.NWBContainer & types.untyped.GroupClass
% SUBJECT - Information about the animal or person from which the data was measured.
%
% Required Properties:
%  None


% OPTIONAL PROPERTIES
properties
    age; %  (char) Age of subject. Can be supplied instead of 'date_of_birth'.
    age_reference = "birth"; %  (char) Age is with reference to this event. Can be 'birth' or 'gestational'. If reference is omitted, 'birth' is implied.
    date_of_birth; %  (datetime) Date of birth of subject. Can be supplied instead of 'age'.
    description; %  (char) Description of subject and where subject came from (e.g., breeder, if animal).
    genotype; %  (char) Genetic strain. If absent, assume Wild Type (WT).
    sex; %  (char) Gender of subject.
    species; %  (char) Species of subject.
    strain; %  (char) Strain of subject.
    subject_id; %  (char) ID of animal/person used/participating in experiment (lab convention).
    weight; %  (char) Weight at time of experiment, at time of surgery and at other important times.
end

methods
    function obj = Subject(varargin)
        % SUBJECT - Constructor for Subject
        %
        % Syntax:
        %  subject = types.core.SUBJECT() creates a Subject object with unset property values.
        %
        %  subject = types.core.SUBJECT(Name, Value) creates a Subject object where one or more property values are specified using name-value pairs.
        %
        % Input Arguments (Name-Value Arguments):
        %  - age (char) - Age of subject. Can be supplied instead of 'date_of_birth'.
        %
        %  - age_reference (char) - Age is with reference to this event. Can be 'birth' or 'gestational'. If reference is omitted, 'birth' is implied.
        %
        %  - date_of_birth (datetime) - Date of birth of subject. Can be supplied instead of 'age'.
        %
        %  - description (char) - Description of subject and where subject came from (e.g., breeder, if animal).
        %
        %  - genotype (char) - Genetic strain. If absent, assume Wild Type (WT).
        %
        %  - sex (char) - Gender of subject.
        %
        %  - species (char) - Species of subject.
        %
        %  - strain (char) - Strain of subject.
        %
        %  - subject_id (char) - ID of animal/person used/participating in experiment (lab convention).
        %
        %  - weight (char) - Weight at time of experiment, at time of surgery and at other important times.
        %
        % Output Arguments:
        %  - subject (types.core.Subject) - A Subject object
        
        varargin = [{'age_reference' 'birth'} varargin];
        obj = obj@types.core.NWBContainer(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'age',[]);
        addParameter(p, 'age_reference',[]);
        addParameter(p, 'date_of_birth',[]);
        addParameter(p, 'description',[]);
        addParameter(p, 'genotype',[]);
        addParameter(p, 'sex',[]);
        addParameter(p, 'species',[]);
        addParameter(p, 'strain',[]);
        addParameter(p, 'subject_id',[]);
        addParameter(p, 'weight',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.age = p.Results.age;
        obj.age_reference = p.Results.age_reference;
        obj.date_of_birth = p.Results.date_of_birth;
        obj.description = p.Results.description;
        obj.genotype = p.Results.genotype;
        obj.sex = p.Results.sex;
        obj.species = p.Results.species;
        obj.strain = p.Results.strain;
        obj.subject_id = p.Results.subject_id;
        obj.weight = p.Results.weight;
        if strcmp(class(obj), 'types.core.Subject')
            cellStringArguments = convertContainedStringsToChars(varargin(1:2:end));
            types.util.checkUnset(obj, unique(cellStringArguments));
        end
    end
    %% SETTERS
    function set.age(obj, val)
        obj.age = obj.validate_age(val);
    end
    function set.age_reference(obj, val)
        obj.age_reference = obj.validate_age_reference(val);
        obj.postset_age_reference()
    end
    function postset_age_reference(obj)
        if isempty(obj.age) && ~isempty(obj.age_reference)
            obj.warnIfAttributeDependencyMissing('age_reference', 'age')
        end
    end
    function set.date_of_birth(obj, val)
        obj.date_of_birth = obj.validate_date_of_birth(val);
    end
    function set.description(obj, val)
        obj.description = obj.validate_description(val);
    end
    function set.genotype(obj, val)
        obj.genotype = obj.validate_genotype(val);
    end
    function set.sex(obj, val)
        obj.sex = obj.validate_sex(val);
    end
    function set.species(obj, val)
        obj.species = obj.validate_species(val);
    end
    function set.strain(obj, val)
        obj.strain = obj.validate_strain(val);
    end
    function set.subject_id(obj, val)
        obj.subject_id = obj.validate_subject_id(val);
    end
    function set.weight(obj, val)
        obj.weight = obj.validate_weight(val);
    end
    %% VALIDATORS
    
    function val = validate_age(obj, val)
        val = types.util.checkDtype('age', 'char', val);
        types.util.validateShape('age', {[1]}, val)
    end
    function val = validate_age_reference(obj, val)
        val = types.util.checkDtype('age_reference', 'char', val);
        types.util.validateShape('age_reference', {[1]}, val)
    end
    function val = validate_date_of_birth(obj, val)
        val = types.util.checkDtype('date_of_birth', 'datetime', val);
        types.util.validateShape('date_of_birth', {[1]}, val)
    end
    function val = validate_description(obj, val)
        val = types.util.checkDtype('description', 'char', val);
        types.util.validateShape('description', {[1]}, val)
    end
    function val = validate_genotype(obj, val)
        val = types.util.checkDtype('genotype', 'char', val);
        types.util.validateShape('genotype', {[1]}, val)
    end
    function val = validate_sex(obj, val)
        val = types.util.checkDtype('sex', 'char', val);
        types.util.validateShape('sex', {[1]}, val)
    end
    function val = validate_species(obj, val)
        val = types.util.checkDtype('species', 'char', val);
        types.util.validateShape('species', {[1]}, val)
    end
    function val = validate_strain(obj, val)
        val = types.util.checkDtype('strain', 'char', val);
        types.util.validateShape('strain', {[1]}, val)
    end
    function val = validate_subject_id(obj, val)
        val = types.util.checkDtype('subject_id', 'char', val);
        types.util.validateShape('subject_id', {[1]}, val)
    end
    function val = validate_weight(obj, val)
        val = types.util.checkDtype('weight', 'char', val);
        types.util.validateShape('weight', {[1]}, val)
    end
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.core.NWBContainer(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        if ~isempty(obj.age)
            if startsWith(class(obj.age), 'types.untyped.')
                refs = obj.age.export(fid, [fullpath '/age'], refs);
            elseif ~isempty(obj.age)
                io.writeDataset(fid, [fullpath '/age'], obj.age);
            end
        end
        if ~isempty(obj.age) && ~isa(obj.age, 'types.untyped.SoftLink') && ~isa(obj.age, 'types.untyped.ExternalLink') && ~isempty(obj.age_reference)
            io.writeAttribute(fid, [fullpath '/age/reference'], obj.age_reference);
        end
        if ~isempty(obj.date_of_birth)
            if startsWith(class(obj.date_of_birth), 'types.untyped.')
                refs = obj.date_of_birth.export(fid, [fullpath '/date_of_birth'], refs);
            elseif ~isempty(obj.date_of_birth)
                io.writeDataset(fid, [fullpath '/date_of_birth'], obj.date_of_birth);
            end
        end
        if ~isempty(obj.description)
            if startsWith(class(obj.description), 'types.untyped.')
                refs = obj.description.export(fid, [fullpath '/description'], refs);
            elseif ~isempty(obj.description)
                io.writeDataset(fid, [fullpath '/description'], obj.description);
            end
        end
        if ~isempty(obj.genotype)
            if startsWith(class(obj.genotype), 'types.untyped.')
                refs = obj.genotype.export(fid, [fullpath '/genotype'], refs);
            elseif ~isempty(obj.genotype)
                io.writeDataset(fid, [fullpath '/genotype'], obj.genotype);
            end
        end
        if ~isempty(obj.sex)
            if startsWith(class(obj.sex), 'types.untyped.')
                refs = obj.sex.export(fid, [fullpath '/sex'], refs);
            elseif ~isempty(obj.sex)
                io.writeDataset(fid, [fullpath '/sex'], obj.sex);
            end
        end
        if ~isempty(obj.species)
            if startsWith(class(obj.species), 'types.untyped.')
                refs = obj.species.export(fid, [fullpath '/species'], refs);
            elseif ~isempty(obj.species)
                io.writeDataset(fid, [fullpath '/species'], obj.species);
            end
        end
        if ~isempty(obj.strain)
            if startsWith(class(obj.strain), 'types.untyped.')
                refs = obj.strain.export(fid, [fullpath '/strain'], refs);
            elseif ~isempty(obj.strain)
                io.writeDataset(fid, [fullpath '/strain'], obj.strain);
            end
        end
        if ~isempty(obj.subject_id)
            if startsWith(class(obj.subject_id), 'types.untyped.')
                refs = obj.subject_id.export(fid, [fullpath '/subject_id'], refs);
            elseif ~isempty(obj.subject_id)
                io.writeDataset(fid, [fullpath '/subject_id'], obj.subject_id);
            end
        end
        if ~isempty(obj.weight)
            if startsWith(class(obj.weight), 'types.untyped.')
                refs = obj.weight.export(fid, [fullpath '/weight'], refs);
            elseif ~isempty(obj.weight)
                io.writeDataset(fid, [fullpath '/weight'], obj.weight);
            end
        end
    end
end

end