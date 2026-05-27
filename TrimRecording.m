function [datatotrim] = TrimRecording(time,datatotrim,datatype,TrimStart,TrimEnd)
%A Wolff 15/2/21
%% Function to trim secs from start and end of recording to remove artifacts
%timearray = timearray of stream data
%datatotrim = array of data you want to trim
%datatype =  string: 'stream or epoc'
%TrimStart  = end time of trim @start of recording (in s)
%TrimEnd = start time of trim @end of recording (in s)


%% find timepoints to trim @start
if ~isnan(TrimStart) %if there are values to trim start of recording
    temp = 1;
    temp2 = find(time <= TrimStart,1,'first');
    if ~isempty(temp2)
    trimindx_S = (temp:temp2);
    trimstartflag = true;
    else 
    trimstartflag = false;
    end
else
    trimstartflag = false;
end
    clear temp temp2
    
%% find timepoints to trim @end

if ~isnan(TrimEnd) %if there are values to trim end of recording
    temp = find(time <= (time(end)-TrimEnd),1,'last');
    temp2 = (length(time));
    trimindx_E = (temp+1:temp2);
    trimendflag = true;
else
    trimendflag = false;
end
    clear temp temp2

%% Trim data and time arrays
if trimendflag % trim end first so that indx still valid for end points

    if strcmp(datatype,'streams')
        datatotrim.data(trimindx_E) = []; %trim stream data using indx from time array
    else
    %trim events
    temp = find(datatotrim.offset >= time(trimindx_E(1)),1, 'first');%find the last offset onset of event (ie.complete event) before data should be trimmed
    if ~isempty(temp)
    datatotrim.onset (temp:end) = [];
    datatotrim.offset(temp:end) = [];
    datatotrim.data(temp:end) = [];
    clear temp
    end
    end    
end

if trimstartflag
    if strcmp(datatype,'streams')
    datatotrim.data(trimindx_S) = [];
    else
    %trim events
    temp = find(datatotrim.onset < time(trimindx_S(end)),1,'first');%find the first onset of event 1 after data has been trimmed
    if ~isempty(temp) 
    datatotrim.onset (1:temp) = [];
    datatotrim.offset(1:temp) = [];
    datatotrim.data(1:temp) = [];
    clear temp
    end
    end
end
end
    