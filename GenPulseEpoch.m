function [StimOn,StimOff,StimDur]= GenPulseEpoch(StimPulse_onset,StimPulse_offset,stimHz)
%A Wolff 15/2/21
%% Function that takes pulsed stim input and generates on/off timestamps and stim duration of each pulse train using the pulse interval (1s/stim in Hz)
pulseinterval = 1/stimHz;

StimOn(1,1) = StimPulse_onset(1,1);%set first stim onset
stimindx = 2;
for s = 2:length(StimPulse_onset) %find the onset of each pulsetrain of stimulation by looking for intervals larger than 2* pulse duration
    if (StimPulse_onset(s,1)-StimPulse_onset(s-1,1)) > pulseinterval*1.5
        StimOn(stimindx,1) = StimPulse_onset(s,1);
        stimindx = stimindx+1;
    end
end
StimOff = NaN(length(StimOn(:,1)),1);
StimDur = NaN(length(StimOn(:,1)),1);
stimindx = 1;
for s = 1:(length(StimOn)-1)
    x = find(StimPulse_offset < StimOn(s+1,1),1,'last');
    StimOff(stimindx,1) = StimPulse_offset(x,1);
    StimDur(stimindx,1) = round(StimOff(stimindx,1) - StimOn(stimindx,1));
    stimindx = stimindx + 1;
end
     StimOff(stimindx,1) = StimPulse_offset(end);
     StimDur(stimindx,1) = round(StimOff(stimindx,1) - StimOn(stimindx,1));
end