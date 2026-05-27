
%FP_UserSetup - AWolff 15/2/2021
%Load User Variables and run FP_Analysis with these settings
clearvars %clears all variables
close all %closes all figures

%% Set Path to Google Drive
UserVals.googledrive = true; %check to see if path is to google drive and use personal path to access
%UserVals.personalpath = '/Users/meganbrickner/Library/CloudStorage/GoogleDrive-brick225@umn.edu' ; %path from your computer to googledrive
UserVals.personalpath = 'G:\' ; %path from your computer to googledrive

%% Load file lists
listofloadfiles = true; %set to false if you only have 1 loadfile
loadfilelist = 'TVB4_StimRecord_Manuscript_LoadfileLIST';%name of single loadfile or list of loadfiles(including path)
if ~listofloadfiles  %for single file give name of exclusion list if there is one
exclusionlist = [];%'G:\Shared drives\SaundersLab\DATA\2Pav dLight\Analysis\Exclusion Lists\NAc65_DLS67_exclusionlist'; 
end

%% Save locations
UserVals.saveloc = ['G:\Shared drives\MeganBrickner2\01_DATA_mab2\TVB Studies\TVB_Cohort4\StimAnalysis\PostExclusions'];%'G:\Shared drives\LivEngel\Proj_OptoPav\Matlab'];%path to folder to save mat files and figures to - if empty ([]) saves to location of raw data
%UserVals.localoutname = ['C:\Users\Saund\Desktop\MatlabTemp'];%local destination for temporary saving of videos
UserVals.SaveUserVals = false; %set true to save uservals to ensure consistency for project setup
    UserVals.UserValsSavePath = 'Shared drives\LivEngel\Proj_OptoPav\Matlab';
    UserVals.UserValsSaveName = 'DLCanalysis'; %input name here to label UserVals.mat file, if empty file is just called UserVals.mat
UserVals.LoadUserVals = [];%['G:\Shared drives\Saunders LAB2\Liv OptoPav Dataset\Amy\Loadfilelists\NewDLC-UserVals'];%'G:\Shared drives\Saunders LAB2\Liv OptoPav Dataset\Amy\Loadfilelists\NoVids-UserVals.mat'; %empty does not load user settings, to load user settings input path to UserVals.mat file

%% User preferences for file processing - Edit info here for your data
%% Edit these as needed
UserVals.signallabel = 'dLight'; %name of signal type used in plotting
UserVals.N = 25; %multiplicative for downsampling (100 = ~10hz, 25 = ~40Hz) 

%UserVals.eventtypes = {'Shock'};
UserVals.eventtypes = {'Stim'};
%UserVals.eventtypes = {'RewardCue','RewardPump','PE'}; %RewCond bLight pilot
%UserVals.eventtypes = {'PE','RewardPump'};
%UserVals.eventtypes = {'Pump','ActivePE'}; %RandomReward
%UserVals.eventtypes = {'HighTone','LowTone','HighLights','LowLights','Lights'}; %RandomCues for TVB and BCDN
%UserVals.eventtypes = {'Stim','FearCue','Shock'}; %FearCond

UserVals.hideplots = true; % set this to false if you want plots to pop up while analysis is running (slower)
UserVals.trialplots = true; %set to true to plot individual trial raw data - should create these at least once to be able to view trial x trial data
UserVals.saveaspdf = false; %set to true to save figures as pdf, if false saved as jpg, faster processing with jpg, but not editable in illustrator
UserVals.plotbuffermagnitude = 0.25; % increase if plot data is off axis, decrease to reduce plot axis limits if lots of dead space 0.1 = 10%
UserVals.normpeaks = false; %use normalization for peak analysis

%% Settings for data processing

%UserVals.DefineData ={'ThreePUMP','APE','IPE','OnePUMP','FivePUMP','SevenPUMP','OneRPEFIRST','ThreeRPEFIRST','FiveRPEFIRST','SevenRPEFIRST'}; %CueDiscrim
%UserVals.DefineData ={'Shock'};
UserVals.DefineData ={'Stim'};
%UserVals.DefineData ={'Lights'};
%UserVals.DefineData = {'HighTone','LowTone','HighLights','LowLights','Lights'}; %RandomCues for TVB and BCDN
%UserVals.DefineData ={'Stim','FearCue','Shock'}; %FearCond

%UserVals.DefineData ={'RPEFIRST','PE','REWCUE'}; %RewCond pilot
%UserVals.DefineData ={'RPEFIRST','PE','PUMP'}; %Sucrose pilot

UserVals.ProcessSubset = false; %set to true to process only a subset of the defined data above
UserVals.SubsetIndx = [2]; % %indx to which datatypes to process if subset selected (indx ignored if ProcessSubset = false)

%setcond.savename =
%{eventtype_inxs[primevent,condevent],{condlabels},ruletype{str},ruleargs[],{[preevent,postevent]},*optional window to find perievent max and calculate AUC {[start end],[start end]....} %relative to t0 pre event, post event and whole window max reponses/AUC generated without user input), *optional{labels for windows}, if no label then windows labeled as userwin1, userwin2 etc, optional{restrictpeakanalysis[timestartpeakdetect, timeendpeakdetect}
% UserVals.setcond.CSreward = {1, {'CueOn'},'none',[],[5,25],{[0 20],[0 10],[10 20],[0 1],[0 2]},{'cueall','cueonly','cue2half','cue1s','cue2s'}};
% UserVals.setcond.CSshock = {2, {'CueOn'},'none',[],[5,25],{[0 20],[0 10],[10 20],[0 1],[0 2],[19.5 20],[19.5 20.5],[19.5 21.5]},{'cueall','cueonly','cue2half','cue1s','cue2s','shockdel','shock1s','shock2s'}};
% UserVals.setcond.CSminus = {3, {'CueOn'},'none',[],[5,25],{[0 20],[0 10],[10 20],[0 1],[0 2]},{'cueall','cueonly','cue2half','cue1s','cue2s'}};
%UserVals.setcond.CPEFIRST = {[4 1],{'CP', 'NCP'},'first',[1],[5,15]};

%UserVals.setcond.Shock = {1, {'Shock'},'none',[],[2,10]}; %vid snips only

%UserVals.setcond.Shock = {1, {'Shock'},'none',[],[2,10],{[0 1],[0 2],[0 5],[1 10]},{'onesec','twosec','fivesec','tensec'}};
UserVals.setcond.Stim = {1, {'Stim'},'none',[],[2,10],{[0 1],[0 2],[0 5],[1 10]},{'onesec','twosec','fivesec','tensec'}};
%UserVals.setcond.Stim = {1, {'Stim'},'none',[],[3,10],{[0 1],[0 2],[0 5],[1 10]},{'onesec','twosec','fivesec','tensec'}}; %TVB does 3s prior
%UserVals.setcond.Lights = {1, {'Lights'},'none',[],[2,10],{[0 1],[0 3],[0 5],[1 10]},{'onesec','LightOn','fivesec','tensec'}};

%UserVals.setcond.Stim = {1, {'Stim'},'none',[],[2,10]}; %vid snips only

%UserVals.setcond.RPEFIRST = {[3 2],{'RP', 'NRP'},'first',[1],[2,10]};
%UserVals.setcond.CPEFIRST = {[3 1],{'CP', 'NCP'},'first',[1],[5,15]};
%UserVals.setcond.PUMP = {2, {'Rew'},'none',[],[5,10],{[0 3]},{'rewarddel'}};
%UserVals.setcond.PE = {3, {'PE'},'none',[],[2,10]};
%UserVals.setcond.REWCUE = {1, {'REWCUE'},'none',[],[5,15],{[0 2],[0 5],[0 10]},{'firsttwosec','firstfivesec','CueOnly'}};

%UserVals.setcond.RPEFIRST = {[1 2],{'RP', 'NRP'},'first',[1],[2,10]};
%UserVals.setcond.PE = {1, {'PE'},'none',[],[2,10]};
%UserVals.setcond.PUMP = {2, {'Rew'},'none',[],[5,10],{[0 3]},{'rewarddel'}};

%UserVals.setcond.FearCue = {[2 1], {'CUEstim','FEARCUE'},'window',[-1 1],[5,25],{[0 2],[0 5],[0 10],[0 20]},{'firsttwosec','firstfivesec','firsttensec','CueDur'}};
%UserVals.setcond.FearCue = {1,{'FearCue'},'none',[],[3,25],{[0 5],[0 20]},{'first5s','cuedur'}};
%UserVals.setcond.Shock = {3,{'Shock'},'none',[],[3,10],{[0 2],[0 5]},{'first2s','first5s'}};

%TVB and BCDN Random Cues
%UserVals.setcond.HighTone = {1, {'HighTone'},'none',[],[2,10],{[0 1],[0 2],[0 5],[1 10]},{'onesec','twosec','fullcue','tensec'}};
%UserVals.setcond.LowTone = {2, {'LowTone'},'none',[],[2,10],{[0 1],[0 2],[0 5],[1 10]},{'onesec','twosec','fullcue','tensec'}};
%UserVals.setcond.HighLights = {3, {'HighLights'},'none',[],[2,10],{[0 1],[0 2],[0 5],[1 10]},{'onesec','twosec','fullcue','tensec'}};
%UserVals.setcond.LowLights = {4, {'LowLights'},'none',[],[2,10],{[0 1],[0 2],[0 5],[1 10]},{'onesec','twosec','fullcue','tensec'}};
%UserVals.setcond.Lights = {5, {'Lights'},'none',[],[2,10],{[0 1],[0 2],[0 5],[1 10]},{'onesec','twosec','fullcue','tensec'}};


%UserVals.setcond.Cue = {1,{'Cue'},'none',[],[5,10],{[0 1],[0 2]},{'cue1s','cue2s'}};
% UserVals.setcond.Stim = {2,{'Stim'},'none',[],[3,6],{[0 1]}};
% UserVals.setcond.Trial = {[1 2], {'StimTrial','ProbeTrial'},'trial',1,[5,10],{[0 1],[0 2],[2 7],[0 7]},{'cue1s','cue2s','stimdur','cuedur'},{[NaN NaN],[NaN NaN],[NaN NaN],[NaN NaN],[NaN NaN],[NaN NaN],[NaN NaN]}};
% %UserVals.setcond.Trial = {[1 2], {'StimTrial','ProbeTrial'},'trial',1,[5,10],{[0 2]},{'cue2s'}};
% UserVals.setcond.Window = {[1 2], {'StimWin','ProbeWin'},'window',[0,5],[5,10],[0 1]};
% UserVals.setcond.During = {[1 2], {'StimDuring','NoStimDuring'},'during',[],[5,10],[0 1]};
% UserVals.setcond.Control = {1,{'Cntrl'},'control',-15,[5,10],{[0 1],[0 2],[2 7],[0 7]},{'cue1s','cue2s','stimdur','cuedur'}};
% %UserVals.setcond.Control = {1,{'Cntrl'},'control',-15,[5,10],{[0 2]},{'cue2s'}};
% UserVals.setcond.First = {[1 2],{'FirstStim', 'OtherStims'},'first',[1,-5],[5,10],[0 1]};
   
% just for opto plots
UserVals.StimPulses = false; %converts stim pulses to epoc data if true (stim on off rather than ts for each pulse of the stim)- knows which channel from eventis below
UserVals.Stim.stimis = 2; %indx to stim channel 
UserVals.Stim.stimHz = 20; %stim pulse frequency in Hz
% plot an event line with fixed duration relative to primary event
    UserVals.Stim.plotevent = false; %plot event line on figures
    UserVals.Stim.primaryis = 1; %indx to ref evencond  conda at channel
    UserVals.Stim.eventis = 2; %indx to event channel 
    UserVals.Stim.eventstart = 2; %time after cue onset (t0) when stim starts
    UserVals.Stim.eventduration = 5; %duration of stim in s

%% Optional Analyses
UserVals.GenerateEvent = false; %creates TTL pulses for inputs with known fixed times but no input from med - include labels in eventlabs above (must be at end of list)
    UserVals.GenEvent.NumChans = 2; %number of event channels to create
    UserVals.GenEvent.CreateInterval = false; %create new channel based on interval from reference event
    if UserVals.GenEvent.CreateInterval
    UserVals.GenEvent.ChanInfo = {[1,10,5], [2,19.5,0.5]};%[Indx to ref event, onset time relative to index event(s), duration(s)]for each event 
    end
    UserVals.GenEvent.CreateDuration = false; %create new channel based on duration of index event
    if UserVals.GenEvent.CreateDuration
    UserVals.GenEvent.ChanInfo = {[2,1,5], [2,0.1,5]};%[Indx to ref event, duration of index event(s), duration(s)]for each created event event 
    end
    
UserVals.FilterEvents = false; %set to true to filter an event channel to remove events that are longer 
                                % or shorter than a given duration
    UserVals.FiltEvent.Chans = [2];%reference to eventtypes position of channel/s to filter
    UserVals.FiltEvent.ChanInfo = {{'<',.5}}; %[filter rule(>/</>=,<=),time criteria(s)]
    
UserVals.CreateVids = false; %1 = true, saves short video snips to match length of cue on plots - need to add Cam ID and filename for video to filelist
    UserVals.Vids.Datatypes = [1]; %#ok<NBRAK> %Indx to which datatypes from DefineData you would like to generate video snippets for
    UserVals.Vids.Uselabeledvids = false; %set true to use pre-generated labeled videos from DLC (not recommended - better to label bodyparts from DLC file)
          
UserVals.DLCAnalysis = false; %set to true to analyse DLCdata
    UserVals.DLC.MaxFPS = 20; %highest frame rate for acquired video in dataset (max in synapse is 20fps)
    UserVals.DLC.Conf = 0.7; %confidence level to set for inclusion of DLC data
    UserVals.DLC.Plotbuffermagnitude = 0.75;% increase if plot data is off axis, decrease to reduce plot axis limits 0.1 = 10%
    UserVals.DLC.Analyseall = false; % if true no user prompts to select types of DLC data to analyse - not recommended

UserVals.locobouts = false;
    UserVals.locobout.minlength = 0.5; %in s
    UserVals.locobout.endtime = 0.2; %time in seconds of activity beyond threshold to consider start/end of bout
    
UserVals.freezingbouts= false; % set to true to assess freezing with DLC analysis results
    UserVals.freezebout.minlength = 1; %in s 
    UserVals.freezebout.endtime = 0.3; %time in seconds of activity beyond threshold to consider start/end of bout
    
UserVals.approaches = false; %set to true to measure approaches to a part of the environment
    UserVals.approach.detectthresh = 2.5; %distance to detect a true approach %find approach events using this value
    UserVals.approach.limthresh = 4.5;%threshold to consider start/end of approach of an environment feature in cm
    UserVals.approach.minlength = 0.2; %minimum length of time to consider as an approach
    UserVals.approach.endtime = 0.2; %time in seconds of activity beyond threshold to consider start/end of approach 
    
 UserVals.orienting = false; %set to true to measure approaches to a part of the environment
    UserVals.orient.angle = 30; %heading angles less than this value == orienting
    UserVals.orient.minlength = 0.2; %minimum length of time to consider as an orient
    UserVals.orient.endtime = 0.2; %time in seconds of activity beyond threshold to consider start/end of orient 

 UserVals.Trim = false; % set to true to trim beginning or end of files in list - new columns needed in loadfile
    %make sure to set trim options in loadfile if true
    %take care when trimming file that you don't remove a trial that is in the trial exclude list or that you account for this missing trial when generating exclude list

    %% Input Data Organisation -  *****don't need to edit if the structure of loadfilelist is not altered***
%filelist should be an xls sheet with the following columns: (each row should be a different rec)...
   %required inputs: 
   UserVals.Input.Path = 1;  % column to locate path to folder 
   UserVals.Input.Folder = 2;  % column to locate folder name for each recording 
   UserVals.Input.IDs = 3;  % column to locate box numbers and Subject ID's (two lists)for each box you want to record from in this file
   UserVals.Input.ISOs = [4,6]; %column to locate name of 405 stream in box 1/box2 for each recording (to find name of streams you can load file and find in data.streams)
   UserVals.Input.Signal= [5,7]; %column to locate name of 465 stream in box 1/box2 for each recording
   UserVals.Input.Events = [8,9]; %column of load file to locate list(separate with comma) of event epochs in box 1/box2 for each recording(to find name of Epocs you can load file and find in data.epochs - this will depend on your TDT settings
   %optional inputs
   UserVals.Input.Cam = [10,11]; %column of load file to find name of Camera epoch box 1/Box2
   UserVals.Input.Tank= 12; %column to find name of recording folder prefix (part of filename that occurs before recording ID in A - the name of the synapse tank store)
   UserVals.Input.DLCnetwork = 13; %column to find name of DLC network used for analysis *optional
   UserVals.Input.vidtype = 14; %column to find video file extension *optional
   UserVals.Input.TrimFlag= [1,4]; %column to find out whether to trim this recording (1 = true, 0 = false) flag as true if either box needs to be trimmed(Bx1/Bx2)
   UserVals.Input.Trimstart = [2,5]; %column to find TrimStart (trim this much time (in s)from beginning of rec, leave blank if no trim needed)_Bx1/Bx2
   UserVals.Input.Trimend= [3,6]; %column  to find TrimEnd (trim this much time  (in s) from end of rec, leave blank if no trim needed)_Bx1/Bx2
   % ***-------***

%% Run Analysis - DO NOT EDIT BELOW HERE
%% loadfilelists - don't edit here
if ~listofloadfiles %for only one loadfile  
    loadfilelist = cellstr(loadfilelist);
    if ~isempty(exclusionlist)
        exclusionlist = cellstr(exclusionlist);
    end
    nloadfiles = 1;
else %for list of loadfiles
       loadfilelist = strcat(loadfilelist,'.xlsx');
       [loadfilelist] = formatconvert_fname(loadfilelist); %check formatting of filepath
       if UserVals.googledrive
       [loadfilelist] = googleconvert_fname(loadfilelist,UserVals.personalpath); %convert for googledrive
       end
        [~,loadlistdata,~] = xlsread(loadfilelist);  
        loadfilelist = loadlistdata(:,1);
        if length(loadlistdata(1,:)) > 1
        exclusionlist = loadlistdata(:,2);%pull exclusionlistname from file if specified
        else
        exclusionlist = [];%if no exclusionlist leave blank
        end
        nloadfiles = length(loadlistdata(:,1));
end
    
if UserVals.googledrive %convert filename for googledrive if needed
        for i = 1:nloadfiles
        loadfilelist{i,1} = googleconvert_fname(loadfilelist{i,1},UserVals.personalpath);   
        if ~isempty(exclusionlist)
        if ~isempty(exclusionlist{i,1})
        exclusionlist{i,1} = googleconvert_fname(exclusionlist{i,1},UserVals.personalpath);
        end
        end
        end
    [UserVals.saveloc] = googleconvert_fname(UserVals.saveloc,UserVals.personalpath);
    [UserVals.UserValsSavePath] = googleconvert_fname(UserVals.UserValsSavePath,UserVals.personalpath);
end

%set fsep correctly for user OS
    [UserVals.saveloc] = formatconvert_fname(UserVals.saveloc);
    [UserVals.UserValsSavePath] = formatconvert_fname(UserVals.UserValsSavePath);

if UserVals.approaches || UserVals.orienting || UserVals.freezingbouts || UserVals.locobouts
    UserVals.DLCAnalysis = true;
end
if ~isempty(UserVals.LoadUserVals)
    load(UserVals.LoadUserVals)
end


for i = 1:nloadfiles
        loadfilename = loadfilelist{i,:}; 
        if ~isempty(exclusionlist)
        exclusionlistname = exclusionlist{i,:};
        else
        exclusionlistname = [];
        end
        disp(loadfilename);
    
    %set fsep correctly for user OS
    [loadfilename] = formatconvert_fname(loadfilename);
    [exclusionlistname] = formatconvert_fname(exclusionlistname);
    [UserVals] = FP_Analysis(loadfilename,exclusionlistname,UserVals);
end
clearvars