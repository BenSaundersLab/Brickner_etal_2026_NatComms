function [DLCdata] = DLC_Analyze(f,outdata,dlccsv)
%Sonal Sinha, edited by A Wolff 15/2/21
%% Function to analyze DLC data from CSV file 
%Inputs:
%f - current file number used to reference outdata
%outdata- required to extract timestamp data from corresponding photometry recording
%dlccsv - string: name of csv file containing DLC data
%VideoFPS - framerate of acquired video
%setconf - level of confidence required to include data
DLCdata.bps = outdata.UserVals.DLC.bps;
DLCdata.environfeats = outdata.UserVals.DLC.environfeats;
DLCdata.environfeatlabs = outdata.UserVals.DLC.environfeatlabs;
% Subfields = outdata.UserVals.DLCSetup.Subfields; 
refLED = {'CueOn_LED','midOn_LED','topOn_LED'};
DLCdata.LED = outdata.UserVals.DLC.LED;
DLCdata.headbps = {'Nose','Implant','L_ear','R_ear','L_eye','R_eye','CofHead'};
DLCdata.bodybps = {'Shoulder','MidBack','TopBack','BottomBack','Tail_base','CathPort'};
videoFPS = outdata.videodata.vidFPS{f,1};
setconf =  outdata.UserVals.DLC.Conf;
Subfields = outdata.UserVals.DLCsetup.Subfields; 

if videoFPS < outdata.UserVals.DLC.MaxFPS
    DLCdata.paddata = true;
    DLCdata.FPS = outdata.UserVals.DLC.MaxFPS;
    %DLCdata.tsarray = outdata.UserVals.DLCsetup.maxtimestamparray{f,1};
else
    DLCdata.paddata = false;
    DLCdata.FPS = round(videoFPS);
end

%% Load Data into Structure
% into table, then cell
T_original = readtable(dlccsv,'Format','auto');
A_original = table2array(T_original);

num_frames = length(outdata.videodata.frames.onset{f,1});
DLCdata.timestamps = outdata.videodata.frames.onset{f,1};

% remove spaces in body part labels
bps = A_original(1,2:end);
bps = strrep(bps,' ','');

% create a data structure
for x = (1:3:length(bps))
   DLCdata.(bps{x}).xy(:,1:2) = str2double(A_original(3:end,x+1:x+2));
   DLCdata.(bps{x}).conf(:,1) = str2double(A_original(3:end,x+3));
end

%% Get absolute location of Environ Features for all subsequent measurements
for e = 1:length(DLCdata.environfeats)
    if isfield(DLCdata,(DLCdata.environfeats{e})) %only do this if the feature was found in the csv file
    confindx = find (DLCdata.(DLCdata.environfeats{e}).conf >= setconf); %find indx of points with high confidence
    if length(confindx) > 20 %only include if there are more than 20 frames where confiden
    coords = DLCdata.(DLCdata.environfeats{e}).xy(confindx,:); %extract only xy coordinates that meet conf criteria
    DLCdata.FixedPoints.(DLCdata.environfeatlabs{e}) = mean(coords); %average to get single location of fixed point
    clear coords confindx
    else
        display (strcat(DLCdata.environfeats{e},' does not exist'))
    end
    else
    display (strcat(DLCdata.environfeats{e},' does not exist'))
    end
end
    
%% Calculate pixpercm conversion using floor markers
%Calculate pixpercm
angledist = hypot(23.5,29.53); %distance in cm of diagonal across box grid floor
if isfield(DLCdata.FixedPoints,'LeftTop') && isfield(DLCdata.FixedPoints,'RightBottom')
pixpercm1= Distance(DLCdata.FixedPoints.LeftTop,DLCdata.FixedPoints.RightBottom)/angledist; %angle from top left to right bottom
else
    pixpercm1 = NaN;
end
if isfield(DLCdata.FixedPoints,'RightTop') && isfield(DLCdata.FixedPoints,'LeftBottom')
pixpercm2= Distance(DLCdata.FixedPoints.RightTop,DLCdata.FixedPoints.LeftBottom)/angledist; %angle from top right to left bottom
else
    pixpercm2 = NaN;
end
if isfield(DLCdata.FixedPoints,'LeftTop') && isfield(DLCdata.FixedPoints,'RightTop')
pixpercm3= Distance(DLCdata.FixedPoints.LeftTop,DLCdata.FixedPoints.RightTop)/29.53; %width top left to right
else
    pixpercm3 = NaN;
end
if isfield(DLCdata.FixedPoints,'LeftBottom') && isfield(DLCdata.FixedPoints,'RightBottom')
pixpercm4= Distance(DLCdata.FixedPoints.LeftBottom,DLCdata.FixedPoints.RightBottom)/29.53;%width bottom left to right
else
    pixpercm4 = NaN;
end
if isfield(DLCdata.FixedPoints,'LeftTop') && isfield(DLCdata.FixedPoints,'LeftBottom')
pixpercm5= Distance(DLCdata.FixedPoints.LeftTop,DLCdata.FixedPoints.LeftBottom)/23.5; %height left top to bottom
else
    pixpercm5 = NaN;
end
if isfield(DLCdata.FixedPoints,'RightTop') && isfield(DLCdata.FixedPoints,'RightBottom')
pixpercm6= Distance(DLCdata.FixedPoints.RightTop,DLCdata.FixedPoints.RightBottom)/23.5;%height right top to bottom
else
    pixpercm6 = NaN;
    
end

if isfield(DLCdata.FixedPoints,'LeftTop') && isfield(DLCdata.FixedPoints,'RightTop')
LRtop = Distance(DLCdata.FixedPoints.LeftTop,DLCdata.FixedPoints.RightTop);
else
    LRtop = NaN;
end
if isfield(DLCdata.FixedPoints,'LeftBottom') && isfield(DLCdata.FixedPoints,'RightBottom')
LRbot = Distance(DLCdata.FixedPoints.LeftBottom,DLCdata.FixedPoints.RightBottom);
else
    LRbot = NaN;
end
LRav = (mean([LRtop LRbot],'omitnan'))/2;
if isfield(DLCdata.FixedPoints,'LeftTop') && isfield(DLCdata.FixedPoints,'LeftBottom')
TBL = Distance(DLCdata.FixedPoints.LeftTop,DLCdata.FixedPoints.LeftBottom);
else
    TBL = NaN;
end
if isfield(DLCdata.FixedPoints,'RightTop') && isfield(DLCdata.FixedPoints,'RightBottom')
TBR = Distance(DLCdata.FixedPoints.RightTop,DLCdata.FixedPoints.RightBottom);
else
    TBR = NaN;
end
TBav = (mean([TBR TBL],'omitnan'))/2;


if isfield(DLCdata.FixedPoints,'LeftTop')
DLCdata.FixedPoints.CenterofEnviron(1) = DLCdata.FixedPoints.LeftTop (1) + LRav;
DLCdata.FixedPoints.CenterofEnviron(2) = DLCdata.FixedPoints.LeftTop(2) + TBav;
else
    if isfield(DLCdata.FixedPoints,'LeftBottom')
        DLCdata.FixedPoints.CenterofEnviron(1) = DLCdata.FixedPoints.LeftBottom (1) + LRav;
        DLCdata.FixedPoints.CenterofEnviron(2) = DLCdata.FixedPoints.LeftBottom(2) - TBav;
    end
end

DLCdata.pixpercm = mean([pixpercm1,pixpercm2,pixpercm3,pixpercm4,pixpercm5,pixpercm6],'omitnan'); %average all measurments
pixpercm = DLCdata.pixpercm;

if isfield(DLCdata.FixedPoints,'LeftTop') && isfield(DLCdata.FixedPoints,'RightTop') 
DLCdata.measdistor(1) = Distance(DLCdata.FixedPoints.LeftTop,DLCdata.FixedPoints.RightTop)/DLCdata.pixpercm; %measure top width to check distortion
end
if isfield(DLCdata.FixedPoints,'LeftBottom') && isfield(DLCdata.FixedPoints,'RightBottom') 
DLCdata.measdistor(2) = Distance(DLCdata.FixedPoints.LeftBottom,DLCdata.FixedPoints.RightBottom)/DLCdata.pixpercm; %measure bottom width to check distortion
end


%%correction for location of cue using pixpercm
if isfield(DLCdata.FixedPoints,'BottomLight')%only do this if the feature was found in the csv file
    coords =  DLCdata.FixedPoints.BottomLight(1) + pixpercm*2.25; %extract only xy coordinates that meet conf criteria
    DLCdata.FixedPoints.BottomLight(1) = coords; %average to get single location of fixed point
     coords =  DLCdata.FixedPoints.BottomLight(2) + pixpercm*0.1; %extract only xy coordinates that meet conf criteria
     DLCdata.FixedPoints.BottomLight(2) = coords; %average to get single location of fixed point
    clear coords 
end

if isfield(DLCdata.FixedPoints,'TopLight')%only do this if the feature was found in the csv file
    coords =  DLCdata.FixedPoints.TopLight(1) + pixpercm*2.16; %extract only xy coordinates that meet conf criteria
    DLCdata.FixedPoints.TopLight(1) = coords; %average to get single location of fixed point
     coords =  DLCdata.FixedPoints.TopLight(2) + pixpercm*0.5; %extract only xy coordinates that meet conf criteria
     DLCdata.FixedPoints.TopLight(2) = coords; %average to get single location of fixed point
    clear coords 
end

%generate Lever locations (fixed)
if isfield(DLCdata.FixedPoints,'BottomLight')%only do this if the feature was found in the csv file
    coords =  DLCdata.FixedPoints.BottomLight(1) + pixpercm*1.8; %extract only xy coordinates that meet conf criteria
    DLCdata.FixedPoints.BottomLever(1) = coords; %average to get single location of fixed point
     coords =  DLCdata.FixedPoints.BottomLight(2) ; %extract only xy coordinates that meet conf criteria
     DLCdata.FixedPoints.BottomLever(2) = coords; %average to get single location of fixed point
    clear coords 
end

if isfield(DLCdata.FixedPoints,'TopLight')%only do this if the feature was found in the csv file
    coords =  DLCdata.FixedPoints.TopLight(1) + pixpercm*1.6; %extract only xy coordinates that meet conf criteria
    DLCdata.FixedPoints.TopLever(1) = coords; %average to get single location of fixed point
     coords =  DLCdata.FixedPoints.TopLight(2)+pixpercm*1.2; %extract only xy coordinates that meet conf criteria
     DLCdata.FixedPoints.TopLever(2) = coords; %average to get single location of fixed point
    clear coords 
end

%%correction for location of LeftMag using pixpercm
if isfield(DLCdata.FixedPoints,'LeftMag')%only do this if the feature was found in the csv file
    coords =  DLCdata.FixedPoints.LeftMag(1) - pixpercm*1.8; %extract only xy coordinates that meet conf criteria
    DLCdata.FixedPoints.LeftMag(1) = coords; %average to get single location of fixed point
     coords =  DLCdata.FixedPoints.LeftMag(2) + pixpercm*0.4; %extract only xy coordinates that meet conf criteria
     DLCdata.FixedPoints.LeftMag(2) = coords; %average to get single location of fixed point
    clear coords 
end
if isfield(DLCdata.FixedPoints,'RightMag')%only do this if the feature was found in the csv file
    coords =  DLCdata.FixedPoints.RightMag(1) + pixpercm*1.8; %extract only xy coordinates that meet conf criteria
    DLCdata.FixedPoints.RightMag(1) = coords; %average to get single location of fixed point
     coords =  DLCdata.FixedPoints.RightMag(2) + pixpercm*0.4; %extract only xy coordinates that meet conf criteria
     DLCdata.FixedPoints.RightMag(2) = coords; %average to get single location of fixed point
    clear coords 
end

%% Filter out low confidence coordinates for Bodyparts
for b = 1: length(DLCdata.bps)
    if isfield(DLCdata,(DLCdata.bps{b}))%only do this if the bodypart was found in the csv file
    DLCdata.bodyparts.(DLCdata.bps{b}).xy = NaN(size(DLCdata.(DLCdata.bps{b}).conf,1),2); %autofill array with NaN
    confindx = find(DLCdata.(DLCdata.bps{b}).conf >= setconf); % find indx of coords that meet conf criteria
    DLCdata.bodyparts.(DLCdata.bps{b}).xy(confindx,:) = DLCdata.(DLCdata.bps{b}).xy(confindx,:); %replace NaN with values where confident
    else
    display (strcat((DLCdata.bps{b}),' does not exist'))
    end
end

%% Linear Interpolation of Bodyparts
% for b = 1: length(DLCdata.bps)
%     if isfield(DLCdata,(DLCdata.bps{b}))%only do this if the bodypart was found in the csv file
% x = DLCdata.(DLCdata.bps{b}).xy(:,1);
% y = DLCdata.(DLCdata.bps{b}).xy(:,2);
% 
% nanx = isnan(x);
% t    = 1:numel(x);
% x(nanx) = interp1(t(~nanx), x(~nanx), t(nanx),'linear');
% 
% nany = isnan(y);
% t    = 1:numel(y);
% y(nany) = interp1(t(~nany), x(~nany), t(nany),'linear');
% DLCdata.bodyparts.(DLCdata.bps{b}).xy(:,1) = x;
% DLCdata.bodyparts.(DLCdata.bps{b}).xy(:,2) = y;
%     end
%end

%Bodypart in Quadrant
QuadBPs = {'Nose','Implant','Shoulder','MidBack'};
for b = 1: length(QuadBPs)
    if isfield(DLCdata,(QuadBPs{b}))%only do this if the bodypart was found in the csv file
    DLCdata.Quadrant.(QuadBPs{b}).LB = zeros(size(DLCdata.(QuadBPs{b}).conf,1),1); %autofill array with NaN
    DLCdata.Quadrant.(QuadBPs{b}).LT = zeros(size(DLCdata.(QuadBPs{b}).conf,1),1); %autofill array with NaN
    DLCdata.Quadrant.(QuadBPs{b}).RB = zeros(size(DLCdata.(QuadBPs{b}).conf,1),1); %autofill array with NaN
    DLCdata.Quadrant.(QuadBPs{b}).RT = zeros(size(DLCdata.(QuadBPs{b}).conf,1),1); %autofill array with NaN
    DLCdata.Quadrant.(QuadBPs{b}).all = cell(size(DLCdata.(QuadBPs{b}).conf,1),1);
    for fr = 1:length(DLCdata.bodyparts.(QuadBPs{b}).xy)
        if ~isnan(DLCdata.bodyparts.(QuadBPs{b}).xy(fr,1))
        if DLCdata.bodyparts.(QuadBPs{b}).xy(fr,1) <  DLCdata.FixedPoints.CenterofEnviron(1,1)% if x is less than center x then Left
            %top or bottom
            if DLCdata.bodyparts.(QuadBPs{b}).xy(fr,2) <  DLCdata.FixedPoints.CenterofEnviron(1,2) %if y < center then Top
                DLCdata.Quadrant.(QuadBPs{b}).LT(fr,1) = 1; 
                DLCdata.Quadrant.(QuadBPs{b}).all{fr,1} = 'LT';
            else
                DLCdata.Quadrant.(QuadBPs{b}).LB(fr,1) = 1; 
                DLCdata.Quadrant.(QuadBPs{b}).all{fr,1} = 'LB';
            end
        else % quadrant is right
            if DLCdata.bodyparts.(QuadBPs{b}).xy(fr,2) <  DLCdata.FixedPoints.CenterofEnviron(1,2) %if y < center then Top
                DLCdata.Quadrant.(QuadBPs{b}).RT(fr,1) = 1;
                DLCdata.Quadrant.(QuadBPs{b}).all{fr,1} = 'RT';
            else
                DLCdata.Quadrant.(QuadBPs{b}).RB(fr,1) = 1; 
                DLCdata.Quadrant.(QuadBPs{b}).all{fr,1}= 'RB';
            end
        end
        else %if bodypart not visible fill all quadrants with nan
            DLCdata.Quadrant.(QuadBPs{b}).LT(fr,1) = NaN;
            DLCdata.Quadrant.(QuadBPs{b}).LB(fr,1) = NaN;
            DLCdata.Quadrant.(QuadBPs{b}).RT(fr,1) = NaN;
            DLCdata.Quadrant.(QuadBPs{b}).RB(fr,1) = NaN;
            DLCdata.Quadrant.(QuadBPs{b}).all{fr,1} = NaN;
        end   
    end
    else
    display (strcat((QuadBPs{b}),' does not exist'))
    end
end


%% Filter low confidence from indicator LEDs
timeperframe = 1/DLCdata.FPS;
framewin = ceil(0.15/timeperframe);

for i = 1:length(refLED)
    if isfield(DLCdata,(refLED{i}))%only do this if the bodypart was found in the csv file
        DLCdata.LEDs.(DLCdata.LED{i}).xy = NaN(size(DLCdata.(refLED{i}).conf,1),2); %autofill array with NaN
        DLCdata.LEDs.(DLCdata.LED{i}).binaryarray = false(size(DLCdata.(refLED{i}).conf,1),1);
        confindx = find(DLCdata.(refLED{i}).conf >= 0.85); % find indx of coords that meet conf criteria
        if ~isempty(confindx) && length(confindx) > 2
            coords = DLCdata.(refLED{i}).xy(confindx,:); %extract only xy coordinates that meet conf criteria
            coords = ones(length(coords),2).*mean(coords);
            DLCdata.LEDs.(DLCdata.LED{i}).xy(confindx,1:2) = coords; %replace NaN with values where confident with the mean location of the cue
            DLCdata.LEDs.(DLCdata.LED{i}).binaryarray (confindx,1) = true; 
            clear coords
    % get onset and offset times for LED indicator events
    t = 1;
    findonset = true;
    for x = 2:num_frames-framewin+1 %go through whole trace with windowing to find onset and offset events
        indxarray = x:x+(framewin-1); %indx for the current window
         currwin = DLCdata.LEDs.(DLCdata.LED{i}).binaryarray(indxarray,1);
        if findonset %if looking for an onset event then check sum == framewin
        if sum(currwin) == framewin
        DLCdata.LEDs.(DLCdata.LED{i}).onset.ts(t,1) = DLCdata.timestamps(x); 
        DLCdata.LEDs.(DLCdata.LED{i}).onset.indx(t,1) = x;
        findonset = false;
        end
        else
        if sum(currwin) == 0
        DLCdata.LEDs.(DLCdata.LED{i}).offset.ts(t,1) = DLCdata.timestamps(x); 
        DLCdata.LEDs.(DLCdata.LED{i}).offset.indx(t,1) = x;
        DLCdata.LEDs.(DLCdata.LED{i}).binaryarray(DLCdata.LEDs.(DLCdata.LED{i}).onset.indx(t,1):DLCdata.LEDs.(DLCdata.LED{i}).offset.indx(t,1)-1) = 1;
        clear startindx
        t = t+1;
        findonset = true;
        end
        end
    end
        end
        if ~isfield(DLCdata.LEDs.(DLCdata.LED{i}),'onset')
            DLCdata.LEDs.(DLCdata.LED{i}).onset.ts=  []; 
            DLCdata.LEDs.(DLCdata.LED{i}).onset.indx=  []; 
            DLCdata.LEDs.(DLCdata.LED{i}).offset.ts = [];
            DLCdata.LEDs.(DLCdata.LED{i}).offset.indx=  []; 

        end
    end
end


%% calculate distance moved for each bodypart
for b = 1:length(DLCdata.bps)
    if isfield(DLCdata,(DLCdata.bps{b}))
        DLCdata.BpsDist.(DLCdata.bps{b}).raw(1,1) = NaN; %can't calculate distance for first frame as no previous data
        if isnan(DLCdata.bodyparts.(DLCdata.bps{b}).xy(1,1))
        lastframe = NaN;
        else
        lastframe = 1;
        end
        
        for i = 2:length(DLCdata.bodyparts.(DLCdata.bps{b}).xy(:,1)) %start at 2nd frame
            if isnan(lastframe)%incase the first frame is low confidence
                if ~isnan(DLCdata.bodyparts.(DLCdata.bps{b}).xy(i,1))%if this frame has valid data make this the last frame
                lastframe = i;
                else
                DLCdata.BpsDist.(DLCdata.bps{b}).raw(i,1) = NaN;
                end
            else %if there is valid last frame data then calculate distance using last frame      
                if ~isnan(DLCdata.bodyparts.(DLCdata.bps{b}).xy(i,1)) %if there is data for this frame
                DLCdata.BpsDist.(DLCdata.bps{b}).raw(i,1) = (Distance(DLCdata.bodyparts.(DLCdata.bps{b}).xy(i,:),DLCdata.bodyparts.(DLCdata.bps{b}).xy(lastframe,:))/pixpercm);
                lastframe = i;
                else
                DLCdata.BpsDist.(DLCdata.bps{b}).raw(i,1) = NaN;
                end
            end 
        end
    end
end

%extract user selected bodyparts info
if isfield(Subfields,'MoveDist')
for x = 1: length(Subfields.MoveDist{1})
    DLCdata.MoveDist.(Subfields.MoveDist{1}{x}).raw = DLCdata.BpsDist.(Subfields.MoveDist{1}{x}).raw;
    DLCdata.MoveDist.(Subfields.MoveDist{1}{x}).totalcumul = sum(DLCdata.MoveDist.(Subfields.MoveDist{1}{x}).raw(~isnan(DLCdata.MoveDist.(Subfields.MoveDist{1}{x}).raw)));
end
end

%% Distance to location
% Take average of evironment location
% Calculation 1: From bodypart to location
% calculate distance and add new field to data structure:
% DistTo.Bodypart
if isfield(Subfields,'DistTo')
for x = 1: length(Subfields.DistTo{1})
for y = 1:length(Subfields.DistTo{2}{x})
    for i = 1:num_frames
        if ~isnan(DLCdata.bodyparts.(Subfields.DistTo{2}{x}{y}).xy(i,1)) %if the value meets conf threshold
            DLCdata.DistTo.(Subfields.DistTo{1}{x}).(Subfields.DistTo{2}{x}{y}).raw(i,1) = (Distance(DLCdata.bodyparts.(Subfields.DistTo{2}{x}{y}).xy(i,:),DLCdata.FixedPoints.(Subfields.DistTo{1}{x})))/pixpercm;
        else
            DLCdata.DistTo.(Subfields.DistTo{1}{x}).(Subfields.DistTo{2}{x}{y}).raw(i,1) = NaN;
        end
    end
    DLCdata.DistTo.(Subfields.DistTo{1}{x}).(Subfields.DistTo{2}{x}{y}).mean = mean(DLCdata.DistTo.(Subfields.DistTo{1}{x}).(Subfields.DistTo{2}{x}{y}).raw,'omitnan');
    DLCdata.DistTo.(Subfields.DistTo{1}{x}).(Subfields.DistTo{2}{x}{y}).stdev = std(DLCdata.DistTo.(Subfields.DistTo{1}{x}).(Subfields.DistTo{2}{x}{y}).raw,'omitnan');
    numvalframes = sum(~isnan(DLCdata.DistTo.(Subfields.DistTo{1}{x}).(Subfields.DistTo{2}{x}{y}).raw));
    DLCdata.DistTo.(Subfields.DistTo{1}{x}).(Subfields.DistTo{2}{x}{y}).sem = DLCdata.DistTo.(Subfields.DistTo{1}{x}).(Subfields.DistTo{2}{x}{y}).stdev/sqrt(numvalframes );  
end
end
    
%get binary array of approach/not approach    
for x = 1: length(Subfields.DistTo{1})
for y = 1:length(Subfields.DistTo{2}{x})   
    Appr = nan(num_frames,2);
    for i = 1:num_frames
        if ~isnan(DLCdata.DistTo.(Subfields.DistTo{1}{x}).(Subfields.DistTo{2}{x}{y}).raw(i,1))
            if abs(DLCdata.DistTo.(Subfields.DistTo{1}{x}).(Subfields.DistTo{2}{x}{y}).raw(i,1)) <= outdata.UserVals.approach.limthresh %if the value meets approach threshold
                Appr(i,1) = 1;
            else
                Appr(i,1) = 0;
            end
            if abs(DLCdata.DistTo.(Subfields.DistTo{1}{x}).(Subfields.DistTo{2}{x}{y}).raw(i,1)) <= outdata.UserVals.approach.detectthresh %if the value meets approach threshold
                Appr(i,2) = 1;
            else
                Appr(i,2) = 0;
            end
        end
    end
    
[ApprEvents,totalapproaches,apprduration] = DLC_FindApproach(Appr,videoFPS,outdata.UserVals.approach.minlength,outdata.UserVals.approach.endtime);
DLCdata.Approach.(Subfields.DistTo{1}{x}).(Subfields.DistTo{2}{x}{y}).Binary = ApprEvents;
DLCdata.Approach.(Subfields.DistTo{1}{x}).(Subfields.DistTo{2}{x}{y}).TotalApproaches = totalapproaches;
DLCdata.Approach.(Subfields.DistTo{1}{x}).(Subfields.DistTo{2}{x}{y}).ApprDuration = apprduration;
DLCdata.Approach.(Subfields.DistTo{1}{x}).(Subfields.DistTo{2}{x}{y}).TotPercAppr = (sum(DLCdata.Approach.(Subfields.DistTo{1}{x}).(Subfields.DistTo{2}{x}{y}).Binary,'omitnan')/num_frames)*100;
clear Appr ApprEvents
end
end
end

   

%% Speed
% distance moved for bodypart from one frame to the next
% cm per second
% calculate speed and add new field to data structure: Speed.bodypart
for b = 1:length(DLCdata.bps) 
    if isfield(DLCdata,(DLCdata.bps{b}))
        DLCdata.BpsSpeed.(DLCdata.bps{b}).raw(1,1) = NaN; %can't calculate speed for first frame as no previous data
for i = 2:num_frames %start at 2nd frame
    if ~isnan(DLCdata.bodyparts.(DLCdata.bps{b}).xy(i,1)) && ~isnan(DLCdata.bodyparts.(DLCdata.bps{b}).xy(i-1,1)) %if there is data for this frame
        DLCdata.BpsSpeed.(DLCdata.bps{b}).raw(i,1) = (Distance(DLCdata.bodyparts.(DLCdata.bps{b}).xy(i,:),DLCdata.bodyparts.(DLCdata.bps{b}).xy(i-1,:))/pixpercm)*videoFPS;
    else
        DLCdata.BpsSpeed.(DLCdata.bps{b}).raw(i,1) = NaN;
    end
end         
    end
end


%extract user selected speed info
if isfield(Subfields,'Speed')
for x = 1: length(Subfields.Speed{1})
    if ~strcmp((Subfields.Speed{1}{x}),'AvSpeed')
         DLCdata.Speed.(Subfields.Speed{1}{x}).raw = DLCdata.BpsSpeed.(Subfields.Speed{1}{x}).raw;
         DLCdata.Speed.(Subfields.Speed{1}{x}).mean = mean(DLCdata.Speed.(Subfields.Speed{1}{x}).raw,'omitnan');
         DLCdata.Speed.(Subfields.Speed{1}{x}).stdev =  std(DLCdata.Speed.(Subfields.Speed{1}{x}).raw,'omitnan');
         numvalframes = sum(~isnan(DLCdata.Speed.(Subfields.Speed{1}{x}).raw));
         DLCdata.Speed.(Subfields.Speed{1}{x}).sem = DLCdata.Speed.(Subfields.Speed{1}{x}).stdev/sqrt(numvalframes);
%     else
%         if outdata.UserVals.locobouts
%         DLCdata.Speed.(Subfields.Speed{1}{x}) = DLCdata.LocomotionBout.(Subfields.Speed{1}{x});
%         else
%         DLCdata.Speed.(Subfields.Speed{1}{x}) = DLCdata.FreezeBout.(Subfields.Speed{1}{x});
%         end
    end
end
end



%% Movement Vector
% Two fields
% calculate from Implant Center to Nose Tip (tail = implant, head = nose)
% calculate from midpoint between two ears to Implant (tail = midpoint, head = implant)

for i = 1:num_frames
    % Implant to Nose Tip
    % if confident about I & NT
    if ~isnan(DLCdata.bodyparts.Implant.xy(i,1)) && ~isnan(DLCdata.bodyparts.Nose.xy(i,1))
        % set IC as tail of vector
        DLCdata.VectorCoord.ItoNT.Tail.xy(i,1:2) = DLCdata.bodyparts.Implant.xy(i,1:2);
        % set NT as head of Vector
        DLCdata.VectorCoord.ItoNT.Head.xy(i,1:2) = DLCdata.bodyparts.Nose.xy(i,1:2);
        % calculate length of vector
        DLCdata.VectorCoord.ItoNT.Length(i,1) = Distance(DLCdata.VectorCoord.ItoNT.Head.xy(i,1:2),DLCdata.VectorCoord.ItoNT.Tail.xy(i,1:2));
    % if not confident set values to NaN
    else 
        DLCdata.VectorCoord.ItoNT.Head.xy(i,1:2) = [NaN NaN];
        DLCdata.VectorCoord.ItoNT.Tail.xy(i,1:2) = [NaN NaN];
        DLCdata.VectorCoord.ItoNT.Length(i,1) = NaN;
    end
    
    % if confident about two ears & IC
    if ~isnan(DLCdata.bodyparts.R_ear.xy(i,1)) && ~isnan(DLCdata.bodyparts.L_ear.xy(i,1)) && ~isnan(DLCdata.bodyparts.Implant.xy(i,1))
        % set midpoint of two ears as tail of vector
        DLCdata.VectorCoord.MtoI.Tail.xy(i,1) = (DLCdata.bodyparts.R_ear.xy(i,1) + DLCdata.bodyparts.L_ear.xy(i,1))/2.0;
        DLCdata.VectorCoord.MtoI.Tail.xy(i,2) = (DLCdata.bodyparts.R_ear.xy(i,2) + DLCdata.bodyparts.L_ear.xy(i,2))/2.0;
        % set IC as head of vector
        DLCdata.VectorCoord.MtoI.Head.xy(i,1:2) = DLCdata.bodyparts.Implant.xy(i,1:2);
        % calculate length of vector
        DLCdata.VectorCoord.MtoI.Length(i,1) = Distance(DLCdata.VectorCoord.MtoI.Head.xy(i,1:2),DLCdata.VectorCoord.MtoI.Tail.xy(i,1:2));
    
    % if not confident set Head & Tail values  to NaN
    else
        DLCdata.VectorCoord.MtoI.Head.xy(i,1:2) = [NaN NaN];
        DLCdata.VectorCoord.MtoI.Tail.xy(i,1:2) = [NaN NaN];
        DLCdata.VectorCoord.MtoI.Length(i,1) = NaN;
    end
    
     %Distance between shoulder and low back
    % if confident about I & NT
    if ~isnan(DLCdata.bodyparts.Shoulder.xy(i,1)) && ~isnan(DLCdata.bodyparts.BottomBack.xy(i,1))
        % set bottom back as tail of vector
        DLCdata.VectorCoord.StoB.Tail.xy(i,1:2) = DLCdata.bodyparts.BottomBack.xy(i,1:2);
        % set NT as head of Vector
        DLCdata.VectorCoord.StoB.Head.xy(i,1:2) = DLCdata.bodyparts.Shoulder.xy(i,1:2);
        % calculate length of vector
        DLCdata.VectorCoord.StoB.Length(i,1) = Distance(DLCdata.VectorCoord.StoB.Head.xy(i,1:2),DLCdata.VectorCoord.StoB.Tail.xy(i,1:2));
    % if not confident set values to NaN
    else 
        DLCdata.VectorCoord.StoB.Head.xy(i,1:2) = [NaN NaN];
        DLCdata.VectorCoord.StoB.Tail.xy(i,1:2) = [NaN NaN];
        DLCdata.VectorCoord.StoB.Length(i,1) = NaN;
    end

    %Distance between shoulder and mid back
    % if confident about I & NT
    if ~isnan(DLCdata.bodyparts.Shoulder.xy(i,1)) && ~isnan(DLCdata.bodyparts.MidBack.xy(i,1))
        % set bottom back as tail of vector
        DLCdata.VectorCoord.StoM.Tail.xy(i,1:2) = DLCdata.bodyparts.MidBack.xy(i,1:2);
        % set NT as head of Vector
        DLCdata.VectorCoord.StoM.Head.xy(i,1:2) = DLCdata.bodyparts.Shoulder.xy(i,1:2);
        % calculate length of vector
        DLCdata.VectorCoord.StoM.Length(i,1) = Distance(DLCdata.VectorCoord.StoM.Head.xy(i,1:2),DLCdata.VectorCoord.StoM.Tail.xy(i,1:2));
    % if not confident set values to NaN
    else 
        DLCdata.VectorCoord.StoM.Head.xy(i,1:2) = [NaN NaN];
        DLCdata.VectorCoord.StoM.Tail.xy(i,1:2) = [NaN NaN];
        DLCdata.VectorCoord.StoM.Length(i,1) = NaN;
    end

    %Distance between implant and shoulder
    % if confident about I & NT
    if ~isnan(DLCdata.bodyparts.Implant.xy(i,1)) && ~isnan(DLCdata.bodyparts.Shoulder.xy(i,1))
        % set bottom back as tail of vector
        DLCdata.VectorCoord.ItoS.Tail.xy(i,1:2) = DLCdata.bodyparts.Shoulder.xy(i,1:2);
        % set NT as head of Vector
        DLCdata.VectorCoord.ItoS.Head.xy(i,1:2) = DLCdata.bodyparts.Implant.xy(i,1:2);
        % calculate length of vector
        DLCdata.VectorCoord.ItoS.Length(i,1) = Distance(DLCdata.VectorCoord.ItoS.Head.xy(i,1:2),DLCdata.VectorCoord.ItoS.Tail.xy(i,1:2));
    % if not confident set values to NaN
    else 
        DLCdata.VectorCoord.ItoS.Head.xy(i,1:2) = [NaN NaN];
        DLCdata.VectorCoord.ItoS.Tail.xy(i,1:2) = [NaN NaN];
        DLCdata.VectorCoord.ItoS.Length(i,1) = NaN;
    end
    
    
end

animalsize = mean(DLCdata.VectorCoord.StoB.Length(:,1),'omitnan');
DLCdata.animalsize = animalsize;

%find locomotion bouts
if outdata.UserVals.locobouts
[DLCdata.Locomotion.boutraw,DLCdata.Locomotion.Binary,DLCdata.Locomotion.bpsarray,DLCdata.Locomotion.totalbouts,DLCdata.Locomotion.boutduration,DLCdata.Locomotion.bodymulti,DLCdata.Locomotion.scalefact,DLCdata.Locomotion.headdetect,DLCdata.Locomotion.bodydetect] = DLC_FindLocomotion (DLCdata.BpsSpeed,outdata.UserVals.locobout.minlength,videoFPS,outdata.UserVals.DLCsetup.locobps,outdata.UserVals.locobout.endtime,DLCdata.bodybps,DLCdata.headbps,animalsize);
 DLCdata.Locomotion.TotPercLocomotion = (sum(DLCdata.Locomotion.Binary,'omitnan')/num_frames)*100;
end
%find freeze bouts
if outdata.UserVals.freezingbouts
[DLCdata.Freeze.boutraw,DLCdata.Freeze.Binary,DLCdata.Freeze.bpsarray,DLCdata.Freeze.totalbouts,DLCdata.Freeze.boutduration,DLCdata.Freeze.bodymulti,DLCdata.Freeze.scalefact,DLCdata.Freeze.headdetect,DLCdata.Freeze.bodydetect] = DLC_FindFreezing (DLCdata.BpsSpeed,outdata.UserVals.freezebout.minlength,videoFPS,outdata.UserVals.DLCsetup.freezebps,outdata.UserVals.freezebout.endtime,DLCdata.bodybps,DLCdata.headbps,animalsize);
DLCdata.Locomotion.TotPercFreeze = (sum(DLCdata.Freeze.Binary,'omitnan')/num_frames)*100;
end

%% Angle to Cue
% Use the dot product to calculate the angle (in degrees) between vector
%preallocate array as NaN
if isfield(Subfields,'Angle')
for x = 1:length(Subfields.Angle{1})
    xvals = Subfields.Angle{1};
    yvals = Subfields.Angle{2}{x};
    for y = 1:length(yvals)       
    for i = 1:num_frames
    % Check if values exist in first field of Movement VectorCoord
    a = DLCdata.VectorCoord.(yvals{y}).Head.xy(i,1);
    
            if ~isnan(a)
            P = DLCdata.VectorCoord.(yvals{y}).Head.xy(i,1:2);
            Q = DLCdata.VectorCoord.(yvals{y}).Tail.xy(i,1:2);
            R = DLCdata.FixedPoints.(xvals{x});
            
            QP = P-Q;
            QR = R-Q;
%             dot = QP(1)*QR(1) + QP(2)*QR(2);
%             norm_QP = power(power(QP(1),2) + power(QP(2),2),0.5);
%             norm_QR = power(power(QR(1),2) + power(QR(2),2),0.5);
%             theta = acosd(dot/(norm_QP*norm_QR));
            theta = atan2d(QP(1)*QR(2)-QP(2)*QR(1),QP(1)*QR(1)+QP(2)*QR(2));
            DLCdata.Angle.(xvals{x}).(yvals{y}).degrees_180(i,1) = abs(theta);
            DLCdata.Angle.(xvals{x}).(yvals{y}).degrees_dir(i,1) = theta;
            if theta < 0 
            DLCdata.Angle.(xvals{x}).(yvals{y}).degrees_360(i,1) = theta+360;
            else
            DLCdata.Angle.(xvals{x}).(yvals{y}).degrees_360(i,1) = theta;
            end
            
            %Distance between vector tail and fixed point
            % if confident about I & NT
            % set tail of vector as tail
            DLCdata.AngleVectorCoord.(xvals{x}).(yvals{y}).Tail.xy(i,1:2) = Q;
            % set fixed point as head of Vector
            DLCdata.AngleVectorCoord.(xvals{x}).(yvals{y}).Head.xy(i,1:2) = R;
            % calculate length of vector
            DLCdata.AngleVectorCoord.(xvals{x}).(yvals{y}).Length(i,1) = Distance(DLCdata.AngleVectorCoord.(xvals{x}).(yvals{y}).Head.xy(i,1:2),DLCdata.AngleVectorCoord.(xvals{x}).(yvals{y}).Tail.xy(i,1:2));
            % if not confident set values to NaN
            else
                DLCdata.Angle.(xvals{x}).(yvals{y}).degrees_180(i,1) = NaN;
                DLCdata.Angle.(xvals{x}).(yvals{y}).degrees_dir(i,1) = NaN;
                DLCdata.Angle.(xvals{x}).(yvals{y}).degrees_360(i,1) = NaN;
                DLCdata.AngleVectorCoord.(xvals{x}).(yvals{y}).Tail.xy(i,1:2) = NaN;
                DLCdata.AngleVectorCoord.(xvals{x}).(yvals{y}).Head.xy(i,1:2) = NaN;
                DLCdata.AngleVectorCoord.(xvals{x}).(yvals{y}).Length(i,1) = NaN;
            end
%             % Note: theta is negative if animal is facing to the left of the cue and positive if it's facing to the right of the cue

    end
    %Detect orienting
    if outdata.UserVals.orienting
    [orient,totalorients,orientduration] = DLC_FindOrienting (videoFPS,outdata.UserVals.orient.endtime,outdata.UserVals.orient.minlength,outdata.UserVals.orient.angle,DLCdata.Angle.(xvals{x}).(yvals{y}).degrees_180);
    DLCdata.Orient.(xvals{x}).(yvals{y}).Binary = orient;  
    DLCdata.Orient.(xvals{x}).(yvals{y}).Total = totalorients;
    DLCdata.Orient.(xvals{x}).(yvals{y}).Duration= orientduration;
    DLCdata.Orient.(xvals{x}).(yvals{y}).TotPercOrient = (sum(DLCdata.Orient.(xvals{x}).(yvals{y}).Binary,'omitnan')/num_frames)*100;
    end
    end
end
end
    
%     %% Angular Velocity
% % Use the dot product to calculate the angle (in degrees) between vector
% %preallocate array as NaN
 if isfield(Subfields,'AngularVelocity')
 for x = 1:length(Subfields.AngularVelocity{1})
     xvals = Subfields.AngularVelocity{1};  
    
    DLCdata.AngularVelocity.(xvals{x}).AbsVelocity.raw(1,1) = NaN;
    DLCdata.AngularVelocity.(xvals{x}).Velocity.raw(1,1) = NaN;
    DLCdata.AngularVelocity.(xvals{x}).Ang.raw(1,1) = NaN;
    DLCdata.AngularVelocity.(xvals{x}).AbsAng.raw(1,1) = NaN;
     for i = 2:num_frames
         % Check if values exist for this frame and previous frame
     a = DLCdata.VectorCoord.(xvals{x}).Head.xy(i,1);
     b = DLCdata.VectorCoord.(xvals{x}).Head.xy(i-1,1);
     

             if ~isnan(a) && ~isnan(b)
             %get xy coords for current and previous angle vectors
             currtx = [DLCdata.VectorCoord.(xvals{x}).Head.xy(i,1),DLCdata.VectorCoord.(xvals{x}).Tail.xy(i,1)];
             currty = [DLCdata.VectorCoord.(xvals{x}).Head.xy(i,2),DLCdata.VectorCoord.(xvals{x}).Tail.xy(i,2)];
             prevx = [DLCdata.VectorCoord.(xvals{x}).Head.xy(i-1,1),DLCdata.VectorCoord.(xvals{x}).Tail.xy(i-1,1)];
             prevy = [DLCdata.VectorCoord.(xvals{x}).Head.xy(i-1,2),DLCdata.VectorCoord.(xvals{x}).Tail.xy(i-1,2)];

             %calculate angle change
             v_1 = [currtx(1),currty(1),0] - [currtx(2),currty(2),0];
             v_2 = [prevx(1),prevy(1),0] - [prevx(2),prevy(2),0];
             AbsAng= atan2d(norm(cross(v_1, v_2)), dot(v_1, v_2)); %angle in degrees
             Theta2 = atan2d(cross(v_2, v_1), dot(v_2, v_1)); %angle in degrees(directional)
             Ang= Theta2(3);
             %AbsAng = rad2deg(Theta); %angle in degrees
             %Ang = rad2deg(Theta2);
             AngVel = Ang*videoFPS; %change in angle x FPS to get degrees per sec
             AbsAngVel = AbsAng*videoFPS; %change in angle x FPS to get degrees per sec
             DLCdata.AngularVelocity.(xvals{x}).Ang.raw(i,1) = Ang;
             DLCdata.AngularVelocity.(xvals{x}).AbsAng.raw(i,1) = AbsAng;
             DLCdata.AngularVelocity.(xvals{x}).Velocity.raw(i,1) = AngVel;
             DLCdata.AngularVelocity.(xvals{x}).AbsVelocity.raw(i,1) = AbsAngVel;
       else
                % DLCdata.AngularVelocity.(xvals{x}).(yvals{y}).degrees_180(i,1) = NaN;
                % DLCdata.AngularVelocity.(xvals{x}).(yvals{y}).degrees_dir(i,1) = NaN;
                % DLCdata.AngularVelocity.(xvals{x}).(yvals{y}).degrees_360(i,1) = NaN;
                DLCdata.AngularVelocity.(xvals{x}).Velocity.raw(i,1) = NaN;
                DLCdata.AngularVelocity.(xvals{x}).AbsVelocity.raw(i,1) = NaN;
                DLCdata.AngularVelocity.(xvals{x}).Ang.raw(i,1) = NaN;
                DLCdata.AngularVelocity.(xvals{x}).AbsAng.raw(i,1) = NaN;
            end
%             % Note: theta is negative if animal is facing to the left of the cue and positive if it's facing to the right of the cue
     end
     end
 end

 %%Angle between 2 vectors
 % if isfield(Subfields,'AngularVelocity')
 % for x = 1:length(Subfields.AngularVelocity{1})
     % xvals = Subfields.AngularVelocity{1};      
     for i = 1:num_frames
         % Check if values exist for both vectors
     a = DLCdata.VectorCoord.ItoS.Head.xy(i,1);
     b = DLCdata.VectorCoord.StoM.Head.xy(i,1);
     

             if ~isnan(a) && ~isnan(b)
             %get xy coords for current and previous angle vectors
             headvecx = [DLCdata.VectorCoord.ItoS.Head.xy(i,1),DLCdata.VectorCoord.ItoS.Tail.xy(i,1)];
             headvecy = [DLCdata.VectorCoord.ItoS.Head.xy(i,2),DLCdata.VectorCoord.ItoS.Tail.xy(i,2)];
             bodyvecx = [DLCdata.VectorCoord.StoM.Tail.xy(i,1),DLCdata.VectorCoord.StoM.Head.xy(i,1)];
             bodyvecy = [DLCdata.VectorCoord.StoM.Tail.xy(i,2),DLCdata.VectorCoord.StoM.Head.xy(i,2)];

             %calculate angle change
             v_1 = [headvecx(1),headvecy(1),0] - [headvecx(2),headvecy(2),0];
             v_2 = [bodyvecx(1),bodyvecy(1),0] - [bodyvecx(2),bodyvecy(2),0];
             AbsAng= atan2d(norm(cross(v_1, v_2)), dot(v_1, v_2)); %angle in degrees
             Theta2 = atan2d(cross(v_2, v_1), dot(v_2, v_1)); %angle in degrees(directional)
             Ang= Theta2(3);
             %AbsAng = rad2deg(Theta); %angle in degrees
             %Ang = rad2deg(Theta2);
             AngVel = Ang*videoFPS; %change in angle x FPS to get degrees per sec
             AbsAngVel = AbsAng*videoFPS;
             DLCdata.HeadvsBody.Ang.raw(i,1) = Ang;
             DLCdata.HeadvsBody.AbsAng.raw(i,1) = AbsAng;
             DLCdata.HeadvsBody.Velocity.raw(i,1) = AngVel;
             DLCdata.HeadvsBody.AbsVelocity.raw(i,1) = AbsAngVel;
       else
                % DLCdata.AngularVelocity.(xvals{x}).(yvals{y}).degrees_180(i,1) = NaN;
                % DLCdata.AngularVelocity.(xvals{x}).(yvals{y}).degrees_dir(i,1) = NaN;
                % DLCdata.AngularVelocity.(xvals{x}).(yvals{y}).degrees_360(i,1) = NaN;
             DLCdata.HeadvsBody.Ang.raw(i,1) = NaN;
             DLCdata.HeadvsBody.AbsAng.raw(i,1) = NaN;
             DLCdata.HeadvsBody.Velocity.raw(i,1) = NaN;
             DLCdata.HeadvsBody.AbsVelocity.raw(i,1) = NaN;
            end
%             % Note: theta is negative if animal is facing to the left of the cue and positive if it's facing to the right of the cue
     end
 % end
 % end
 
 end


        