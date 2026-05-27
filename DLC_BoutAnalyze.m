function [outdata] = DLC_BoutAnalyze(f,outdata,processdata,condition,winlabels,wintimes,bouttype)
if strcmp(bouttype,'Approach') || strcmp(bouttype,'Orient')
nsubfields = 2;
else
nsubfields = 1;
end

if nsubfields ==2
    if strcmp(bouttype,'Approach')
        subfields = outdata.UserVals.DLCsetup.Subfields.DistTo;
    else
        subfields = outdata.UserVals.DLCsetup.Subfields.Angle;
    end
end

if nsubfields == 1
Boutdata = outdata.rawdata.DLC{f,1}.(bouttype).Binary; 
Bouton = find(Boutdata == 1);
Boutoff = find(Boutdata == 0);
framefs = 1/outdata.videodata.vidFPS{f,1}; %DLC FPS

avmeasures = {'boutlatency','boutperc','numbouts','duration','bouttime'};
    for av = 1:length(avmeasures)
        outdata.Bouts.(processdata).(bouttype).DLC.plot.(avmeasures{av}).maxval.trial=0.001;
        outdata.Bouts.(processdata).(bouttype).DLC.plot.(avmeasures{av}).minval.trial=0;
        outdata.Bouts.(processdata).(bouttype).DLC.plot.(avmeasures{av}).maxval.mean=0.001;
        outdata.Bouts.(processdata).(bouttype).DLC.plot.(avmeasures{av}).minval.mean=0;
    end
    
for w = 1:length(winlabels)
for c = 1:length(condition)
    
    %find window start and end times
    if ~isnan(wintimes{w}(1)) 
    arraystart = find(outdata.DLC.(processdata).time{f,1} >= wintimes{w}(1),1,'first');
    else
    arraystart = 1;
    end
    if ~isnan(wintimes{w}(2)) 
    arrayend = find(outdata.DLC.(processdata).time{f,1} <= wintimes{w}(2),1,'last');
    else
    arrayend = length(outdata.DLC.(processdata).time{f,1});
    end
    
outdata.Bouts.(processdata).(bouttype).DLC.(condition{c}).(winlabels{w}).time = outdata.DLC.(processdata).time{f,1}(arraystart:arrayend);
    
if isfield(outdata.eventdata.(processdata),(condition{c}))
   
DLCindxdata = outdata.DLC.(processdata).(condition{c}).frameindx{f,1}(:,arraystart:arrayend);
    % boutcount = NaN;
    % bouttime = NaN;
    % boutlatency = NaN;
    % boutperc = NaN;
    % boutdur = NaN;
if ~isempty(DLCindxdata)
    for t = 1:size(DLCindxdata,1)
    boutcount = NaN;
    bouttime = NaN;
    boutlatency = NaN;
    boutperc = NaN;
    boutdur = NaN;
    if ~isnan(DLCindxdata(t,1))
        boutcount = 0; %set to 0 here to distinguish between trails with no bouts vs non existent trials
    %find first bout 
    if outdata.rawdata.DLC{f,1}.paddata
    Boutsnip = NaN(length(DLCindxdata(t,:)),1);
    Boutsnip(1:2:end) = Boutdata(DLCindxdata(t,1:2:end));
    Boutframes = length(Boutsnip) - sum(isnan(Boutsnip));
    else
    Boutsnip = Boutdata(DLCindxdata(t,:)); 
    Boutframes = length(Boutsnip);
    end
    outdata.Bouts.(processdata).(bouttype).DLC.(condition{c}).(winlabels{w}).boutarray{f,1}(t,:) = Boutsnip;
    boutperc = (sum(Boutsnip,'omitnan')/Boutframes)*100;
    bouttime = sum(Boutsnip,'omitnan')*framefs;
  
    if sum(Boutsnip,'omitnan') > 0 %if there are bouts this trial 
        startframe = DLCindxdata(t,1);
        endframe = DLCindxdata(t,end);
        boutindx = 1;
        boutstart = find(Boutsnip == 1,1,'first'); %find the first bout
        boutstart = DLCindxdata(t,boutstart);%ref boutstart to entire array for timestamp indexing
        while ~isempty (boutstart) %continue to cycle through bouts for this window until there are no more
            boutcount = boutcount + 1; %add to boutcount
            if boutstart == startframe %if the first frame is a bout- find the start time and log latency (as negative)and get duration
            boutstart =  find(Boutoff < startframe,1,'last'); %find the last frame before the startframe of this window where there were no bouts and set boutstart to next frame
            boutstart = (Boutoff(boutstart) + 1);
            if isempty(boutstart)%catch for if bout starts at start of video
                boutstart = 1;
            end
            end
            
            if boutindx == 1 %get latency for first bout only
            boutlatency = outdata.rawdata.DLC{f,1}.timestamps(boutstart)-outdata.rawdata.DLC{f,1}.timestamps(startframe);%workout latency  
            end
            %find end of bout
            boutend = find(Boutoff > boutstart,1,'first'); %find first bout off point after start of current bout
            boutend = Boutoff(boutend);
            if boutindx == 1 && ~isempty(boutend)%get duration for first bout only
            boutdur = outdata.rawdata.DLC{f,1}.timestamps(boutend)-outdata.rawdata.DLC{f,1}.timestamps(boutstart);%workout duration of first bout
            end
            boutindx = boutindx+1; %add to indxing for this trial
            %find next bout
            if ~isempty(boutend)
            boutstart = find(Bouton > boutend,1,'first'); %find next bout after current bout end
            else
                boutstart = [];
            end
            if ~isempty(boutstart)
            boutstart = Bouton(boutstart);
            if boutstart > endframe %if this next bout is outside the window
                boutstart = [];
            end
            else
                boutstart = [];
            end
        end
    end
    
    end
    outdata.Bouts.(processdata).(bouttype).DLC.(condition{c}).(winlabels{w}).trialn.trials{f,1}(t,1) = outdata.perievent.(processdata).(condition{c}).trialn{f,1}(t);
    outdata.Bouts.(processdata).(bouttype).DLC.(condition{c}).(winlabels{w}).numbouts.trials{f,1}(t,1) = boutcount;
    outdata.Bouts.(processdata).(bouttype).DLC.(condition{c}).(winlabels{w}).latency.trials{f,1}(t,1) = boutlatency;
    outdata.Bouts.(processdata).(bouttype).DLC.(condition{c}).(winlabels{w}).duration.trials{f,1}(t,1) = boutdur;
    outdata.Bouts.(processdata).(bouttype).DLC.(condition{c}).(winlabels{w}).boutperc.trials{f,1}(t,1) = boutperc;
    outdata.Bouts.(processdata).(bouttype).DLC.(condition{c}).(winlabels{w}).bouttime.trials{f,1}(t,1) = bouttime;
    end
end
else
    outdata.Bouts.(processdata).(bouttype).DLC.(condition{c}).(winlabels{w}).trialn.trials{f,1} = [];
    outdata.Bouts.(processdata).(bouttype).DLC.(condition{c}).(winlabels{w}).numbouts.trials{f,1} = [];
    outdata.Bouts.(processdata).(bouttype).DLC.(condition{c}).(winlabels{w}).latency.trials{f,1} = [];
    outdata.Bouts.(processdata).(bouttype).DLC.(condition{c}).(winlabels{w}).duration.trials{f,1} = [];
    outdata.Bouts.(processdata).(bouttype).DLC.(condition{c}).(winlabels{w}).boutperc.trials{f,1} = [];
    outdata.Bouts.(processdata).(bouttype).DLC.(condition{c}).(winlabels{w}).bouttime.trials{f,1} = [];    
end
end
end

else %for approach and orient

flds = subfields{1,1};
for x = 1:length(flds)
refr = subfields{2}{x};
for r = 1:length(refr)

Boutdata = outdata.rawdata.DLC{f,1}.(bouttype).(flds{x}).(refr{r}).Binary; 
Bouton = find(Boutdata == 1);
Boutoff = find(Boutdata == 0);
framefs = 1/outdata.rawdata.DLC{f,1}.FPS; %DLC FPS

avmeasures = {'boutlatency','boutperc','numbouts','duration','bouttime'};
    for av = 1:length(avmeasures)
        outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).DLC.plot.(avmeasures{av}).maxval.trial=0.001;
        outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).DLC.plot.(avmeasures{av}).minval.trial=0;
        outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).DLC.plot.(avmeasures{av}).maxval.mean=0.001;
        outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).DLC.plot.(avmeasures{av}).minval.mean=0;
    end
    
for w = 1:length(winlabels)
for c = 1:length(condition)
    
    %find window start and end times
    if ~isnan(wintimes{w}(1)) 
    arraystart = find(outdata.DLC.(processdata).time{f,1} >= wintimes{w}(1),1,'first');
    else
    arraystart = 1;
    end
    if ~isnan(wintimes{w}(2)) 
    arrayend = find(outdata.DLC.(processdata).time{f,1} <= wintimes{w}(2),1,'last');
    else
    arrayend = length(outdata.DLC.(processdata).time{f,1});
    end
    
outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).DLC.(condition{c}).(winlabels{w}).time = outdata.DLC.(processdata).time{f,1}(arraystart:arrayend);
    
if isfield(outdata.eventdata.(processdata),(condition{c}))
   
DLCindxdata = outdata.DLC.(processdata).(condition{c}).frameindx{f,1}(:,arraystart:arrayend);

if ~isempty(DLCindxdata)
    for t = 1:size(DLCindxdata,1)
    boutcount = NaN;
    bouttime = NaN;
    boutlatency = NaN;
    boutperc = NaN;
    boutdur = NaN;
    if ~isnan(DLCindxdata(t,1))
        boutcount = 0; %set to 0 here to distinguish between trails with no bouts vs non existent trials
    %find first bout 
    if outdata.rawdata.DLC{f,1}.paddata
    Boutsnip = NaN(length(DLCindxdata(t,:)),1);
    Boutsnip(1:2:end) = Boutdata(DLCindxdata(t,1:2:end));
    Boutframes = length(Boutsnip) - sum(isnan(Boutsnip));
    else
    Boutsnip = Boutdata(DLCindxdata(t,:)); 
    Boutframes = length(Boutsnip);
    end
    outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).DLC.(condition{c}).(winlabels{w}).boutarray{f,1}(t,:) = Boutsnip;
    boutperc = (sum(Boutsnip,'omitnan')/Boutframes)*100;
    bouttime = sum(Boutsnip,'omitnan')*framefs;
  
    if sum(Boutsnip,'omitnan') > 0 %if there are bouts this trial 
        startframe = DLCindxdata(t,1);
        endframe = DLCindxdata(t,end);
        boutindx = 1;
        boutstart = find(Boutsnip == 1,1,'first'); %find the first bout
        boutstart = DLCindxdata(t,boutstart);%ref boutstart to entire array for timestamp indexing
        while ~isempty (boutstart) %continue to cycle through bouts for this window until there are no more
            boutcount = boutcount + 1; %add to boutcount
            if boutstart == startframe %if the first frame is a bout- find the start time and log latency (as negative)and get duration
            boutstart =  find(Boutoff < startframe,1,'last'); %find the last frame before the startframe of this window where there were no bouts and set boutstart to next frame
            boutstart = (Boutoff(boutstart) + 1);
            if isempty(boutstart) %catch for if the bout starts at start of video?
                boutstart = 1;
            end
            end
            
            if boutindx == 1 %get latency for first bout only
            boutlatency = outdata.rawdata.DLC{f,1}.timestamps(boutstart)-outdata.rawdata.DLC{f,1}.timestamps(startframe);%workout latency  
            end
            %find end of bout
            boutend = find(Boutoff > boutstart,1,'first'); %find first bout off point after start of current bout
            boutend = Boutoff(boutend);
            if boutindx == 1 && ~isempty(boutend)%get duration for first bout only
            boutdur = outdata.rawdata.DLC{f,1}.timestamps(boutend)-outdata.rawdata.DLC{f,1}.timestamps(boutstart);%workout duration of first bout
            end
            boutindx = boutindx+1; %add to indxing for this trial
            %find next bout
            if ~isempty(boutend)
            boutstart = find(Bouton > boutend,1,'first'); %find next bout after current bout end
            else
            boutstart = [];
            end
            if ~isempty(boutstart)
            boutstart = Bouton(boutstart);
            if boutstart > endframe %if this next bout is outside the window
                boutstart = [];
            end
            else
                boutstart = [];
            end
        end
    end
    
    end
    outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).DLC.(condition{c}).(winlabels{w}).trialn.trials{f,1}(t,1) = outdata.perievent.(processdata).(condition{c}).trialn{f,1}(t);
    outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).DLC.(condition{c}).(winlabels{w}).numbouts.trials{f,1}(t,1) = boutcount;
    outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).DLC.(condition{c}).(winlabels{w}).latency.trials{f,1}(t,1) = boutlatency;
    outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).DLC.(condition{c}).(winlabels{w}).duration.trials{f,1}(t,1) = boutdur;
    outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).DLC.(condition{c}).(winlabels{w}).boutperc.trials{f,1}(t,1) = boutperc;
    outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).DLC.(condition{c}).(winlabels{w}).bouttime.trials{f,1}(t,1) = bouttime;
    end
end
else
    outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).DLC.(condition{c}).(winlabels{w}).trialn.trials{f,1} = [];
    outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).DLC.(condition{c}).(winlabels{w}).numbouts.trials{f,1} = [];
    outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).DLC.(condition{c}).(winlabels{w}).latency.trials{f,1}= [];
    outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).DLC.(condition{c}).(winlabels{w}).duration.trials{f,1} = [];
    outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).DLC.(condition{c}).(winlabels{w}).boutperc.trials{f,1} = [];
    outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).DLC.(condition{c}).(winlabels{w}).bouttime.trials{f,1} = [];    
end
end
end
end
end
end
end