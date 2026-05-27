function [UserVals]= FP_Analysis(loadfilename,exclusionlistname,UserVals)
%FP_Analysis-A Wolff 15/2/2021 - edited from LickingBouts.m code on the TDT website

fsep = filesep; %sets correct fileseparator for user OS
outdata = struct;
eventtypes = UserVals.eventtypes;
DefineData = UserVals.DefineData;
ProcessSubset = UserVals.ProcessSubset;
SubsetIndx = UserVals.SubsetIndx;
setcond = UserVals.setcond;
signallabel = UserVals.signallabel;
missingdata = missing;




%% START ANALYSIS
%% Load files from filelist and extract relevant info
if ~strcmp(loadfilename(end-4:end),'.xlsx')
    filename = strcat(loadfilename,'.xlsx');
else
    filename = loadfilename;
end
%check formatting of filename

%[listdata] = xlsread(filename); %reads list of filenames from xls sheet   
[listdata] = readcell(filename);
[Foundlists]= GetLists(listdata{1,UserVals.Input.IDs},'%f');
boxnumb = cell2mat(Foundlists{1,1});  %input list of boxes to analyse (examples: [2] will only analyse box 2, [1 2] will analyse both boxes) 
subjID = (Foundlists{1,2}); %actual box numbers for first and second box in pair - used to label savefiles/output

%% DLS Setup - Select options for DLC analysis
if UserVals.DLCAnalysis
[UserVals]=DLC_SelectUserOptions(UserVals);
else
DLCsetup.measures = [];
DLCsetup.axislabels = [];
DLCsetup.Subfields = [];
UserVals.DLCsetup = DLCsetup;
end

for b = 1: length(boxnumb) %start of box loop
subj = subjID{b};%creates an ID for save file location which includes the box number 
outdata.UserVals = UserVals;

%% Data to process
if ProcessSubset 
    ProcessData = DefineData(SubsetIndx);
else
    ProcessData = DefineData; 
end

%% Exclusionlist
if ~isempty(exclusionlistname)
    if ~contains(exclusionlistname,'.xlsx')
    exclusionlistname = strcat(exclusionlistname,'.xlsx');
    end

    %[~,~,exclusionlist] = readcell(exclusionlistname);
    exclusionlist = readcell(exclusionlistname);
    exclusionlist(1,:) = []; %removeheaders

    if length(exclusionlist(:,1)) < length(listdata(:,1))
    exclusionlist(length(exclusionlist(:,1))+1:length(listdata(:,1)),:) = {missingdata};
    end
    if length(exclusionlist(1,:)) < length(DefineData)*2
        for x = length(exclusionlist(1,:))+1:length(DefineData)*2
        exclusionlist(:,x) = {missingdata};
        end
    end
else
    exclusionlist(1:length(listdata(:,1)),1:length(DefineData)*2) = {missingdata};
end
    if ~ProcessSubset
    exclindx (1,:)= (1:1:length(ProcessData));
    exclindx (2,:)= (length(ProcessData)+1:1:length(ProcessData)*2);
    else
    exclindx(1,:) = SubsetIndx;
    exclindx(2,:) = SubsetIndx + length(DefineData);
    end

if UserVals.Trim
    trimdata = listdata(:,15:end);
    if size(trimdata,2) < 6
    trimdata(:,size(trimdata,2)+1:6) = {missingdata};
    end
while length(trimdata(:,1)) < length(listdata(:,1))
   trimdata(length(trimdata(:,1))+1,:) = {missingdata};
end
end 

for f = 1:length(listdata(:,1))%cycles through analysis for each file in the list
    close all
    currentexists = false;
    %check data for this box exists for this file
    [CheckData]= GetLists(listdata{f,UserVals.Input.IDs},'%f');
    CheckData = CheckData{1,1};
    for i= 1:length(CheckData)
        if CheckData{i} == boxnumb(b)
            currentexists = true;
        end
    end

if currentexists
clear currentexists CheckData
%% Import TDT data extract for each trial:
    PATH = listdata{f,UserVals.Input.Path};   
    if UserVals.googledrive
        [PATH] = googleconvert_fname(PATH,UserVals.personalpath); %convert path to use google drive
    end
    [PATH]= formatconvert_fname(PATH); %correct formating errors in file path
    
    if PATH(end)~= fsep %add file separator if missing from path
    PATH = strcat(PATH,fsep);
    end 
    FILE = listdata{f,UserVals.Input.Folder}; 
    BLOCK_PATH = strcat(PATH,FILE);
    filenumb = num2str(f);
    fileprog = strcat('file_',filenumb,fsep,num2str(length(listdata(:,1))));
    disp(subj); %shows current box number 
    disp(fileprog); %shows current filenumber and total number of files so you can see progress
    data = TDTbin2mat(BLOCK_PATH);
    outdata.metadata.fileID {f} = FILE;
    outdata.metadata.subjID {f} = subj;
    clear temp
    
    if isempty (UserVals.saveloc)
        UserVals.saveloc = PATH;
    end
    if UserVals.saveloc(end)~= fsep %add file separator if missing from path
    UserVals.saveloc = strcat(UserVals.saveloc,fsep);
    end

    recfilename = outdata.metadata.fileID{f}; %used for fig savefilenames
if isfield (data.streams,'Fi1r') %only do photometry analysis if photometry data exists
   %loads stream and epoch names for current file/box from filelist
    ISOs = (listdata{f,UserVals.Input.ISOs(boxnumb(b))}); 
    SIG = (listdata{f,UserVals.Input.Signal(boxnumb(b))}); 
    [FoundLists] = GetLists (listdata{f,UserVals.Input.Events(boxnumb(b))});
    EVENTS = FoundLists{1,1};
    clear FoundLists
    for e = 1:length(eventtypes)
        if e <= length(EVENTS)
        EVENT.(eventtypes{e}) = (EVENTS{1,e});   
        end
    end
    clear EVENTS
    
        if UserVals.Trim && ~isempty(trimdata)
            TrimFiles = (trimdata(f,UserVals.Input.TrimFlag(boxnumb(b))));
            TrimStart = (trimdata(f,UserVals.Input.Trimstart(boxnumb(b))));
            TrimEnd = (trimdata(f,UserVals.Input.Trimend(boxnumb(b))));
        end
        
        if UserVals.CreateVids || UserVals.DLCAnalysis || UserVals.freezingbouts || UserVals.locobouts 
            if ~isempty(listdata{f,UserVals.Input.Cam(boxnumb(b))})
            CAM = (listdata{f,UserVals.Input.Cam(boxnumb(b))});
            VIDprefix = (listdata{f,UserVals.Input.Tank});
            VIDtype = (listdata{f,UserVals.Input.vidtype});
            else
            disp 'No video file specified';
            end
            DLC = (listdata{f,UserVals.Input.DLCnetwork});
        else 
            disp ('No camera data loaded');
            UserVals.CreateVids = false;
        end
  
   % if there is cam data for this file then 
   if UserVals.CreateVids || UserVals.DLCAnalysis || UserVals.freezingbouts || UserVals.locobouts
      if ~isempty(CAM) && ~isempty(VIDprefix)%if there is cam and vid data then get info and set flag to create snips
          if VIDprefix(end) == '_'
             VIDprefix = VIDprefix(1:end-1);
          end
          if UserVals.Vids.Uselabeledvids 
            vidfilename = strcat(PATH,FILE,fsep,VIDprefix,'_',FILE,'_',CAM,DLC,'_labeled',VIDtype);
            if ~isfile(vidfilename)
            disp('Labeled Video Not Found, Using Original Video')
            vidfilename = strcat(PATH,FILE,fsep,VIDprefix,'_',FILE,'_',CAM,VIDtype); 
            end
          else
            vidfilename = strcat(PATH,FILE,fsep,VIDprefix,'_',FILE,'_',CAM,VIDtype); 
          end
          
          %if file doesn't exist try different file extension
           if ~isfile(vidfilename)
               if strcmp(VIDtype,'.mp4')
               strindx = strfind(vidfilename,'.mp4');
               vidfilename(strindx:end) = '.avi';
               else
               strindx = strfind(vidfilename,'.avi');
               vidfilename(strindx:end) = '.mp4';
               end
           end
           
          if isfile(vidfilename)
          
          outdata.videodata.videofile{f} = vidfilename;
          %;
          
          UserVals.Vids.VidSnips = true;
              outdata.videodata.frames.onset{f,1} = data.epocs.(CAM).onset;
              outdata.videodata.frames.offset{f,1} = data.epocs.(CAM).offset;
              
          tf = isunix; %if not windows OS
          if tf && strcmp(VIDtype,'.avi')
          videoFPS = FP_GetVidFPS (data,CAM);
          else
          v = VideoReader(vidfilename);
          videoFPS = round(v.FrameRate);
          end
          
          outdata.videodata.vidFPS{f,1} = round(videoFPS);
          if tf && strcmp(VIDtype,'.avi')
              UserVals.Vids.VidSnips = false; 
              disp 'video file needs to be converted to .mp4 for macOS';
          end    
          else 
          UserVals.Vids.VidSnips = false;
          disp 'videofile not found or does not exist';
          end
      else 
      UserVals.Vids.VidSnips = false;
      end
   else
       UserVals.Vids.VidSnips = false;
   end

    % Make a time array based on number of samples and sample freq of demodulated streams
    clear totaltrials time    
    time = (1:length(data.streams.(SIG).data))/data.streams.(SIG).fs;

    % Save raw data
    outdata.rawdata.(signallabel){f,1} = data.streams.(SIG).data;
    outdata.rawdata.ISOs{f,1} = data.streams.(ISOs).data;
    outdata.rawdata.time{f,1} = time;

outdata.metadata.PATH{f,1}= PATH;
outdata.metadata.subj {f,1}= subj;
% if UserVals.CreateVids  || UserVals.Vids.VidSnips
% outdata.rawdata.camticks.onset{f,1} = data.epocs.(CAM).onset;
% outdata.rawdata.camticks.offset{f,1} = data.epocs.(CAM).offset;
% outdata.videodata.vidFPS{f,1} = round(videoFPS);
% end
if UserVals.Trim &&  ~isempty(trimdata)
outdata.metadata.trimmedfiles.Files{f,1} = TrimFiles;
outdata.metadata.trimmedfiles.TrimStart {f,1}= TrimStart;
outdata.metadata.trimmedfiles.TrimEnd {f,1}= TrimEnd;
end

%% Ensure all stream arrays are equal lengths
chklength = [length(time),length(data.streams.(SIG).data),length(data.streams.(ISOs).data)];
minval = min(chklength);
time = time(1:minval);
data.streams.(SIG).data = data.streams.(SIG).data(1:minval);
data.streams.(ISOs).data = data.streams.(ISOs).data(1:minval);
outdata.unfilt.(signallabel){f,1}= data.streams.(SIG).data(1:minval);
outdata.unfilt.ISOs{f,1} = data.streams.(ISOs).data(1:minval);
clear chklength minval

%% Lowpass Filter
LFcut = 2; % cut-off frequency of lowpass filter %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% for DA sensor
%order = 4; % N-th order for butterworth filter
%fs = data.streams.(SIG).fs;%sampling frequency
%filt25Hzbutter = FP_lowpassFilt(data.streams.(SIG).data,LFcut,fs,order); 
data = TDTdigitalfilter(data, (SIG), LFcut, 'TYPE', 'low');
data = TDTdigitalfilter(data, (ISOs), LFcut, 'TYPE', 'low');

%% remove artifact from turning on LEDs
t = 1; % time threshold below which we will discard
ind = find (time>t,1); % find first index of when time crosses threshold
time = time(ind:end); % reformat vector to only include allowed time
data.streams.time.data = time;
data.streams.(SIG).data = data.streams.(SIG).data(ind:end);
data.streams.(ISOs).data = data.streams.(ISOs).data(ind:end);
%same for unfiltered sig
outdata.unfilt.(signallabel){f,1} = outdata.unfilt.(signallabel){f,1}(ind:end);
outdata.unfilt.ISOs{f,1} = outdata.unfilt.ISOs{f,1}(ind:end);
outdata.unfilt.time{f,1} = time;
clear ind t

if UserVals.StimPulses
%Turn Stim Pulse Channel into On/Off Epoch
[Stim_on,Stim_off,Stim_Dur]= GenPulseEpoch(data.epocs.(EVENT.(eventtypes{UserVals.Stim.stimis})).onset,data.epocs.(EVENT.(eventtypes{UserVals.Stim.stimis})).onset,UserVals.Stim.stimHz);
data.epocs.(EVENT.(eventtypes{UserVals.Stim.stimis})).onset = Stim_on;
data.epocs.(EVENT.(eventtypes{UserVals.Stim.stimis})).offset = Stim_off;
data.epocs.(EVENT.(eventtypes{UserVals.Stim.stimis})).duration = Stim_Dur;
data.epocs.(EVENT.(eventtypes{UserVals.Stim.stimis})).data = data.epocs.(EVENT.(eventtypes{UserVals.Stim.stimis})).data(1:length(Stim_on));
clear Stim_on Stim_off Stim_Dur
end

if UserVals.GenerateEvent
existingchans = length(fieldnames(EVENT));
    if UserVals.GenEvent.CreateInterval
    for nc = 1:UserVals.GenEvent.NumChans
    outdata.rawdata.(eventtypes{existingchans+nc}).onset = data.epocs.(EVENT.(eventtypes{UserVals.GenEvent.ChanInfo{1,nc}(1)})).onset + UserVals.GenEvent.ChanInfo{1,nc}(2); %create event onset by adding interval from ref event to ref event onset
    outdata.rawdata.(eventtypes{existingchans+nc}).offset = outdata.rawdata.(eventtypes{existingchans+nc}).onset + UserVals.GenEvent.ChanInfo{1,nc}(3);  
    outdata.rawdata.(eventtypes{existingchans+nc}).data = data.epocs.(EVENT.(eventtypes{UserVals.GenEvent.ChanInfo{1,nc}(1)})).data;  
    end
    end
    if UserVals.GenEvent.CreateDuration
    for nc = 1:UserVals.GenEvent.NumChans
    %get ref channel event duration
    refdur = round(data.epocs.(EVENT.(eventtypes{UserVals.GenEvent.ChanInfo{1,nc}(1)})).offset-data.epocs.(EVENT.(eventtypes{UserVals.GenEvent.ChanInfo{1,nc}(1)})).onset,1);
    evindx = find(refdur == UserVals.GenEvent.ChanInfo{1,nc}(2));  % if duration matches this events ID duration then log event
    outindx = 1:length(evindx);
    outdata.rawdata.(eventtypes{existingchans+nc}).onset(outindx,1) = data.epocs.(EVENT.(eventtypes{UserVals.GenEvent.ChanInfo{1,nc}(1)})).onset(evindx); %create event onset by adding interval from ref event to ref event onset
    outdata.rawdata.(eventtypes{existingchans+nc}).offset(outindx,1) = data.epocs.(EVENT.(eventtypes{UserVals.GenEvent.ChanInfo{1,nc}(1)})).onset(evindx) + UserVals.GenEvent.ChanInfo{1,nc}(3);  
    outdata.rawdata.(eventtypes{existingchans+nc}).data(outindx,1) = data.epocs.(EVENT.(eventtypes{UserVals.GenEvent.ChanInfo{1,nc}(1)})).data(evindx);  
    end
    end
end
clear nc

if UserVals.FilterEvents
    for fc = 1:length(UserVals.FiltEvent.Chans)
    data = FiltEventChan(time(end),data,EVENT.(eventtypes{UserVals.FiltEvent.Chans(fc)}),UserVals.FiltEvent.ChanInfo{fc});
    end
end

%% Save event data
for e = 1: length(fieldnames(EVENT))
    if isfield (data.epocs,EVENT.(eventtypes{e}))
    outdata.rawdata.(eventtypes{e})= data.epocs.(EVENT.(eventtypes{e}));
    else
    outdata.rawdata.(eventtypes{e})= [];  
    end
end
clear e

%% Trim Recording && Events to match *optional % add in trim of raw signals
if UserVals.Trim && ~isempty(trimdata)
    if ~isnan(TrimFiles) 
    if f <= length(trimdata)   
    if TrimFiles 
        datatotrim = {SIG, ISOs};
        datatypetotrim = {'streams','streams'};
        datatotrim{1,length(datatotrim)+length(eventtypes)+1}= 'time';
        datatypetotrim{1,length(datatypetotrim)+length(eventtypes)+1}= 'streams';
        for e = 1:length(eventtypes)
        datatotrim{1,2+e} = (EVENT.(eventtypes{e}));
        datatypetotrim{1,2+e} = 'epocs';
        end
        for tr = 1:length(datatypetotrim)
            if isfield(data.(datatypetotrim{tr}),datatotrim{tr})
            [data.(datatypetotrim{tr}).(datatotrim{tr})] = TrimRecording(time, data.(datatypetotrim{tr}).(datatotrim{tr}), datatypetotrim{tr}, TrimStart,TrimEnd);
            end
        end
        clear datatypetotrim datatotrim tr e
        disp 'Data Trimmed';
    end
    end
    end

    time = data.streams.time.data;    
    clear TrimEnd TrimStart TrimFiles
end

%% Downsample data doing local averaging
% Average around every Nth point and downsample Nx
N = UserVals.N;
data.streams.(SIG).data = arrayfun(@(i)...
    mean(data.streams.(SIG).data(i:i+N-1)),...
    1:N:length(data.streams.(SIG).data)-N+1);
data.streams.(ISOs).data = arrayfun(@(i)...
    mean(data.streams.(ISOs).data(i:i+N-1)),...
    1:N:length(data.streams.(ISOs).data)-N+1);
% Decimate time array and match length to demodulated stream
time = time(1:N:end);
time = time(1:length(data.streams.(SIG).data));
fs = data.streams.(SIG).fs/N; % update fs after downsampling

outdata.downsamp.(signallabel){f,1} = data.streams.(SIG).data;
outdata.downsamp.ISOs{f,1}  = data.streams.(ISOs).data;
outdata.downsamp.time{f,1}  = time;
outdata.metadata.FPfs= fs;

% same for unfilt signal
outdata.unfilt.ds.(signallabel){f,1} = arrayfun(@(i)...
    mean(outdata.unfilt.(signallabel){f,1}(i:i+N-1)),...
    1:N:length(outdata.unfilt.(signallabel){f,1})-N+1);
outdata.unfilt.ds.ISOs{f,1} = arrayfun(@(i)...
    mean(outdata.unfilt.ISOs{f,1}(i:i+N-1)),...
    1:N:length(outdata.unfilt.ISOs{f,1})-N+1);
outdata.unfilt.ds.time{f,1}  = time;

outdata.unfilt.ds.ISOs{f,1} = double(outdata.unfilt.ds.ISOs{f,1});
outdata.unfilt.ds.(signallabel){f,1} = double(outdata.unfilt.ds.(signallabel){f,1});

%% Detrending and dFF
%dFF for unfilt signal
[dFF,Y_fit_all,std_dFF,sem_dFF] = GetdFF(outdata.unfilt.ds.ISOs{f,1},outdata.unfilt.ds.(signallabel){f,1});
outdata.unfilt.detrended.ISOSfit{f,1} = Y_fit_all;
outdata.unfilt.detrended.dFF{f,1}  = dFF;
outdata.unfilt.detrended.std_dFF{f,1}  = std_dFF;
outdata.unfilt.detrended.sem_dFF{f,1}  = sem_dFF;
clear std_dFF sem_dFF dFF Y_fit_all

%for filtered signal
[dFF,Y_fit_all,std_dFF,sem_dFF] = GetdFF(data.streams.(ISOs).data,data.streams.(SIG).data);
outdata.detrended.ISOSfit{f,1} = Y_fit_all;
outdata.detrended.dFF{f,1}  = dFF;
outdata.detrended.std_dFF{f,1}  = std_dFF;
outdata.detrended.sem_dFF{f,1}  = sem_dFF;
clear std_dFF sem_dFF


%% Make a continuous time series of TTL events (epocs) for plot
    dFFdiff = (ceil(max(dFF)-min(dFF)));
    plotbuffer = ceil(dFFdiff *UserVals.plotbuffermagnitude);
    y_shiftstart = (floor(min(dFF)) - plotbuffer);
    y_scale = 2; %size of epoc to display on whole trial figure for each eventtype
    y_shift = (y_shiftstart:-y_scale*2:y_shiftstart+((-y_scale*2)*length(eventtypes)));
    clear plotbuffer dFFdiff y_shiftstart

for e = 1: length(eventtypes)
    if isfield(outdata.rawdata,(eventtypes{e}) )
        if isfield(outdata.rawdata.(eventtypes{e}),'onset')
        plotdata.(eventtypes{e}).on = outdata.rawdata.(eventtypes{e}).onset;
        plotdata.(eventtypes{e}).off = outdata.rawdata.(eventtypes{e}).offset;
        plotdata.(eventtypes{e}).data = outdata.rawdata.(eventtypes{e}).data;
        outdata.eventdata.raw.(eventtypes{e}).on {f,1} = plotdata.(eventtypes{e}).on;
        outdata.eventdata.raw.(eventtypes{e}).off {f,1} = plotdata.(eventtypes{e}).off;
        plotdata.(eventtypes{e}).x = reshape(kron([plotdata.(eventtypes{e}).on,plotdata.(eventtypes{e}).off], [1, 1])', [], 1);
        sz = length(plotdata.(eventtypes{e}).on);
        d = ones(1,length(outdata.rawdata.(eventtypes{e}).data'));
        plotdata.(eventtypes{e}).y = reshape([zeros(1, sz); d; d; zeros(1, sz)], 1, []);
        plotdata.(eventtypes{e}).y = (y_scale * (plotdata.(eventtypes{e}).y))+ y_shift(e);
        clear sz d 
        outdata.rawdata.(eventtypes{e}).epoc.on{f,1} = plotdata.(eventtypes{e}).on;
        outdata.rawdata.(eventtypes{e}).epoc.off{f,1} = plotdata.(eventtypes{e}).off;
        else
        plotdata.(eventtypes{e}).on = [];
        plotdata.(eventtypes{e}).off = [];
        outdata.eventdata.raw.(eventtypes{e}).on{f,1} = [];
        outdata.eventdata.raw.(eventtypes{e}).off{f,1}= [];
        plotdata.(eventtypes{e}).x = [];
        plotdata.(eventtypes{e}).y = [];
        outdata.rawdata.(eventtypes{e}).epoc.on{f,1} = [];
        outdata.rawdata.(eventtypes{e}).epoc.off{f,1} = [];
        end
    else
    plotdata.(eventtypes{e}).on = [];
    plotdata.(eventtypes{e}).off = [];
    outdata.eventdata.raw.(eventtypes{e}).on{f,1} = [];
    outdata.eventdata.raw.(eventtypes{e}).off{f,1}= [];
    plotdata.(eventtypes{e}).x = [];
    plotdata.(eventtypes{e}).y = [];
    outdata.rawdata.(eventtypes{e}).epoc.on{f,1} = [];
    outdata.rawdata.(eventtypes{e}).epoc.off{f,1} = [];
    end
end


%% Make some pretty colors for later plotting
% http://math.loyola.edu/~loberbro/matlab/html/colorsInMatlab.html
purple = [0.3,0.2,.9];
purple2 = [0.6,0,1];
green = [0,.9,.3];
green2 = [0, 0.5, 0];
cmap = cool(256);
close all
cmapindx = 1;
indxstep = (floor(length(cmap)/length(eventtypes)+1));

%% Plot signal and fitted 405 
if UserVals.hideplots
fig1 = figure('Position',[150, 300, 800, 400],'visible','off');
else
fig1 = figure('Position',[150, 300, 800, 400]);
end
subplot(2,1,1,'Parent',fig1);
hold on;
p1 = plot(time, data.streams.(SIG).data,'color',green,'LineWidth',2);
p2 = plot(time, Y_fit_all,'color',purple,'LineWidth',2);
p3 = plot(time, data.streams.(ISOs).data,'color',purple2,'LineWidth',2);
title('Raw Signals and Fitted Isosbestic','fontsize',12);
ylabel('mV','fontsize',10);
axis tight;
legend([p1 p3 p2], {(signallabel),'UV', 'Fitted UV'},'Location','eastoutside');

clear p1 p2 p3 
%% Plot dFF with Event epocs 
subplot(2,1,2,'Parent',fig1);
%figure('Position',[100, 100, 800, 400]);
plot(time, dFF, 'Color',green2,'LineWidth',2); hold on;
legendlabels{1,1} = (signallabel);
legindx = 2;
for e = 1:length(eventtypes)
    if ~isempty(plotdata.(eventtypes{e}).x)
    plot(plotdata.(eventtypes{e}).x, plotdata.(eventtypes{e}).y','color',cmap(cmapindx,:),'LineWidth',2);
    cmapindx = cmapindx+(indxstep-1);
    legendlabels{1,legindx} = eventtypes{e};
    legindx = legindx+1;
    end
end
title('Detrended, y-shifted dFF','fontsize',12);
xlabel('Time(Seconds)','fontsize',10)
ylabel('\DeltaF/F','fontsize',10);
legend(legendlabels{1,:},'Location','eastoutside');
axis tight
hold off

figdir = (strcat((UserVals.saveloc),'Figs',filesep,subjID{b},filesep,'WholeRec',filesep));
if ~exist(figdir, 'dir')
       mkdir(figdir);
end

if UserVals.saveaspdf
savename = strcat(figdir,recfilename,'_raw+dFF-',num2str(f),'.pdf');
fig1.Renderer='Painters'; %makes sure figure can be manipulated in illustrator
print(savename,'-dpdf','-bestfit');
else
savename = strcat(figdir,recfilename,'_raw+dFF-',num2str(f),'.png');
plotme=getframe(gcf);
imwrite(plotme.cdata,savename);
clear plotme
end

close all
clear p1 p2 p3 f1 fig1 plotdata cmapindx cmap indxstep legendlabels legindx
clear green green2 purple purple2 
clear Y_dF_all Y_fit_all plotdata y_scale y_shift tempindx

%% Initialize variables for time Filter Around Event Epocs
% Note that we are using dFF of the full time-series, not peri-event dFF where f0 is taken from a pre-event baseline period.

%% Save arrays of cue onsets binned depending on trial type (cond1 or cond2)
outdata.perievent.fs{f,1} = fs;
for p = 1: length(ProcessData)   
    [outdata] = FP_ConditionalBinTrials(f,outdata,time,eventtypes,ProcessData,setcond,p);
    if ~isfield(outdata.eventdata,(ProcessData{p}))
        outdata.eventdata.(ProcessData{p})=[]; %incase there are no trials for this condition creates a field needed in outdata
    end
end

% if UserVals.GetResponseSnips
% [outdata]= FP_CondBinTrials_Resp(f,outdata,time,{'Rew','NoRew'},1,[],[-2 0],4,3,0.5);
% end

for p = 1:length(ProcessData)
if isfield(outdata.eventdata,(ProcessData{p}))
outdata.metadata.availcond{f,1}{p} = setcond.(ProcessData{p}){2}; 
datatypes = {'Z_dFF','dFF','Z_raw','raw'};
wins = {'PreEvent','PostEvent','All'}; %labels of windows to find max value in 
wintimes = {[-1*setcond.(ProcessData{p}){5}(1) 0],[0 setcond.(ProcessData{p}){5}(2)],[NaN NaN]};%set start and end times for each window - use NaN to default to start end of trial%window to look for peak response relative to t0- if empty ([]) searches whole trace, if only one number then assumes this is start and uses end trace and endpoint
if length(setcond.(ProcessData{p})) > 5 % if there are user windows and or labels add them   
    for w = 1:length(setcond.(ProcessData{p}){6}) %for each defined window set wintimes
        wintimes{3+w} = setcond.(ProcessData{p}){6}{w};
        if length(setcond.(ProcessData{p})) > 6 %if there are labels for windows use them
        wins{3+w} = setcond.(ProcessData{p}){7}{w};
        else %otherwise generate generic label
        wins{3+w} = strcat('Userwin',num2str(w));
        end
    end
end
outdata.metadata.perievent.maxwins.label{p} = wins;
outdata.metadata.perievent.maxwins.timepoints{p} = wintimes;
for c = 1:length(setcond.(ProcessData{p}){2})

%% time span for peri-event filtering, PRE and POST
    preevent = setcond.(ProcessData{p}){5}(1);
    postevent = setcond.(ProcessData{p}){5}(2);
    TRANGE = round([-1*preevent*(fs),postevent*(fs)]);
    framefs = 1/fs;
    outdata.timearray.(ProcessData{p}).FP.perievent{f,1} = (TRANGE(1)*framefs:framefs:TRANGE(2)*framefs);
    outdata.perievent.(ProcessData{p}).TRANGE{f,1} = TRANGE;
    clear TRANGE temp
    
    if isfield(outdata.eventdata.(ProcessData{p}),setcond.(ProcessData{p}){2}{c}) %if there are trials of this type fill data    
%% Get and save Snips 
     % get perievent snips 
     %trials = outdata.eventdata.(ProcessData{p}).(outdata.metadata.cond{f,1}{1,p}{1,c}).trialn{f,1};
     trials = outdata.eventdata.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).trialn{f,1};
     if ~ismissing(exclusionlist{f,exclindx(boxnumb(b),p)}) 
        if ~isa(exclusionlist{f,exclindx(boxnumb(b),p)},'char')
        exclusionlist{f,exclindx(boxnumb(b),p)} = num2str(exclusionlist{f,exclindx(boxnumb(b),p)});
        end
     exclude = GetLists(exclusionlist{f,exclindx(boxnumb(b),p)},'%f');
     exclude = exclude{1,1};
     else
     exclude = [];
     end

      %unfilt
     [ufdFF_snips,ufraw_snips,ufdFF_snips_ts, ufdFF_snips_trialn, ufdFF_snips_indx] = FP_GetSnips(outdata.eventdata.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).ts{f,1}, outdata.perievent.(ProcessData{p}).TRANGE{f,1},time, outdata.unfilt.detrended.dFF{f,1}, outdata.unfilt.ds.(signallabel){f,1},trials,exclude);    
       %filt
     [dFF_snips,raw_snips,dFF_snips_ts, dFF_snips_trialn, dFF_snips_indx,exclude,removecond] = FP_GetSnips(outdata.eventdata.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).ts{f,1}, outdata.perievent.(ProcessData{p}).TRANGE{f,1},time, dFF, data.streams.(SIG).data,trials,exclude);    

         if ~removecond %if there are enough trials continue
     % Save Snips 
      outdata.perievent.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).ts{f,1} = cell2mat(dFF_snips_ts);%timestamps for each trial
      outdata.perievent.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).trialn{f,1}= dFF_snips_trialn;%trial number for each trial
      outdata.perievent.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).indx{f,1} = cell2mat(dFF_snips_indx); %array indx for each snip
      outdata.perievent.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).dFF.trials{f,1} = cell2mat(dFF_snips); %trace_cue
      outdata.perievent.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).raw.trials{f,1} = cell2mat(raw_snips); %trace_cue
      outdata.metadata.excludedtrials.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}){f,1} = exclude;

      outdata.unfilt.perievent.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).ts{f,1} = cell2mat(ufdFF_snips_ts);%timestamps for each trial
      outdata.unfilt.perievent.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).trialn{f,1}= ufdFF_snips_trialn;%trial number for each trial
      outdata.unfilt.perievent.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).indx{f,1} = cell2mat(ufdFF_snips_indx); %array indx for each snip
      outdata.unfilt.perievent.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).dFF.trials{f,1} = cell2mat(ufdFF_snips); %trace_cue
      outdata.unfilt.perievent.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).raw.trials{f,1} = cell2mat(ufraw_snips); %trace_cue
      clear dFF_snips raw_snips dFF_snips_ts dFF_snips_trialn trials exclude dFF_snips_indx ufdFF_snips ufraw_snips ufdFF_snips_ts ufdFF_snips_trialn uftrials ufdFF_snips_indx
     % Get Zscored Snips
     %dFF data
      [Z_dFFdata]= FP_Zscoresnips(outdata.perievent.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).dFF.trials{f,1},outdata.timearray.(ProcessData{p}).FP.perievent{f,1},0);
      outdata.perievent.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).Z_dFF.trials{f,1} = Z_dFFdata; 
      clear Z_dFFdata
      [Z_dFFdata]= FP_Zscoresnips(outdata.unfilt.perievent.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).dFF.trials{f,1},outdata.timearray.(ProcessData{p}).FP.perievent{f,1},0);
      outdata.unfilt.perievent.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).Z_dFF.trials{f,1} = Z_dFFdata; 
      clear Z_dFFdata
      %raw data
      [Z_rawdata]= FP_Zscoresnips(outdata.perievent.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).raw.trials{f,1},outdata.timearray.(ProcessData{p}).FP.perievent{f,1},0);
      outdata.perievent.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).Z_raw.trials{f,1} = Z_rawdata; 
      clear Z_rawdata
      [Z_rawdata]= FP_Zscoresnips(outdata.unfilt.perievent.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).raw.trials{f,1},outdata.timearray.(ProcessData{p}).FP.perievent{f,1},0);
      outdata.unfilt.perievent.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).Z_raw.trials{f,1} = Z_rawdata; 
      clear Z_rawdata
      
      for dd = 1:length(datatypes) 
      %calculate mean and error for trials
      [outdata] = GetPlotData(f, outdata, (ProcessData{p}),(setcond.(ProcessData{p}){2}{c}),(datatypes{dd}));
      
      %Find Max Response value and ts
      for w = 1:length(wins)
      maxmeasures = {'peaktimearray','peakval','peakval_norm','peakts','peaklatency','peaktrace','peaktrace_norm','peakindx','riseslope','riseslope_norm','fallslope','fallslope_norm','AUC','AUC_norm','avFP','avFP_norm','normval'}; 
      maxmeasurelabs = {'timearray','peakval','normpeakval','ts','latency','trace','normtrace','indx','rise','normrise','fall','normfall','AUC','normAUC','avFP','normavFP','normval'};
      if length(setcond.(ProcessData{p})) == 8 
      %[peakanalysis.peak,peakanalysis.normpeak,peakanalysis.indx,peakanalysis.ts,peakanalysis.latency,peakanalysis.trace,peakanalysis.normtrace,peakanalysis.timearray,peakanalysis.rise,peakanalysis.normrise,peakanalysis.fall,peakanalysis.normfall,peakanalysis.AUC,peakanalysis.normAUC,peakanalysis.normval]= FP_MaxResponse_new(outdata.timearray.(ProcessData{p}).FP.perievent{f,1},outdata.perievent.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(datatypes{dd}).trials{f,1},(wintimes{w}),setcond.(ProcessData{p}){8}{w});
      [peakanalysis.trials]= FP_MaxResponse(outdata.timearray.(ProcessData{p}).FP.perievent{f,1},outdata.perievent.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(datatypes{dd}).trials{f,1},(wintimes{w}),setcond.(ProcessData{p}){8}{w});
      else
      [peakanalysis.trials]= FP_MaxResponse(outdata.timearray.(ProcessData{p}).FP.perievent{f,1},outdata.perievent.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(datatypes{dd}).trials{f,1},(wintimes{w}));
      end
      outdata.timearray.(ProcessData{p}).FP.Peak.(wins{w}){f,1} =  peakanalysis.trials.peaktimearray(1,:);
          for mm = 2:length(maxmeasures)
            outdata.perievent.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(datatypes{dd}).Peak.(maxmeasurelabs{mm}).(wins{w}).trials{f,1} = peakanalysis.trials.(maxmeasures{mm});
            outdata.perievent.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(datatypes{dd}).Peak.(maxmeasurelabs{mm}).(wins{w}).mean(f,:)= mean(outdata.perievent.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(datatypes{dd}).Peak.(maxmeasurelabs{mm}).(wins{w}).trials{f,1},'omitnan');
            outdata.perievent.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(datatypes{dd}).Peak.(maxmeasurelabs{mm}).(wins{w}).stdev(f,:)= std(outdata.perievent.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(datatypes{dd}).Peak.(maxmeasurelabs{mm}).(wins{w}).trials{f,1},'omitnan');
            outdata.perievent.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(datatypes{dd}).Peak.(maxmeasurelabs{mm}).(wins{w}).n(f,:)= length(outdata.perievent.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(datatypes{dd}).Peak.(maxmeasurelabs{mm}).(wins{w}).trials{f,1}(:,1))-sum(isnan(outdata.perievent.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(datatypes{dd}).Peak.(maxmeasurelabs{mm}).(wins{w}).trials{f,1}(:,1)));
            outdata.perievent.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(datatypes{dd}).Peak.(maxmeasurelabs{mm}).(wins{w}).sem(f,:)= (outdata.perievent.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(datatypes{dd}).Peak.(maxmeasurelabs{mm}).(wins{w}).stdev(f,:))/sqrt(outdata.perievent.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(datatypes{dd}).Peak.(maxmeasurelabs{mm}).(wins{w}).n(f,:));
          end
      clear peakanalysis mm
      end
      
      %Find Min Response value and ts
      for w = 1:length(wins)
      if length(setcond.(ProcessData{p})) == 8 
      %[peakanalysis.peak,peakanalysis.normpeak,peakanalysis.indx,peakanalysis.ts,peakanalysis.latency,peakanalysis.trace,peakanalysis.normtrace,peakanalysis.timearray,peakanalysis.rise,peakanalysis.normrise,peakanalysis.fall,peakanalysis.normfall,peakanalysis.AUC,peakanalysis.normAUC,peakanalysis.normval]= FP_MaxResponse_new(outdata.timearray.(ProcessData{p}).FP.perievent{f,1},outdata.perievent.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(datatypes{dd}).trials{f,1},(wintimes{w}),setcond.(ProcessData{p}){8}{w});
      [peakanalysis.trials]= FP_MinResponse(outdata.timearray.(ProcessData{p}).FP.perievent{f,1},outdata.perievent.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(datatypes{dd}).trials{f,1},(wintimes{w}),setcond.(ProcessData{p}){8}{w});
      else
      [peakanalysis.trials]= FP_MinResponse(outdata.timearray.(ProcessData{p}).FP.perievent{f,1},outdata.perievent.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(datatypes{dd}).trials{f,1},(wintimes{w}));
      end
      outdata.timearray.(ProcessData{p}).FP.Trough.(wins{w}){f,1} =  peakanalysis.trials.peaktimearray(1,:);
          for mm = 2:length(maxmeasures)
            outdata.perievent.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(datatypes{dd}).Trough.(maxmeasurelabs{mm}).(wins{w}).trials{f,1} = peakanalysis.trials.(maxmeasures{mm});
            outdata.perievent.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(datatypes{dd}).Trough.(maxmeasurelabs{mm}).(wins{w}).mean(f,:)= mean(outdata.perievent.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(datatypes{dd}).Peak.(maxmeasurelabs{mm}).(wins{w}).trials{f,1},'omitnan');
            outdata.perievent.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(datatypes{dd}).Trough.(maxmeasurelabs{mm}).(wins{w}).stdev(f,:)= std(outdata.perievent.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(datatypes{dd}).Peak.(maxmeasurelabs{mm}).(wins{w}).trials{f,1},'omitnan');
            outdata.perievent.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(datatypes{dd}).Trough.(maxmeasurelabs{mm}).(wins{w}).n(f,:)= length(outdata.perievent.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(datatypes{dd}).Peak.(maxmeasurelabs{mm}).(wins{w}).trials{f,1}(:,1))-sum(isnan(outdata.perievent.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(datatypes{dd}).Peak.(maxmeasurelabs{mm}).(wins{w}).trials{f,1}(:,1)));
            outdata.perievent.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(datatypes{dd}).Trough.(maxmeasurelabs{mm}).(wins{w}).sem(f,:)= (outdata.perievent.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(datatypes{dd}).Peak.(maxmeasurelabs{mm}).(wins{w}).stdev(f,:))/sqrt(outdata.perievent.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(datatypes{dd}).Peak.(maxmeasurelabs{mm}).(wins{w}).n(f,:));
          end
          clear peakanalysis mm
      end
       clear maxmeasurelabs maxmeasures
      end
      
     else %if there are not enough trials for analysis then remove from struct and remove condition from list
        outdata.eventdata.(ProcessData{p}) = rmfield(outdata.eventdata.(ProcessData{p}),(setcond.(ProcessData{p}){2}{c}));
        indxcondition = strcmp(outdata.metadata.availcond{f,1}{p},setcond.(ProcessData{p}){2}{c});
        ic = find(indxcondition==1);
        if ~isempty(ic)
        outdata.metadata.availcond{f,1}{p}(ic) = [];
        end
     end
    else
        indxcondition = strcmp(outdata.metadata.availcond{f,1}{p},setcond.(ProcessData{p}){2}{c});
        ic = find(indxcondition==1);
        if ~isempty(ic)
        outdata.metadata.availcond{f,1}{p}(ic) = [];
        end
    end

      if ~isfield(outdata.eventdata.(ProcessData{p}),setcond.(ProcessData{p}){2}{c}) %if there are no trials of this type fill data in as NaN
      outdata.perievent.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).ts{f,1} = [];%timestamps for each trial
      outdata.perievent.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).trialn{f,1}= [];%trial number for each trial
      outdata.perievent.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).indx{f,1} = []; %array indx for each snip
      outdata.perievent.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).dFF.trials{f,1} = []; %trace_cue
      outdata.perievent.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).raw.trials{f,1} = []; %trace_cue
      
      outdata.perievent.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).Z_dFF.trials{f,1} = [];
      outdata.perievent.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).Z_raw.trials{f,1} = [];
        for dd = 1:length(datatypes) 
            arraywidth = length(outdata.timearray.(ProcessData{p}).FP.perievent{f,1});
        %mean and error for trials
        outdata.perievent.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(datatypes{dd}).mean(f,:) = NaN(1,arraywidth);
        outdata.perievent.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(datatypes{dd}).std(f,:) = NaN(1,arraywidth);
        outdata.perievent.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(datatypes{dd}).n (f,:) = NaN;
        outdata.perievent.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(datatypes{dd}).sem(f,:) = NaN(1,arraywidth);
        %Find Max Response value and ts
        maxmeasurelabs = {'peakval','normpeakval','ts','latency','indx','rise','normrise','fall','normfall','AUC','normAUC','avFP','normavFP','normval','trace','normtrace','timearray'};

        for w = 1:length(wins)
            if ~isnan(wintimes{w}(1))
            arraystart = find(outdata.timearray.(ProcessData{p}).FP.perievent{f,1} >= wintimes{w}(1),1,'first');
            else
            arraystart = 1;
            end
            if ~isnan(wintimes{w}(2))
            arrayend = find(outdata.timearray.(ProcessData{p}).FP.perievent{f,1} <= wintimes{w}(2),1,'last');
            else
            arrayend = length(outdata.timearray.(ProcessData{p}).FP.perievent{f,1});
            end
            maxarray = (arraystart:arrayend);
            
            %peak
            for m = 1:length(maxmeasurelabs)
                if m < 15
                outdata.perievent.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(datatypes{dd}).Peak.(maxmeasurelabs{m}).(wins{w}).trials{f,1} = [];
                outdata.perievent.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(datatypes{dd}).Peak.(maxmeasurelabs{m}).(wins{w}).mean(f,:)= NaN;
                outdata.perievent.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(datatypes{dd}).Peak.(maxmeasurelabs{m}).(wins{w}).stdev(f,:)= NaN;
                outdata.perievent.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(datatypes{dd}).Peak.(maxmeasurelabs{m}).(wins{w}).n(f,:)= NaN;
                outdata.perievent.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(datatypes{dd}).Peak.(maxmeasurelabs{m}).(wins{w}).sem(f,:)= NaN;
                else
                     if m~=17
                        outdata.perievent.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(datatypes{dd}).Peak.(maxmeasurelabs{m}).(wins{w}).trials{f,1} = NaN(1,length(maxarray));              
                        outdata.perievent.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(datatypes{dd}).Peak.(maxmeasurelabs{m}).(wins{w}).mean(f,:)= NaN(1,length(maxarray));
                        outdata.perievent.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(datatypes{dd}).Peak.(maxmeasurelabs{m}).(wins{w}).stdev(f,:)= NaN(1,length(maxarray));
                        outdata.perievent.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(datatypes{dd}).Peak.(maxmeasurelabs{m}).(wins{w}).n(f,:)= NaN;
                        outdata.perievent.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(datatypes{dd}).Peak.(maxmeasurelabs{m}).(wins{w}).sem(f,:)= NaN(1,length(maxarray));   
                    else %time array
                    outdata.timearray.(ProcessData{p}).FP.Peak.(wins{w}){f,1} = outdata.timearray.(ProcessData{p}).FP.perievent{f,1}(maxarray);    
                    end
                end
            end
            
            %trough
             for m = 1:length(maxmeasurelabs)
                if m < 15
                outdata.perievent.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(datatypes{dd}).Trough.(maxmeasurelabs{m}).(wins{w}).trials{f,1} = [];
                outdata.perievent.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(datatypes{dd}).Trough.(maxmeasurelabs{m}).(wins{w}).mean(f,:)= NaN;
                outdata.perievent.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(datatypes{dd}).Trough.(maxmeasurelabs{m}).(wins{w}).stdev(f,:)= NaN;
                outdata.perievent.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(datatypes{dd}).Trough.(maxmeasurelabs{m}).(wins{w}).n(f,:)= NaN;
                outdata.perievent.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(datatypes{dd}).Trough.(maxmeasurelabs{m}).(wins{w}).sem(f,:)= NaN;
                else
                     if m~=17
                        outdata.perievent.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(datatypes{dd}).Trough.(maxmeasurelabs{m}).(wins{w}).trials{f,1} = NaN(1,length(maxarray));              
                        outdata.perievent.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(datatypes{dd}).Trough.(maxmeasurelabs{m}).(wins{w}).mean(f,:)= NaN(1,length(maxarray));
                        outdata.perievent.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(datatypes{dd}).Trough.(maxmeasurelabs{m}).(wins{w}).stdev(f,:)= NaN(1,length(maxarray));
                        outdata.perievent.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(datatypes{dd}).Trough.(maxmeasurelabs{m}).(wins{w}).n(f,:)= NaN;
                        outdata.perievent.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(datatypes{dd}).Trough.(maxmeasurelabs{m}).(wins{w}).sem(f,:)= NaN(1,length(maxarray));   
                    else %time array
                    outdata.timearray.(ProcessData{p}).FP.Trough.(wins{w}){f,1} = outdata.timearray.(ProcessData{p}).FP.perievent{f,1}(maxarray);    
                    end
                end
            end
        end
        end
      end
clear removecond
end
else
    outdata.metadata.availcond{f,1}{p} = []; 
end
end

clear  dFF time
%% Setup plotting variables (eventline and labels)
for p = 1:length(ProcessData)
if UserVals.Stim.plotevent
   t0event = setcond.(ProcessData{p}){1}(1); %event to be plotted as t0
   eventtoplot = true;
   eventonset= UserVals.Stim.eventstart;

   if strcmp((setcond.(ProcessData{p}){3}),'during') && ~isempty (setcond.(ProcessData{p}){4}) %if user can set t0
   t0event = setcond.(ProcessData{p}){4}(1);%if they have override default
   end

       %check to make sure t0 is the primary event
       if t0event ~= UserVals.Stim.primaryis %only adjust defaults if t0event is not cue
           if t0event == UserVals.Stim.eventis
           eventonset = 0; %if event is t0 set eventonset to 0
           else
           eventtoplot = false; %if the t0 event is not primary or event to plot then don't plot event
           end
       end      
   outdata.plot.(ProcessData{p}).t0event=eventtypes{t0event};
   outdata.plot.(ProcessData{p}).eventtoplot=eventtoplot;
   outdata.plot.(ProcessData{p}).eventonset=eventonset;
   outdata.plot.(ProcessData{p}).eventduration=UserVals.Stim.eventduration; 
   outdata.plot.(ProcessData{p}).eventlabel= eventtypes{UserVals.Stim.eventis};
else
    eventtoplot = false;
    t0event = setcond.(ProcessData{p}){1}(1); %event to be plotted as t0
    if strcmp((setcond.(ProcessData{p}){3}),'during') && ~isempty (setcond.(ProcessData{p}){4}) %if user can set t0
    t0event = setcond.(ProcessData{p}){4}(1);%if they have override default
    end
    outdata.plot.(ProcessData{p}).t0event=eventtypes{t0event};
end
end

%% Plot individual trials with mean and error - to manually look for outliers in perievent data 
if UserVals.trialplots
for p = 1:length(ProcessData)
for c = 1:length(setcond.(ProcessData{p}){2}) %%cycle through and pull data for all conditions
        datatypes = {'Z_dFF','Z_raw'};
    for dd = 1:length(datatypes) 
        figdir = (strcat(UserVals.saveloc,'Figs',fsep,subjID{b},fsep,'Trials',fsep,'FP',fsep,(datatypes{dd}),fsep,(ProcessData{p}),fsep));    
        if ~exist(figdir, 'dir')
        mkdir(figdir);
        end  
 
        if isfield(outdata.eventdata.(ProcessData{p}),(setcond.(ProcessData{p}){2}{c}))%only plot if there are events for this condition
        if UserVals.Stim.plotevent &&  eventtoplot
        FP_PlotTrials(f,outdata,(ProcessData{p}),outdata.plot.(ProcessData{p}).t0event,(setcond.(ProcessData{p}){2}{c}),c,(datatypes{dd}),figdir,outdata.plot.(ProcessData{p}).eventonset,outdata.plot.(ProcessData{p}).eventduration);
        else
        FP_PlotTrials(f,outdata,(ProcessData{p}),outdata.plot.(ProcessData{p}).t0event,(setcond.(ProcessData{p}){2}{c}),c,(datatypes{dd}),figdir); 
        end
        end
    end
    clear dd
end
end
end

%% Perievent plots
for p = 1: length(ProcessData)
if isfield(outdata.perievent,(ProcessData{p})) && ~isempty(outdata.metadata.availcond{f,1}{p})
figdir = (strcat((UserVals.saveloc),'Figs',fsep,subjID{b},fsep,'Perievent',fsep,'FP',fsep,(ProcessData{p}),fsep));
    if ~exist(figdir, 'dir')
       mkdir(figdir);
    end
    
    if UserVals.Stim.plotevent && outdata.plot.(ProcessData{p}).eventtoplot 
    [outdata]= FP_PlotPerievent(f,outdata,figdir,(ProcessData{p}),outdata.metadata.availcond{f,1}{p},outdata.plot.(ProcessData{p}).t0event,outdata.plot.(ProcessData{p}).eventonset,outdata.plot.(ProcessData{p}).eventduration,outdata.plot.(ProcessData{p}).eventlabel);
    else
    [outdata]= FP_PlotPerievent(f,outdata,figdir,(ProcessData{p}),(outdata.metadata.availcond{f,1}{p}),outdata.plot.(ProcessData{p}).t0event); 
    end
end
end

%% Plot Peaks
for p = 1: length(ProcessData)
if isfield(outdata.perievent,(ProcessData{p})) && ~isempty(outdata.metadata.availcond{f,1}{p})
figdir = (strcat((UserVals.saveloc),'Figs',fsep,subjID{b},fsep,'Peak',fsep,'FP',fsep,(ProcessData{p}),fsep));
    if ~exist(figdir, 'dir')
       mkdir(figdir);
    end
    %maxresponselabs = {'maxval','maxvalchange', 'maxts','maxtrace'};
    if UserVals.normpeaks
    maxresponselabs = {'normpeakval','ts','normtrace','normAUC'}; 
    else
    maxresponselabs = {'peakval','ts','trace','AUC'}; 
    end
    maxfiglabels = {'Peak Fluorescence','Peak time(s)','FP Trace','AUC'};
    wins = outdata.metadata.perievent.maxwins.label{p};
    if UserVals.Stim.plotevent && outdata.plot.(ProcessData{p}).eventtoplot 
    FP_PlotPeaks(f,outdata,figdir,(ProcessData{p}),outdata.plot.(ProcessData{p}).t0event,outdata.metadata.availcond{f,1}{p},wins,maxresponselabs,maxfiglabels,outdata.plot.(ProcessData{p}).eventonset,outdata.plot.(ProcessData{p}).eventduration,outdata.plot.(ProcessData{p}).eventlabel);
    else
    FP_PlotPeaks(f,outdata,figdir,(ProcessData{p}),outdata.plot.(ProcessData{p}).t0event,outdata.metadata.availcond{f,1}{p},wins,maxresponselabs,maxfiglabels);
    end
end
end

%% DLC Analysis
if UserVals.DLCAnalysis || UserVals.freezingbouts || UserVals.locobouts   
    %Get DLCdata
    dlccsv = strcat(PATH,FILE,fsep,VIDprefix,'_',FILE,'_',CAM,DLC,'.csv');
    [DLCdata] = DLC_Analyze(f,outdata,dlccsv);
    clear dlccsv 
    outdata.rawdata.DLC{f,1} = DLCdata; %saves raw DLC struct
    outdata.UserVals.DLC.pixelpercm{f,1} = DLCdata.pixpercm;
    outdata.UserVals.DLC.FPS{f,1} = round(DLCdata.FPS);
   
    %get perievent snips of DLCdata
    for p = 1:length(ProcessData)      
    preevent = setcond.(ProcessData{p}){5}(1);
    postevent = setcond.(ProcessData{p}){5}(2);
    DLCTRANGE = [-1*(preevent*(round(DLCdata.FPS))),postevent*(round(outdata.UserVals.DLC.FPS{f,1}))];
    % outdata.UserVals.DLCsetup.DLCTRANGE{p} = DLCTRANGE;  
    framefs = 1/DLCdata.FPS;
    outdata.DLC.(ProcessData{p}).time{f,1}= (DLCTRANGE(1)*framefs:framefs:DLCTRANGE(2)*framefs);
    clear TRANGE 
    
    if outdata.rawdata.DLC{f,1}.paddata
        framerate =outdata.videodata.vidFPS{f,1}; %original FPS 
        padDLCTRANGE = [-1*(preevent*(round(framerate))),postevent*(round(framerate))];    
        outdata.UserVals.DLCsetup.padDLCTRANGE{f,1}{p} = padDLCTRANGE;
        framefs = 1/framerate;
        outdata.UserVals.DLC.padtimearray{f,1}{p} = (padDLCTRANGE(1)*framefs:framefs:padDLCTRANGE(2)*framefs);  
        outdata.timearray.(ProcessData{p}).DLC.perievent{f,1} = outdata.UserVals.DLC.padtimearray{f,1}{p};
    else
        outdata.UserVals.DLC.padDLCTRANGE{f,1} = [];
        outdata.UserVals.DLC.padtimearray{f,1} = [];
        outdata.timearray.(ProcessData{p}).DLC.perievent{f,1} = outdata.DLC.(ProcessData{p}).time{f,1};
    end
    
    wins = outdata.metadata.perievent.maxwins.label{p};
    wintimes = outdata.metadata.perievent.maxwins.timepoints{p};
    for w = 1:length(wins)
                            if ~isempty(wintimes{w})
                                if ~isnan(wintimes{w}(1))
                                    arraystart = find(outdata.DLC.(ProcessData{p}).time{f,1} >= wintimes{w}(1),1,'first');
                                else
                                    arraystart = 1;
                                end
                                if ~isnan(wintimes{w}(2))
                                    arrayend = find(outdata.DLC.(ProcessData{p}).time{f,1} <= wintimes{w}(2),1,'last');
                                else
                                    arrayend = length(outdata.DLC.(ProcessData{p}).time{f,1});
                                end
                            else
                                arraystart = 1;
                                arrayend = length(outdata.DLC.(ProcessData{p}).time{f,1});
                            end
                        indxarray.wins{w} = (arraystart:arrayend);
                        outdata.timearray.(ProcessData{p}).DLC.Peak.(wins{w}){f,1} = outdata.DLC.(ProcessData{p}).time{f,1}(indxarray.wins{w});
    end
   
    arraywidth = size(outdata.DLC.(ProcessData{p}).time{f},2);
    for c = 1:length(setcond.(ProcessData{p}){2})
        if ~isfield(outdata.eventdata.(ProcessData{p}),(setcond.(ProcessData{p}){2}{c}))%if there are no trials of this type fill data in as NaN                
            for m = 1: length(outdata.UserVals.DLCsetup.measures)
                numsubfields = length(outdata.UserVals.DLCsetup.Subfields.(outdata.UserVals.DLCsetup.measures{m}));
                flds = outdata.UserVals.DLCsetup.Subfields.(outdata.UserVals.DLCsetup.measures{m}){1};
                for x =1:length(flds) 
                switch numsubfields
                case 1 %one subfield
                    outdata.DLC.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(outdata.UserVals.DLCsetup.measures{m}).(flds{x}).mean(f,:) = NaN(1,arraywidth);
                    outdata.DLC.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(outdata.UserVals.DLCsetup.measures{m}).(flds{x}).std(f,:) = NaN(1,arraywidth);
                    outdata.DLC.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(outdata.UserVals.DLCsetup.measures{m}).(flds{x}).n (f,:) = NaN;
                    outdata.DLC.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(outdata.UserVals.DLCsetup.measures{m}).(flds{x}).sem(f,:) = NaN(1,arraywidth);
                        %maxvals 
                        for w= 1:length(wins)
                        outdata.DLC.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(outdata.UserVals.DLCsetup.measures{m}).(flds{x}).Peak.(wins{w}).trials{f,1} = [];
                        outdata.DLC.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(outdata.UserVals.DLCsetup.measures{m}).(flds{x}).Peak.(wins{w}).mean(f,:) = NaN(1,length(indxarray.wins{w}));
                        outdata.DLC.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(outdata.UserVals.DLCsetup.measures{m}).(flds{x}).Peak.(wins{w}).stdev(f,:)= NaN(1,length(indxarray.wins{w}));
                        outdata.DLC.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(outdata.UserVals.DLCsetup.measures{m}).(flds{x}).Peak.(wins{w}).n(f,:)= NaN(1,length(indxarray.wins{w}));
                        outdata.DLC.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(outdata.UserVals.DLCsetup.measures{m}).(flds{x}).Peak.(wins{w}).sem(f,:)= NaN(1,length(indxarray.wins{w}));
                        end
                        
                case 2 %two subfields
                    refr = outdata.UserVals.DLCsetup.Subfields.(outdata.UserVals.DLCsetup.measures{m}){2}{x};
                    for r = 1:length(refr)
                    outdata.DLC.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(outdata.UserVals.DLCsetup.measures{m}).(flds{x}).(refr{r}).mean(f,:) = NaN(1,arraywidth);
                    outdata.DLC.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(outdata.UserVals.DLCsetup.measures{m}).(flds{x}).(refr{r}).std(f,:) = NaN(1,arraywidth);
                    outdata.DLC.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(outdata.UserVals.DLCsetup.measures{m}).(flds{x}).(refr{r}).n (f,:) = NaN;
                    outdata.DLC.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(outdata.UserVals.DLCsetup.measures{m}).(flds{x}).(refr{r}).sem(f,:) = NaN(1,arraywidth);
                        for w = 1:length(wins)
                            outdata.DLC.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(outdata.UserVals.DLCsetup.measures{m}).(flds{x}).(refr{r}).Peak.(wins{w}).trials{f,1} = [];
                            outdata.DLC.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(outdata.UserVals.DLCsetup.measures{m}).(flds{x}).(refr{r}).Peak.(wins{w}).mean(f,:) = NaN(1,length(indxarray.wins{w}));
                            outdata.DLC.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(outdata.UserVals.DLCsetup.measures{m}).(flds{x}).(refr{r}).Peak.(wins{w}).stdev(f,:)= NaN(1,length(indxarray.wins{w}));
                            outdata.DLC.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(outdata.UserVals.DLCsetup.measures{m}).(flds{x}).(refr{r}).Peak.(wins{w}).n(f,:)= NaN(1,length(indxarray.wins{w}));
                            outdata.DLC.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(outdata.UserVals.DLCsetup.measures{m}).(flds{x}).(refr{r}).Peak.(wins{w}).sem(f,:)= NaN(1,length(indxarray.wins{w}));
                        end
                    end
                case 3 %three subfields
                    refr = outdata.UserVals.DLCsetup.Subfields.(outdata.UserVals.DLCsetup.measures{m}){2}{x};
                    for r = 1:length(refr)
                        typ = outdata.UserVals.DLCsetup.Subfields.(outdata.UserVals.DLCsetup.measures{m}){3}{x,r};
                        for i = 1:length(typ)  
                        outdata.DLC.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(outdata.UserVals.DLCsetup.measures{m}).(flds{x}).(refr{r}).(typ{i}).mean(f,:) = NaN(1,arraywidth);
                        outdata.DLC.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(outdata.UserVals.DLCsetup.measures{m}).(flds{x}).(refr{r}).(typ{i}).std(f,:) = NaN(1,arraywidth);
                        outdata.DLC.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(outdata.UserVals.DLCsetup.measures{m}).(flds{x}).(refr{r}).(typ{i}).n (f,:) = NaN;
                        outdata.DLC.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(outdata.UserVals.DLCsetup.measures{m}).(flds{x}).(refr{r}).(typ{i}).sem(f,:) = NaN(1,arraywidth);
                            for w = 1:length(wins)
                                 outdata.DLC.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(outdata.UserVals.DLCsetup.measures{m}).(flds{x}).(refr{r}).(typ{i}).Peak.(wins{w}).trials{f,1} = [];
                                 outdata.DLC.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(outdata.UserVals.DLCsetup.measures{m}).(flds{x}).(refr{r}).(typ{i}).Peak.(wins{w}).mean(f,:) = NaN(1,length(indxarray.wins{w}));
                                 outdata.DLC.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(outdata.UserVals.DLCsetup.measures{m}).(flds{x}).(refr{r}).(typ{i}).Peak.(wins{w}).stdev(f,:)= NaN(1,length(indxarray.wins{w}));
                                 outdata.DLC.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(outdata.UserVals.DLCsetup.measures{m}).(flds{x}).(refr{r}).(typ{i}).Peak.(wins{w}).n(f,:)= NaN(1,length(indxarray.wins{w}));
                                 outdata.DLC.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(outdata.UserVals.DLCsetup.measures{m}).(flds{x}).(refr{r}).(typ{i}).Peak.(wins{w}).sem(f,:)= NaN(1,length(indxarray.wins{w}));
                            end
                        end
                    end
                end
                clear refr typ x r y
                end
                clear numsubfields flds
            end
            
        else
            if outdata.rawdata.DLC{f,1}.paddata
            [outdata] = DLC_GetSnips (f,outdata,DLCdata,padDLCTRANGE,(setcond.(ProcessData{p}){2}{c}),(ProcessData{p}));
            else                   
            [outdata] = DLC_GetSnips (f,outdata,DLCdata,DLCTRANGE,(setcond.(ProcessData{p}){2}{c}),(ProcessData{p}));
            end
        end
        

                %extract quadrant data for peak windows here
        for w = 1:length(wins)
        if isfield(outdata.UserVals.DLCsetup.Subfields,'Quadrant')
            quad = {'LT','LB','RT','RB'};
            quadbps = outdata.UserVals.DLCsetup.Subfields.Quadrant{1,1};
            for qb = 1:length(quadbps)
                for q = 1:4
                    if isfield(outdata.eventdata.(ProcessData{p}),(setcond.(ProcessData{p}){2}{c}))
                        for t = 1:length(outdata.DLC.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).Quadrant.(quadbps{qb}).(quad{q}).trials{f,1}(:,1))
                        validpoints = sum(~isnan(outdata.DLC.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).Quadrant.(quadbps{qb}).(quad{q}).trials{f,1}(t,indxarray.wins{w})));
                        if validpoints ~= 0 %if not all points are nan
                            outdata.DLC.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).Quadrant.(quadbps{qb}).(quad{q}).Peak.(wins{w}).trials{f,1}(t,1) = (sum(outdata.DLC.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).Quadrant.(quadbps{qb}).(quad{q}).trials{f,1}(t,indxarray.wins{w}),'omitnan')/validpoints)*100;
                        else
                            outdata.DLC.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).Quadrant.(quadbps{qb}).(quad{q}).Peak.(wins{w}).trials{f,1}(t,1) = NaN; 
                        end
                        end
                        outdata.DLC.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).Quadrant.(quadbps{qb}).(quad{q}).Peak.(wins{w}).mean{f,1} = mean(outdata.DLC.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).Quadrant.(quadbps{qb}).(quad{q}).Peak.(wins{w}).trials{f,1},'omitnan');
                        outdata.DLC.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).Quadrant.(quadbps{qb}).(quad{q}).Peak.(wins{w}).stdev{f,1} = std(outdata.DLC.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).Quadrant.(quadbps{qb}).(quad{q}).Peak.(wins{w}).trials{f,1},'omitnan');
                        outdata.DLC.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).Quadrant.(quadbps{qb}).(quad{q}).Peak.(wins{w}).n{f,1} = sum(~isnan(outdata.DLC.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).Quadrant.(quadbps{qb}).(quad{q}).Peak.(wins{w}).trials{f,1}));
                        outdata.DLC.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).Quadrant.(quadbps{qb}).(quad{q}).Peak.(wins{w}).sem{f,1} = outdata.DLC.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).Quadrant.(quadbps{qb}).(quad{q}).Peak.(wins{w}).stdev{f,1}/sqrt(outdata.DLC.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).Quadrant.(quadbps{qb}).(quad{q}).Peak.(wins{w}).n{f,1});
                    else
                        outdata.DLC.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).Quadrant.(quadbps{qb}).(quad{q}).Peak.(wins{w}).trials{f,1} = [];
                        outdata.DLC.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).Quadrant.(quadbps{qb}).(quad{q}).Peak.(wins{w}).mean{f,1} = NaN;
                        outdata.DLC.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).Quadrant.(quadbps{qb}).(quad{q}).Peak.(wins{w}).stdev{f,1} = NaN;
                        outdata.DLC.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).Quadrant.(quadbps{qb}).(quad{q}).Peak.(wins{w}).n{f,1} = NaN;
                        outdata.DLC.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).Quadrant.(quadbps{qb}).(quad{q}).Peak.(wins{w}).sem{f,1} = NaN;
                    end
                end
            end
        end
        end
        %extract DLC traces for peak analysis windows
        wins = outdata.metadata.perievent.maxwins.label{p};
        wintimes = outdata.metadata.perievent.maxwins.timepoints{p};

        for m = 1:length(outdata.UserVals.DLCsetup.measures)
        numsubfields = length(outdata.UserVals.DLCsetup.Subfields.(outdata.UserVals.DLCsetup.measures{m}));
        flds = outdata.UserVals.DLCsetup.Subfields.(outdata.UserVals.DLCsetup.measures{m}){1};                
            for x =1:length(flds) 
            switch numsubfields
            case 1
                for w = 1:length(wins)   
                    if isfield(outdata.eventdata.(ProcessData{p}),(setcond.(ProcessData{p}){2}{c}))
                    outdata.DLC.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(outdata.UserVals.DLCsetup.measures{m}).(flds{x}).Peak.(wins{w}).trials{f,1} = outdata.DLC.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(outdata.UserVals.DLCsetup.measures{m}).(flds{x}).trials{f,1}(:,indxarray.wins{w});
                    outdata.DLC.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(outdata.UserVals.DLCsetup.measures{m}).(flds{x}).Peak.(wins{w}).mean(f,:) = mean(outdata.DLC.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(outdata.UserVals.DLCsetup.measures{m}).(flds{x}).Peak.(wins{w}).trials{f,1},'omitnan');
                    outdata.DLC.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(outdata.UserVals.DLCsetup.measures{m}).(flds{x}).Peak.(wins{w}).stdev(f,:)= std(outdata.DLC.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(outdata.UserVals.DLCsetup.measures{m}).(flds{x}).Peak.(wins{w}).trials{f,1},'omitnan');
                        for i = 1: length(outdata.DLC.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(outdata.UserVals.DLCsetup.measures{m}).(flds{x}).Peak.(wins{w}).trials{f,1}(1,:))
                        outdata.DLC.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(outdata.UserVals.DLCsetup.measures{m}).(flds{x}).Peak.(wins{w}).n(f,i) =length(outdata.DLC.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(outdata.UserVals.DLCsetup.measures{m}).(flds{x}).Peak.(wins{w}).trials{f,1}(:,i))-sum(isnan(outdata.DLC.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(outdata.UserVals.DLCsetup.measures{m}).(flds{x}).Peak.(wins{w}).trials{f,1}(:,i)));
                        outdata.DLC.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(outdata.UserVals.DLCsetup.measures{m}).(flds{x}).Peak.(wins{w}).sem(f,i)=outdata.DLC.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(outdata.UserVals.DLCsetup.measures{m}).(flds{x}).Peak.(wins{w}).stdev(f,i)/sqrt(outdata.DLC.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(outdata.UserVals.DLCsetup.measures{m}).(flds{x}).Peak.(wins{w}).n(f,i));
                        end
                    else
                    outdata.DLC.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(outdata.UserVals.DLCsetup.measures{m}).(flds{x}).Peak.(wins{w}).trials{f,1} = [];
                    outdata.DLC.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(outdata.UserVals.DLCsetup.measures{m}).(flds{x}).Peak.(wins{w}).mean(f,:) = NaN(1,length(indxarray.wins{w}));
                    outdata.DLC.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(outdata.UserVals.DLCsetup.measures{m}).(flds{x}).Peak.(wins{w}).stdev(f,:)= NaN(1,length(indxarray.wins{w}));
                    outdata.DLC.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(outdata.UserVals.DLCsetup.measures{m}).(flds{x}).Peak.(wins{w}).n(f,:)= NaN(1,length(indxarray.wins{w}));
                    outdata.DLC.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(outdata.UserVals.DLCsetup.measures{m}).(flds{x}).Peak.(wins{w}).sem(f,:)= NaN(1,length(indxarray.wins{w}));
                    end
                end
            case 2
                refr = outdata.UserVals.DLCsetup.Subfields.(outdata.UserVals.DLCsetup.measures{m}){2}{x};
                for r = 1:length(refr)
                    for w = 1:length(wins)   
                    if isfield(outdata.eventdata.(ProcessData{p}),(setcond.(ProcessData{p}){2}{c}))
                    outdata.DLC.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(outdata.UserVals.DLCsetup.measures{m}).(flds{x}).(refr{r}).Peak.(wins{w}).trials{f,1} = outdata.DLC.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(outdata.UserVals.DLCsetup.measures{m}).(flds{x}).(refr{r}).trials{f,1}(:,indxarray.wins{w});
                    outdata.DLC.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(outdata.UserVals.DLCsetup.measures{m}).(flds{x}).(refr{r}).Peak.(wins{w}).mean(f,:) = mean(outdata.DLC.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(outdata.UserVals.DLCsetup.measures{m}).(flds{x}).(refr{r}).Peak.(wins{w}).trials{f,1},'omitnan');
                    outdata.DLC.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(outdata.UserVals.DLCsetup.measures{m}).(flds{x}).(refr{r}).Peak.(wins{w}).stdev(f,:)= std(outdata.DLC.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(outdata.UserVals.DLCsetup.measures{m}).(flds{x}).(refr{r}).Peak.(wins{w}).trials{f,1},'omitnan');
                        for i = 1: length(outdata.DLC.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(outdata.UserVals.DLCsetup.measures{m}).(flds{x}).(refr{r}).Peak.(wins{w}).trials{f,1}(1,:))
                        outdata.DLC.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(outdata.UserVals.DLCsetup.measures{m}).(flds{x}).(refr{r}).Peak.(wins{w}).n(f,i) =length(outdata.DLC.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(outdata.UserVals.DLCsetup.measures{m}).(flds{x}).(refr{r}).Peak.(wins{w}).trials{f,1}(:,i))-sum(isnan(outdata.DLC.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(outdata.UserVals.DLCsetup.measures{m}).(flds{x}).(refr{r}).Peak.(wins{w}).trials{f,1}(:,i)));
                        outdata.DLC.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(outdata.UserVals.DLCsetup.measures{m}).(flds{x}).(refr{r}).Peak.(wins{w}).sem(f,i)=outdata.DLC.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(outdata.UserVals.DLCsetup.measures{m}).(flds{x}).(refr{r}).Peak.(wins{w}).stdev(f,i)/sqrt(outdata.DLC.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(outdata.UserVals.DLCsetup.measures{m}).(flds{x}).(refr{r}).Peak.(wins{w}).n(f,i));
                        end
                    else
                    outdata.DLC.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(outdata.UserVals.DLCsetup.measures{m}).(flds{x}).(refr{r}).Peak.(wins{w}).trials{f,1} = [];
                    outdata.DLC.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(outdata.UserVals.DLCsetup.measures{m}).(flds{x}).(refr{r}).Peak.(wins{w}).mean(f,:) = NaN(1,length(indxarray.wins{w}));
                    outdata.DLC.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(outdata.UserVals.DLCsetup.measures{m}).(flds{x}).(refr{r}).Peak.(wins{w}).stdev(f,:)= NaN(1,length(indxarray.wins{w}));
                    outdata.DLC.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(outdata.UserVals.DLCsetup.measures{m}).(flds{x}).(refr{r}).Peak.(wins{w}).n(f,:)= NaN(1,length(indxarray.wins{w}));
                    outdata.DLC.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(outdata.UserVals.DLCsetup.measures{m}).(flds{x}).(refr{r}).Peak.(wins{w}).sem(f,:)= NaN(1,length(indxarray.wins{w}));
                    end
                    end
                end
            case 3
                refr = outdata.UserVals.DLCsetup.Subfields.(outdata.UserVals.DLCsetup.measures{m}){2}{x};
                for r = 1:length(refr)
                    degs = outdata.UserVals.DLCsetup.Subfields.(outdata.UserVals.DLCsetup.measures{m}){3}{x,r};
                    for d = 1:length(degs)
                    for w = 1:length(wins)   
                    if isfield(outdata.eventdata.(ProcessData{p}),(setcond.(ProcessData{p}){2}{c}))
                    outdata.DLC.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(outdata.UserVals.DLCsetup.measures{m}).(flds{x}).(refr{r}).(degs{d}).Peak.(wins{w}).trials{f,1} = outdata.DLC.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(outdata.UserVals.DLCsetup.measures{m}).(flds{x}).(refr{r}).(degs{d}).trials{f,1}(:,indxarray.wins{w});
                    outdata.DLC.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(outdata.UserVals.DLCsetup.measures{m}).(flds{x}).(refr{r}).(degs{d}).Peak.(wins{w}).mean(f,:) = mean(outdata.DLC.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(outdata.UserVals.DLCsetup.measures{m}).(flds{x}).(refr{r}).(degs{d}).Peak.(wins{w}).trials{f,1},'omitnan');
                    outdata.DLC.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(outdata.UserVals.DLCsetup.measures{m}).(flds{x}).(refr{r}).(degs{d}).Peak.(wins{w}).stdev(f,:)= std(outdata.DLC.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(outdata.UserVals.DLCsetup.measures{m}).(flds{x}).(refr{r}).(degs{d}).Peak.(wins{w}).trials{f,1},'omitnan');
                        for i = 1: length(outdata.DLC.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(outdata.UserVals.DLCsetup.measures{m}).(flds{x}).(refr{r}).(degs{d}).Peak.(wins{w}).trials{f,1}(1,:))
                        outdata.DLC.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(outdata.UserVals.DLCsetup.measures{m}).(flds{x}).(refr{r}).(degs{d}).Peak.(wins{w}).n(f,i) =length(outdata.DLC.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(outdata.UserVals.DLCsetup.measures{m}).(flds{x}).(refr{r}).(degs{d}).Peak.(wins{w}).trials{f,1}(:,i))-sum(isnan(outdata.DLC.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(outdata.UserVals.DLCsetup.measures{m}).(flds{x}).(refr{r}).(degs{d}).Peak.(wins{w}).trials{f,1}(:,i)));
                        outdata.DLC.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(outdata.UserVals.DLCsetup.measures{m}).(flds{x}).(refr{r}).(degs{d}).Peak.(wins{w}).sem(f,i)=outdata.DLC.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(outdata.UserVals.DLCsetup.measures{m}).(flds{x}).(refr{r}).(degs{d}).Peak.(wins{w}).stdev(f,i)/sqrt(outdata.DLC.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(outdata.UserVals.DLCsetup.measures{m}).(flds{x}).(refr{r}).(degs{d}).Peak.(wins{w}).n(f,i));
                        end
                    else
                    outdata.DLC.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(outdata.UserVals.DLCsetup.measures{m}).(flds{x}).(refr{r}).(degs{d}).Peak.(wins{w}).trials{f,1} = [];
                    outdata.DLC.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(outdata.UserVals.DLCsetup.measures{m}).(flds{x}).(refr{r}).(degs{d}).Peak.(wins{w}).mean(f,:) = NaN(1,length(indxarray.wins{w}));
                    outdata.DLC.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(outdata.UserVals.DLCsetup.measures{m}).(flds{x}).(refr{r}).(degs{d}).Peak.(wins{w}).stdev(f,:)= NaN(1,length(indxarray.wins{w}));
                    outdata.DLC.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(outdata.UserVals.DLCsetup.measures{m}).(flds{x}).(refr{r}).(degs{d}).Peak.(wins{w}).n(f,:)= NaN(1,length(indxarray.wins{w}));
                    outdata.DLC.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(outdata.UserVals.DLCsetup.measures{m}).(flds{x}).(refr{r}).(degs{d}).Peak.(wins{w}).sem(f,:)= NaN(1,length(indxarray.wins{w}));
                    end
                    end
                    end
                    clear d degs
                end
                clear r refr
            end
            end
            clear x 
            end           
            clear arraystart arrayend flds
            clear numsubfields i
        end   
        
    
    %plot dlc behavior individual trials
    if UserVals.trialplots       
        for m = 1: length(outdata.UserVals.DLCsetup.measures) 
                    figdir = (strcat((UserVals.saveloc),'Figs',fsep,subjID{b},fsep,'Trials',fsep,'DLC',fsep,(ProcessData{p}),fsep,(outdata.UserVals.DLCsetup.measures{m}),fsep));
                    if ~exist(figdir, 'dir')
                    mkdir(figdir);
                    end
        
                    if isfield(outdata.eventdata.(ProcessData{p}),(setcond.(ProcessData{p}){2}{c}))
                    if UserVals.Stim.plotevent && outdata.plot.(ProcessData{p}).eventtoplot
                    [outdata]=DLC_PlotTrials(f,outdata,figdir,(setcond.(ProcessData{p}){2}{c}),c,ProcessData{p}, outdata.UserVals.DLCsetup.measures{m}, outdata.UserVals.DLCsetup.Subfields.(outdata.UserVals.DLCsetup.measures{m}),outdata.UserVals.DLCsetup.axislabels{m},outdata.plot.(ProcessData{p}).eventonset,outdata.plot.(ProcessData{p}).eventduration);
                    else
                    [outdata]=DLC_PlotTrials(f,outdata,figdir,(setcond.(ProcessData{p}){2}{c}),c,ProcessData{p}, outdata.UserVals.DLCsetup.measures{m}, outdata.UserVals.DLCsetup.Subfields.(outdata.UserVals.DLCsetup.measures{m}),outdata.UserVals.DLCsetup.axislabels{m}); 
                    end
                    end
        end
    end
    end
    clear arraywidth
    
    for p = 1:length(ProcessData) 
        for m = 1:length(outdata.UserVals.DLCsetup.measures)
        %plot dlc behavior mean
        if ~isempty(outdata.metadata.availcond{f,1}{p})
            figdir = (strcat((UserVals.saveloc),'Figs',fsep,subjID{b},fsep,'Perievent',fsep,'DLC',fsep',(ProcessData{p}),fsep));          
        if ~exist(figdir, 'dir')
        mkdir(figdir);
        end 
       
            if UserVals.Stim.plotevent && outdata.plot.(ProcessData{p}).eventtoplot
            [outdata]= DLC_PlotPerievent(f,outdata,figdir,outdata.metadata.availcond{f,1}{p},ProcessData{p},outdata.UserVals.DLCsetup.measures,outdata.plot.(ProcessData{p}).eventonset,outdata.plot.(ProcessData{p}).eventduration,outdata.plot.(ProcessData{p}).eventlabel);
            else
            [outdata]= DLC_PlotPerievent(f,outdata,figdir,outdata.metadata.availcond{f,1}{p},ProcessData{p},outdata.UserVals.DLCsetup.measures); %#ok<*UNRCH>
            end

        end
        end
    end 
%% get Max DLC data for peak windows
peakmeasures = [];
pmind = 1;
for m = 1:length(outdata.UserVals.DLCsetup.measures)
if strcmp(outdata.UserVals.DLCsetup.measures{m},'Speed')
    peakmeasures{pmind} = 'Speed';
    pmind = pmind+1;
end
if strcmp(outdata.UserVals.DLCsetup.measures{m},'MoveDist')
    peakmeasures{pmind} = 'MoveDist';
    pmind = pmind+1;
end
if strcmp(outdata.UserVals.DLCsetup.measures{m},'AngularVelocity')
    peakmeasures{pmind} = 'AngularVelocity';
    pmind = pmind+1;
end
end
if ~isempty(peakmeasures)
    for p = 1: length(ProcessData)
        wins = outdata.metadata.perievent.maxwins.label{p};
        for c = 1:length(setcond.(ProcessData{p}){2})
            if isfield(outdata.eventdata.(ProcessData{p}),(setcond.(ProcessData{p}){2}{c}))%only get data if there are trials of this type
                outdata = DLC_GetMaxVals(f,outdata,(ProcessData{p}),(setcond.(ProcessData{p}){2}{c}),wins,peakmeasures);
            else
                for m = 1:length(peakmeasures)
                    numsubfields = length(outdata.UserVals.DLCsetup.Subfields.(peakmeasures{m}));
                    flds = outdata.UserVals.DLCsetup.Subfields.(peakmeasures{m}){1};
                    switch numsubfields
                        case  1
                            for x = 1:length(flds)
                                for w = 1:length(wins)
                                    outdata.DLC.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(peakmeasures{m}).(flds{x}).Peak.(wins{w}).MaxVal.trials{f,1}= [];
                                end
                            end
                        case 2
                            for x = 1:length(flds)
                                refr = outdata.UserVals.DLCsetup.Subfields.(peakmeasures{m}){2}{x};
                                for r = 1:length(refr)
                                    for w = 1:length(wins)
                                        outdata.DLC.(ProcessData{p}).(setcond.(ProcessData{p}){2}{c}).(peakmeasures{m}).(flds{x}).(refr{r}).Peak.(wins{w}).MaxVal.trials{f,1}= [];
                                    end
                                end
                            end
                    end
                end
            end
        end
    end
end

if isfield (outdata.UserVals.DLCsetup.Subfields,'Speed')
%[outdata] = DLC_SpeedChange (f,ProcessData,setcond,outdata);
end

%% plot DLC data for peak windows
for p = 1: length(ProcessData)
if isfield(outdata.perievent,(ProcessData{p})) && ~isempty(outdata.metadata.availcond{f,1}{p})
    figdir = (strcat((UserVals.saveloc),'Figs',fsep,subjID{b},fsep,'Peak',fsep,'DLC',fsep,(ProcessData{p}),fsep));
    if ~exist(figdir, 'dir')
       mkdir(figdir);
    end
    maxresponselabs = outdata.UserVals.DLCsetup.measures;
    maxfiglabels = outdata.UserVals.DLCsetup.axislabels;
    wins = outdata.metadata.perievent.maxwins.label{p};
    if UserVals.Stim.plotevent && outdata.plot.(ProcessData{p}).eventtoplot 
    DLC_PlotPeaks(f,outdata,figdir,(ProcessData{p}),outdata.plot.(ProcessData{p}).t0event,outdata.metadata.availcond{f,1}{p},wins,maxresponselabs,maxfiglabels,outdata.plot.(ProcessData{p}).eventonset,outdata.plot.(ProcessData{p}).eventduration,outdata.plot.(ProcessData{p}).eventlabel);
    else
    DLC_PlotPeaks(f,outdata,figdir,(ProcessData{p}),outdata.plot.(ProcessData{p}).t0event,outdata.metadata.availcond{f,1}{p},wins,maxresponselabs,maxfiglabels);
    end
end
end

%Approach Analysis
if UserVals.approaches
if isfield(outdata.UserVals.DLCsetup.Subfields,'DistTo')
for p = 1: length(ProcessData)
    winlabels = outdata.metadata.perievent.maxwins.label{p};
    wintimes = outdata.metadata.perievent.maxwins.timepoints{p};
    if isfield(outdata.perievent,(ProcessData{p})) && ~isempty(outdata.metadata.availcond{f,1}{p})   
    %[outdata] = DLC_ApproachAnalyze(f,outdata,(ProcessData{p}),setcond.(ProcessData{p}){2},winlabels,wintimes,outdata.UserVals.DLCsetup.Subfields);
    [outdata] = DLC_BoutAnalyze(f,outdata,(ProcessData{p}),setcond.(ProcessData{p}){2},winlabels,wintimes,'Approach');
    [outdata] = FP_BoutAlign(f,outdata,(ProcessData{p}),setcond.(ProcessData{p}){2},winlabels,wintimes,'Approach');
    end
end
end
end

%Orient Analysis
if UserVals.orienting
if isfield(outdata.UserVals.DLCsetup.Subfields,'Angle')
for p = 1: length(ProcessData)
    winlabels = outdata.metadata.perievent.maxwins.label{p};
    wintimes = outdata.metadata.perievent.maxwins.timepoints{p};
    if isfield(outdata.perievent,(ProcessData{p})) && ~isempty(outdata.metadata.availcond{f,1}{p})   
    %[outdata] = DLC_OrientAnalyze(f,outdata,(ProcessData{p}),setcond.(ProcessData{p}){2},winlabels,wintimes,outdata.UserVals.DLCsetup.Subfields);  
    [outdata] = DLC_BoutAnalyze(f,outdata,(ProcessData{p}),setcond.(ProcessData{p}){2},winlabels,wintimes,'Orient');
    [outdata] = FP_BoutAlign(f,outdata,(ProcessData{p}),setcond.(ProcessData{p}){2},winlabels,wintimes,'Orient');
    end
end
end
end

% Bout Analysis
for p = 1: length(ProcessData)
    winlabels = outdata.metadata.perievent.maxwins.label{p};
    wintimes = outdata.metadata.perievent.maxwins.timepoints{p};
    if isfield(outdata.perievent,(ProcessData{p})) && ~isempty(outdata.metadata.availcond{f,1}{p})
    if UserVals.freezingbouts
    [outdata] = DLC_BoutAnalyze(f,outdata,(ProcessData{p}),setcond.(ProcessData{p}){2},winlabels,wintimes,'Freeze');
    [outdata] = FP_BoutAlign(f,outdata,(ProcessData{p}),setcond.(ProcessData{p}){2},winlabels,wintimes,'Freeze');
    end
    if UserVals.locobouts
    [outdata] = DLC_BoutAnalyze(f,outdata,(ProcessData{p}),setcond.(ProcessData{p}){2},winlabels,wintimes,'Locomotion');   
    [outdata] = FP_BoutAlign(f,outdata,(ProcessData{p}),setcond.(ProcessData{p}){2},winlabels,wintimes,'Locomotion');
    end
    end
end

% Plot Bouts
datatypes = {'raw','zscored'};
datalabels = {'dFF','Z score'};
if UserVals.freezingbouts && isfield (outdata,'Bouts')
    figdir = strcat((UserVals.saveloc),'Figs',fsep,subjID{b},fsep,'Bouts',fsep,'FP');
    FP_PlotBouts(f,outdata,'Freeze',datatypes,datalabels,figdir);
end
if UserVals.locobouts  && isfield (outdata,'Bouts')
   figdir = strcat((UserVals.saveloc),'Figs',fsep,subjID{b},fsep,'Bouts',fsep,'FP');
   FP_PlotBouts(f,outdata,'Locomotion',datatypes,datalabels,figdir); 
end  
if UserVals.orienting && isfield (outdata,'Bouts')
    figdir = strcat((UserVals.saveloc),'Figs',fsep,subjID{b},fsep,'Bouts',fsep,'FP');
    FP_PlotBouts(f,outdata,'Orient',datatypes,datalabels,figdir);
end
if UserVals.approaches && isfield (outdata,'Bouts')
    figdir = strcat((UserVals.saveloc),'Figs',fsep,subjID{b},fsep,'Bouts',fsep,'FP');
    FP_PlotBouts(f,outdata,'Approach',datatypes,datalabels,figdir);
end
end
clear DLCdata 
close all 
%% Save vid snips
gindx = 1;
if UserVals.CreateVids && UserVals.Vids.VidSnips
    for p = 1:length(ProcessData)
    if gindx <= length(UserVals.Vids.Datatypes)
    if p == UserVals.Vids.Datatypes(gindx)
    preevent = setcond.(ProcessData{p}){5}(1);
    postevent = setcond.(ProcessData{p}){5}(2);
    vidTRANGE = [-1*(preevent*videoFPS),postevent*videoFPS];
    outdata.videodata.vidTRANGE{f,1} = vidTRANGE;
    [outdata] = SaveVidSnips (f,outdata,fsep,UserVals.saveloc,outdata.metadata.availcond{f,1}{p},vidfilename,outdata.videodata.frames.onset{f,1},PATH, FILE,(ProcessData{p}),vidTRANGE);
    gindx = gindx+1;
    else
    end
    end
    end
end
end
clear data
end
%% End of File processing
disp ('end of file');
SAVEPATH = strcat(UserVals.saveloc,subj,'.mat');
outdata.rawdata.(signallabel){f,1}= [];
outdata.rawdata.ISOs{f,1} = [];
outdata.downsampled.ISOS{f,1} = [];
outdata.downsampled.(signallabel){f,1} = [];
clear outdata.unfilt
save (SAVEPATH,'outdata'); %saves data in struct 'outdata' to specified save path with name "subj".mat

end %end of file loop
disp ('saving data ...')
SAVEPATH = strcat(UserVals.saveloc,subj,'.mat');
clear outdata.downsampled outdata.unfilt
save (SAVEPATH,'outdata','-v7.3'); %saves data in struct 'outdata' to specified save path with name "subj".mat

% % if plothistos
% if outdata.UserVals.orienting
% figdir = (strcat((UserVals.saveloc),'Figs',filesep,subj,filesep,'PolarPlots',filesep));
% if ~exist(figdir, 'dir')
%        mkdir(figdir);
% end
% DLC_PlotPolarHist(outdata,figdir);
% end

clear SAVEPATH 
clear outdata
end %end of box loop
close all %closes all figures
disp ('data processing complete');
end