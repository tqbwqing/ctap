function [EEG, varargout] = ctapeeg_load_chanlocs(EEG, varargin)
%CTAPEEG_LOAD_CHANLOCS imports channels locations from a given file.
%
% SYNTAX
%   [EEG, varargout] = ctapeeg_load_chanlocs(EEG, varargin)
% 
% INPUT
%   'EEG'       eeglab data struct to process
% 
% VARARGIN
%   'locs'          string, filename pointing to a channel locations file
%                   Default = ''
%   'filetype'      string, type of chanlocs file
%                   Default = ''
%   'format'        string, IF custom chanlocs THEN format must be defined
%                   Default = ''
%   'skiplines'     integer, number header lines for custom chanlocs
%                   Default = 0
%   'writemissing'  true|false, IF for all channels chanlocs file doesn't match
%                   EEG.chanlocs by label, write by index
%                   Default = true
%
% OUTPUT
%   'EEG'       struct, modified input EEG
% VARARGOUT
%   {1}         struct, the complete list of arguments actually used
%   {2}         struct, channel location data
%
% NOTE
%
% CALLS    readlocs, set_channel_locations
%
% Version History:
% 20.10.2014 Created (Benjamin Cowley, FIOH)
%
% Copyright(c) 2015 FIOH:
% Benjamin Cowley (Benjamin.Cowley@ttl.fi), Jussi Korpela (jussi.korpela@ttl.fi)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Check input
sbf_check_input() % parse the varargin, set defaults

%% The main work: Import channel locations
if strcmp(Arg.filetype,'custom') == 1
    if isempty(Arg.format) || isempty(Arg.skiplines)
        error('ctapeeg_load_chanlocs:bad_param',...
            'Missing format or header for custom chanlocs!');
    end
    filelocs = readlocs(Arg.locs, 'filetype', Arg.filetype,...
                  'format', Arg.format, 'skiplines', Arg.skiplines);
elseif ~isempty(Arg.filetype)
    filelocs = readlocs(Arg.locs, 'filetype', Arg.filetype);
else
    try filelocs = readlocs(Arg.locs); 
    catch ME,
        error('ctapeeg_load_chanlocs:readlocs_fail', ME.message);
    end
end

if isempty(EEG.chanlocs)
    %no channel information present -> use channel locations as given
    EEG.chanlocs = filelocs;
else
    %Channel names available -> matching data to channels by channel name
    EEG = set_channel_locations(EEG, filelocs, Arg.writemissing);
end

varargout{1} = Arg;
varargout{2} = filelocs;


%% Sub-functions
    function sbf_check_input() % parse the varargin, set defaults
        % Unpack and store varargin
        if isempty(varargin)
            vargs = struct;
        elseif numel(varargin) > 1 %(assume parameter/name pairs)
            vargs = cell2struct(varargin(2:2:end), varargin(1:2:end), 2);
        else
            vargs = varargin{1}; %(assume a struct wrapped in a cell)
        end

        % If desired, the default values can be changed here:
        Arg.locs = '';
        Arg.filetype = '';
        Arg.format = '';
        Arg.skiplines = 0;
        Arg.writemissing = true;

        % Arg fields are canonical, vargs data is canonical: intersect-join
        Arg = intersect_struct(Arg, vargs);
        
        if exist(Arg.locs, 'file') == 0
            error('ctapeeg_load_chanlocs:fileNotFound',...
                'Cannot find channel locations file: %s', Arg.locs);
        end

    end

end % ctapeeg_load_chanlocs()
