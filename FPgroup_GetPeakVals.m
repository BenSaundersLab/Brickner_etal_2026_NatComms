function[PeakData] = FPgroup_GetPeakVals(window,time,trace)

 winstart = find(time >= window(1),1,"first");
 if length(window) == 1 % assume start of window if only one val is given and default to end
 winend = length(time);
 else
 winend = find(time <= window(2),1,"last");
 end

 tracesnip = trace(winstart:winend);
 timesnip = time(winstart:winend);
 snipindx = winstart:winend;

 %% Get Peak/Trough Values and Index
 [maxval,maxindx] = max(tracesnip);
 [minval, minindx] = min(tracesnip);
 PeakData.Peak.PeakVal = maxval;
 PeakData.Peak.Indx = snipindx(maxindx);
 PeakData.Trough.PeakVal = minval;
 PeakData.Trough.Indx = snipindx(minindx);

 %% Get Latencies 
 if ~isnan(maxval)
 PeakData.Peak.Latency = timesnip(maxindx) - timesnip(1);                            
 else
 PeakData.Peak.Latency = NaN; 
 end

 if ~isnan(minval)
 PeakData.Trough.Latency = timesnip(minindx) - timesnip(1);                            
 else
 PeakData.Trough.Latency = NaN; 
 end
 
 %% Peak Rise/Fall Slopes
risefallval = maxval/2;%find 50% of max norm value
risefallindx = find(tracesnip < risefallval);%find values below 50% 
risestart = find(risefallindx < maxindx, 1, 'last');
if isempty(risestart)
    [~,risestart] = min(tracesnip(1:maxindx)); %if values do not drop below 50% then find the minimum value between start and peak and use this
else
    risestart = risefallindx(risestart)+1;
end
x1 = timesnip(risestart);
x2 = timesnip(maxindx);
y1 = tracesnip(risestart);
y2 = tracesnip(maxindx);
PeakData.Peak.RiseSlope = (y2-y1)/(x2-x1);
clear x1 x2 y1 y2

fallend = find(risefallindx > maxindx,1,'first');%
if isempty(fallend)
[~,fallend] = min(tracesnip(maxindx:end)); %if values do not drop below 50% then find the minimum value between peak and end and use this
indxtrace = snipindx(maxindx:end);
%%********** check here
fallend = indxtrace(fallend);%indx minimum to whole trace
fallend = find(snipindx == fallend);
else
fallend = risefallindx(fallend)-1;
end

x1 = timesnip(maxindx);
x2 = timesnip(fallend);
y1 = tracesnip(maxindx);
y2 = tracesnip(fallend);
PeakData.Peak.FallSlope = (y2-y1)/(x2-x1);

%% Trough Rise/Fall Slopes
risefallval = minval/2;%find 50% of max norm value
risefallindx = find(tracesnip > risefallval);%find values below 50%  
risestart = find(risefallindx < minindx, 1, 'last');%
if isempty(risestart)
     [~,risestart] = max(tracesnip(1:minindx)); %if values do not drop below 50% then find the max value between start and peak and use this
else
    risestart = risefallindx(risestart)+1;
end
x1 = timesnip(risestart);
x2 = timesnip(minindx);
y1 = tracesnip(risestart);
y2 = tracesnip(minindx);
PeakData.Trough.RiseSlope = (y2-y1)/(x2-x1);
clear x1 x2 y1 y2

fallend = find(risefallindx > minindx,1,'first');%     
if isempty(fallend)
    [~,fallend] = max(tracesnip(minindx:end)); %if values do not drop below 50% then find the max value between peak and end and use this
    indxtrace = snipindx(minindx:end);
    %******* check this
    fallend = indxtrace(fallend); %indx min value to whole trace
    fallend = find(snipindx == fallend);
else
    fallend = risefallindx(fallend)-1;
end
x1 = timesnip(minindx);
x2 = timesnip(fallend);
y1 = tracesnip(minindx);
y2 = tracesnip(fallend);
PeakData.Trough.FallSlope = (y2-y1)/(x2-x1);

%AUC - same for peak and trough
PeakData.Peak.AUC = trapz(tracesnip);
PeakData.Trough.AUC = trapz(tracesnip);

%average z scored DFF across window - same for peak and trough
PeakData.Peak.AverageFP = mean(tracesnip);
PeakData.Trough.AverageFP = mean(tracesnip); 
end