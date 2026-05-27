function [outdata] = DLC_GetSnips (f,outdata,DLCdata,DLCTRANGE,condition,sniplabel)
%A Wolff 15/2/21
%% Function to get perievent snips of DLC data and caluclate PE event means
%Inputs: 
%f - current file number needed for referencing in outdata
%outdata - needed to save output
%DLCdata - output file of analyzed DLC data from DLC_Analyze function
%DLCtrange - number of frames before and after event onset to include in snips
%condition - string: cond1 or cond2 snip type
%sniplabel - string: event type

measures = outdata.UserVals.DLCsetup.measures;
bps = outdata.UserVals.DLC.bps;
environfeats = outdata.UserVals.DLC.environfeatlabs;
vectorcoords = outdata.UserVals.DLCsetup.Subfields.VectorCoord{1,1};
LED = outdata.UserVals.DLC.LED;
trialn = outdata.perievent.(sniplabel).(condition).trialn{f,1};
numtrials = length(trialn);
winend = outdata.timearray.(sniplabel).DLC.perievent{f,1}(end);
includetrial = NaN(1,numtrials);

if numtrials == 0
    numtrials = 1;
    trialn(1) = NaN;
    dataindx = (1+DLCTRANGE(1):1+DLCTRANGE(2));
end
%% get data for each trial
for t = 1:numtrials
    if ~isnan(trialn(t))
    indx = outdata.eventdata.(sniplabel).(condition).trialn{f,1} == trialn(t);
    indxts = outdata.eventdata.(sniplabel).(condition).ts{f,1}(indx); %find event ts
    dlcindx = find(outdata.videodata.frames.onset{f,1} >= indxts,1,'first');  %find indx to first videoframe with timestamp >=  event onset
    dataindx = (dlcindx+DLCTRANGE(1):dlcindx+DLCTRANGE(2)); 
    actualend = find(outdata.videodata.frames.onset{f,1} >= indxts+winend,1,'first');
    foundend = dataindx(end); 
    if isempty(actualend) || foundend > length(outdata.videodata.frames.onset{f,1})
        includetrial(t) = false;
    else
        if dataindx(1) >= 1 && abs(actualend-foundend) <= 1 %only extract data if there have not been too many frames dropped
            includetrial(t) = true;
        else
            includetrial(t) = false;
        end
    end
    else
         includetrial(t) = false;
         dataindx = (1+DLCTRANGE(1):1+DLCTRANGE(2));
    end

if ~DLCdata.paddata  %if framerate is at default
    if includetrial(t)
    outdata.DLC.(sniplabel).(condition).frameindx{f,1}(t,:) = dataindx;
    outdata.DLC.(sniplabel).(condition).ts{f,1}(t,:) = outdata.rawdata.DLC{f,1}.timestamps(dataindx);
    else
    outdata.DLC.(sniplabel).(condition).frameindx{f,1}(t,:) = nan(1,length(dataindx));
    outdata.DLC.(sniplabel).(condition).ts{f,1}(t,:) =  nan(1,length(dataindx));   
    end
else
    if t == 1 %get info about pad length and indexing for the first trial only
    padfq = DLCdata.FPS/outdata.videodata.vidFPS{f,1};
    newarraysz = length(outdata.DLC.(sniplabel).time {f,1});
    inputindx = (1:padfq:newarraysz); %indx array for data to input to NaN array
    end

    if includetrial(t)
        outdata.DLC.(sniplabel).(condition).frameindx{f,1}(t,1:newarraysz) = NaN;
        outdata.DLC.(sniplabel).(condition).frameindx{f,1}(t,inputindx) = dataindx;
        outdata.DLC.(sniplabel).(condition).ts{f,1}(t,1:newarraysz) = NaN;
        outdata.DLC.(sniplabel).(condition).ts{f,1}(t,inputindx) = outdata.rawdata.DLC{f,1}.timestamps(dataindx);
    else
        outdata.DLC.(sniplabel).(condition).frameindx{f,1}(t,1:newarraysz) = NaN;
        outdata.DLC.(sniplabel).(condition).ts{f,1}(t,1:newarraysz) = NaN;
    end
end


%bodypart coordinates - low confidence already removed
for b = 1:length(bps)
    if isfield(outdata.rawdata.DLC{f,1}.bodyparts,(bps{b}))
    if includetrial(t)
        if DLCdata.paddata
        outdata.DLC.(sniplabel).(condition).bodyparts.(bps{b}){f,1}{t,:} = NaN(newarraysz,2);     
        outdata.DLC.(sniplabel).(condition).bodyparts.(bps{b}){f,1}{t,:}(inputindx,:) = outdata.rawdata.DLC{f,1}.bodyparts.(bps{b}).xy(dataindx,:);
        else
        outdata.DLC.(sniplabel).(condition).bodyparts.(bps{b}){f,1}{t,:} = outdata.rawdata.DLC{f,1}.bodyparts.(bps{b}).xy(dataindx,:);
        end
    else
        outdata.DLC.(sniplabel).(condition).bodyparts.(bps{b}){f,1}{t,:} = [];
    end
    end
end
clear b

%indicator light coordinates - low confidence already removed
for b = 1:length(LED)
    if isfield(outdata.rawdata.DLC{f,1}.LEDs,(LED{b}))
    if includetrial(t)
        if DLCdata.paddata
        outdata.DLC.(sniplabel).(condition).LED.(LED{b}){f,1}{t,:} = NaN(newarraysz,2);
        outdata.DLC.(sniplabel).(condition).LED.(LED{b}){f,1}{t,:}(inputindx,:) = outdata.rawdata.DLC{f,1}.LEDs.(LED{b}).xy(dataindx,:);    
        else
        outdata.DLC.(sniplabel).(condition).LED.(LED{b}){f,1}{t,:} = outdata.rawdata.DLC{f,1}.LEDs.(LED{b}).xy(dataindx,:);
        end
    else
    outdata.DLC.(sniplabel).(condition).LED.(LED{b}){f,1}{t,:} = [];
    end
    end
end
clear b

%fixed environment features coordinates
for e = 1:length(environfeats)
    if isfield(outdata.rawdata.DLC{f,1}.FixedPoints,(environfeats{e}))
    if includetrial(t)
        if DLCdata.paddata
        outdata.DLC.(sniplabel).(condition).fixedpoints.(environfeats{e}){f,1}{t,:} = NaN(newarraysz,2);
        datatemp = ones(length(inputindx),2).*outdata.rawdata.DLC{f,1}.FixedPoints.(environfeats{e})(1,:);
        outdata.DLC.(sniplabel).(condition).fixedpoints.(environfeats{e}){f,1}{t,:}(inputindx,:) = datatemp;
        clear datatemp
        else
        outdata.DLC.(sniplabel).(condition).fixedpoints.(environfeats{e}){f,1}{t,:} = outdata.rawdata.DLC{f,1}.FixedPoints.(environfeats{e})(1,:);
        end
    else
    outdata.DLC.(sniplabel).(condition).fixedpoints.(environfeats{e}){f,1}{t,:} = [];
    end
    end
end
clear e

%get quadrant data
if isfield(outdata.UserVals.DLCsetup.Subfields,'Quadrant')
quad = {'LT','LB','RT','RB'};
quadbps = outdata.UserVals.DLCsetup.Subfields.Quadrant{1,1};
for qb = 1:length(quadbps)
for q = 1:4
    if includetrial(t)
        if DLCdata.paddata
        outdata.DLC.(sniplabel).(condition).Quadrant.(quadbps{qb}).(quad{q}).trials{f,1}(t,:) = NaN(1,newarraysz);
        outdata.DLC.(sniplabel).(condition).Quadrant.(quadbps{qb}).(quad{q}).trials{f,1}(t,inputindx) = outdata.rawdata.DLC{f,1}.Quadrant.(quadbps{qb}).(quad{q})(dataindx,1);
        else
        outdata.DLC.(sniplabel).(condition).Quadrant.(quadbps{qb}).(quad{q}).trials{f,1}(t,:) = outdata.rawdata.DLC{f,1}.Quadrant.(quadbps{qb}).(quad{q})(dataindx,1);
        end
    else
        if DLCdata.paddata
        outdata.DLC.(sniplabel).(condition).Quadrant.(quadbps{qb}).(quad{q}).trials{f,1}(t,:) = NaN(1,newarraysz);
        else
        outdata.DLC.(sniplabel).(condition).Quadrant.(quadbps{qb}).(quad{q}).trials{f,1}(t,:) = NaN(length(dataindx),1);
        end
    end
end
end
end


% %angluar velocity data
% if isfield(outdata.UserVals.DLCsetup.Subfields,'AngularVelocity')
%     ref = outdata.UserVals.DLCsetup.Subfields.AngularVelocity{1,1};
%     for r = 1:length(ref)
%         if includetrial(t)
%             if DLCdata.paddata
%             outdata.DLC.(sniplabel).(condition).AngularVelocity.(ref{r}).velocity.trials{f,1}.raw(t,:) = NaN(1,newarraysz);
%             outdata.DLC.(sniplabel).(condition).AngularVelocity.(ref{r}).velocity.trials{f,1}.raw(t,inputindx) = DLCdata.AngularVelocity.(ref{r}).Velocity(dataindx,1); 
%             else
%             outdata.DLC.(sniplabel).(condition).AngularVelocity.(ref{r}).velocity.trials{f,1}.raw(t,:) = DLCdata.AngularVelocity.(ref{r}).Velocity.raw(dataindx,1);
%             end
%             outdata.DLC.(sniplabel).(condition).AngularVelocity.(ref{r}).velocity.trials{f,1}.average(t,1) = mean(DLCdata.AngularVelocity.(ref{r}).Velocity(dataindx,1),'omitnan');
%         else
%             if DLCdata.paddata
%             outdata.DLC.(sniplabel).(condition).AngularVelocity.(ref{r}).velocity.trials{f,1}.raw(t,:) = NaN(1,newarraysz);
%             else
%             outdata.DLC.(sniplabel).(condition).AngularVelocity.(ref{r}).velocity.trials{f,1}.raw(t,:) = nan(length(dataindx),1);
%             end
%             outdata.DLC.(sniplabel).(condition).AngularVelocity.(ref{r}).velocity.trials{f,1}.average(t,:) = NaN;
%         end
%     end
% end

%Vectors
if isfield(outdata.UserVals.DLCsetup.Subfields,'VectorCoord') 
for v = 1:length(outdata.UserVals.DLCsetup.Subfields.VectorCoord{1})
    if includetrial(t)
        if DLCdata.paddata
        outdata.DLC.(sniplabel).(condition).VectorCoord.trials.(vectorcoords{v}).headxy{f,1}{t,:} = NaN(newarraysz,2);
        outdata.DLC.(sniplabel).(condition).VectorCoord.trials.(vectorcoords{v}).tailxy{f,1}{t,:} = NaN(newarraysz,2);
        outdata.DLC.(sniplabel).(condition).VectorCoord.trials.(vectorcoords{v}).headxy{f,1}{t,:}(inputindx,:) = DLCdata.VectorCoord.(vectorcoords{v}).Head.xy(dataindx,:);
        outdata.DLC.(sniplabel).(condition).VectorCoord.trials.(vectorcoords{v}).tailxy{f,1}{t,:}(inputindx,:) = DLCdata.VectorCoord.(vectorcoords{v}).Tail.xy(dataindx,:);
        else
        outdata.DLC.(sniplabel).(condition).VectorCoord.trials.(vectorcoords{v}).headxy{f,1}{t,:} = DLCdata.VectorCoord.(vectorcoords{v}).Head.xy(dataindx,:);
        outdata.DLC.(sniplabel).(condition).VectorCoord.trials.(vectorcoords{v}).tailxy{f,1}{t,:} = DLCdata.VectorCoord.(vectorcoords{v}).Tail.xy(dataindx,:);
        end
    else
        if DLCdata.paddata
        outdata.DLC.(sniplabel).(condition).VectorCoord.trials.(vectorcoords{v}).headxy{f,1}{t,:} = NaN(newarraysz,2);
        outdata.DLC.(sniplabel).(condition).VectorCoord.trials.(vectorcoords{v}).tailxy{f,1}{t,:} = NaN(newarraysz,2);
        else
        outdata.DLC.(sniplabel).(condition).VectorCoord.trials.(vectorcoords{v}).headxy{f,1}{t,:} = nan(length(dataindx),2);
        outdata.DLC.(sniplabel).(condition).VectorCoord.trials.(vectorcoords{v}).tailxy{f,1}{t,:} = nan(length(dataindx),2);
        end
    end
end     
clear v 
end

% %Bps Speed
% for b = 1:length(bps)
%     if isfield (outdata.rawdata.DLC{f,1}.BpsSpeed,(bps{b}))
%     if includetrial(t)
%         if DLCdata.paddata
%         outdata.DLC.(sniplabel).(condition).BpsSpeed.(bps{b}){f,1}(t,1:newarraysz) = NaN;
%         outdata.DLC.(sniplabel).(condition).BpsSpeed.(bps{b}){f,1}(t,inputindx) = outdata.rawdata.DLC{f,1}.BpsSpeed.(bps{b}).raw(dataindx,:);
%         else
%         outdata.DLC.(sniplabel).(condition).BpsSpeed.(bps{b}){f,1}(t,:) = outdata.rawdata.DLC{f,1}.BpsSpeed.(bps{b}).raw(dataindx,1);
%         end        
%     else
%         if DLCdata.paddata
%         outdata.DLC.(sniplabel).(condition).BpsSpeed.(bps{b}){f,1}(t,1:newarraysz) = NaN;
%         else
%         outdata.DLC.(sniplabel).(condition).BpsSpeed.(bps{b}){f,1}(t,:) = nan(length(dataindx),1);
%         end
%     end
%     end
% end
% clear b

%BpsDist - cumulative
if isfield(outdata.UserVals.DLCsetup.Subfields,'MoveDist')
    flds = outdata.UserVals.DLCsetup.Subfields.MoveDist{1,1};
for x = 1:length(flds)
    if isfield (outdata.rawdata.DLC{f,1}.BpsDist,(flds{x}))
    if includetrial(t)
        cumuldata(1,1) = 0; %no distance moved in first frame of window
        for idv = 2:length(dataindx)
            if ~isnan(outdata.rawdata.DLC{f,1}.BpsDist.(flds{x}).raw(dataindx(idv),1)) %if this frame is not nan calc dist moved
            cumuldata(1,idv) = outdata.rawdata.DLC{f,1}.BpsDist.(flds{x}).raw(dataindx(idv),1) + cumuldata(1,idv-1); %current frame + running total (last frame) - to get cumul distance
            else %if nan then input distance from previous frame
            cumuldata(1,idv) = NaN;
            end
        end
        if DLCdata.paddata
        outdata.DLC.(sniplabel).(condition).MoveDist.(flds{x}).trials{f,1}(t,1:newarraysz) = NaN;
        outdata.DLC.(sniplabel).(condition).MoveDist.(flds{x}).trials{f,1}(t,inputindx) = cumuldata;
        else
        outdata.DLC.(sniplabel).(condition).MoveDist.(flds{x}).trials{f,1}(t,:) = cumuldata;
        end        
    else
        if DLCdata.paddata
        outdata.DLC.(sniplabel).(condition).MoveDist.(flds{x}).trials{f,1}(t,1:newarraysz) = NaN;
        else
        outdata.DLC.(sniplabel).(condition).MoveDist.(flds{x}).trials{f,1}(t,:) = nan(length(dataindx),1);
        end
    end
    end
end
clear x flds
end




%locomotion bouts
if outdata.UserVals.locobouts
    if includetrial(t)
        if DLCdata.paddata
        outdata.DLC.(sniplabel).(condition).Locomotion{f,1}(t,1:newarraysz) = NaN;
        outdata.DLC.(sniplabel).(condition).Locomotion{f,1}(t,inputindx)= outdata.rawdata.DLC{f,1}.Locomotion.Binary(dataindx,:);    
        else
        outdata.DLC.(sniplabel).(condition).Locomotion{f,1}(t,:) = outdata.rawdata.DLC{f,1}.Locomotion.Binary(dataindx);
        end
    else
        if DLCdata.paddata
        outdata.DLC.(sniplabel).(condition).Locomotion{f,1}(t,1:newarraysz) = NaN;
        else
        outdata.DLC.(sniplabel).(condition).Locomotion{f,1}(t,:) = nan(length(dataindx),1);
        end
    end
end

%freezing bouts
if outdata.UserVals.freezingbouts
    if includetrial(t)
        if DLCdata.paddata
        outdata.DLC.(sniplabel).(condition).Freeze{f,1}(t,1:newarraysz) = NaN;
        outdata.DLC.(sniplabel).(condition).Freeze{f,1}(t,inputindx) = outdata.rawdata.DLC{f,1}.Freeze.Binary(dataindx,:);  
        else
        outdata.DLC.(sniplabel).(condition).Freeze{f,1}(t,:) = outdata.rawdata.DLC{f,1}.Freeze.Binary(dataindx);
        end
    else
        if DLCdata.paddata
        outdata.DLC.(sniplabel).(condition).Freeze{f,1}(t,1:newarraysz) = NaN;
        else
        outdata.DLC.(sniplabel).(condition).Freeze{f,1}(t,:) = nan(length(dataindx),1);
        end
    end
end

for m = 1:length(measures)
if ~strcmp(measures{m},'MoveDist')         
nsubfields = length(outdata.UserVals.DLCsetup.Subfields.(measures{m}));
%Measures
flds = outdata.UserVals.DLCsetup.Subfields.(measures{m}){1};
switch nsubfields
    case 1
        for x = 1:length(flds)
            if includetrial(t)  
                if DLCdata.paddata
                outdata.DLC.(sniplabel).(condition).(measures{m}).(flds{x}).trials{f,1}(t,1:newarraysz) = NaN;
                outdata.DLC.(sniplabel).(condition).(measures{m}).(flds{x}).trials{f,1}(t,inputindx) = DLCdata.(measures{m}).(flds{x}).raw(dataindx); 
                else
                outdata.DLC.(sniplabel).(condition).(measures{m}).(flds{x}).trials{f,1}(t,:) = DLCdata.(measures{m}).(flds{x}).raw(dataindx);
                end
            else
                if DLCdata.paddata
                outdata.DLC.(sniplabel).(condition).(measures{m}).(flds{x}).trials{f,1}(t,1:newarraysz) = NaN; 
                else
                outdata.DLC.(sniplabel).(condition).(measures{m}).(flds{x}).trials{f,1}(t,:) = nan(length(dataindx),1);
                end
            end
        end
        clear flds x
    case 2
        for x = 1:length(flds)
        refr = outdata.UserVals.DLCsetup.Subfields.(measures{m}){2}{x};
        for r = 1:length(refr)
            if includetrial(t)
                if DLCdata.paddata
                    outdata.DLC.(sniplabel).(condition).(measures{m}).(flds{x}).(refr{r}).trials{f,1}(t,1:newarraysz) = NaN; 
                    outdata.DLC.(sniplabel).(condition).(measures{m}).(flds{x}).(refr{r}).trials{f,1}(t,inputindx) = DLCdata.(measures{m}).(flds{x}).(refr{r}).raw(dataindx); 
                    if outdata.UserVals.approaches && strcmp(measures{m},'DistTo') %get approach data here
                    outdata.DLC.(sniplabel).(condition).Approach.(flds{x}).(refr{r}){f,1}(t,1:newarraysz) = NaN;
                    outdata.DLC.(sniplabel).(condition).Approach.(flds{x}).(refr{r}){f,1}(t,inputindx)=DLCdata.Approach.(flds{x}).(refr{r}).Binary(dataindx);
                    end   
                else
                    outdata.DLC.(sniplabel).(condition).(measures{m}).(flds{x}).(refr{r}).trials{f,1}(t,:) = DLCdata.(measures{m}).(flds{x}).(refr{r}).raw(dataindx);
                    if outdata.UserVals.approaches && strcmp(measures{m},'DistTo') %get approach data here
                    outdata.DLC.(sniplabel).(condition).Approach.(flds{x}).(refr{r}){f,1}(t,:) =DLCdata.Approach.(flds{x}).(refr{r}).Binary(dataindx);
                    end
                end
            else
                if DLCdata.paddata
                    outdata.DLC.(sniplabel).(condition).(measures{m}).(flds{x}).(refr{r}).trials{f,1}(t,1:newarraysz) = NaN; 
                    if outdata.UserVals.approaches && strcmp(measures{m},'DistTo') %get approach data here
                    outdata.DLC.(sniplabel).(condition).Approach.(flds{x}).(refr{r}){f,1}(t,1:newarraysz) = NaN;
                    end
                else
                    outdata.DLC.(sniplabel).(condition).(measures{m}).(flds{x}).(refr{r}).trials{f,1}(t,:) = nan(length(dataindx),1);
                    if outdata.UserVals.approaches && strcmp(measures{m},'DistTo')%get approach data here
                    outdata.DLC.(sniplabel).(condition).Approach.(flds{x}).(refr{r}){f,1}(t,:) = nan(length(dataindx),1);
                    end
                end
            end
        end
        clear refr r
        end
        clear flds x

    case 3
        for x = 1:length(flds)
        refr = outdata.UserVals.DLCsetup.Subfields.(measures{m}){2}{x};
        for r = 1:length(refr)
            deg = outdata.UserVals.DLCsetup.Subfields.(measures{m}){3}{x,r};
            if includetrial(t)
                if DLCdata.paddata
                outdata.DLC.(sniplabel).(condition).AngleVectorCoord.(flds{x}).(refr{r}).trials{f,1}.headxy{t,:} = NaN(newarraysz,2);
                outdata.DLC.(sniplabel).(condition).AngleVectorCoord.(flds{x}).(refr{r}).trials{f,1}.tailxy{t,:} = NaN(newarraysz,2);
                outdata.DLC.(sniplabel).(condition).Orient.(flds{x}).(refr{r}).trials{f,1}(t,:) =  NaN(1,newarraysz); 
                outdata.DLC.(sniplabel).(condition).AngleVectorCoord.(flds{x}).(refr{r}).trials{f,1}.headxy{t,:}(inputindx,:) = DLCdata.AngleVectorCoord.(flds{x}).(refr{r}).Head.xy(dataindx,:);
                outdata.DLC.(sniplabel).(condition).AngleVectorCoord.(flds{x}).(refr{r}).trials{f,1}.tailxy{t,:}(inputindx,:) = DLCdata.AngleVectorCoord.(flds{x}).(refr{r}).Tail.xy(dataindx,:);
                if outdata.UserVals.orienting && strcmp(measures{m},'Angle')
                outdata.DLC.(sniplabel).(condition).Orient.(flds{x}).(refr{r}).trials{f,1}(t,inputindx) = DLCdata.Orient.(flds{x}).(refr{r}).Binary(dataindx); 
                end
                else
                outdata.DLC.(sniplabel).(condition).AngleVectorCoord.(flds{x}).(refr{r}).trials{f,1}.headxy{t,:} = DLCdata.AngleVectorCoord.(flds{x}).(refr{r}).Head.xy(dataindx,:);
                outdata.DLC.(sniplabel).(condition).AngleVectorCoord.(flds{x}).(refr{r}).trials{f,1}.tailxy{t,:} = DLCdata.AngleVectorCoord.(flds{x}).(refr{r}).Tail.xy(dataindx,:);
                if outdata.UserVals.orienting && strcmp(measures{m},'Angle')
                outdata.DLC.(sniplabel).(condition).Orient.(flds{x}).(refr{r}).trials{f,1}(t,:) = DLCdata.Orient.(flds{x}).(refr{r}).Binary(dataindx);  
                end
                end
            else
                 if DLCdata.paddata
                     outdata.DLC.(sniplabel).(condition).AngleVectorCoord.(flds{x}).(refr{r}).trials{f,1}.headxy{t,:} = NaN(newarraysz,2);
                     outdata.DLC.(sniplabel).(condition).AngleVectorCoord.(flds{x}).(refr{r}).trials{f,1}.tailxy{t,:} = NaN(newarraysz,2);
                     if outdata.UserVals.orienting && strcmp(measures{m},'Angle')
                     outdata.DLC.(sniplabel).(condition).Orient.(flds{x}).(refr{r}).trials{f,1}(t,:) = NaN(1,newarraysz);
                     end
                 else
                     outdata.DLC.(sniplabel).(condition).AngleVectorCoord.(flds{x}).(refr{r}).trials{f,1}.headxy{t,:} = nan(length(dataindx),2);
                     outdata.DLC.(sniplabel).(condition).AngleVectorCoord.(flds{x}).(refr{r}).trials{f,1}.tailxy{t,:} = nan(length(dataindx),2);
                     if outdata.UserVals.orienting && strcmp(measures{m},'Angle')
                     outdata.DLC.(sniplabel).(condition).Orient.(flds{x}).(refr{r}).trials{f,1}(t,:) = nan(1,length(dataindx));
                     end
                 end
            end
            for d = 1:length(deg)
                if includetrial(t)
                if DLCdata.paddata
                    outdata.DLC.(sniplabel).(condition).(measures{m}).(flds{x}).(refr{r}).(deg{d}).trials{f,1}(t,1:newarraysz) = NaN; 
                    outdata.DLC.(sniplabel).(condition).(measures{m}).(flds{x}).(refr{r}).(deg{d}).trials{f,1}(t,inputindx) = DLCdata.(measures{m}).(flds{x}).(refr{r}).(deg{d})(dataindx); 
                else
                    outdata.DLC.(sniplabel).(condition).(measures{m}).(flds{x}).(refr{r}).(deg{d}).trials{f,1}(t,:) = DLCdata.(measures{m}).(flds{x}).(refr{r}).(deg{d})(dataindx);
                end
                else
                    if DLCdata.paddata
                    outdata.DLC.(sniplabel).(condition).(measures{m}).(flds{x}).(refr{r}).(deg{d}).trials{f,1}(t,1:newarraysz) = NaN;
                    else
                    outdata.DLC.(sniplabel).(condition).(measures{m}).(flds{x}).(refr{r}).(deg{d}).trials{f,1}(t,:) = nan(1,length(dataindx));
                    end
                end
            end    
            clear deg d
        end
        clear refr r
        end
        clear flds x
end
end
end
end


%z score and save speed
if ~DLCdata.paddata
preindx = 1: abs(DLCTRANGE(1));
else
preindx = 1:padfq: (abs(DLCTRANGE(1))*padfq);
end

% for b = 1:length(bps)
%     outdata.DLC.(sniplabel).(condition).BpsSpeedZ.(bps{b}){f,1} = nan(size( outdata.DLC.(sniplabel).(condition).BpsSpeed.(bps{b}){f,1})); %autofill with NaN
%     outdata.DLC.(sniplabel).(condition).BpsSpeedZ2.(bps{b}){f,1} =  nan(size( outdata.DLC.(sniplabel).(condition).BpsSpeed.(bps{b}){f,1}));
%     indxincl = find(includetrial == 1);
%     u = mean(mean (outdata.DLC.(sniplabel).(condition).BpsSpeed.(bps{b}){f,1}(indxincl,preindx),'omitnan'),'omitnan'); %calc pre-event mean using only trials that should be included
%     sdev = std(std(outdata.DLC.(sniplabel).(condition).BpsSpeed.(bps{b}){f,1}(indxincl,preindx),'omitnan'),'omitnan'); %calc pre-event stdev using only trials that should be included
%     for z = 1:length(outdata.DLC.(sniplabel).(condition).BpsSpeed.(bps{b}){f,1}(:,1))%for each trial
%         if includetrial(z) %overwrite NaN values if trial should be included
%             if  sum(~isnan(outdata.DLC.(sniplabel).(condition).BpsSpeed.(bps{b}){f,1}(z,preindx))) >= 2
%                 tu = mean(outdata.DLC.(sniplabel).(condition).BpsSpeed.(bps{b}){f,1}(z,preindx),'omitnan');
%                 tsdev = std(outdata.DLC.(sniplabel).(condition).BpsSpeed.(bps{b}){f,1}(z,preindx),'omitnan');
%                 outdata.DLC.(sniplabel).(condition).BpsSpeedZ2.(bps{b}){f,1}(z,:)= arrayfun(@(x)(x-tu)/tsdev,outdata.DLC.(sniplabel).(condition).BpsSpeed.(bps{b}){f,1}(z,:));
%             else
%                 outdata.DLC.(sniplabel).(condition).BpsSpeedZ2.(bps{b}){f,1}(z,:) = arrayfun(@(x)(x-u)/sdev,outdata.DLC.(sniplabel).(condition).BpsSpeed.(bps{b}){f,1}(z,:));    
%             end
%         end 
%     end
%         clear u sdev
% end


%% Get average data
    arraywidth = size(outdata.DLC.(sniplabel).(condition).frameindx{f,1},2);
    nt = size(outdata.DLC.(sniplabel).(condition).frameindx{f,1},1);

    %get quadrant data
    if isfield(outdata.UserVals.DLCsetup.Subfields,'Quadrant')
    quad = {'LT','LB','RT','RB'};
    quadbps = outdata.UserVals.DLCsetup.Subfields.Quadrant{1,1};
    for qb = 1:length(quadbps)
        for q = 1:4
            if nt > 1
                temp = nan(length(outdata.DLC.(sniplabel).(condition).Quadrant.(quadbps{qb}).(quad{q}).trials{f,1}(:,1)),1);
                for t = 1:length(outdata.DLC.(sniplabel).(condition).Quadrant.(quadbps{qb}).(quad{q}).trials{f,1}(:,1))
                    validpoints = sum(~isnan(outdata.DLC.(sniplabel).(condition).Quadrant.(quadbps{qb}).(quad{q}).trials{f,1}(t,:)));
                    if validpoints ~= 0 %if not all points are nan
                        temp(t,1) = (sum(outdata.DLC.(sniplabel).(condition).Quadrant.(quadbps{qb}).(quad{q}).trials{f,1}(t,:),'omitnan')/validpoints)*100;
                    end
                end
                outdata.DLC.(sniplabel).(condition).Quadrant.(quadbps{qb}).(quad{q}).mean{f,1} = mean(temp,'omitnan');
                outdata.DLC.(sniplabel).(condition).Quadrant.(quadbps{qb}).(quad{q}).stdev{f,1} = std(temp,'omitnan');
                outdata.DLC.(sniplabel).(condition).Quadrant.(quadbps{qb}).(quad{q}).n{f,1} = sum(~isnan(temp));
                outdata.DLC.(sniplabel).(condition).Quadrant.(quadbps{qb}).(quad{q}).sem{f,1} = outdata.DLC.(sniplabel).(condition).Quadrant.(quadbps{qb}).(quad{q}).stdev{f,1}/sqrt(outdata.DLC.(sniplabel).(condition).Quadrant.(quadbps{qb}).(quad{q}).n{f,1});
            else
                outdata.DLC.(sniplabel).(condition).Quadrant.(quadbps{qb}).(quad{q}).mean{f,1} = NaN;
                outdata.DLC.(sniplabel).(condition).Quadrant.(quadbps{qb}).(quad{q}).stdev{f,1} = NaN;
                outdata.DLC.(sniplabel).(condition).Quadrant.(quadbps{qb}).(quad{q}).n{f,1} = NaN;
                outdata.DLC.(sniplabel).(condition).Quadrant.(quadbps{qb}).(quad{q}).sem{f,1} = NaN;
            end
        end
    end
    end

% for qb = 1:length(quadbps)
% for q = 1:4
%     if nt > 1
%     outdata.DLC.(sniplabel).(condition).Quadrant.(quadbps{qb}).(quad{q}).average(f,:) = mean(outdata.DLC.(sniplabel).(condition).Quadrant.(quadbps{qb}).(quad{q}).trials{f,1} ,'omitnan');
%     outdata.DLC.(sniplabel).(condition).Quadrant.(quadbps{qb}).(quad{q}).stdev(f,:)= std(outdata.DLC.(sniplabel).(condition).Quadrant.(quadbps{qb}).(quad{q}).trials{f,1},'omitnan');
%     outdata.DLC.(sniplabel).(condition).Quadrant.(quadbps{qb}).(quad{q}).n(f,:)= sum(~isnan(outdata.DLC.(sniplabel).(condition).Quadrant.(quadbps{qb}).(quad{q}).trials{f,1}));
%     outdata.DLC.(sniplabel).(condition).Quadrant.(quadbps{qb}).(quad{q}).sem(f,:)= outdata.DLC.(sniplabel).(condition).Quadrant.(quadbps{qb}).(quad{q}).stdev(f,:)/sqrt(outdata.DLC.(sniplabel).(condition).Quadrant.(quadbps{qb}).(quad{q}).n(f,:));    
%     else
%     outdata.DLC.(sniplabel).(condition).Quadrant.(quadbps{qb}).(quad{q}).average(f,:) = nan;
%     outdata.DLC.(sniplabel).(condition).Quadrant.(quadbps{qb}).(quad{q}).stdev(f,:)= nan;
%     outdata.DLC.(sniplabel).(condition).Quadrant.(quadbps{qb}).(quad{q}).n(f,:)= nan;
%     outdata.DLC.(sniplabel).(condition).Quadrant.(quadbps{qb}).(quad{q}).sem(f,:)= nan;
% 
%     end
% 
% end
% end

% %angluar velocity data
% if isfield(outdata.UserVals.DLCsetup.Subfields,'AngularVelocity')
%     ref = outdata.UserVals.DLCsetup.Subfields.AngularVelocity{1,1};
%     for r = 1:length(ref)
%      if nt > 1
%         outdata.DLC.(sniplabel).(condition).AngularVelocity.(ref{r}).velocity.average(f,:) = mean(outdata.DLC.(sniplabel).(condition).AngularVelocity.(ref{r}).velocity.trials{f,1}.raw,'omitnan');
%         outdata.DLC.(sniplabel).(condition).AngularVelocity.(ref{r}).velocity.stdev(f,:) = std(outdata.DLC.(sniplabel).(condition).AngularVelocity.(ref{r}).velocity.trials{f,1}.raw,'omitnan');
%         for i = 1:length(outdata.DLC.(sniplabel).(condition).AngularVelocity.(ref{r}).velocity.stdev(f,:))
%         outdata.DLC.(sniplabel).(condition).AngularVelocity.(ref{r}).velocity.n(f,i) = sum(~isnan(outdata.DLC.(sniplabel).(condition).AngularVelocity.(ref{r}).velocity.trials{f,1}.raw(:,i)));
%         outdata.DLC.(sniplabel).(condition).AngularVelocity.(ref{r}).velocity.sem(f,i) = outdata.DLC.(sniplabel).(condition).AngularVelocity.(ref{r}).velocity.stdev(f,i)/sqrt(outdata.DLC.(sniplabel).(condition).AngularVelocity.(ref{r}).velocity.n(f,i));
%         end
%         outdata.DLC.(sniplabel).(condition).AngularVelocity.(ref{r}).avvelocity.average(f,:) = mean(outdata.DLC.(sniplabel).(condition).AngularVelocity.(ref{r}).velocity.trials{f,1}.average,'omitnan');
%         outdata.DLC.(sniplabel).(condition).AngularVelocity.(ref{r}).avvelocity.stdev(f,:) = std(outdata.DLC.(sniplabel).(condition).AngularVelocity.(ref{r}).velocity.trials{f,1}.average,'omitnan');
%         outdata.DLC.(sniplabel).(condition).AngularVelocity.(ref{r}).avvelocity.n(f,:) = sum(~isnan(outdata.DLC.(sniplabel).(condition).AngularVelocity.(ref{r}).velocity.trials{f,1}.average));
%         outdata.DLC.(sniplabel).(condition).AngularVelocity.(ref{r}).avvelocity.sem(f,:) = outdata.DLC.(sniplabel).(condition).AngularVelocity.(ref{r}).velocity.stdev(f,:)/sqrt(outdata.DLC.(sniplabel).(condition).AngularVelocity.(ref{r}).velocity.n(f,:));  
%      else
%         outdata.DLC.(sniplabel).(condition).AngularVelocity.(ref{r}).velocity.average(f,:) = NaN(1,arraywidth);
%         outdata.DLC.(sniplabel).(condition).AngularVelocity.(ref{r}).velocity.stdev(f,:) = NaN(1,arraywidth);
%         outdata.DLC.(sniplabel).(condition).AngularVelocity.(ref{r}).velocity.n(f,:) = NaN(1,arraywidth);
%         outdata.DLC.(sniplabel).(condition).AngularVelocity.(ref{r}).velocity.sem(f,:) = NaN(1,arraywidth);
%         outdata.DLC.(sniplabel).(condition).AngularVelocity.(ref{r}).avvelocity.average(f,:) = NaN;
%         outdata.DLC.(sniplabel).(condition).AngularVelocity.(ref{r}).avvelocity.stdev(f,:) = NaN;
%         outdata.DLC.(sniplabel).(condition).AngularVelocity.(ref{r}).avvelocity.n(f,:) = NaN;
%         outdata.DLC.(sniplabel).(condition).AngularVelocity.(ref{r}).avvelocity.sem(f,:) = NaN;
%      end
%      end
% 
% end

    for m = 1:length(measures)
        numsubfields = length(outdata.UserVals.DLCsetup.Subfields.(measures{m}));
        flds = outdata.UserVals.DLCsetup.Subfields.(measures{m}){1};
        for x =1:length(flds) 
        switch numsubfields
        case 1
            if nt > 1
                outdata.DLC.(sniplabel).(condition).(measures{m}).(flds{x}).mean(f,:) = mean(outdata.DLC.(sniplabel).(condition).(measures{m}).(flds{x}).trials{f,1},'omitnan');
                outdata.DLC.(sniplabel).(condition).(measures{m}).(flds{x}).std(f,:) = std (outdata.DLC.(sniplabel).(condition).(measures{m}).(flds{x}).trials{f,1},'omitnan');
                for i = 1: length(outdata.DLC.(sniplabel).(condition).(measures{m}).(flds{x}).trials{f,1}(1,:))%for each frame caluclate n and sem to exclude missing data
                    outdata.DLC.(sniplabel).(condition).(measures{m}).(flds{x}).n (f,i) = length(outdata.DLC.(sniplabel).(condition).(measures{m}).(flds{x}).trials{f,1}(:,1))-sum(isnan(outdata.DLC.(sniplabel).(condition).(measures{m}).(flds{x}).trials{f,1}(:,1)));
                    outdata.DLC.(sniplabel).(condition).(measures{m}).(flds{x}).sem(f,i) = outdata.DLC.(sniplabel).(condition).(measures{m}).(flds{x}).std(f,i)/sqrt(outdata.DLC.(sniplabel).(condition).(measures{m}).(flds{x}).n(f,i));
                end
            else
                outdata.DLC.(sniplabel).(condition).(measures{m}).(flds{x}).mean(f,:) = NaN(1,arraywidth);
                outdata.DLC.(sniplabel).(condition).(measures{m}).(flds{x}).std(f,:) = NaN(1,arraywidth);
                outdata.DLC.(sniplabel).(condition).(measures{m}).(flds{x}).n (f,:) = NaN;
                outdata.DLC.(sniplabel).(condition).(measures{m}).(flds{x}).sem(f,:) = NaN(1,arraywidth);
            end
        case 2
            refr = outdata.UserVals.DLCsetup.Subfields.(measures{m}){2}{x};
            for r = 1:length(refr)
                if nt > 1 
                outdata.DLC.(sniplabel).(condition).(measures{m}).(flds{x}).(refr{r}).mean(f,:) = mean(outdata.DLC.(sniplabel).(condition).(measures{m}).(flds{x}).(refr{r}).trials{f,1},'omitnan');
                outdata.DLC.(sniplabel).(condition).(measures{m}).(flds{x}).(refr{r}).std(f,:) = std (outdata.DLC.(sniplabel).(condition).(measures{m}).(flds{x}).(refr{r}).trials{f,1},'omitnan');
                for i = 1: length(outdata.DLC.(sniplabel).(condition).(measures{m}).(flds{x}).(refr{r}).trials{f,1}(1,:))%for each frame caluclate n and sem to exclude missing data
                outdata.DLC.(sniplabel).(condition).(measures{m}).(flds{x}).(refr{r}).n (f,i) = length(outdata.DLC.(sniplabel).(condition).(measures{m}).(flds{x}).(refr{r}).trials{f,1}(:,1))-sum(isnan(outdata.DLC.(sniplabel).(condition).(measures{m}).(flds{x}).(refr{r}).trials{f,1}(:,1)));
                outdata.DLC.(sniplabel).(condition).(measures{m}).(flds{x}).(refr{r}).sem(f,i) = outdata.DLC.(sniplabel).(condition).(measures{m}).(flds{x}).(refr{r}).std(f,i)/sqrt(outdata.DLC.(sniplabel).(condition).(measures{m}).(flds{x}).(refr{r}).n(f,i));
                end
                else
                outdata.DLC.(sniplabel).(condition).(measures{m}).(flds{x}).(refr{r}).mean(f,:) = NaN(1,arraywidth);
                outdata.DLC.(sniplabel).(condition).(measures{m}).(flds{x}).(refr{r}).std(f,:) = NaN(1,arraywidth);
                outdata.DLC.(sniplabel).(condition).(measures{m}).(flds{x}).(refr{r}).n (f,:) = NaN;
                outdata.DLC.(sniplabel).(condition).(measures{m}).(flds{x}).(refr{r}).sem(f,:) = NaN(1,arraywidth);
                end
            end
        case 3
            refr = outdata.UserVals.DLCsetup.Subfields.(measures{m}){2}{x};
            for r = 1:length(refr)
                degs = outdata.UserVals.DLCsetup.Subfields.Angle{3}{x,r};
                for d = 1:length(degs) 
                if nt > 1 
                outdata.DLC.(sniplabel).(condition).(measures{m}).(flds{x}).(refr{r}).(degs{d}).mean(f,:) = mean(outdata.DLC.(sniplabel).(condition).(measures{m}).(flds{x}).(refr{r}).(degs{d}).trials{f,1},'omitnan');
                outdata.DLC.(sniplabel).(condition).(measures{m}).(flds{x}).(refr{r}).(degs{d}).std(f,:) = std (outdata.DLC.(sniplabel).(condition).(measures{m}).(flds{x}).(refr{r}).(degs{d}).trials{f,1},'omitnan');
                for i = 1: length(outdata.DLC.(sniplabel).(condition).(measures{m}).(flds{x}).(refr{r}).(degs{d}).trials{f,1}(1,:))%for each frame caluclate n and sem to exclude missing data
                outdata.DLC.(sniplabel).(condition).(measures{m}).(flds{x}).(refr{r}).(degs{d}).n (f,i) = length(outdata.DLC.(sniplabel).(condition).(measures{m}).(flds{x}).(refr{r}).(degs{d}).trials{f,1}(:,1))-sum(isnan(outdata.DLC.(sniplabel).(condition).(measures{m}).(flds{x}).(refr{r}).(degs{d}).trials{f,1}(:,1)));
                outdata.DLC.(sniplabel).(condition).(measures{m}).(flds{x}).(refr{r}).(degs{d}).sem(f,i) = outdata.DLC.(sniplabel).(condition).(measures{m}).(flds{x}).(refr{r}).(degs{d}).std(f,i)/sqrt(outdata.DLC.(sniplabel).(condition).(measures{m}).(flds{x}).(refr{r}).(degs{d}).n(f,i));
                end
                else
                outdata.DLC.(sniplabel).(condition).(measures{m}).(flds{x}).(refr{r}).(degs{d}).mean(f,:) = NaN(1,arraywidth);
                outdata.DLC.(sniplabel).(condition).(measures{m}).(flds{x}).(refr{r}).(degs{d}).std(f,:) = NaN(1,arraywidth);
                outdata.DLC.(sniplabel).(condition).(measures{m}).(flds{x}).(refr{r}).(degs{d}).n (f,:) = NaN;
                outdata.DLC.(sniplabel).(condition).(measures{m}).(flds{x}).(refr{r}).(degs{d}).sem(f,:) = NaN(1,arraywidth);
                end
                end
            end  
        end
        end     
end

