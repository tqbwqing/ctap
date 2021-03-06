function [figh, startSamp] = plot_raw(EEG, varargin)
%PLOT_RAW - Plot EEG data to a static 2D figure
%
% Description:
%   Plots raw data, can be channels or components depending on what is passed
% 
% Syntax:
%   [figH, startSamp] = plot_raw(EEG, varargin)
% 
% Input:
%   'EEG'       struct, EEGLAB structured data
% 
% varargin:
%   'dataname'      string, what to call data rows, default = 'Channels'
%   'startSample'   integer, first sample to plot, default = NaN
%   'secs'          integer, seconds to plot from min to max, default = [0 16]
%   'channels'      cell string array, labels, default = {EEG.chanlocs.labels}
%   'markChannels'  cell string array, labels of bad channels, default = {}
%   'plotEvents'    boolean, add labels & vertical dash lines, default = true
%   'figVisible'    on|off, default = off
%   'eegname'       string, default = EEG.setname
%   'paperwh'       vector, output dimensions in cm - if set to 0,0 uses screen 
%                           dimensions, if either dimension is negative then
%                           calculates from data, default = [0 0]
%   'shadingLimits' vector, beginning and end sample to be shaded, 
%                           default = [NaN NaN]
% 
%
% See also:
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

p.addParameter('dataname', 'Channels', @isstr); %what is data called?
p.addParameter('startSample', NaN, @isnumeric); %start of plotting in samples
p.addParameter('secs', [0 16], @isnumeric); %how much to plot
p.addParameter('channels', {EEG.chanlocs.labels}, @iscellstr); %channels to plot
p.addParameter('markChannels', {}, @iscellstr); %channels to plot in red
p.addParameter('plotEvents', true, @islogical);
p.addParameter('figVisible', 'on', @isstr);
p.addParameter('eegname', EEG.setname, @isstr);
p.addParameter('paperwh', [0 0], @isnumeric);
p.addParameter('shadingLimits', [NaN NaN], @isnumeric); % in samples

p.parse(EEG, varargin{:});
Arg = p.Results;


%% Initialize
if isscalar(Arg.secs), Arg.secs = [0 Arg.secs]; end
Arg.secs = sort(Arg.secs);
% get rid of missing channels
missingChannels = setdiff(Arg.channels, {EEG.chanlocs.labels});
if ~isempty(missingChannels)
    % some channels could not be found
    fprintf('plot_raw: %s ''%s'' are missing...',...
            Arg.dataname, strjoin(missingChannels,'; '));   
end
CHANNELS = intersect(Arg.channels, {EEG.chanlocs.labels}); 
Arg.markChannels = intersect(CHANNELS, Arg.markChannels);
% Find channel indices (order matters!)
[~, CHANIDX] = ismember(CHANNELS, {EEG.chanlocs.labels});

% sort channels such that rows of 'eegdata' and CHANNELS match
[CHANIDX, si] = sort(CHANIDX);
CHANNELS = CHANNELS(si);


%% Setup Plot
%Epoched or continuous?
switch ndims(EEG.data)
    case 3
        [~, col, eps] = size(EEG.data);
        eegdata = EEG.data(CHANIDX, 1:col * eps);
        Arg.secs(2) = min([Arg.secs(2) (col * eps) / EEG.srate]);
    case 2
        eegdata = EEG.data(CHANIDX, :);
        Arg.secs(2) = min([Arg.secs(2) EEG.xmax]);
end

%get the data duration
dur = floor(min([EEG.srate * diff(Arg.secs),...
                 size(eegdata, 2) - min(Arg.shadingLimits)]));
if dur == 0
    warning('plot_raw:duration_zero', 'Duration was 0 - no plot made')
    return
end
if isnan(Arg.startSample)
    Arg.startSample = ceil(rand(1) * ((size(eegdata, 2) - dur) + 1));
elseif ~isinteger(Arg.startSample)
    %set Arg.startSample to integer, as EEG latencies are often double
    Arg.startSample = int64(Arg.startSample);
end

t = linspace(0, diff(Arg.secs), dur);
sig = eegdata(:, Arg.startSample:Arg.startSample + dur - 1);
% calculate shift
mi = min(sig, [], 2);
match = abs(mi) < 1e-4;
mi(match) = mean(mi); %to get space around low variance channels

ma = max(sig, [], 2);
match = abs(ma) < 1e-4;
ma(match) = mean(ma); %to get space around low variance channels

shift = cumsum([0; abs(ma(1:end - 1)) + abs(mi(2:end))]);
shift = repmat(shift, 1, round(dur));
sig = sig + shift;


%% fix page size and associated dimensions
% IF paper width+height has been specified as 0,0 then use screen dims
if sum(Arg.paperwh) == 0
    %ScreenSize is a four-element vector: [left, bottom, width, height]:
    figh = figure('Position', get(0,'ScreenSize'),...
                  'Visible', Arg.figVisible);
else
    %IF paper width or height is set as negative, estimate from data dimensions
    if Arg.paperwh(1) < 0
        Arg.paperwh(1) = ceil((log2(diff(Arg.secs)) + 1) .* 4);
    end
    if Arg.paperwh(2) < 0
        Arg.paperwh(2) = numel(CHANNELS) * 0.8;
    end
    figh = figure('PaperType', '<custom>',...
                  'PaperUnits', 'centimeters',...
                  'PaperPositionMode', 'manual',...
                  'PaperPosition', round([0 0 Arg.paperwh]),...
                  'Visible', Arg.figVisible);
end


%% plot EEG data
% rows must be plotted one by one, otherwise ordering information is lost!
hold on;
for i = 1:size(eegdata, 1)
    ploh = plot(t, sig(i, :), 'b');
    if ismember(CHANNELS{i}, Arg.markChannels)% color marked channels
        set(ploh, 'Color', [1 0 0]);
    end
end
hold off;


%% edit axes & prettify
set(gca, 'YTick', mean(sig, 2), 'YTickLabel', CHANNELS)
grid on
if Arg.plotEvents && ~isempty(EEG.event)
    ylim([mi(1) 1.1*max(max(sig))])
else
    ylim([mi(1) max(max(sig))])
end
xlim(Arg.secs)
xbds = double(get(gca, 'xlim'));
ybds = double(get(gca, 'ylim'));
top = ybds(2);
 
%draw a y-axis scalebar at 10% of the total range of the y-axis
sbar = ybds(1) + (ybds(2) - ybds(1)) / 10;
sbr100 = ybds(1) + 100; %plus another one at 100 uV
line(xbds(2) .* [1.02 1.02], [ybds(1) sbar], 'color', 'b', 'clipping', 'off')
line(xbds(2) .* [1 1.04], [ybds(1) ybds(1)], 'color', 'b', 'clipping', 'off')
line(xbds(2) .* [1 1.04], [sbar sbar], 'color', 'b', 'clipping', 'off')
line(xbds(2) .* [1 1.04], [sbr100 sbr100], 'color', 'r', 'clipping', 'off')
text(xbds(2) * 1.02, sbar, '\muV', 'VerticalAlignment', 'bottom')
text(xbds(2) * 1.022, sbar, num2str(round(sbar)), 'VerticalAlignment', 'top')
if sbar < 90 || sbar > 110
    text(xbds(2) * 1.022, ybds(1) + 100, '100', 'color', 'r'...
        , 'VerticalAlignment', 'bottom')
end

% make shaded area
set(figh, 'Color', 'w')
if ~isnan(Arg.shadingLimits(1))
    x = (Arg.shadingLimits(1) - Arg.startSample) / EEG.srate;
    y = ybds(1);
    w = (Arg.shadingLimits(2) - Arg.shadingLimits(1)) / EEG.srate;
    h = ybds(2) - ybds(1);
    rectangle('Position', [x, y, w, h], 'EdgeColor', 'red', 'LineWidth', 2);
end


%% plot events
if Arg.plotEvents && ~isempty(EEG.event)
    evlat = int64(cell2mat({EEG.event.latency}));
    evlatidx = (evlat >= Arg.startSample) & ...
               (evlat < Arg.startSample + dur - 1);

    if any(evlatidx) %note: to plot, we need events in range to plot
        evplot = EEG.event(evlatidx);
        peek = evplot(find(ismember({evplot.type}, 'peeks'),1));
        evplot = evplot(~ismember({evplot.type}, 'peeks'));
        evplottyp = {evplot.type peek.label};
        evplotlat = (double([[evplot.latency] peek.latency]) -...
            double(Arg.startSample)) ./ EEG.srate;
        for i = 1:numel(evplotlat)
            line([evplotlat(i) evplotlat(i)], ybds...
                    , 'color', 'k', 'LineWidth', 1, 'LineStyle', '--')
            t = text(evplotlat(i), double(max(ybds)), evplottyp{i}...
                    , 'BackgroundColor', 'none' ... %[0.9 0.9 0.9]...
                    , 'Rotation', -90 ...
                    , 'Interpreter', 'none'...
                    , 'VerticalAlignment', 'bottom'...
                    , 'HorizontalAlignment', 'left');
        end
        top = t.Extent;
        top = top(2) + top(4);
    end
end
startSamp = Arg.startSample;


%% TITLE
title( sprintf('%s -\n raw %s', Arg.eegname, Arg.dataname),...
    'Position', [xbds(2)/2 top],...
    'VerticalAlignment', 'bottom', ...
    'Interpreter', 'none');


%% FONT ELEMENTS
%Determine y-axis-relative proportion & fix size of everything
fsz = 0.5 * (1 / Arg.paperwh(2));
set(findall(figh, '-property', 'FontUnits'), 'FontUnits', 'normalized')
set(findall(figh, '-property', 'FontSize'), 'FontSize', fsz)

% do the axis tick-labels so there is no overlap
if length(CHANIDX) > 1
    %todo (ben): The follwing can be done only if there are more than one 
    % channel to plot. Is this hacky fix ok?
    fsz = 1 / ((ybds(2) - ybds(1)) / min(diff(mean(sig, 2))));
    set(gca, 'FontSize', fsz)
end
%ONLY IN r2016:: do the Y-AXIS tick-labels so there is no overlap
% ax = ancestor(ploh, 'axes');
% yrule = ax.YAxis;
% yrule.FontSize = fsz;

%AXIS LABELS
xlabel( sprintf('Time\n[samples=%d:%d - seconds=%1.0f:%1.0f]'...
    , Arg.startSample, Arg.startSample+dur...
    , Arg.startSample / (EEG.srate), (Arg.startSample+dur) / (EEG.srate)) )
ylabel(Arg.dataname)


end % plot_raw()
