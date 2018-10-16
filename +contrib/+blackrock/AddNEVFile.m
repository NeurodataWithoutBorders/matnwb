function file = AddNEVFile(file, nev, name, starting_time)

if ~exist('name','var') || isempty(name)
    name = 'spikes';
end

if ~exist('starting_time', 'var') || isempty(starting_time)
    starting_time = 0.0;
end

if ischar(nev)
    spikes_data = openNEV(nev);
else
    spikes_data = nev;
end

Spikes = spikes_data.Data.Spikes;
spike_loc = ['/acquisition/' name '/spike_times'];

UnitTimes = util.createUnitTimes(Spikes.Electrode, ...
    double(Spikes.TimeStamp + starting_time), spike_loc);

file.acquisition.set(name, UnitTimes);