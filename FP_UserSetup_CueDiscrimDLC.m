
%FP_UserSetup - AWolff 15/2/2021
%Load User Variables and run FP_Analysis with these settings
clearvars %clears all variables
close all %closes all figures

%% Set Path to Google Drive
UserVals.googledrive = true; %check to see if path is to google drive and use personal path to access

%UserVals.personalpath = '/Users/meganbrickner/Library/CloudStorage/GoogleDrive-brick225@umn.edu' ; %path from your computer to googledrive
UserVals.personalpath = 'G:\' ;% 'G:\' ; %path from your computer to googledrive

%% Load file lists
listofloadfiles = false; %set to false if you only have 1 loadfile
loadfilelist = 'TVB_11_12_RandRew';%name of single loadfile or list of loadfiles(including path)
if ~listofloadfiles  %for single file give name of exclusion list if there is one
exclusionlist = [];%'G:\Shared drives\SaundersLab\DATA\2Pav dLight\Analysis\Exclusion Lists\NAc65_DLS67_exclusionlist'; 
end

%% Save locations
UserVals.saveloc = ['/Users/meganbrickner/Library/CloudStorage/GoogleDrive-brick225@umn.edu/Shared drives/MeganBrickner2/01_DATA_mab2/SafetyManuscript_Analysis/Cohort 7/RewardScale/RandRewRPE_IndvAn2026/0.75s'];%'G:\Shared drives\LivEngel\Proj_OptoPav\Matlab'];%path to folder to save mat files and figures to - if empty ([]) saves to location of raw data
%UserVals.localoutname = ['C:\Users\Saund\Desktop\MatlabTemp'];%local destination for temporary saving of videos
UserVals.SaveUserVals = false; %set true to save uservals to ensure consistency for project setup
    UserVals.UserValsSavePath = 'Shared drives\LivEngel\Proj_OptoPav\Matlab';
    UserVals.UserValsSaveName = 'DLCanalysis'; %input name here to label UserVals.mat file, if empty file is just called UserVals.mat
UserVals.LoadUserVals = [];%['G:\Shared drives\Saunders LAB2\Liv OptoPav Dataset\Amy\Loadfilelists\NewDLC-UserVals'];%'G:\Shared drives\Saunders LAB2\Liv OptoPav Dataset\Amy\Loadfilelists\NoVids-UserVals.mat'; %empty does not load user settings, to load user settings input path to UserVals.mat file

%% User preferences for file processing - Edit info here for your data
%% Edit these as needed
UserVals.signallabel = 'dLight'; %name of signal type used in plotting
UserVals.N = 25; %multiplicative for downsampling (100 = ~10hz, 25 = ~40Hz) 

%UserVals.eventtypes = {'RewardCue','FearCue', 'NeutralCue', 'PE'}; %cuediscrim and hablabels for PC channels including any to be generated as part of option analyses below
%UserVals.eventtypes = {'RewardPump','PE','RewardCue'}; %RewCond
%UserVals.eventtypes = {'RewardCue','RewardPump','FearCue','PE'}; %FearCond event types/PC channels
%UserVals.eventtypes = {'RewardCue','FearCue','PE'}; %EXT labels
%UserVals.eventtypes = {'Shock','PE'}; %Shock Test labels
%UserVals.eventtypes = {'RewardCue','RewardPump','FearCue','PE','Shock'}; %FearCond event types/PC channels

%UserVals.eventtypes = {'RewardCue','FearCue', 'NeutralCue', 'PE','RewardPump'}; %Cohort 7 - Cue Hab
%UserVals.eventtypes = {'RewardCue','FearCue', 'NeutralCue', 'PE','SafetyCue','RewardPump','Shock'}; %Cohort 7 - Cue Discrim
%UserVals.eventtypes = {'RewardCue','RewardPump','FearCue','PE','Shock'}; %Cohort 7 - Fear Cond and EXT
UserVals.eventtypes = {'RewardPump','PE'}; %Random Reward Scaling
%UserVals.eventtypes = {'SucroseCue','SucrosePump','EnsureCue','EnsurePump','Suc_R_PE','Ens_L_PE'}; %Reward Scaling Discrim
%UserVals.eventtypes = {'LowCue','LowShock','HighCue','HighShock'}; %Fear Scaling Discrim

UserVals.hideplots = true; % set this to false if you want plots to pop up while analysis is running (slower)
UserVals.trialplots = true; %set to true to plot individual trial raw data - should create these at least once to be able to view trial x trial data
UserVals.saveaspdf = false; %set to true to save figures as pdf, if false saved as jpg, faster processing with jpg, but not editable in illustrator
UserVals.plotbuffermagnitude = 0.25; % increase if plot data is off axis, decrease to reduce plot axis limits if lots of dead space 0.1 = 10%
UserVals.normpeaks = false; %use normalization for peak analysis

%% Settings for data processing
%UserVals.DefineData ={'CPEFIRST','REWCUE','PE','NEUTRALCUE','FEARCUE'}; %CueDiscrim
%UserVals.DefineData ={'RPEFIRST','REWCUE'}; %RewCond (Post exclusion)
%UserVals.DefineData ={'REWCUE','FEARCUE','NEUTRALCUE'}; %CueDiscrim - Cues only
%UserVals.DefineData ={'RPEFIRST','CPEFIRST','PUMP','PE','REWCUE'}; %RewCond
%UserVals.DefineData ={'CPEFIRST','REWCUE','PE','FEARCUE','NEUTRALCUE'}; % Cue Habituation
%UserVals.DefineData ={'CPEFIRST','REWCUE','FEARCUE','NEUTRALCUE'}; % Cue Habituation (post exclusion)
%UserVals.DefineData ={'RPEFIRST','CPEFIRST','REWCUE','PE','FEARCUE'}; % Fear Cond
%UserVals.DefineData ={'RPEFIRST','REWCUE','FEARCUE'}; % Fear Cond (post exclusion)
%UserVals.DefineData ={'CPEFIRST','REWCUE','FEARCUE'}; % EXT (post exclusion)
%UserVals.DefineData ={'FEARCUE','SHOCK'}; % Fear Cond (post exclusion)

%UserVals.DefineData ={'RPEFIRST','CPEFIRST','REWCUE','PE','FEARCUE','NEUTRALCUE'}; %Cue Habituation for cohort 7
%UserVals.DefineData ={'RPEFIRST','CPEFIRST','REWCUE','PE','FEARCUE','NEUTRALCUE','SAFETYCUE','SHOCK'}; %Cue Discrimination for cohort 7
%UserVals.DefineData ={'RPEFIRST','CPEFIRST','REWCUE','PE','FEARCUE','SHOCK'}; %Fear Cond and EXT for cohort 7
%UserVals.DefineData ={'RPEFIRST','CPEFIRST','PE'}; %RewCond PE test
UserVals.DefineData ={'RPEFIRST','PUMP','PE'}; %Reward Scale 
%UserVals.DefineData ={'SucREWCUE','Suc_RPEFIRST','SucPUMP','EnsREWCUE','Ens_RPEFIRST','EnsPUMP'}; %Reward Scale Discrim
%UserVals.DefineData ={'Low_FEARCUE','Low_Shock','High_FEARCUE','High_Shock'}; %Fear Scale Discrim

%UserVals.DefineData ={'CPEFIRST','REWCUE','FEARCUE','PE',}; %EXT
%UserVals.DefineData ={'SHOCK','PE'}; %Shock Test
%UserVals.DefineData ={'SHOCK'};

%UserVals.DefineData ={'REWCUE'}; %RewCond Cohort 7 (Post exclusion)
%UserVals.DefineData ={'REWCUE','FEARCUE','NEUTRALCUE','SAFETYCUE'}; %Cue Discrimination for cohort 7 (Post exclusion)

UserVals.ProcessSubset = false; %set to true to process only a subset of the defined data above
UserVals.SubsetIndx = [3,6]; % %indx to which datatypes to process if subset selected (indx ignored if ProcessSubset = false)

%setcond.savename =
%{eventtype_inxs[primevent,condevent],{condlabels},ruletype{str},ruleargs[],{[preevent,postevent]},*optional window to find perievent max and calculate AUC {[start end],[start end]....} %relative to t0 pre event, post event and whole window max reponses/AUC generated without user input), *optional{labels for windows}, if no label then windows labeled as userwin1, userwin2 etc, optional{restrictpeakanalysis[timestartpeakdetect, timeendpeakdetect}
% UserVals.setcond.CSreward = {1, {'CueOn'},'none',[],[5,25],{[0 20],[0 10],[10 20],[0 1],[0 2]},{'cueall','cueonly','cue2half','cue1s','cue2s'}};
% UserVals.setcond.CSshock = {2, {'CueOn'},'none',[],[5,25],{[0 20],[0 10],[10 20],[0 1],[0 2],[19.5 20],[19.5 20.5],[19.5 21.5]},{'cueall','cueonly','cue2half','cue1s','cue2s','shockdel','shock1s','shock2s'}};
% UserVals.setcond.CSminus = {3, {'CueOn'},'none',[],[5,25],{[0 20],[0 10],[10 20],[0 1],[0 2]},{'cueall','cueonly','cue2half','cue1s','cue2s'}};

% Cue Discrimination:
%UserVals.setcond.CPEFIRST = {[4 1],{'CP', 'NCP'},'first',[1],[5,15]};
%UserVals.setcond.REWCUE = {1, {'REWCUE'},'none',[],[5,25],{[0 2],[0 5],[0 10],[0 20]},{'firsttwosec','firstfivesec','CueOnly','CueDur'}};
%UserVals.setcond.PE = {4, {'PE'},'none',[],[2,4]};
%UserVals.setcond.FEARCUE = {[2 3], {'SAFETYCUE','FEARCUE'},'window',[-1 1],[5,25],{[0 2],[0 5],[0 10],[0 20]},{'firsttwosec','firstfivesec','firsttensec','CueDur'}};
%UserVals.setcond.NEUTRALCUE = {[3 2], {'SAFETYCUE','NEUTRALCUE'},'window',[-1 1],[5,25],{[0 2],[0 5],[0 10],[0 20]},{'firsttwosec','firstfivesec','firsttensec','CueDur'}};

%Reward Conditioning (and Rand Rew for Scaling):
UserVals.setcond.RPEFIRST = {[2 1],{'RP', 'NRP'},'first',[1],[2,15],{[0 2],[0 5],[0 10]},{'firsttwosec','firstfivesec','firsttensec'}};
%UserVals.setcond.CPEFIRST = {[2 3],{'CP', 'NCP'},'first',[1],[5,15],{[0 2],[0 5],[0 10]},{'firsttwosec','firstfivesec','firsttensec'}};
UserVals.setcond.PUMP = {1, {'Rew'},'none',[],[5,10],{[0 3]},{'rewarddel'}};
%UserVals.setcond.PUMP = {1, {'Rew'},'none',[],[5,10],{[0 3],[0 5]},{'rewarddel','whitenoise'}}; %RewScale for WhiteNoise
UserVals.setcond.PE = {2, {'PE'},'none',[],[2,4]};
%UserVals.setcond.REWCUE = {3, {'REWCUE'},'none',[],[5,25],{[0 2],[0 5],[0 10],[0 20]},{'firsttwosec','firstfivesec','CueOnly','CueDur'}};

%Cue Habitituation and Discrim
%UserVals.setcond.RPEFIRST = {[4 5],{'RP', 'NRP'},'first',[1],[2,10]}; %CH
%UserVals.setcond.RPEFIRST = {[4 6],{'RP', 'NRP'},'first',[1],[2,10]}; %CD
%UserVals.setcond.CPEFIRST = {[4 1],{'CP', 'NCP'},'first',[1],[2,10]};
%UserVals.setcond.REWCUE = {1, {'REWCUE'},'none',[],[5,25],{[0 2],[0 5],[0 10],[0 20]},{'firsttwosec','firstfivesec','CueOnly','CueDur'}};
%UserVals.setcond.FEARCUE = {2, {'FEARCUE'},'none',[],[5,25],{[0 2],[0 5],[0 10],[0 20]},{'firsttwosec','firstfivesec','firsttensec','CueDur'}};
%UserVals.setcond.NEUTRALCUE = {3, {'NEUTRALCUE'},'none',[],[5,25],{[0 2],[0 5],[0 10],[0 20]},{'firsttwosec','firstfivesec','firsttensec','CueDur'}};
%UserVals.setcond.PE = {4, {'PE'},'none',[],[2,4]};
%UserVals.setcond.SAFETYCUE = {5, {'SAFETYCUE'},'none',[],[5,25],{[0 2],[0 5],[0 10],[0 20]},{'firsttwosec','firstfivesec','firsttensec','CueDur'}};
%UserVals.setcond.SHOCK = {7, {'SHOCK'},'none',[],[2,15],{[0 2],[0 5],[0 10]},{'firsttwosec','firstfivesec','firsttensec'}};

%UserVals.setcond.REWCUE = {1, {'REWCUE'},'none',[],[5,25],{[0 20]},{'CueDur'}};
%UserVals.setcond.FEARCUE = {2, {'FEARCUE'},'none',[],[5,25],{[0 20]},{'CueDur'}};
%UserVals.setcond.NEUTRALCUE = {3, {'NEUTRALCUE'},'none',[],[5,25],{[0 20]},{'CueDur'}};
%UserVals.setcond.SAFETYCUE = {5, {'SAFETYCUE'},'none',[],[5,25],{[0 20]},{'CueDur'}};

%Fear Conditioning
%UserVals.setcond.RPEFIRST = {[4 2],{'RP', 'NRP'},'first',[1],[2,10]};
%UserVals.setcond.CPEFIRST = {[4 1],{'CP', 'NCP'},'first',[1],[2,10]};
%UserVals.setcond.REWCUE = {1, {'REWCUE'},'none',[],[5,25],{[0 2],[0 5],[0 10],[0 20]},{'firsttwosec','firstfivesec','CueOnly','CueDur'}};
%UserVals.setcond.PE = {4, {'PE'},'none',[],[2,4]};
%UserVals.setcond.FEARCUE = {3, {'FEARCUE'},'none',[],[5,25],{[0 2],[0 5],[0 10],[0 20]},{'firsttwosec','firstfivesec','firsttensec','CueDur'}};
%UserVals.setcond.SHOCK = {5, {'SHOCK'},'none',[],[2,15],{[0 2],[0 5],[0 10]},{'firsttwosec','firstfivesec','firsttensec'}};

% Extinction:
%UserVals.setcond.CPEFIRST = {[3 1],{'CP', 'NCP'},'first',[1],[2,10]};
%UserVals.setcond.REWCUE = {1, {'REWCUE'},'none',[],[5,25],{[0 2],[0 5],[0 10],[0 20]},{'firsttwosec','firstfivesec','CueOnly','CueDur'}};
%UserVals.setcond.PE = {4, {'PE'},'none',[],[2,4]};
%UserVals.setcond.FEARCUE = {2, {'FEARCUE'},'none',[],[5,25],{[0 2],[0 5],[0 10],[0 20]},{'firsttwosec','firstfivesec','firsttensec','CueDur'}};

%RewScale Discrim
%UserVals.setcond.SucREWCUE = {1, {'SucREWCUE'},'none',[],[5,25],{[0 2],[0 5],[0 10],[0 20]},{'firsttwosec','firstfivesec','CueOnly','CueDur'}};
%UserVals.setcond.Suc_RPEFIRST = {[5 2],{'RP', 'NRP'},'first',[1],[2,15],{[0 2],[0 5],[0 10]},{'firsttwosec','firstfivesec','firsttensec'}};
%UserVals.setcond.SucPUMP = {2, {'Rew'},'none',[],[5,10],{[0 3],[0 2],[0 5],[0 10]},{'rewarddel','firsttwosec','firstfivesec','firsttensec'}};
%UserVals.setcond.EnsREWCUE = {3, {'EnsREWCUE'},'none',[],[5,25],{[0 2],[0 5],[0 10],[0 20]},{'firsttwosec','firstfivesec','CueOnly','CueDur'}};
%UserVals.setcond.Ens_RPEFIRST = {[6 4],{'RP', 'NRP'},'first',[1],[2,15],{[0 2],[0 5],[0 10]},{'firsttwosec','firstfivesec','firsttensec'}};
%UserVals.setcond.EnsPUMP = {4, {'Rew'},'none',[],[5,10],{[0 3],[0 2],[0 5],[0 10]},{'rewarddel','firsttwosec','firstfivesec','firsttensec'}};

%FearScale Discrim
%UserVals.setcond.Low_FEARCUE = {1, {'FEARCUE'},'none',[],[5,25],{[0 2],[0 5],[0 10],[0 20]},{'firsttwosec','firstfivesec','firsttensec','CueDur'}};
%UserVals.setcond.Low_Shock = {2, {'SHOCK'},'none',[],[2,15],{[0 2],[0 5],[0 10]},{'firsttwosec','firstfivesec','firsttensec'}};
%UserVals.setcond.High_FEARCUE = {3, {'FEARCUE'},'none',[],[5,25],{[0 2],[0 5],[0 10],[0 20]},{'firsttwosec','firstfivesec','firsttensec','CueDur'}};
%UserVals.setcond.High_Shock = {4, {'SHOCK'},'none',[],[2,15],{[0 2],[0 5],[0 10]},{'firsttwosec','firstfivesec','firsttensec'}};

%UserVals.setcond.Low_FEARCUE = {1, {'FEARCUE'},'none',[],[5,25],{[0 2],[0 5],[0 20]},{'firsttwosec','firstfivesec','CueDur'}};
%UserVals.setcond.Low_Shock = {2, {'SHOCK'},'none',[],[2,15],{[0 2],[0 5]},{'firsttwosec','firstfivesec'}};
%UserVals.setcond.High_FEARCUE = {3, {'FEARCUE'},'none',[],[5,25],{[0 2],[0 5],[0 20]},{'firsttwosec','firstfivesec','CueDur'}};
%UserVals.setcond.High_Shock = {4, {'SHOCK'},'none',[],[2,15],{[0 2],[0 5]},{'firsttwosec','firstfivesec'}};


%UserVals.setcond.SucREWCUE = {1, {'SucREWCUE'},'none',[],[1,21]};
%UserVals.setcond.EnsREWCUE = {3, {'EnsREWCUE'},'none',[],[1,21]};

%Shock Test:
%UserVals.setcond.SHOCK = {1, {'SHOCK'},'none',[],[2,11],{[0 2],[0 5],[0 10]},{'firsttwosec','firstfivesec','firsttensec'}};
%UserVals.setcond.PE = {2, {'PE'},'none',[],[2,4]};

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
    UserVals.Stim.primaryis = 1; %indx to ref event channel
    UserVals.Stim.eventis = 2; %indx to event channel 
    UserVals.Stim.eventstart = 2; %time after cue onset (t0) when stim starts
    UserVals.Stim.eventduration = 5; %duration of stim in s

%% Optional Analyses
UserVals.GenerateEvent = false; %creates TTL pulses for inputs with known fixed times but no input from med - include labels in eventlabs above (must be at end of list)
    UserVals.GenEvent.NumChans = 1; %number of event channels to create
    UserVals.GenEvent.CreateInterval = true; %create new channel based on interval from reference event
    if UserVals.GenEvent.CreateInterval
    UserVals.GenEvent.ChanInfo = {[3,20,0.5]};%[Indx to ref event, onset time relative to index event(s), duration(s)]for each event 
        %UserVals.GenEvent.ChanInfo = {[1,10,5], [2,19.5,0.5]};%[Indx to ref event, onset time relative to index event(s), duration(s)]for each event 
    end
    UserVals.GenEvent.CreateDuration = false; %create new channel based on duration of index event
    if UserVals.GenEvent.CreateDuration
    UserVals.GenEvent.ChanInfo = {[2,1,5], [2,0.1,5]};%[Indx to ref event, duration of index event(s), duration(s)]for each created event event 
    end
    
UserVals.FilterEvents = true; %set to true to filter an event channel to remove events that are longer or shorter than a given duration
    UserVals.FiltEvent.Chans = [2];%reference to eventtypes position of channel/s to filter
    UserVals.FiltEvent.ChanInfo = {{'<',0.75}};
    %UserVals.FiltEvent.ChanInfo = {{'<',1},{'>=',10}}; %[filter rule(>/</>=,<=),time criteria(s)]
    
UserVals.CreateVids = false; %1 = true, saves short video snips to match length of cue on plots - need to add Cam ID and filename for video to filelist
    UserVals.Vids.Datatypes = [1,3]; %#ok<NBRAK> %Indx to which datatypes from DefineData you would like to generate video snippets for
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