function EEG = ctapeeg_add_regular_events(EEG, evLength, evOverlap, evType, varargin)
%CTAPEEG_ADD_REGULAR_EVENTS - Add events to EEG
%
% Description:
%   Add regularly spaced events to EEG.event to enable computations.
%
% Syntax:
%   EEG = ctapeeg_add_cseg(EEG, evLength, evOverlap, evType);
%
% Inputs:
%   EEG         struct, EEGLAB struct, non-epoched data
%   evLength   [1,1] numeric, Event length in seconds
%   evOverlap  [1,1] numeric, Event overlap percentage using range [0,1]
%   evType      string, Event type string for the new events
%
%   varargin    Keyword-value pairs
%   Keyword         Type, description, values
%   startAt str, Event type string for an event that is to be
%           considered time zero when adding the events
%   stopAt  str, Event type string for an event that is to be
%           considered end of generation range       
%
% Outputs:
%   EEG         struct, EEGLAB struct with new events of evLength at
%               with possible overlap.
%
% Assumptions:
%
% References:
%
% Example:
%
% Notes:
%   Assumes continuous time. Does not check for the existence of boundary
%   events within the generated segments.
%
% See also:
%
% Version History:
% 2015 Jussi Korpla, FIOH, jussi.korpela@ttl.fi
%
% Copyright(c) 2015 FIOH:
% Benjamin Cowley (Benjamin.Cowley@ttl.fi), Jussi Korpela (jussi.korpela@ttl.fi)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Parse input arguments and set varargin defaults
p = inputParser;

p.addRequired('EEG', @isstruct);
p.addRequired('evLength', @isnumeric);
p.addRequired('evOverlap', @isnumeric);
p.addRequired('evType', @ischar);

p.addParameter('startAt', '', @ischar);
p.addParameter('stopAt', '', @ischar);

p.parse(EEG, evLength, evOverlap, evType, varargin{:});
Arg = p.Results;


%% Find a range to add events to
fprintf('ctapeeg_add_regular_events: adding events of type ''%s''.', evType);

startEventInd = find(ismember({EEG.event.type}, Arg.startAt));
if isempty(startEventInd)
    disp('Starting from first sample.');
    startsample = 1;    
else
    if length(startEventInd) > 1
        warning('ctapeeg_add_regular_events:eventInconsistency'...
            , 'Several range start events found. Taking the first one.'); 
        startEventInd = startEventInd(1);
    end
    startsample = EEG.event(startEventInd).latency;
end

stopEventInd = find(ismember({EEG.event.type}, Arg.stopAt));
if isempty(stopEventInd)
    disp('Stopping at last sample.');
    stopsample = EEG.pnts;

else
    if length(stopEventInd) > 1
        warning('ctapeeg_add_regular_events:eventInconsistency'...
            , 'Several range stop events found. Taking last one.');
        stopEventInd = stopEventInd(end); 
    end
    stopsample = EEG.event(stopEventInd).latency;
end


%% Generate segments
csegArr = generate_segments(...
            stopsample-startsample,...
            floor(evLength*EEG.srate),...
            evOverlap);
durArr = csegArr(:,2)-csegArr(:,1)+1;

        
%% Add segments as 'cseg' events
event = eeglab_create_event(startsample+csegArr(:,1)-1,...
                            evType,...
                            'duration', num2cell(durArr));
%EEG.event latency and duration are passed and stored in samples.


% Merge new events with existing data
EEG.event = eeglab_merge_event_tables(event, EEG.event,...
                                      'ignoreDiscontinuousTime');

EEG = eeg_checkset(EEG, 'eventconsistency');

end %EOF