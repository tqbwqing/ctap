function plot_histogram(data, varargin)
% Note: many parts of this function copied from EEGLABs signalstat.m
% TODO(feature-request)(JKOR): Add some less ad-hoc measure of trimmed mean and sd 


%% Parse input arguments and set varargin defaults
p = inputParser;
p.addRequired('data', @isnumeric);
p.addParameter('title', 'Histogram & Gaussian fit', @isstr);
p.addParameter('xlabel', 'data value', @isstr);
p.addParameter('ylabel', 'Count / PDF value', @isstr);
p.addParameter('plotTitle',  true, @islogical);
p.addParameter('plotLabels',  true, @islogical);
p.addParameter('plotYLabels', true, @islogical);
p.addParameter('tailPrc',  0.05, @isnumeric);
p.addParameter('xlim', [NaN, NaN], @isnumeric);
p.addParameter('ylim', [NaN, NaN], @isnumeric);
p.addParameter('plotLegend', false, @islogical);

p.parse(data, varargin{:});
Arg = p.Results;


%% Make data a vector
if ~isvector(data)
    data = data(:);
end
data = double(data);


%% Computed parameters
pnts = length(data);
nbins = max(50, min(500,round(pnts/100)));


%% Basic properties
cte = mean(data);
SD = std(data);


%% Basic properties without the highest and lowest 'percent'/2 % of data
zlow = quantile(data, (Arg.tailPrc / 2));   % low  quantile
zhi  = quantile(data, 1 - Arg.tailPrc / 2); % high quantile
tndx = find((data >= zlow & data <= zhi & ~isnan(data)));

tM = mean(data(tndx)); %#ok<NASGU> % mean with excluded Arg.tailPrc/2*100
                                   % of highest and lowest values
tSD = std(data(tndx)); % trimmed SD


%% Histogram data
%[nel,binpos]=hist(data,nbins);
%bar(binpos, nel, 'FaceColor', [200, 200, 250]/255);
%dx=binpos(2)-binpos(1); % bin width

h = histogram(data, nbins,...
              'EdgeColor', 'none', ...
              'FaceColor', [180, 180, 220]/255);
binpos = h.BinEdges(1:end-1);
dx = h.BinWidth;


%% Fits to normal distribution
datafit = norm_pdf(binpos, cte, SD);       % estimated normpdf with sd
datafit = datafit * pnts * dx;

tdatafit = norm_pdf(binpos, cte, tSD);     % estimated normpdf with trimmed sd
tdatafit = tdatafit * pnts * dx;
%figure('Visible', 'off');


%% Plot histogram

if isnan(Arg.xlim(1))
    Arg.xlim = get(gca, 'XLim');
end
if isnan(Arg.ylim(1))
    Arg.ylim = get(gca, 'YLim');
    %sometimes the plots give way too much vertical space, squashing the hist
    top = max(max(h.Values), max(tdatafit));
    o = floor(single(log(abs(top))./log(10))); % get the order
    if top < 10^(o) * 2 % if top is less than 20% of the higher order
        o = o-1;
    end
    top = (ceil(top / (10^o))) * 10^o; 
    if Arg.ylim(2) > top
        Arg.ylim(2) = top;
        set(gca, 'YLim', Arg.ylim)
    end
end

if Arg.plotTitle, title(Arg.title); end
if Arg.plotLabels
    xlabel(Arg.xlabel);
    if Arg.plotYLabels
        ylabel(Arg.ylabel);
    end
end

% Overplotting a normal distribution using sd (in red)
hold on;
h1 = plot(binpos, datafit, 'r', 'LineWidth', 1);
set(gca, 'XLim', Arg.xlim)

% Overplotting a normal distribution using trimmed sd (in black)
h2 = plot(binpos, tdatafit, 'k');

if zlow > Arg.xlim(1)
    plot([zlow zlow], [0 Arg.ylim(2)/2], 'k', 'LineWidth', 1) % low  percentile
    text(zlow, Arg.ylim(2)/2, sprintf('%2.1f%%', 100*Arg.tailPrc/2),...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom');
end
if zhi < Arg.xlim(2)
    plot([zhi  zhi], [0 Arg.ylim(2)/2], 'k', 'LineWidth', 1) % high percentile
    text(zhi, Arg.ylim(2)/2, sprintf('%2.1f%%', 100-100*Arg.tailPrc/2),...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom');
end

set(gca, 'XLim', Arg.xlim);

% Overplotting a mean and zero line
h3 = plot([cte cte], Arg.ylim,'b--', 'LineWidth', 1);
set(gca, 'XMinorTick', 'on', 'XLim', Arg.xlim);


if Arg.plotLegend
    tmp = get(gca, 'Position');
    H = [h1 h2 h3];
    l = legend(H, 'gaussian fit', 'trimmed g. fit', 'mean',...
        'Location', 'southoutside', 'Orientation', 'horizontal');
    set(l, 'FontSize', 12)
    legend boxoff
    set(gca, 'Position', tmp)
end

hold off;
