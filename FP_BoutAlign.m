function [outdata] = FP_BoutAlign(f,outdata,processdata,condition,winlabels,wintimes,bouttype)

switch bouttype
    case 'Freeze'
        boutname = 'freezebout';
    case 'Locomotion'
        boutname = 'locobout';
    case 'Approach'
        boutname = 'approach';
    case 'Orient'
        boutname = 'orient';
end
        

if isfield(outdata.UserVals.(boutname),'FPwin')
    if ~isempty(outdata.UserVals.(boutname).FPwin)
    FPwin = outdata.UserVals.(boutname).FPwin;
    else
    FPwin = [-1 3]; %use default FPwin if none defined
    end
else
FPwin = [-1 3]; %use default FPwin if none defined
end

if strcmp(bouttype,'Approach') || strcmp(bouttype,'Orient')
nsubfields = 2;
else
nsubfields = 1;
end

if nsubfields == 2
    if strcmp(bouttype,'Approach')
        subfields = outdata.UserVals.DLCsetup.Subfields.DistTo;
    else
        subfields = outdata.UserVals.DLCsetup.Subfields.Angle;
    end
end

if nsubfields == 1
Boutdata = outdata.rawdata.DLC{f,1}.(bouttype).Binary; 
boutoff = find(Boutdata == 0);
FPfs = outdata.perievent.fs{f,1};
prebout = FPwin(1);
postbout = FPwin(2);
FPTRANGE = round([prebout*(FPfs),postbout*(FPfs)]);
framefs = 1/FPfs;
    
    avmeasures = {'latency','duration'};
    for av = 1:length(avmeasures)
        outdata.Bouts.(processdata).(bouttype).DLC.plot.(avmeasures{av}).maxval.trial=0.001;
        outdata.Bouts.(processdata).(bouttype).DLC.plot.(avmeasures{av}).minval.trial=0;
        outdata.Bouts.(processdata).(bouttype).DLC.plot.(avmeasures{av}).maxval.mean=0.001;
        outdata.Bouts.(processdata).(bouttype).DLC.plot.(avmeasures{av}).minval.mean=0;
    end
    
    avmeasures = {'raw','zscored'};
    for av = 1:length(avmeasures)
    outdata.Bouts.(processdata).(bouttype).FP.plot.(avmeasures{av}).maxval.trial = 0.001;
    outdata.Bouts.(processdata).(bouttype).FP.plot.(avmeasures{av}).minval.trial = 0;
    outdata.Bouts.(processdata).(bouttype).FP.plot.(avmeasures{av}).maxval.mean = 0.001;
    outdata.Bouts.(processdata).(bouttype).FP.plot.(avmeasures{av}).minval.mean = 0;
    end

for w = 1:length(winlabels)
for c = 1:length(condition)
    preindx=1; %indx for binning data in outfile
    duringindx=1;%indx for binning data in outfile
    noneindx = 1;%indx for binning data in outfile
    outdata.Bouts.(processdata).(bouttype).FP.(condition{c}).(winlabels{w}).time = (FPTRANGE(1)*framefs:framefs:FPTRANGE(2)*framefs);
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
    
if isfield(outdata.eventdata.(processdata),(condition{c}))
    
DLCindxdata = outdata.DLC.(processdata).(condition{c}).frameindx{f,1}(:,arraystart:arrayend);
outdata.Bouts.(processdata).(bouttype).DLC.(condition{c}).(winlabels{w}).boutarray{f,1} = DLCindxdata; 
if ~isempty(DLCindxdata)
    for t = 1:size(DLCindxdata,1)
    if ~isnan(DLCindxdata(t,1))
    %find first bout 
    if outdata.rawdata.DLC{f,1}.paddata
    Boutsnip = NaN(length(DLCindxdata(t,:)),1);
    Boutsnip(1:2:end) = Boutdata(DLCindxdata(t,1:2:end));
    else
    Boutsnip = Boutdata(DLCindxdata(t,:));   
    end
    findstart = find(Boutsnip == 1,1,'first'); %find first bout point in window
    
    if ~isempty(findstart)
        startindx = DLCindxdata(t,findstart);
        boutstarttime =  outdata.rawdata.DLC{f,1}.timestamps(startindx);
        FPindxstart = find(outdata.downsamp.time{f,1}>= boutstarttime,1,'first');
        if ~((FPindxstart+FPTRANGE(1))<0) && ~((FPindxstart+FPTRANGE(2)) > length(outdata.detrended.dFF{f,1})) %do not include if event window extends beyond start/end of recording
        if findstart > 1 %if bout begins in window
        %get latency
        outdata.Bouts.(processdata).(bouttype).DLC.(condition{c}).(winlabels{w}).latency.during.trials{f,1}(duringindx,1) = outdata.rawdata.DLC{f,1}.timestamps(startindx)-outdata.rawdata.DLC{f,1}.timestamps(DLCindxdata(t,1)); %get latency
%         outdata.Bouts.(processdata).(bouttype).DLC.(condition{c}).(winlabels{w}).latency.during.trials{f,1}(duringindx,1) = outdata.perievent.(processdata).(condition{c}).trialn{f,1}(t);
%         outdata.Bouts.(processdata).(bouttype).DLC.(condition{c}).(winlabels{w}).latency.all.trials{f,1}(t,2) = outdata.rawdata.DLC{f,1}.timestamps(startindx)-outdata.rawdata.DLC{f,1}.timestamps(DLCindxdata(t,1)); %get latency
        %get FPindx for boutstart
        outdata.Bouts.(processdata).(bouttype).FP.(condition{c}).(winlabels{w}).indx {f,1}.during(duringindx,:)= FPindxstart+FPTRANGE(1):FPindxstart+FPTRANGE(2); 
        outdata.Bouts.(processdata).(bouttype).FP.(condition{c}).(winlabels{w}).raw.trials{f,1}.during(duringindx,:) = outdata.detrended.dFF{f,1}(outdata.Bouts.(processdata).(bouttype).FP.(condition{c}).(winlabels{w}).indx {f,1}.during(duringindx,:));
        outdata.Bouts.(processdata).(bouttype).FP.(condition{c}).(winlabels{w}).Z_dFF.trials{f,1}.during(duringindx,:) = outdata.perievent.(processdata).(condition{c}).Z_dFF.trials{f,1}(t,:);
        outdata.Bouts.(processdata).(bouttype).FP.(condition{c}).(winlabels{w}).trialn{f,1}.during(duringindx,1) = outdata.perievent.(processdata).(condition{c}).trialn{f,1}(t);
        %find end of bout
        boutend = find(boutoff > startindx,1,'first');
        boutend = boutoff(boutend);
        %get duration
        if ~isempty(boutend)
        outdata.Bouts.(processdata).(bouttype).DLC.(condition{c}).(winlabels{w}).duration.during.trials{f,1}(duringindx,1) = outdata.rawdata.DLC{f,1}.timestamps(boutend)-outdata.rawdata.DLC{f,1}.timestamps(startindx); %get duration
        else %set bout duration to NaN if last bout does not end before end of session
        outdata.Bouts.(processdata).(bouttype).DLC.(condition{c}).(winlabels{w}).duration.during.trials{f,1}(duringindx,1) = NaN;
        boutend =length(outdata.rawdata.DLC{f,1}.timestamps); %set boutend to end of session for indx calculation (next line)
        end
        outdata.Bouts.(processdata).(bouttype).DLC.(condition{c}).(winlabels{w}).indx.during{f,1}{duringindx,1} = startindx:boutend; 
        outdata.Bouts.(processdata).(bouttype).DLC.(condition{c}).(winlabels{w}).trialn.during{f,1}(duringindx,1) = outdata.perievent.(processdata).(condition{c}).trialn{f,1}(t);
        duringindx = duringindx+1;
        else
        %find boutstart
        boutstart = find(boutoff < startindx,1,'last');
        boutstart = boutoff(boutstart)+1;
        %get FPindx for boutstart
        boutstarttime =  outdata.rawdata.DLC{f,1}.timestamps(boutstart);
        FPindxstart = find(outdata.downsamp.time{f,1}>= boutstarttime,1,'first');
        if FPindxstart+FPTRANGE(1) > 0 && FPindxstart+FPTRANGE(2) <= length(outdata.detrended.dFF{f,1}) %only save trace if the whole trace exists (excludes events too close to start/end of recording)         
        %get latency
        if boutstart ~= DLCindxdata(t,1)
        outdata.Bouts.(processdata).(bouttype).DLC.(condition{c}).(winlabels{w}).latency.pre.trials{f,1}(preindx,1) = outdata.rawdata.DLC{f,1}.timestamps(boutstart)-outdata.rawdata.DLC{f,1}.timestamps(DLCindxdata(t,1)); %get latency 
        outdata.Bouts.(processdata).(bouttype).DLC.(condition{c}).(winlabels{w}).trialn.pre{f,1}(preindx,1) = outdata.perievent.(processdata).(condition{c}).trialn{f,1}(t);
        outdata.Bouts.(processdata).(bouttype).FP.(condition{c}).(winlabels{w}).indx {f,1}.pre(preindx,:)= FPindxstart+FPTRANGE(1):FPindxstart+FPTRANGE(2);  
        outdata.Bouts.(processdata).(bouttype).FP.(condition{c}).(winlabels{w}).raw.trials{f,1}.pre(preindx,:) = outdata.detrended.dFF{f,1}(outdata.Bouts.(processdata).(bouttype).FP.(condition{c}).(winlabels{w}).indx {f,1}.pre(preindx,:));
        outdata.Bouts.(processdata).(bouttype).FP.(condition{c}).(winlabels{w}).Z_dFF.trials{f,1}.pre(preindx,:) = outdata.perievent.(processdata).(condition{c}).Z_dFF.trials{f,1}(t,:);
        outdata.Bouts.(processdata).(bouttype).FP.(condition{c}).(winlabels{w}).trialn{f,1}.pre(preindx,1) = outdata.perievent.(processdata).(condition{c}).trialn{f,1}(t); 

        else
        outdata.Bouts.(processdata).(bouttype).DLC.(condition{c}).(winlabels{w}).latency.during.trials {f,1}(duringindx,:) = outdata.rawdata.DLC{f,1}.timestamps(boutstart)-outdata.rawdata.DLC{f,1}.timestamps(DLCindxdata(t,1)); %get latency
        outdata.Bouts.(processdata).(bouttype).DLC.(condition{c}).(winlabels{w}).trialn.during{f,1}(duringindx,1) = outdata.perievent.(processdata).(condition{c}).trialn{f,1}(t);
        outdata.Bouts.(processdata).(bouttype).FP.(condition{c}).(winlabels{w}).indx {f,1}.during(duringindx,:)= FPindxstart+FPTRANGE(1):FPindxstart+FPTRANGE(2);  
        outdata.Bouts.(processdata).(bouttype).FP.(condition{c}).(winlabels{w}).raw.trials{f,1}.during(duringindx,:) = outdata.detrended.dFF{f,1}(outdata.Bouts.(processdata).(bouttype).FP.(condition{c}).(winlabels{w}).indx {f,1}.during(duringindx,:));
        outdata.Bouts.(processdata).(bouttype).FP.(condition{c}).(winlabels{w}).Z_dFF.trials{f,1}.during(duringindx,:) = outdata.perievent.(processdata).(condition{c}).Z_dFF.trials{f,1}(t,:);
        outdata.Bouts.(processdata).(bouttype).FP.(condition{c}).(winlabels{w}).trialn{f,1}.during(duringindx,1) = outdata.perievent.(processdata).(condition{c}).trialn{f,1}(t);  
        end
        % %get FPindx for boutstart
        % boutstarttime =  outdata.rawdata.DLC{f,1}.timestamps(boutstart);
        % FPindxstart = find(outdata.downsamp.time{f,1}>= boutstarttime,1,'first');
        % if boutstart < DLCindxdata(t,1)
        %           else
        %             end
        %find end of bout
        boutend = find(boutoff > boutstart,1,'first');
        boutend = boutoff(boutend);
        %get duration
        if boutstart < DLCindxdata(t,1)
            if ~isempty(boutend)
            outdata.Bouts.(processdata).(bouttype).DLC.(condition{c}).(winlabels{w}).duration.pre.trials{f,1}(preindx,1) = outdata.rawdata.DLC{f,1}.timestamps(boutend)-outdata.rawdata.DLC{f,1}.timestamps(boutstart); %get duration
            else %set duration to NaN if there is no end to the last bout before end of session
            outdata.Bouts.(processdata).(bouttype).DLC.(condition{c}).(winlabels{w}).duration.pre.trials{f,1}(preindx,1) = NaN;
            boutend =length(outdata.rawdata.DLC{f,1}.timestamps); %set boutend to end of session for indx calculation (next line)
            end
        outdata.Bouts.(processdata).(bouttype).DLC.(condition{c}).(winlabels{w}).indx.pre{f,1}{preindx,1} = boutstart:boutend;
        outdata.Bouts.(processdata).(bouttype).DLC.(condition{c}).(winlabels{w}).trialn.pre{f,1}(preindx,1) = outdata.perievent.(processdata).(condition{c}).trialn{f,1}(t);
        preindx = preindx+1;
        else
            if ~isempty(boutend)
            outdata.Bouts.(processdata).(bouttype).DLC.(condition{c}).(winlabels{w}).duration.during.trials{f,1}(duringindx,1) = outdata.rawdata.DLC{f,1}.timestamps(boutend)-outdata.rawdata.DLC{f,1}.timestamps(boutstart); %get duration
            else %set duration to NaN if there is no end to the last bout before end of session
            outdata.Bouts.(processdata).(bouttype).DLC.(condition{c}).(winlabels{w}).duration.during.trials{f,1}(duringindx,1) = NaN;
            end
        outdata.Bouts.(processdata).(bouttype).DLC.(condition{c}).(winlabels{w}).indx.during{f,1}{duringindx,1} = boutstart:boutend;
        outdata.Bouts.(processdata).(bouttype).DLC.(condition{c}).(winlabels{w}).trialn.during{f,1}(duringindx,1) = outdata.perievent.(processdata).(condition{c}).trialn{f,1}(t);
        duringindx = duringindx+1;
        end
        else
        outdata.Bouts.(processdata).(bouttype).FP.(condition{c}).(winlabels{w}).Z_dFF.trials{f,1}.none(noneindx,:) = outdata.perievent.(processdata).(condition{c}).Z_dFF.trials{f,1}(t,:);
        outdata.Bouts.(processdata).(bouttype).FP.(condition{c}).(winlabels{w}).trialn{f,1}.none(noneindx,1) = outdata.perievent.(processdata).(condition{c}).trialn{f,1}(t);  
        noneindx = noneindx+1;    
        end
        end         
        else
        outdata.Bouts.(processdata).(bouttype).FP.(condition{c}).(winlabels{w}).Z_dFF.trials{f,1}.none(noneindx,:) = outdata.perievent.(processdata).(condition{c}).Z_dFF.trials{f,1}(t,:);
        outdata.Bouts.(processdata).(bouttype).FP.(condition{c}).(winlabels{w}).trialn{f,1}.none(noneindx,1) = outdata.perievent.(processdata).(condition{c}).trialn{f,1}(t);  
        noneindx = noneindx+1;    
        end
    else 
        outdata.Bouts.(processdata).(bouttype).FP.(condition{c}).(winlabels{w}).Z_dFF.trials{f,1}.none(noneindx,:) = outdata.perievent.(processdata).(condition{c}).Z_dFF.trials{f,1}(t,:);
        outdata.Bouts.(processdata).(bouttype).FP.(condition{c}).(winlabels{w}).trialn{f,1}.none(noneindx,1) = outdata.perievent.(processdata).(condition{c}).trialn{f,1}(t);  
        noneindx = noneindx+1;
    end
    end
    end
    
    %zscore trace 2 ways
    if isfield (outdata.Bouts.(processdata).(bouttype).FP.(condition{c}).(winlabels{w}),'raw')
    if length(outdata.Bouts.(processdata).(bouttype).FP.(condition{c}).(winlabels{w}).raw.trials(:,1))== f
        if isfield(outdata.Bouts.(processdata).(bouttype).FP.(condition{c}).(winlabels{w}).raw.trials{f,1},'during')
%         outdata.Bouts.(processdata).(bouttype).FP.(condition{c}).(winlabels{w}).zscored.trials{f,1}.during = zscore(outdata.Bouts.(processdata).(bouttype).FP.(condition{c}).(winlabels{w}).raw.trials{f,1}.during,0,2);
        temp = find(outdata.Bouts.(processdata).(bouttype).FP.(condition{c}).(winlabels{w}).time == 0);
        for t = 1:size(outdata.Bouts.(processdata).(bouttype).FP.(condition{c}).(winlabels{w}).raw.trials{f,1}.during,1) %for each trial
        meansnip = mean(outdata.Bouts.(processdata).(bouttype).FP.(condition{c}).(winlabels{w}).raw.trials{f,1}.during(t,1:temp-1),'omitnan'); %pre-bout mean
        stdevsnip = std(outdata.Bouts.(processdata).(bouttype).FP.(condition{c}).(winlabels{w}).raw.trials{f,1}.during(t,1:temp-1),'omitnan'); %pre-bout stdev
        for i = 1:length(outdata.Bouts.(processdata).(bouttype).FP.(condition{c}).(winlabels{w}).raw.trials{f,1}.during(t,:)) %z score each datapoint in this trial to the mean and stdev of the pre-bout period for this trial
            outdata.Bouts.(processdata).(bouttype).FP.(condition{c}).(winlabels{w}).zscored.trials{f,1}.during(t,i) = (outdata.Bouts.(processdata).(bouttype).FP.(condition{c}).(winlabels{w}).raw.trials{f,1}.during(t,i)-meansnip)/stdevsnip;
        end
        end     
        end

    if isfield(outdata.Bouts.(processdata).(bouttype).FP.(condition{c}).(winlabels{w}).raw.trials{f,1},'pre')
%     outdata.Bouts.(processdata).(bouttype).FP.(condition{c}).(winlabels{w}).zscored.trials{f,1}.pre = zscore(outdata.Bouts.(processdata).(bouttype).FP.(condition{c}).(winlabels{w}).raw.trials{f,1}.pre,0,2);
    temp = find(outdata.Bouts.(processdata).(bouttype).FP.(condition{c}).(winlabels{w}).time == 0);
    for t = 1:size(outdata.Bouts.(processdata).(bouttype).FP.(condition{c}).(winlabels{w}).raw.trials{f,1}.pre,1)
        meansnip = mean(outdata.Bouts.(processdata).(bouttype).FP.(condition{c}).(winlabels{w}).raw.trials{f,1}.pre(t,1:temp-1),'omitnan');
        stdevsnip = std(outdata.Bouts.(processdata).(bouttype).FP.(condition{c}).(winlabels{w}).raw.trials{f,1}.pre(t,1:temp-1),'omitnan');
        for i = 1:length(outdata.Bouts.(processdata).(bouttype).FP.(condition{c}).(winlabels{w}).raw.trials{f,1}.pre(t,:))
            outdata.Bouts.(processdata).(bouttype).FP.(condition{c}).(winlabels{w}).zscored.trials{f,1}.pre(t,i) = (outdata.Bouts.(processdata).(bouttype).FP.(condition{c}).(winlabels{w}).raw.trials{f,1}.pre(t,i)-meansnip)/stdevsnip;
        end
    end   
    end
    else
        outdata.Bouts.(processdata).(bouttype).FP.(condition{c}).(winlabels{w}).raw.trials{f,1} = [];
    end   
    else
        outdata.Bouts.(processdata).(bouttype).FP.(condition{c}).(winlabels{w}).raw.trials{f,1} = [];
    end
    
    %average data across trials
    %DLCdata
    avmeasures = {'latency','duration'};
    boutoccurs = {'pre','during'};
    for av = 1:length(avmeasures)
    for b = 1:length(boutoccurs)
        if b == 1
            indx = preindx;
        else
            indx = duringindx;
        end
        if indx > 2 %if there are enough trials to average          
        maxval = max(max(outdata.Bouts.(processdata).(bouttype).DLC.(condition{c}).(winlabels{w}).(avmeasures{av}).(boutoccurs{b}).trials{f,1}));
        minval = min(min(outdata.Bouts.(processdata).(bouttype).DLC.(condition{c}).(winlabels{w}).(avmeasures{av}).(boutoccurs{b}).trials{f,1}));
        if maxval > outdata.Bouts.(processdata).(bouttype).DLC.plot.(avmeasures{av}).maxval.trial
            outdata.Bouts.(processdata).(bouttype).DLC.plot.(avmeasures{av}).maxval.trial = maxval;
        end
        if minval < outdata.Bouts.(processdata).(bouttype).DLC.plot.(avmeasures{av}).minval.trial
            outdata.Bouts.(processdata).(bouttype).DLC.plot.(avmeasures{av}).minval.trial = minval;
        end  
        outdata.Bouts.(processdata).(bouttype).DLC.(condition{c}).(winlabels{w}).(avmeasures{av}).(boutoccurs{b}).mean{f,1}=mean(outdata.Bouts.(processdata).(bouttype).DLC.(condition{c}).(winlabels{w}).(avmeasures{av}).(boutoccurs{b}).trials{f,1},'omitnan');
        outdata.Bouts.(processdata).(bouttype).DLC.(condition{c}).(winlabels{w}).(avmeasures{av}).(boutoccurs{b}).std{f,1}=std(outdata.Bouts.(processdata).(bouttype).DLC.(condition{c}).(winlabels{w}).(avmeasures{av}).(boutoccurs{b}).trials{f,1},'omitnan');
        outdata.Bouts.(processdata).(bouttype).DLC.(condition{c}).(winlabels{w}).(avmeasures{av}).(boutoccurs{b}).n{f,1}=sum(~isnan(outdata.Bouts.(processdata).(bouttype).DLC.(condition{c}).(winlabels{w}).(avmeasures{av}).(boutoccurs{b}).trials{f,1}));
        outdata.Bouts.(processdata).(bouttype).DLC.(condition{c}).(winlabels{w}).(avmeasures{av}).(boutoccurs{b}).sem{f,1}= outdata.Bouts.(processdata).(bouttype).DLC.(condition{c}).(winlabels{w}).(avmeasures{av}).(boutoccurs{b}).std{f,1}/sqrt(outdata.Bouts.(processdata).(bouttype).DLC.(condition{c}).(winlabels{w}).(avmeasures{av}).(boutoccurs{b}).n{f,1});        
        maxval = max(max(outdata.Bouts.(processdata).(bouttype).DLC.(condition{c}).(winlabels{w}).(avmeasures{av}).(boutoccurs{b}).mean{f,1}));
        minval = min(min(outdata.Bouts.(processdata).(bouttype).DLC.(condition{c}).(winlabels{w}).(avmeasures{av}).(boutoccurs{b}).mean{f,1}));
        if maxval > outdata.Bouts.(processdata).(bouttype).DLC.plot.(avmeasures{av}).maxval.mean
            outdata.Bouts.(processdata).(bouttype).DLC.plot.(avmeasures{av}).maxval.mean = maxval;
        end
        if minval < outdata.Bouts.(processdata).(bouttype).DLC.plot.(avmeasures{av}).minval.mean
            outdata.Bouts.(processdata).(bouttype).DLC.plot.(avmeasures{av}).minval.mean = minval;
        end
        else
        outdata.Bouts.(processdata).(bouttype).DLC.(condition{c}).(winlabels{w}).(avmeasures{av}).(boutoccurs{b}).mean{f,1} =NaN;
        outdata.Bouts.(processdata).(bouttype).DLC.(condition{c}).(winlabels{w}).(avmeasures{av}).(boutoccurs{b}).std{f,1} = NaN;
        outdata.Bouts.(processdata).(bouttype).DLC.(condition{c}).(winlabels{w}).(avmeasures{av}).(boutoccurs{b}).n{f,1} = 0;
        outdata.Bouts.(processdata).(bouttype).DLC.(condition{c}).(winlabels{w}).(avmeasures{av}).(boutoccurs{b}).sem{f,1} = NaN;
        end  
    end
    end
    
    %FPdata
   % avmeasures = {'raw','zscored','preZ'};
    avmeasures = {'raw','zscored'}; %zscored = pre-Z
    boutoccurs = {'pre','during'};
    for av = 1:length(avmeasures)
    for b = 1:length(boutoccurs)
        if b == 1
            indx = preindx;
        else
            indx = duringindx;
        end
        
        if indx > 2 %if there are enough trials to average
        maxval = max(max(outdata.Bouts.(processdata).(bouttype).FP.(condition{c}).(winlabels{w}).(avmeasures{av}).trials{f,1}.(boutoccurs{b})));
        minval = min(min(outdata.Bouts.(processdata).(bouttype).FP.(condition{c}).(winlabels{w}).(avmeasures{av}).trials{f,1}.(boutoccurs{b})));
        if maxval > outdata.Bouts.(processdata).(bouttype).FP.plot.(avmeasures{av}).maxval.trial
        outdata.Bouts.(processdata).(bouttype).FP.plot.(avmeasures{av}).maxval.trial = maxval;
        end
        if minval < outdata.Bouts.(processdata).(bouttype).FP.plot.(avmeasures{av}).minval.trial
        outdata.Bouts.(processdata).(bouttype).FP.plot.(avmeasures{av}).minval.trial = minval;
        end
        outdata.Bouts.(processdata).(bouttype).FP.(condition{c}).(winlabels{w}).(avmeasures{av}).(boutoccurs{b}).mean{f,1}=mean(outdata.Bouts.(processdata).(bouttype).FP.(condition{c}).(winlabels{w}).(avmeasures{av}).trials{f,1}.(boutoccurs{b}),'omitnan');
        outdata.Bouts.(processdata).(bouttype).FP.(condition{c}).(winlabels{w}).(avmeasures{av}).(boutoccurs{b}).std{f,1}=std(outdata.Bouts.(processdata).(bouttype).FP.(condition{c}).(winlabels{w}).(avmeasures{av}).trials{f,1}.(boutoccurs{b}),'omitnan');
        for x = 1:length(outdata.Bouts.(processdata).(bouttype).FP.(condition{c}).(winlabels{w}).(avmeasures{av}).(boutoccurs{b}).mean{f,1})
        outdata.Bouts.(processdata).(bouttype).FP.(condition{c}).(winlabels{w}).(avmeasures{av}).(boutoccurs{b}).n{f,1}(x)=sum(~isnan(outdata.Bouts.(processdata).(bouttype).FP.(condition{c}).(winlabels{w}).(avmeasures{av}).trials{f,1}.(boutoccurs{b})(:,x)));
        outdata.Bouts.(processdata).(bouttype).FP.(condition{c}).(winlabels{w}).(avmeasures{av}).(boutoccurs{b}).sem{f,1}(x)= outdata.Bouts.(processdata).(bouttype).FP.(condition{c}).(winlabels{w}).(avmeasures{av}).(boutoccurs{b}).std{f,1}(x)/sqrt(outdata.Bouts.(processdata).(bouttype).FP.(condition{c}).(winlabels{w}).(avmeasures{av}).(boutoccurs{b}).n{f,1}(x));
        end
        maxval = max(max(outdata.Bouts.(processdata).(bouttype).FP.(condition{c}).(winlabels{w}).(avmeasures{av}).(boutoccurs{b}).mean{f,1}));
        minval = min(min(outdata.Bouts.(processdata).(bouttype).FP.(condition{c}).(winlabels{w}).(avmeasures{av}).(boutoccurs{b}).mean{f,1}));
        if maxval > outdata.Bouts.(processdata).(bouttype).FP.plot.(avmeasures{av}).maxval.mean
        outdata.Bouts.(processdata).(bouttype).FP.plot.(avmeasures{av}).maxval.mean = maxval;
        end
        if minval < outdata.Bouts.(processdata).(bouttype).FP.plot.(avmeasures{av}).minval.mean
        outdata.Bouts.(processdata).(bouttype).FP.plot.(avmeasures{av}).minval.mean = minval;
        end
        else
         outdata.Bouts.(processdata).(bouttype).FP.(condition{c}).(winlabels{w}).(avmeasures{av}).(boutoccurs{b}).mean{f,1} = NaN(1,length(outdata.Bouts.(processdata).(bouttype).FP.(condition{c}).(winlabels{w}).time));
         outdata.Bouts.(processdata).(bouttype).FP.(condition{c}).(winlabels{w}).(avmeasures{av}).(boutoccurs{b}).std{f,1} = NaN(1,length(outdata.Bouts.(processdata).(bouttype).FP.(condition{c}).(winlabels{w}).time));
         outdata.Bouts.(processdata).(bouttype).FP.(condition{c}).(winlabels{w}).(avmeasures{av}).(boutoccurs{b}).n{f,1} = 0;
         outdata.Bouts.(processdata).(bouttype).FP.(condition{c}).(winlabels{w}).(avmeasures{av}).(boutoccurs{b}).sem{f,1}=NaN(1,length(outdata.Bouts.(processdata).(bouttype).FP.(condition{c}).(winlabels{w}).time));
        end  
    end
    end  
end
else
    
        outdata.Bouts.(processdata).(bouttype).DLC.(condition{c}).(winlabels{w}).latency.pre.trials {f,1} = [];
        outdata.Bouts.(processdata).(bouttype).DLC.(condition{c}).(winlabels{w}).latency.during.trials {f,1} = [];
        outdata.Bouts.(processdata).(bouttype).DLC.(condition{c}).(winlabels{w}).duration.pre.trials {f,1} = []; %get duration
        outdata.Bouts.(processdata).(bouttype).DLC.(condition{c}).(winlabels{w}).duration.during.trials {f,1} = []; %get duration
        outdata.Bouts.(processdata).(bouttype).DLC.(condition{c}).(winlabels{w}).indx.pre {f,1} = [];
        outdata.Bouts.(processdata).(bouttype).DLC.(condition{c}).(winlabels{w}).indx.during {f,1} = [];
        outdata.Bouts.(processdata).(bouttype).DLC.(condition{c}).(winlabels{w}).trialn.pre{f,1} = [];
        outdata.Bouts.(processdata).(bouttype).DLC.(condition{c}).(winlabels{w}).trialn.during{f,1} = [];
        outdata.Bouts.(processdata).(bouttype).FP.(condition{c}).(winlabels{w}).indx {f,1}= [];  
        outdata.Bouts.(processdata).(bouttype).FP.(condition{c}).(winlabels{w}).raw.trials{f,1} = [];
        outdata.Bouts.(processdata).(bouttype).FP.(condition{c}).(winlabels{w}).Z_dFF.trials{f,1}=[];
        outdata.Bouts.(processdata).(bouttype).FP.(condition{c}).(winlabels{w}).trialn{f,1}.during{f,1}=[];  
        outdata.Bouts.(processdata).(bouttype).FP.(condition{c}).(winlabels{w}).trialn{f,1}.pre=[];
        outdata.Bouts.(processdata).(bouttype).FP.(condition{c}).(winlabels{w}).trialn{f,1}.none{f,1}=[];
        
        avmeasures = {'latency','duration'};
        boutoccurs = {'pre','during'};
        for av = 1:length(avmeasures)
        for b = 1:length(boutoccurs)
        outdata.Bouts.(processdata).(bouttype).DLC.(condition{c}).(winlabels{w}).(avmeasures{av}).(boutoccurs{b}).mean{f,1} =NaN;
        outdata.Bouts.(processdata).(bouttype).DLC.(condition{c}).(winlabels{w}).(avmeasures{av}).(boutoccurs{b}).std{f,1} = NaN;
        outdata.Bouts.(processdata).(bouttype).DLC.(condition{c}).(winlabels{w}).(avmeasures{av}).(boutoccurs{b}).n{f,1} = 0;
        outdata.Bouts.(processdata).(bouttype).DLC.(condition{c}).(winlabels{w}).(avmeasures{av}).(boutoccurs{b}).sem{f,1} = NaN;
        end
        end

        avmeasures = {'raw','zscored'}; %zscored = pre-Z
        boutoccurs = {'pre','during'};
        for av = 1:length(avmeasures)
        for b = 1:length(boutoccurs) 
         outdata.Bouts.(processdata).(bouttype).FP.(condition{c}).(winlabels{w}).(avmeasures{av}).(boutoccurs{b}).mean{f,1} = NaN(1,length(outdata.Bouts.(processdata).(bouttype).FP.(condition{c}).(winlabels{w}).time));
         outdata.Bouts.(processdata).(bouttype).FP.(condition{c}).(winlabels{w}).(avmeasures{av}).(boutoccurs{b}).std{f,1} = NaN(1,length(outdata.Bouts.(processdata).(bouttype).FP.(condition{c}).(winlabels{w}).time));
         outdata.Bouts.(processdata).(bouttype).FP.(condition{c}).(winlabels{w}).(avmeasures{av}).(boutoccurs{b}).n{f,1} = 0;
         outdata.Bouts.(processdata).(bouttype).FP.(condition{c}).(winlabels{w}).(avmeasures{av}).(boutoccurs{b}).sem{f,1}=NaN(1,length(outdata.Bouts.(processdata).(bouttype).FP.(condition{c}).(winlabels{w}).time));
        end
        end
        
end
end
end

else % approach/orient
flds = subfields{1,1};
for x = 1:length(flds)
refr = subfields{2}{x};
for r = 1:length(refr)

Boutdata = outdata.rawdata.DLC{f,1}.(bouttype).(flds{x}).(refr{r}).Binary; 
boutoff = find(Boutdata == 0);
FPfs = outdata.perievent.fs{f,1};
prebout = FPwin(1);
postbout = FPwin(2);
FPTRANGE = round([prebout*(FPfs),postbout*(FPfs)]);
framefs = 1/FPfs;
    
    avmeasures = {'latency','duration'};
    for av = 1:length(avmeasures)
        outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).DLC.plot.(avmeasures{av}).maxval.trial=0.001;
        outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).DLC.plot.(avmeasures{av}).minval.trial=0;
        outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).DLC.plot.(avmeasures{av}).maxval.mean=0.001;
        outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).DLC.plot.(avmeasures{av}).minval.mean=0;
    end
    
    avmeasures = {'raw','zscored'};
    for av = 1:length(avmeasures)
    outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).FP.plot.(avmeasures{av}).maxval.trial = 0.001;
    outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).FP.plot.(avmeasures{av}).minval.trial = 0;
    outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).FP.plot.(avmeasures{av}).maxval.mean = 0.001;
    outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).FP.plot.(avmeasures{av}).minval.mean = 0;
    end

for w = 1:length(winlabels)
for c = 1:length(condition)
    preindx=1; %indx for binning data in outfile
    duringindx=1;%indx for binning data in outfile
    noneindx = 1;%indx for binning data in outfile
    outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).FP.(condition{c}).(winlabels{w}).time = (FPTRANGE(1)*framefs:framefs:FPTRANGE(2)*framefs);
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
    
if isfield(outdata.eventdata.(processdata),(condition{c}))
    
DLCindxdata = outdata.DLC.(processdata).(condition{c}).frameindx{f,1}(:,arraystart:arrayend);
outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).DLC.(condition{c}).(winlabels{w}).boutarray{f,1} = DLCindxdata; 
if ~isempty(DLCindxdata)
    for t = 1:size(DLCindxdata,1)
    if ~isnan(DLCindxdata(t,1))
    %find first bout 
    if outdata.rawdata.DLC{f,1}.paddata
    Boutsnip = NaN(length(DLCindxdata(t,:)),1);
    Boutsnip(1:2:end) = Boutdata(DLCindxdata(t,1:2:end));
    else
    Boutsnip = Boutdata(DLCindxdata(t,:));   
    end
    findstart = find(Boutsnip == 1,1,'first'); %find first bout point in window  
    if ~isempty(findstart)
        startindx = DLCindxdata(t,findstart);
        boutstarttime =  outdata.rawdata.DLC{f,1}.timestamps(startindx);
        FPindxstart = find(outdata.downsamp.time{f,1}>= boutstarttime,1,'first');
        if ~((FPindxstart+FPTRANGE(1))<0) && ~((FPindxstart+FPTRANGE(2)) > length(outdata.detrended.dFF{f,1})) %do not include if event window extends beyond start/end of recording
        if findstart > 1 %if bout begins in window
        %get latency
        outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).DLC.(condition{c}).(winlabels{w}).latency.during.trials{f,1}(duringindx,1) = outdata.rawdata.DLC{f,1}.timestamps(startindx)-outdata.rawdata.DLC{f,1}.timestamps(DLCindxdata(t,1)); %get latency
%         outdata.Bouts.(processdata).(bouttype).DLC.(condition{c}).(winlabels{w}).latency.during.trials{f,1}(duringindx,1) = outdata.perievent.(processdata).(condition{c}).trialn{f,1}(t);
%         outdata.Bouts.(processdata).(bouttype).DLC.(condition{c}).(winlabels{w}).latency.all.trials{f,1}(t,2) = outdata.rawdata.DLC{f,1}.timestamps(startindx)-outdata.rawdata.DLC{f,1}.timestamps(DLCindxdata(t,1)); %get latency
        %get FPindx for boutstart
        outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).FP.(condition{c}).(winlabels{w}).trialn{f,1}.during(duringindx,:) =  outdata.perievent.(processdata).(condition{c}).trialn{f,1}(t);
        outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).FP.(condition{c}).(winlabels{w}).indx {f,1}.during(duringindx,:)= FPindxstart+FPTRANGE(1):FPindxstart+FPTRANGE(2); 
        outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).FP.(condition{c}).(winlabels{w}).raw.trials{f,1}.during(duringindx,:) = outdata.detrended.dFF{f,1}(outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).FP.(condition{c}).(winlabels{w}).indx {f,1}.during(duringindx,:));
        outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).FP.(condition{c}).(winlabels{w}).Z_dFF.trials{f,1}.during(duringindx,:) = outdata.perievent.(processdata).(condition{c}).Z_dFF.trials{f,1}(t,:);
        outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).FP.(condition{c}).(winlabels{w}).trialn{f,1}.during(duringindx,1) = outdata.perievent.(processdata).(condition{c}).trialn{f,1}(t);
        %find end of bout
        boutend = find(boutoff > startindx,1,'first');
        boutend = boutoff(boutend);
        %get duration
        if ~isempty(boutend)
        outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).DLC.(condition{c}).(winlabels{w}).duration.during.trials{f,1}(duringindx,1) = outdata.rawdata.DLC{f,1}.timestamps(boutend)-outdata.rawdata.DLC{f,1}.timestamps(startindx); %get duration
        else %input NaN duration if last bout is ongoing at end of session
        outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).DLC.(condition{c}).(winlabels{w}).duration.during.trials{f,1}(duringindx,1) = NaN;
        boutend =length(outdata.rawdata.DLC{f,1}.timestamps); %set boutend to end of session for indx calculation (next line)
        end
        outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).DLC.(condition{c}).(winlabels{w}).indx.during{f,1}{duringindx,1} = startindx:boutend; 
        outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).DLC.(condition{c}).(winlabels{w}).trialn.during{f,1}(duringindx,1) = outdata.perievent.(processdata).(condition{c}).trialn{f,1}(t);
        duringindx = duringindx+1;
        else
        %find boutstart
        boutstart = find(boutoff < startindx,1,'last');
        boutstart = boutoff(boutstart)+1;
        %get FPindx for boutstart
        boutstarttime =  outdata.rawdata.DLC{f,1}.timestamps(boutstart);
        FPindxstart = find(outdata.downsamp.time{f,1}>= boutstarttime,1,'first');
        if ~((FPindxstart+FPTRANGE(1))<0) && ~((FPindxstart+FPTRANGE(2)) > length(outdata.detrended.dFF{f,1})) %do not include if event window extends beyond start/end of recording
        %get latency
        if boutstart ~= DLCindxdata(t,1)
        outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).DLC.(condition{c}).(winlabels{w}).latency.pre.trials{f,1}(preindx,1) = outdata.rawdata.DLC{f,1}.timestamps(boutstart)-outdata.rawdata.DLC{f,1}.timestamps(DLCindxdata(t,1)); %get latency 
        outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).DLC.(condition{c}).(winlabels{w}).trialn.pre{f,1}(preindx,1) = outdata.perievent.(processdata).(condition{c}).trialn{f,1}(t);
        outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).FP.(condition{c}).(winlabels{w}).indx {f,1}.pre(preindx,:)= FPindxstart+FPTRANGE(1):FPindxstart+FPTRANGE(2);  
        outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).FP.(condition{c}).(winlabels{w}).raw.trials{f,1}.pre(preindx,:) = outdata.detrended.dFF{f,1}(outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).FP.(condition{c}).(winlabels{w}).indx {f,1}.pre(preindx,:));
        outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).FP.(condition{c}).(winlabels{w}).Z_dFF.trials{f,1}.pre(preindx,:) = outdata.perievent.(processdata).(condition{c}).Z_dFF.trials{f,1}(t,:);
        outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).FP.(condition{c}).(winlabels{w}).trialn{f,1}.pre(preindx,1) = outdata.perievent.(processdata).(condition{c}).trialn{f,1}(t); 
  
        else
        outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).DLC.(condition{c}).(winlabels{w}).latency.during.trials {f,1}(duringindx,:) = outdata.rawdata.DLC{f,1}.timestamps(boutstart)-outdata.rawdata.DLC{f,1}.timestamps(DLCindxdata(t,1)); %get latency
        outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).DLC.(condition{c}).(winlabels{w}).trialn.during{f,1}(duringindx,1) = outdata.perievent.(processdata).(condition{c}).trialn{f,1}(t);
        outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).FP.(condition{c}).(winlabels{w}).indx {f,1}.during(duringindx,:)= FPindxstart+FPTRANGE(1):FPindxstart+FPTRANGE(2);  
        outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).FP.(condition{c}).(winlabels{w}).raw.trials{f,1}.during(duringindx,:) = outdata.detrended.dFF{f,1}(outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).FP.(condition{c}).(winlabels{w}).indx {f,1}.during(duringindx,:));
        outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).FP.(condition{c}).(winlabels{w}).Z_dFF.trials{f,1}.during(duringindx,:) = outdata.perievent.(processdata).(condition{c}).Z_dFF.trials{f,1}(t,:);
        outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).FP.(condition{c}).(winlabels{w}).trialn{f,1}.during(duringindx,1) = outdata.perievent.(processdata).(condition{c}).trialn{f,1}(t);  
 
        end
        %get FPindx for boutstart
        % boutstarttime =  outdata.rawdata.DLC{f,1}.timestamps(boutstart);
        % FPindxstart = find(outdata.downsamp.time{f,1}>= boutstarttime,1,'first');
        % if boutstart < DLCindxdata(t,1)
        %           else
        %            end
        %find end of bout
        boutend = find(boutoff > boutstart,1,'first');
        boutend = boutoff(boutend);
        %get duration
        if boutstart < DLCindxdata(t,1)
            if ~isempty(boutend)
            outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).DLC.(condition{c}).(winlabels{w}).duration.pre.trials{f,1}(preindx,1) = outdata.rawdata.DLC{f,1}.timestamps(boutend)-outdata.rawdata.DLC{f,1}.timestamps(boutstart); %get duration
            else
            outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).DLC.(condition{c}).(winlabels{w}).duration.pre.trials{f,1}(preindx,1) = NaN;
            boutend =length(outdata.rawdata.DLC{f,1}.timestamps); %set boutend to end of session for indx calculation (next line)
            end
        outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).DLC.(condition{c}).(winlabels{w}).indx.pre{f,1}{preindx,1} = boutstart:boutend;
        outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).DLC.(condition{c}).(winlabels{w}).trialn.pre{f,1}(preindx,1) = outdata.perievent.(processdata).(condition{c}).trialn{f,1}(t);
        preindx = preindx+1;
        else
        outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).DLC.(condition{c}).(winlabels{w}).duration.during.trials{f,1}(duringindx,1) = outdata.rawdata.DLC{f,1}.timestamps(boutend)-outdata.rawdata.DLC{f,1}.timestamps(boutstart); %get duration
        outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).DLC.(condition{c}).(winlabels{w}).indx.during{f,1}{duringindx,1} = boutstart:boutend;
        outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).DLC.(condition{c}).(winlabels{w}).trialn.during{f,1}(duringindx,1) = outdata.perievent.(processdata).(condition{c}).trialn{f,1}(t);
        duringindx = duringindx+1;
        end
        else
        outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).FP.(condition{c}).(winlabels{w}).Z_dFF.trials{f,1}.none(noneindx,:) = outdata.perievent.(processdata).(condition{c}).Z_dFF.trials{f,1}(t,:);
        outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).FP.(condition{c}).(winlabels{w}).trialn{f,1}.none(noneindx,1) = outdata.perievent.(processdata).(condition{c}).trialn{f,1}(t);  
        noneindx = noneindx+1;
        end
        end 
        else
        outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).FP.(condition{c}).(winlabels{w}).Z_dFF.trials{f,1}.none(noneindx,:) = outdata.perievent.(processdata).(condition{c}).Z_dFF.trials{f,1}(t,:);
        outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).FP.(condition{c}).(winlabels{w}).trialn{f,1}.none(noneindx,1) = outdata.perievent.(processdata).(condition{c}).trialn{f,1}(t);  
        noneindx = noneindx+1;
        end
    else 
        outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).FP.(condition{c}).(winlabels{w}).Z_dFF.trials{f,1}.none(noneindx,:) = outdata.perievent.(processdata).(condition{c}).Z_dFF.trials{f,1}(t,:);
        outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).FP.(condition{c}).(winlabels{w}).trialn{f,1}.none(noneindx,1) = outdata.perievent.(processdata).(condition{c}).trialn{f,1}(t);  
        noneindx = noneindx+1;
    end
    end
    end
    
    %zscore trace 2 ways
    if isfield (outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).FP.(condition{c}).(winlabels{w}),'raw')
    if length(outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).FP.(condition{c}).(winlabels{w}).raw.trials(:,1))== f
        if isfield(outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).FP.(condition{c}).(winlabels{w}).raw.trials{f,1},'during')
%         outdata.Bouts.(processdata).(bouttype).FP.(condition{c}).(winlabels{w}).zscored.trials{f,1}.during = zscore(outdata.Bouts.(processdata).(bouttype).FP.(condition{c}).(winlabels{w}).raw.trials{f,1}.during,0,2);
        temp = find(outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).FP.(condition{c}).(winlabels{w}).time == 0);
        for t = 1:size(outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).FP.(condition{c}).(winlabels{w}).raw.trials{f,1}.during,1) %for each trial
        meansnip = mean(outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).FP.(condition{c}).(winlabels{w}).raw.trials{f,1}.during(t,1:temp-1),'omitnan'); %pre-bout mean
        stdevsnip = std(outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).FP.(condition{c}).(winlabels{w}).raw.trials{f,1}.during(t,1:temp-1),'omitnan'); %pre-bout stdev
        for i = 1:length(outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).FP.(condition{c}).(winlabels{w}).raw.trials{f,1}.during(t,:)) %z score each datapoint in this trial to the mean and stdev of the pre-bout period for this trial
            outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).FP.(condition{c}).(winlabels{w}).zscored.trials{f,1}.during(t,i) = (outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).FP.(condition{c}).(winlabels{w}).raw.trials{f,1}.during(t,i)-meansnip)/stdevsnip;
        end
        end 
        else
            outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).FP.(condition{c}).(winlabels{w}).zscored.trials{f,1}.during=[];
        end

    if isfield(outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).FP.(condition{c}).(winlabels{w}).raw.trials{f,1},'pre')
%     outdata.Bouts.(processdata).(bouttype).FP.(condition{c}).(winlabels{w}).zscored.trials{f,1}.pre = zscore(outdata.Bouts.(processdata).(bouttype).FP.(condition{c}).(winlabels{w}).raw.trials{f,1}.pre,0,2);
    temp = find(outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).FP.(condition{c}).(winlabels{w}).time == 0);
    for t = 1:size(outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).FP.(condition{c}).(winlabels{w}).raw.trials{f,1}.pre,1)
        meansnip = mean(outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).FP.(condition{c}).(winlabels{w}).raw.trials{f,1}.pre(t,1:temp-1),'omitnan');
        stdevsnip = std(outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).FP.(condition{c}).(winlabels{w}).raw.trials{f,1}.pre(t,1:temp-1),'omitnan');
        for i = 1:length(outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).FP.(condition{c}).(winlabels{w}).raw.trials{f,1}.pre(t,:))
            outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).FP.(condition{c}).(winlabels{w}).zscored.trials{f,1}.pre(t,i) = (outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).FP.(condition{c}).(winlabels{w}).raw.trials{f,1}.pre(t,i)-meansnip)/stdevsnip;
        end
    end 
    else
        outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).FP.(condition{c}).(winlabels{w}).zscored.trials{f,1}.pre=[];
    end
    else
        outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).FP.(condition{c}).(winlabels{w}).raw.trials{f,1} = [];
    end   
    else
        outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).FP.(condition{c}).(winlabels{w}).raw.trials{f,1} = [];
    end
    
    %average data across trials
    %DLCdata
    avmeasures = {'latency','duration'};
    boutoccurs = {'pre','during'};
    for av = 1:length(avmeasures)
    for b = 1:length(boutoccurs)
        if b == 1
            indx = preindx;
        else
            indx = duringindx;
        end
        if indx > 2 %if there are enough trials to average          
        maxval = max(max(outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).DLC.(condition{c}).(winlabels{w}).(avmeasures{av}).(boutoccurs{b}).trials{f,1}));
        minval = min(min(outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).DLC.(condition{c}).(winlabels{w}).(avmeasures{av}).(boutoccurs{b}).trials{f,1}));
        if maxval > outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).DLC.plot.(avmeasures{av}).maxval.trial
            outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).DLC.plot.(avmeasures{av}).maxval.trial = maxval;
        end
        if minval < outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).DLC.plot.(avmeasures{av}).minval.trial
            outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).DLC.plot.(avmeasures{av}).minval.trial = minval;
        end  
        outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).DLC.(condition{c}).(winlabels{w}).(avmeasures{av}).(boutoccurs{b}).mean{f,1}=mean(outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).DLC.(condition{c}).(winlabels{w}).(avmeasures{av}).(boutoccurs{b}).trials{f,1},'omitnan');
        outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).DLC.(condition{c}).(winlabels{w}).(avmeasures{av}).(boutoccurs{b}).std{f,1}=std(outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).DLC.(condition{c}).(winlabels{w}).(avmeasures{av}).(boutoccurs{b}).trials{f,1},'omitnan');
        outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).DLC.(condition{c}).(winlabels{w}).(avmeasures{av}).(boutoccurs{b}).n{f,1}=sum(~isnan(outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).DLC.(condition{c}).(winlabels{w}).(avmeasures{av}).(boutoccurs{b}).trials{f,1}));
        outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).DLC.(condition{c}).(winlabels{w}).(avmeasures{av}).(boutoccurs{b}).sem{f,1}= outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).DLC.(condition{c}).(winlabels{w}).(avmeasures{av}).(boutoccurs{b}).std{f,1}/sqrt(outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).DLC.(condition{c}).(winlabels{w}).(avmeasures{av}).(boutoccurs{b}).n{f,1});        
        maxval = max(max(outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).DLC.(condition{c}).(winlabels{w}).(avmeasures{av}).(boutoccurs{b}).mean{f,1}));
        minval = min(min(outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).DLC.(condition{c}).(winlabels{w}).(avmeasures{av}).(boutoccurs{b}).mean{f,1}));
        if maxval > outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).DLC.plot.(avmeasures{av}).maxval.mean
            outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).DLC.plot.(avmeasures{av}).maxval.mean = maxval;
        end
        if minval < outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).DLC.plot.(avmeasures{av}).minval.mean
            outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).DLC.plot.(avmeasures{av}).minval.mean = minval;
        end
        else
        outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).DLC.(condition{c}).(winlabels{w}).(avmeasures{av}).(boutoccurs{b}).mean{f,1} =NaN;
        outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).DLC.(condition{c}).(winlabels{w}).(avmeasures{av}).(boutoccurs{b}).std{f,1} = NaN;
        outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).DLC.(condition{c}).(winlabels{w}).(avmeasures{av}).(boutoccurs{b}).n{f,1} = 0;
        outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).DLC.(condition{c}).(winlabels{w}).(avmeasures{av}).(boutoccurs{b}).sem{f,1} = NaN;
        end  
    end
    end
    
    %FPdata
   % avmeasures = {'raw','zscored','preZ'};
    avmeasures = {'raw','zscored'}; %zscored = pre-Z
    boutoccurs = {'pre','during'};
    for av = 1:length(avmeasures)
    for b = 1:length(boutoccurs)
        if b == 1
            indx = preindx;
        else
            indx = duringindx;
        end
        
        if indx > 2 %if there are enough trials to average
        maxval = max(max(outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).FP.(condition{c}).(winlabels{w}).(avmeasures{av}).trials{f,1}.(boutoccurs{b})));
        minval = min(min(outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).FP.(condition{c}).(winlabels{w}).(avmeasures{av}).trials{f,1}.(boutoccurs{b})));
        if maxval > outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).FP.plot.(avmeasures{av}).maxval.trial
        outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).FP.plot.(avmeasures{av}).maxval.trial = maxval;
        end
        if minval < outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).FP.plot.(avmeasures{av}).minval.trial
        outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).FP.plot.(avmeasures{av}).minval.trial = minval;
        end
        outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).FP.(condition{c}).(winlabels{w}).(avmeasures{av}).(boutoccurs{b}).mean{f,1}=mean(outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).FP.(condition{c}).(winlabels{w}).(avmeasures{av}).trials{f,1}.(boutoccurs{b}),'omitnan');
        outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).FP.(condition{c}).(winlabels{w}).(avmeasures{av}).(boutoccurs{b}).std{f,1}=std(outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).FP.(condition{c}).(winlabels{w}).(avmeasures{av}).trials{f,1}.(boutoccurs{b}),'omitnan');
        for y = 1:length(outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).FP.(condition{c}).(winlabels{w}).(avmeasures{av}).(boutoccurs{b}).mean{f,1})
        outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).FP.(condition{c}).(winlabels{w}).(avmeasures{av}).(boutoccurs{b}).n{f,1}(y)=sum(~isnan(outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).FP.(condition{c}).(winlabels{w}).(avmeasures{av}).trials{f,1}.(boutoccurs{b})(:,y)));
        outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).FP.(condition{c}).(winlabels{w}).(avmeasures{av}).(boutoccurs{b}).sem{f,1}(y)= outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).FP.(condition{c}).(winlabels{w}).(avmeasures{av}).(boutoccurs{b}).std{f,1}(y)/sqrt(outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).FP.(condition{c}).(winlabels{w}).(avmeasures{av}).(boutoccurs{b}).n{f,1}(y));
        end
        maxval = max(max(outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).FP.(condition{c}).(winlabels{w}).(avmeasures{av}).(boutoccurs{b}).mean{f,1}));
        minval = min(min(outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).FP.(condition{c}).(winlabels{w}).(avmeasures{av}).(boutoccurs{b}).mean{f,1}));
        if maxval > outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).FP.plot.(avmeasures{av}).maxval.mean
        outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).FP.plot.(avmeasures{av}).maxval.mean = maxval;
        end
        if minval < outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).FP.plot.(avmeasures{av}).minval.mean
        outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).FP.plot.(avmeasures{av}).minval.mean = minval;
        end
        else
         outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).FP.(condition{c}).(winlabels{w}).(avmeasures{av}).(boutoccurs{b}).mean{f,1} = NaN(1,length(outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).FP.(condition{c}).(winlabels{w}).time));
         outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).FP.(condition{c}).(winlabels{w}).(avmeasures{av}).(boutoccurs{b}).std{f,1} =NaN(1,length(outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).FP.(condition{c}).(winlabels{w}).time));
         outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).FP.(condition{c}).(winlabels{w}).(avmeasures{av}).(boutoccurs{b}).n{f,1} = 0;
         outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).FP.(condition{c}).(winlabels{w}).(avmeasures{av}).(boutoccurs{b}).sem{f,1}=NaN(1,length(outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).FP.(condition{c}).(winlabels{w}).time));
        end  
    end
    end  
end
else
    
        outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).DLC.(condition{c}).(winlabels{w}).latency.pre.trials {f,1} = [];
        outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).DLC.(condition{c}).(winlabels{w}).latency.during.trials {f,1} = [];
        outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).DLC.(condition{c}).(winlabels{w}).duration.pre.trials {f,1} = []; %get duration
        outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).DLC.(condition{c}).(winlabels{w}).duration.during.trials {f,1} = []; %get duration
        outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).DLC.(condition{c}).(winlabels{w}).indx.pre {f,1} = [];
        outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).DLC.(condition{c}).(winlabels{w}).indx.during {f,1} = [];
        outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).DLC.(condition{c}).(winlabels{w}).trialn.pre{f,1} = [];
        outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).DLC.(condition{c}).(winlabels{w}).trialn.during{f,1} = [];
        outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).FP.(condition{c}).(winlabels{w}).indx {f,1}= [];  
        outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).FP.(condition{c}).(winlabels{w}).raw.trials{f,1} = [];
        outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).FP.(condition{c}).(winlabels{w}).Z_dFF.trials{f,1}=[];
        outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).FP.(condition{c}).(winlabels{w}).zscored.trials{f,1}=[];
        outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).FP.(condition{c}).(winlabels{w}).trialn{f,1}.during{f,1}=[];  
        outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).FP.(condition{c}).(winlabels{w}).trialn{f,1}.pre=[];
        outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).FP.(condition{c}).(winlabels{w}).trialn{f,1}.none{f,1}=[];
        
        avmeasures = {'latency','duration'};
        boutoccurs = {'pre','during'};
        for av = 1:length(avmeasures)
        for b = 1:length(boutoccurs)
        outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).DLC.(condition{c}).(winlabels{w}).(avmeasures{av}).(boutoccurs{b}).mean{f,1} =NaN;
        outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).DLC.(condition{c}).(winlabels{w}).(avmeasures{av}).(boutoccurs{b}).std{f,1} = NaN;
        outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).DLC.(condition{c}).(winlabels{w}).(avmeasures{av}).(boutoccurs{b}).n{f,1} = 0;
        outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).DLC.(condition{c}).(winlabels{w}).(avmeasures{av}).(boutoccurs{b}).sem{f,1} = NaN;
        end
        end
        avmeasures = {'raw','zscored'};
        boutoccurs = {'pre','during'};
        for av = 1:length(avmeasures)
        for b = 1:length(boutoccurs)
         outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).FP.(condition{c}).(winlabels{w}).(avmeasures{av}).(boutoccurs{b}).mean{f,1} = NaN(1,length(outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).FP.(condition{c}).(winlabels{w}).time));
         outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).FP.(condition{c}).(winlabels{w}).(avmeasures{av}).(boutoccurs{b}).std{f,1} = NaN(1,length(outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).FP.(condition{c}).(winlabels{w}).time));
         outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).FP.(condition{c}).(winlabels{w}).(avmeasures{av}).(boutoccurs{b}).n{f,1} = 0;
         outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).FP.(condition{c}).(winlabels{w}).(avmeasures{av}).(boutoccurs{b}).sem{f,1}=NaN(1,length(outdata.Bouts.(processdata).(bouttype).(flds{x}).(refr{r}).FP.(condition{c}).(winlabels{w}).time));
        end
        end
end
end
end
end
end
end
end


