%% FP Group Analysis 
%ARW 4/20/2020
%   Loads .mat files from individual animals analysed with the FP_UserSetup script
%   Generates data plots averaged across animals for a given set of recordings (recordings specified in loadfile)
%   optional: can also sort into groups and plot group averages - group numbers specified in loadfile
%   note: individual animal files are required to have the same parameters in FP_UserSetup

%% OUTPUTS
%.mat file with individual and group(.plot) data sorted by group and recording

%.xlsx files with group means for stats analysis h

%% Inialization
% clearvars
% close all 
% fsep = filesep; %sets correct fileseparator for user OS
% loadfilename = '/Users/amywolff/Library/CloudStorage/GoogleDrive-awolff@umn.edu/Shared drives/LivEngel/Proj_OptoPav/Matlab/VTAstim_Loadfile_Group_VS.xlsx';%name of excel spreadsheet with list of .mat files to load
% PATH = 'G:\Shared drives\AmyWolff\MatlabTemp\LabMeeting'; %output data path
% savefolder = 'GroupAnalysisExample'; %folder name
% googledrive = true; %check to see if path is to google drive and use personal path to access
% googlepath = '/Users/amywolff/Library/CloudStorage/GoogleDrive-awolff@umn.edu' ; %path from your computer to googledrive

clearvars
close all 
fsep = filesep; %sets correct fileseparator for user OS
loadfilename = 'TVB4_RandRewScale_0.75s_Group';%name of excel spreadsheet with list of .mat files to load
PATH = '/Users/meganbrickner/Library/CloudStorage/GoogleDrive-brick225@umn.edu/Shared drives/MeganBrickner2/01_DATA_mab2/SafetyManuscript_Analysis/Cohort 7/RewardScale/RandRewRPE_IndvAn2026/0.75s/TVB'; %output data path
%PATH = '/Users/amywolff/Library/CloudStorage/GoogleDrive-awolff@umn.edu/Shared drives/AmyWolff/SCanalysis/New/OptoPav_EventLocked_Exclusion'
savefolder = 'GroupAnalysis_noEx'; %folder name
googledrive = true; %check to see if path is to google drive and use personal path to access
%googlepath = '/Users/meganbrickner/Library/CloudStorage/GoogleDrive-brick225@umn.edu';% ' ; %path from your computer to googledrive
googlepath = 'G:' ;

    
%% USER EDITABLE VARIABLES
%Reclabels = {'2s_5Hz','2s_20Hz','5s_5Hz','5s_20Hz'}; % if not determined will just label as numbers from 1 --> number of recordings
%Reclabels = {'day1','day2'};
%Reclabels = {'0.2mA','0.4mA','0.6mA'};
%Reclabels = {'10%_Suc','20%_Suc','Ensure','WhiteNoise'};
%Reclabels = {'day1','day4','day7'};
%Reclabels = {'INF'};
%Reclabels = {'day1','day2','day3'};
%Reclabels = {'0.2mA_Cond','0.4mA_Cond','Discrim'};
%Reclabels = {'day1','day3','day5'};
Reclabels = {'10%_Suc','Ensure'};

FPAnalysis = true;
FPplottype = {'Z_dFF'}; % {'Z_dFF','dFF'}; : remove from here if you don't want to plot both
DLCanalysis = false; %true to include DLC data
% usenormvals = false ; %use normalised values for peak analysis (must have normalised during individual data)
% appthresh = 4; %threshold (in cm) distance for approach
%peakdetect = 1; %time in s from window start to detect peaks/troughs
FPCorrs = false; % set to true for trial x trial correlations between FPcorrwin and DLC measures (speed, angular velocity, approach, orient, freezing, locomotion, distmoved?)
FPcorrwin = {{'firsttwosec','firstfivesec'},{'firsttwosec','firstfivesec'},{'firsttwosec','firstfivesec'}}; % this cell array needs to be the same length as process data - for each cell, give the labels of the FP peak response window/s to use for correlations with DLC data

%% Make Directory for Savefiles
%correct any formatting issues with PATH & savefolder
if googledrive
PATH = googleconvert_fname(PATH,googlepath);
savefolder = googleconvert_fname(savefolder, googlepath);
loadfilename = googleconvert_fname(loadfilename,googlepath);
end
PATH = formatconvert_fname(PATH);
savefolder = formatconvert_fname(savefolder);
loadfilename = formatconvert_fname(loadfilename);
if PATH(end) ~= fsep
    PATH = strcat(PATH,fsep);
end

if savefolder(end) == fsep
    savefolder = savefolder(1:end-1);
end

%% Load files from filelist and extract relevant info
if ~contains(loadfilename,'.xlsx')
    filename = strcat(loadfilename,'.xlsx');
else
    filename = loadfilename;
end
%[~,~,listdata] = xlsread(filename);  
[listdata] = readcell(filename); %reads list of filenames from xls sheet

A = 1; %full path to .matfile
E = 2; %filename
B = 3; % Group #
C = 4 ; %Animal ID
D = 5 ; %Start of recording numbers to include (each recording in a seperate column if no recording leave blank)

if googledrive
    for colA= 1:length(listdata(:,1))
    listdata{colA,1} = googleconvert_fname(listdata{colA,1},googlepath);
    end
end

for colA= 1:length(listdata(:,1))
    listdata{colA,1} = formatconvert_fname(listdata{colA,1});
end

if ~ischar(listdata{1,B})
    for colC = 1:length(listdata(:,B))
    listdata{colC,B} = num2str(listdata{colC,B});
    tf = isvarname(listdata{colC,B});
    if ~tf
        listdata{colC,B} = strcat('grp',listdata{colC,B});
    end
    end
end


[~,idx]=unique((listdata(:,B))); %find number of unique groups in loadfile list
Grouplabels = {listdata{idx,B}}; %extract unique labels for groups

numgroups = length(Grouplabels);
outgroup.ID = []; %prealloate output array

sz = size(listdata);
numfiles = sz(1);
numrecs = sz(2)-(D-1);
g_indx = ones(numgroups,1); % used to allocate data in output array
recs = NaN(numfiles, numrecs); %preallocate

outgroup.numrecs = numrecs;
outgroup.numgroups = numgroups;
%% loop through files and extract data for each recording
for f = 1: numfiles
    file = listdata {f,A};
    if file(end) ~= fsep
       file(end+1) = fsep;
    end
    file = strcat(file,listdata{f,E},'.mat');
    load(file);
    outgroup.ID{f} = listdata{f,C};
    % Labels to locate data in outfiles
    
    if ~exist('ProcessData','var') %for the first file get metadata (should be the same for all files)
        %get important metadata for labels
        if outdata.UserVals.ProcessSubset 
        ProcessData = outdata.UserVals.DefineData(outdata.UserVals.SubsetIndx);
        else
        ProcessData = outdata.UserVals.DefineData; 
        end
        setcond = outdata.UserVals.setcond;
        if DLCanalysis
            DLCmeasures = outdata.UserVals.DLCsetup.measures; %#ok<UNRCH>
            DLCaxislabs = outdata.UserVals.DLCsetup.axislabels;
            DLCsubfields = outdata.UserVals.DLCsetup.Subfields;
        end
    end
    
    if numgroups > 1 %get group number from loadfile
        exact_match_mask = strcmp(Grouplabels, listdata{f,B});
        group = find(exact_match_mask);
    else
        group = 1;
    end
    
    for ii = D: (D-1)+numrecs %get recording numbers to pull from loadfile
        recs(f,ii-D+1) = listdata{f,ii};
    end
    
    
    % Pull FP data  (rows = different animals, columns = different recordings)

    if ~isfield(outgroup,'plot')  %only need once as all data of a given type should be the same
        maxresponse_labels = cell(1,length(ProcessData));
        for p = 1:length(ProcessData)                
                maxresponse_labels{p} = outdata.metadata.perievent.maxwins.label{p};
                outgroup.plot.maxwins.(ProcessData{p}).label= maxresponse_labels{p} ;
                outgroup.plot.maxwins.(ProcessData{p}).wintimes=outdata.metadata.perievent.maxwins.timepoints{p};   
        end
    end

    for r = 1:numrecs     
        for p = 1:length(ProcessData)
            conds = setcond.(ProcessData{p}){2};
            if ~isfield(outgroup,(Grouplabels{group}))
                outgroup.(Grouplabels{group})=[];
            end
            if FPAnalysis
                if ~isfield(outgroup.(Grouplabels{group}),'FP')
                outgroup.(Grouplabels{group}).FP =[];
                end
                if ~isfield(outgroup.(Grouplabels{group}).FP,(ProcessData{p}))
                outgroup.(Grouplabels{group}).FP.(ProcessData{p}) = [];
                end
            if ~isfield(outgroup.(Grouplabels{group}).FP.(ProcessData{p}),'peaktimearray')
                    ind = ~isnan(recs(f,:));
                    ind = find(ind == 1, 1, 'first');
                    outgroup.(Grouplabels{group}).FP.(ProcessData{p}).time = outdata.timearray.(ProcessData{p}).FP.perievent{(recs(f,ind)),:};
                    maxe = size(outgroup.(Grouplabels{group}).FP.(ProcessData{p}).time); %figure out array length for NaN assignment
                    for m = 1:length(maxresponse_labels{p})
                        outgroup.(Grouplabels{group}).FP.(ProcessData{p}).peaktimearray.(maxresponse_labels{p}{m}) = outdata.timearray.(ProcessData{p}).FP.Peak.(maxresponse_labels{p}{m}){(recs(f,ind)),:};
                    end
            end
            end
            if DLCanalysis
                if ~isfield(outgroup.(Grouplabels{group}),'DLC')
                outgroup.(Grouplabels{group}).DLC =[];
                end
                if ~isfield(outgroup.(Grouplabels{group}).DLC,(ProcessData{p}))
                outgroup.(Grouplabels{group}).DLC.(ProcessData{p}) = [];
                end       
            if ~isfield(outgroup.(Grouplabels{group}).DLC.(ProcessData{p}),'peaktimearray')
            ind = ~isnan(recs(f,:));
            ind = find(ind == 1, 1, 'first');
            outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).time = outdata.DLC.(ProcessData{p}).time{(recs(f,ind)),:}; %#ok<UNRCH>
                for m = 1:length(maxresponse_labels{p})
                outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).peaktimearray.(maxresponse_labels{p}{m}) = outdata.timearray.(ProcessData{p}).DLC.Peak.(maxresponse_labels{p}{m}){(recs(f,ind)),:};
                end
            end
            end
            clear ind

            for c = 1:length(conds)           
                if ~isnan(recs(f,r)) % only pull data if this recording should be included for this animal
                    if FPAnalysis
                    for m = 1:length(maxresponse_labels{p}) %get maxresponses
                    for d = 1:length(FPplottype) 
                    %get trial x trial waveforms for each window
                    outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).(FPplottype{d}).Peak.Trials.trace.(maxresponse_labels{p}{m}){g_indx(group),r} = outdata.perievent.(ProcessData{p}).(conds{c}).(FPplottype{d}).Peak.trace.(maxresponse_labels{p}{m}).trials{recs(f,r),1};   
                    FPtypes = {'peakval','latency','rise','fall','AUC','avFP'};
                    for fpt = 1:length(FPtypes)
                    outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).(FPplottype{d}).Peak.Trials.(FPtypes{fpt}).(maxresponse_labels{p}{m}){g_indx(group),r} = outdata.perievent.(ProcessData{p}).(conds{c}).(FPplottype{d}).Peak.(FPtypes{fpt}).(maxresponse_labels{p}{m}).trials{recs(f,r),1};  
                    end
                    %get mean waveforms for each window    
                    outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).(FPplottype{d}).Peak.MeanTrace.trace.(maxresponse_labels{p}{m}){r}(g_indx(group),:)= outdata.perievent.(ProcessData{p}).(conds{c}).(FPplottype{d}).Peak.trace.(maxresponse_labels{p}{m}).mean(recs(f,r),:);
 %                   outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).(FPplottype{d}).Peak.MeanTrace.trace.(maxresponse_labels{p}{m}).sem{r}(g_indx(group),:) = outdata.perievent.(ProcessData{p}).(conds{c}).(FPplottype{d}).Peak.trace.(maxresponse_labels{p}{m}).sem(recs(f,r),:);
                    
                    %get peak/trough values of mean trace for each window
                    [maxval,maxindx] = max(outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).(FPplottype{d}).Peak.MeanTrace.trace.(maxresponse_labels{p}{m}){r}(g_indx(group),:));
                    [minval, minindx] = min(outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).(FPplottype{d}).Peak.MeanTrace.trace.(maxresponse_labels{p}{m}){r}(g_indx(group),:));
                    outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).(FPplottype{d}).Peak.MeanTrace.PeakVal.(maxresponse_labels{p}{m}){r}(g_indx(group),:) = maxval;
                    if ~isnan(maxval)
                    outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).(FPplottype{d}).Peak.MeanTrace.Latency.(maxresponse_labels{p}{m}){r}(g_indx(group),:) = outdata.timearray.(ProcessData{p}).FP.Peak.(maxresponse_labels{p}{m}){recs(f,r),1}(maxindx) - outdata.timearray.(ProcessData{p}).FP.Peak.(maxresponse_labels{p}{m}){recs(f,r),1}(1);                            
                    else
                    outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).(FPplottype{d}).Peak.MeanTrace.Latency.(maxresponse_labels{p}{m}){r}(g_indx(group),:) = NaN;
                    end
                    outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).(FPplottype{d}).Peak.MeanTrace.Indx.(maxresponse_labels{p}{m}){r}(g_indx(group),:) = maxindx;
                    outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).(FPplottype{d}).Trough.MeanTrace.PeakVal.(maxresponse_labels{p}{m}){r}(g_indx(group),:) = minval;
                    if ~isnan(minval)
                    outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).(FPplottype{d}).Trough.MeanTrace.Latency.(maxresponse_labels{p}{m}){r}(g_indx(group),:) = outdata.timearray.(ProcessData{p}).FP.Trough.(maxresponse_labels{p}{m}){recs(f,r),1}(minindx) - outdata.timearray.(ProcessData{p}).FP.Trough.(maxresponse_labels{p}{m}){recs(f,r),1}(1);
                    else
                    outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).(FPplottype{d}).Trough.MeanTrace.Latency.(maxresponse_labels{p}{m}){r}(g_indx(group),:) = NaN;    
                    end
                    outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).(FPplottype{d}).Trough.MeanTrace.Indx.(maxresponse_labels{p}{m}){r}(g_indx(group),:) = minindx;
 
                    %peak
                    risefallval = outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).(FPplottype{d}).Peak.MeanTrace.trace.(maxresponse_labels{p}{m}){r}(g_indx(group),maxindx)/2;%find 50% of max norm value
                    risefallindx = find(outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).(FPplottype{d}).Peak.MeanTrace.trace.(maxresponse_labels{p}{m}){r}(g_indx(group),:) < risefallval);%find values below 50% 
                    risestart = find(risefallindx < maxindx, 1, 'last');%
                    if isempty(risestart)
                        [~,risestart] = min(outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).(FPplottype{d}).Peak.MeanTrace.trace.(maxresponse_labels{p}{m}){r}(g_indx(group),1:maxindx)); %if values do not drop below 50% then find the minimum value between start and peak and use this
                    else
                        risestart = risefallindx(risestart)+1;
                    end
                    x1 = outdata.timearray.(ProcessData{p}).FP.Peak.(maxresponse_labels{p}{m}){recs(f,r),1}(risestart);
                    x2 = outdata.timearray.(ProcessData{p}).FP.Peak.(maxresponse_labels{p}{m}){recs(f,r),1}(maxindx);
                    y1 = outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).(FPplottype{d}).Peak.MeanTrace.trace.(maxresponse_labels{p}{m}){r}(g_indx(group),risestart);
                    y2 = outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).(FPplottype{d}).Peak.MeanTrace.trace.(maxresponse_labels{p}{m}){r}(g_indx(group),maxindx);
                    outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).(FPplottype{d}).Peak.MeanTrace.RiseSlope.(maxresponse_labels{p}{m}){r}(g_indx(group),:) = (y2-y1)/(x2-x1);
                    clear x1 x2 y1 y2
                    
                    fallend = find(risefallindx > maxindx,1,'first');%
                    if isempty(fallend)
                    [~,fallend] = min(outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).(FPplottype{d}).Peak.MeanTrace.trace.(maxresponse_labels{p}{m}){r}(g_indx(group),maxindx:end)); %if values do not drop below 50% then find the minimum value between peak and end and use this
                    indxtrace = (maxindx:length(outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).(FPplottype{d}).Peak.MeanTrace.trace.(maxresponse_labels{p}{m}){r}(g_indx(group),:)));
                    fallend = indxtrace(fallend);%indx minimum to whole trace
                    else
                    fallend = risefallindx(fallend)-1;
                    end
                    
                    x1 = outdata.timearray.(ProcessData{p}).FP.Peak.(maxresponse_labels{p}{m}){recs(f,r),1}(maxindx);
                    x2 = outdata.timearray.(ProcessData{p}).FP.Peak.(maxresponse_labels{p}{m}){recs(f,r),1}(fallend);
                    y1 = outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).(FPplottype{d}).Peak.MeanTrace.trace.(maxresponse_labels{p}{m}){r}(g_indx(group),maxindx);
                    y2 = outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).(FPplottype{d}).Peak.MeanTrace.trace.(maxresponse_labels{p}{m}){r}(g_indx(group),fallend);
                    outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).(FPplottype{d}).Peak.MeanTrace.FallSlope.(maxresponse_labels{p}{m}){r}(g_indx(group),:) = (y2-y1)/(x2-x1);
                    
                    %trough
                    risefallval = outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).(FPplottype{d}).Peak.MeanTrace.trace.(maxresponse_labels{p}{m}){r}(g_indx(group),minindx)/2;%find 50% of max norm value
                    risefallindx = find(outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).(FPplottype{d}).Peak.MeanTrace.trace.(maxresponse_labels{p}{m}){r}(g_indx(group),:) > risefallval);%find values below 50% 
                   
                    
                    risestart = find(risefallindx < minindx, 1, 'last');%
                    if isempty(risestart)
                         [~,risestart] = max(outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).(FPplottype{d}).Peak.MeanTrace.trace.(maxresponse_labels{p}{m}){r}(g_indx(group),1:minindx)); %if values do not drop below 50% then find the max value between start and peak and use this
                    else
                        risestart = risefallindx(risestart)+1;
                    end
                    x1 = outdata.timearray.(ProcessData{p}).FP.Trough.(maxresponse_labels{p}{m}){recs(f,r),1}(risestart);
                    x2 = outdata.timearray.(ProcessData{p}).FP.Trough.(maxresponse_labels{p}{m}){recs(f,r),1}(minindx);
                    y1 = outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).(FPplottype{d}).Peak.MeanTrace.trace.(maxresponse_labels{p}{m}){r}(g_indx(group),risestart);
                    y2 = outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).(FPplottype{d}).Peak.MeanTrace.trace.(maxresponse_labels{p}{m}){r}(g_indx(group),minindx);
                    outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).(FPplottype{d}).Trough.MeanTrace.RiseSlope.(maxresponse_labels{p}{m}){r}(g_indx(group),:) = (y2-y1)/(x2-x1);
                    clear x1 x2 y1 y2
                    
                    fallend = find(risefallindx > minindx,1,'first');%     
                    if isempty(fallend)
                        [~,fallend] = max(outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).(FPplottype{d}).Peak.MeanTrace.trace.(maxresponse_labels{p}{m}){r}(g_indx(group),minindx:end)); %if values do not drop below 50% then find the max value between peak and end and use this
                        indxtrace = (minindx:length(outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).(FPplottype{d}).Peak.MeanTrace.trace.(maxresponse_labels{p}{m}){r}(g_indx(group),:)));
                        fallend = indxtrace(fallend); %indx min value to whole trace
                    else
                        fallend = risefallindx(fallend)-1;
                    end
                    x1 = outdata.timearray.(ProcessData{p}).FP.Trough.(maxresponse_labels{p}{m}){recs(f,r),1}(minindx);
                    x2 = outdata.timearray.(ProcessData{p}).FP.Trough.(maxresponse_labels{p}{m}){recs(f,r),1}(fallend);
                    y1 = outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).(FPplottype{d}).Peak.MeanTrace.trace.(maxresponse_labels{p}{m}){r}(g_indx(group),minindx);
                    y2 = outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).(FPplottype{d}).Peak.MeanTrace.trace.(maxresponse_labels{p}{m}){r}(g_indx(group),fallend);
                    outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).(FPplottype{d}).Trough.MeanTrace.FallSlope.(maxresponse_labels{p}{m}){r}(g_indx(group),:) = (y2-y1)/(x2-x1);
               
                    
                    %AUC - same for peak and trough
                    outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).(FPplottype{d}).Peak.MeanTrace.AUC.(maxresponse_labels{p}{m}){r}(g_indx(group),:) = trapz(outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).(FPplottype{d}).Peak.MeanTrace.trace.(maxresponse_labels{p}{m}){r}(g_indx(group),:));
                    outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).(FPplottype{d}).Trough.MeanTrace.AUC.(maxresponse_labels{p}{m}){r}(g_indx(group),:) = trapz(outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).(FPplottype{d}).Peak.MeanTrace.trace.(maxresponse_labels{p}{m}){r}(g_indx(group),:));
                    
                    %average z scored DFF across window - same for peak and
                    %trough
                    outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).(FPplottype{d}).Peak.MeanTrace.AverageFP.(maxresponse_labels{p}{m}){r}(g_indx(group),:) = mean(outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).(FPplottype{d}).Peak.MeanTrace.trace.(maxresponse_labels{p}{m}){r}(g_indx(group),:));
                    outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).(FPplottype{d}).Trough.MeanTrace.AverageFP.(maxresponse_labels{p}{m}){r}(g_indx(group),:) = mean(outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).(FPplottype{d}).Peak.MeanTrace.trace.(maxresponse_labels{p}{m}){r}(g_indx(group),:));  
                    end
                    end
                    end
              
                    %% DLC Analysis
                    if DLCanalysis
                        if outdata.videodata.vidFPS{recs(f,r),1} < outdata.UserVals.DLC.MaxFPS
                        paddata = true;
                        else
                        paddata = false;
                        end
                        if paddata
                        outgroup.(Grouplabels{group}).DLC.paddata.paddata{r}(g_indx(group),:)= true;    
                        outgroup.(Grouplabels{group}).DLC.paddata.padDLCTRANGE{r}(g_indx(group),:)= outdata.UserVals.DLCsetup.padDLCTRANGE{recs(f,r),1};
                        outgroup.(Grouplabels{group}).DLC.paddata.padtimearray{r}(g_indx(group),:)= outdata.UserVals.DLC.padtimearray{recs(f,r),1};
                        else
                        outgroup.(Grouplabels{group}).DLC.paddata.paddata{r}(g_indx(group),:)= false;
                        end
                    
                    % Get Quadrant Data               
                    if isfield (DLCsubfields,'Quadrant')
                    Quadrant = {'LT','LB','RT','RB'};
                    qbps = DLCsubfields.Quadrant{1};
                    for bp = 1:length(qbps)
                    for m = 1:length(maxresponse_labels{p})                  
                        for q = 1:4
                            outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Quadrant.(qbps{bp}).(Quadrant{q}).Peak.(maxresponse_labels{p}{m}).mean{r}(g_indx(group),:) = outdata.DLC.(ProcessData{p}).(conds{c}).Quadrant.(qbps{bp}).(Quadrant{q}).Peak.(maxresponse_labels{p}{m}).mean{(recs(f,r)),:};
                            outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Quadrant.(qbps{bp}).(Quadrant{q}).Peak.(maxresponse_labels{p}{m}).sem{r}(g_indx(group),:) = outdata.DLC.(ProcessData{p}).(conds{c}).Quadrant.(qbps{bp}).(Quadrant{q}).Peak.(maxresponse_labels{p}{m}).sem{(recs(f,r)),:};
                        end
                    end
                    end
                    end
                    
                    %% Get locomotion/Freezing Bout data
                    if isfield(outdata,'Bouts')
                    bouttypes = {'Locomotion','Freeze'};
                    for bt = 1:length(bouttypes)
                    if isfield(outdata.Bouts.(ProcessData{p}),(bouttypes{bt}))
                        %get boutmetrics for correl
                        %get DLC data for correlations
                        for m = 1:length(maxresponse_labels{p})  
                        getdata = true;
                        if isempty(outdata.Bouts.(ProcessData{p}).(bouttypes{bt}).DLC.(conds{c}).(maxresponse_labels{p}{m}).latency.trials)
                        getdata = false;
                        else
                            if length(outdata.Bouts.(ProcessData{p}).(bouttypes{bt}).DLC.(conds{c}).(maxresponse_labels{p}{m}).latency.trials) < recs(f,r)
                            getdata = false;
                            else
                                if  isempty (outdata.Bouts.(ProcessData{p}).(bouttypes{bt}).DLC.(conds{c}).(maxresponse_labels{p}{m}).latency.trials{recs(f,r),1})
                                getdata = false;
                                end
                            end
                        end
                        
                        if getdata
                        boutindx = outdata.Bouts.(ProcessData{p}).(bouttypes{bt}).DLC.(conds{c}).(maxresponse_labels{p}{m}).latency.trials{recs(f,r),1} > 0; %Exclude trials where the bouts started before Cue Onset
                        boutindxall = sum(~isnan(outdata.Bouts.(ProcessData{p}).(bouttypes{bt}).DLC.(conds{c}).(maxresponse_labels{p}{m}).latency.trials{recs(f,r),1})); %trials with bouts(incl those that start before bout onset)
                        totaltrials = sum(~isnan(outdata.Bouts.(ProcessData{p}).(bouttypes{bt}).DLC.(conds{c}).(maxresponse_labels{p}{m}).numbouts.trials{recs(f,r),1}));
                        %measures - excludes bouts initiated before window
                        outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).(bouttypes{bt}).Corr.trialn.(maxresponse_labels{p}{m}).trials{r,g_indx(group)} = outdata.perievent.(ProcessData{p}).(conds{c}).trialn{recs(f,r),1}(boutindx);
                        outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).(bouttypes{bt}).Corr.Latency.(maxresponse_labels{p}{m}).trials{r,g_indx(group)} = outdata.Bouts.(ProcessData{p}).(bouttypes{bt}).DLC.(conds{c}).(maxresponse_labels{p}{m}).latency.trials{recs(f,r),1}(boutindx);  
                        outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).(bouttypes{bt}).Corr.Duration.(maxresponse_labels{p}{m}).trials{r,g_indx(group)} = outdata.Bouts.(ProcessData{p}).(bouttypes{bt}).DLC.(conds{c}).(maxresponse_labels{p}{m}).duration.trials{recs(f,r),1}(boutindx);  
                        outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).(bouttypes{bt}).Corr.Time.(maxresponse_labels{p}{m}).trials{r,g_indx(group)} = outdata.Bouts.(ProcessData{p}).(bouttypes{bt}).DLC.(conds{c}).(maxresponse_labels{p}{m}).bouttime.trials{recs(f,r),1}(boutindx);    
                        outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).(bouttypes{bt}).Corr.Perc.(maxresponse_labels{p}{m}).trials{r,g_indx(group)} = outdata.Bouts.(ProcessData{p}).(bouttypes{bt}).DLC.(conds{c}).(maxresponse_labels{p}{m}).boutperc.trials{recs(f,r),1}(boutindx);        
                         
                        if FPAnalysis %get FP data for correlations
                         FPdatatypes = {'peakval','latency','AUC','rise','fall'};                       
                            for x = 1: length(FPdatatypes)
                                if FPCorrs
                                    for cw = 1:length(FPcorrwin{p})
                                    outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).(bouttypes{bt}).Corr.Z_dFF.Peak.(FPdatatypes{x}).(FPcorrwin{p}{cw}).(maxresponse_labels{p}{m}).trials{r,g_indx(group)} = outdata.perievent.(ProcessData{p}).(conds{c}).Z_dFF.Peak.(FPdatatypes{x}).(FPcorrwin{p}{cw}).trials{recs(f,r),1}(boutindx);   
                                    end
                                end
                            end

                            %get FP event traces for trials with/without
                            %bouts
                            eventtimes = {'pre','during','none'};
                            wflength = size(outdata.timearray.(ProcessData{p}).FP.perievent{recs(f,r),1},2);
                            for et = 1:3
                            if isfield(outdata.Bouts.(ProcessData{p}).(bouttypes{bt}).FP.(conds{c}).(maxresponse_labels{p}{m}).Z_dFF.trials{recs(f,r),1},(eventtimes{et}))
                                if size(outdata.Bouts.(ProcessData{p}).(bouttypes{bt}).FP.(conds{c}).(maxresponse_labels{p}{m}).Z_dFF.trials{recs(f,r),1}.(eventtimes{et}),1) > 1 %if there are enough trials to average get data
                                outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).(bouttypes{bt}).MeanWF_Event.(maxresponse_labels{p}{m}).(eventtimes{et}){r}(g_indx(group),:) =  mean(outdata.Bouts.(ProcessData{p}).(bouttypes{bt}).FP.(conds{c}).(maxresponse_labels{p}{m}).Z_dFF.trials{recs(f,r),1}.(eventtimes{et}),'omitnan');  
                                else
                                outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).(bouttypes{bt}).MeanWF_Event.(maxresponse_labels{p}{m}).(eventtimes{et}){r}(g_indx(group),:)= nan(1,wflength);
                                end
                            else
                            outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).(bouttypes{bt}).MeanWF_Event.(maxresponse_labels{p}{m}).(eventtimes{et}){r}(g_indx(group),:)= nan(1,wflength);
                            end
                            end

                         

                       %Get bout aligned FP data
                        for et = 1:2                     
                        if isfield(outdata.Bouts.(ProcessData{p}).(bouttypes{bt}).FP.(conds{c}).(maxresponse_labels{p}{m}).zscored,(eventtimes{et})) %if there are data for the window
                        tracelength = length(outdata.Bouts.(ProcessData{p}).(bouttypes{bt}).FP.(conds{c}).(maxresponse_labels{p}{m}).time);
                        outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).(bouttypes{bt}).MeanWF_Bout.time = outdata.Bouts.(ProcessData{p}).(bouttypes{bt}).FP.(conds{c}).(maxresponse_labels{p}{m}).time;
                        if sum(isnan(outdata.Bouts.(ProcessData{p}).(bouttypes{bt}).FP.(conds{c}).(maxresponse_labels{p}{m}).zscored.(eventtimes{et}).mean{recs(f,r),1})) == length(outdata.Bouts.(ProcessData{p}).(bouttypes{bt}).FP.(conds{c}).(maxresponse_labels{p}{m}).zscored.(eventtimes{et}).mean{recs(f,r),1})
                        outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).(bouttypes{bt}).MeanWF_Bout.(maxresponse_labels{p}{m}).(eventtimes{et}){r}(g_indx(group),:) = NaN(1,tracelength);
                        else
                        outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).(bouttypes{bt}).MeanWF_Bout.(maxresponse_labels{p}{m}).(eventtimes{et}){r}(g_indx(group),:) = outdata.Bouts.(ProcessData{p}).(bouttypes{bt}).FP.(conds{c}).(maxresponse_labels{p}{m}).zscored.(eventtimes{et}).mean{recs(f,r),1};
                        end
                        if sum(isnan(outdata.Bouts.(ProcessData{p}).(bouttypes{bt}).FP.(conds{c}).(maxresponse_labels{p}{m}).zscored.(eventtimes{et}).mean{recs(f,r),1})) == length(outdata.Bouts.(ProcessData{p}).(bouttypes{bt}).FP.(conds{c}).(maxresponse_labels{p}{m}).zscored.(eventtimes{et}).mean{recs(f,r),1})
                        outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).(bouttypes{bt}).TrialWF_Bout.(maxresponse_labels{p}{m}).(eventtimes{et}){r,g_indx(group)} = NaN(1,tracelength);
                        else
                        outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).(bouttypes{bt}).TrialWF_Bout.(maxresponse_labels{p}{m}).(eventtimes{et}){r,g_indx(group)} = outdata.Bouts.(ProcessData{p}).(bouttypes{bt}).FP.(conds{c}).(maxresponse_labels{p}{m}).zscored.trials{recs(f,r),1}.(eventtimes{et});
                        end
                        end
                        end
                        end
                        %get mean
                        outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).(bouttypes{bt}).Perctrials.(maxresponse_labels{p}{m}).num{r}(g_indx(group),:) = (sum(boutindx)/totaltrials)*100;
                        outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).(bouttypes{bt}).PerctrialsAll.(maxresponse_labels{p}{m}).num{r}(g_indx(group),:) = (sum(boutindxall)/totaltrials)*100;
                        outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).(bouttypes{bt}).Numevents.(maxresponse_labels{p}{m}).mean{r}(g_indx(group),:) = mean(outdata.Bouts.(ProcessData{p}).(bouttypes{bt}).DLC.(conds{c}).(maxresponse_labels{p}{m}).numbouts.trials{recs(f,r),1}(boutindx),'omitnan');
                        outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).(bouttypes{bt}).Latency.(maxresponse_labels{p}{m}).mean{r}(g_indx(group),:) = mean(outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).(bouttypes{bt}).Corr.Latency.(maxresponse_labels{p}{m}).trials{r,g_indx(group)},'omitnan');
                        outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).(bouttypes{bt}).LatencyAll.(maxresponse_labels{p}{m}).mean{r}(g_indx(group),:) = mean(outdata.Bouts.(ProcessData{p}).(bouttypes{bt}).DLC.(conds{c}).(maxresponse_labels{p}{m}).latency.trials{recs(f,r),1},'omitnan');  
                        outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).(bouttypes{bt}).Duration.(maxresponse_labels{p}{m}).mean{r}(g_indx(group),:) = mean(outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).(bouttypes{bt}).Corr.Duration.(maxresponse_labels{p}{m}).trials{r,g_indx(group)},'omitnan');
                        outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).(bouttypes{bt}).TimeAll.(maxresponse_labels{p}{m}).mean{r}(g_indx(group),:) = mean(outdata.Bouts.(ProcessData{p}).(bouttypes{bt}).DLC.(conds{c}).(maxresponse_labels{p}{m}).bouttime.trials{recs(f,r),1},'omitnan'); %includes trials with no bouts/bouts initiated before window onset
                        outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).(bouttypes{bt}).PercAll.(maxresponse_labels{p}{m}).mean{r}(g_indx(group),:) = mean(outdata.Bouts.(ProcessData{p}).(bouttypes{bt}).DLC.(conds{c}).(maxresponse_labels{p}{m}).boutperc.trials{recs(f,r),1},'omitnan'); %includes trials with no bouts/bouts initiated before window onset
                        outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).(bouttypes{bt}).Time.(maxresponse_labels{p}{m}).mean{r}(g_indx(group),:) = mean(outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).(bouttypes{bt}).Corr.Time.(maxresponse_labels{p}{m}).trials{r,g_indx(group)},'omitnan'); %only includes trials with bouts initiated within window
                        outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).(bouttypes{bt}).Perc.(maxresponse_labels{p}{m}).mean{r}(g_indx(group),:) = mean(outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).(bouttypes{bt}).Corr.Perc.(maxresponse_labels{p}{m}).trials{r,g_indx(group)},'omitnan'); %only includes trials with bouts initiated within window

                        else
                            % outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).(bouttypes{bt}).Corr.trialn.(maxresponse_labels{p}{m}).trials{r,g_indx(group)} = [];
                            % outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).(bouttypes{bt}).Corr.Latency.(maxresponse_labels{p}{m}).trials{r,g_indx(group)} = [];
                            % outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).(bouttypes{bt}).Corr.Duration.(maxresponse_labels{p}{m}).trials{r,g_indx(group)} = [];
                            % outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).(bouttypes{bt}).Corr.Time.(maxresponse_labels{p}{m}).trials{r,g_indx(group)} = [];
                            % outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).(bouttypes{bt}).Corr.Perc.(maxresponse_labels{p}{m}).trials{r,g_indx(group)} = [];
                            if FPAnalysis
                            FPdatatypes = {'peakval','latency','AUC','rise','fall'}; 
                                % if FPCorrs
                                % for x = 1: length(FPdatatypes)
                                %     for cw = 1:length(FPcorrwin{p})
                                %     if strcmp(maxresponse_labels{p}{m},FPcorrwin{p}{cw})
                                %     outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).(bouttypes{bt}).Corr.Z_dFF.Peak.(FPcorrwin{p}{cw}).(maxresponse_labels{p}{m}).trials{r,g_indx(group)} = [];
                                %     end
                                %     end
                                % end
                                % end
                                eventtimes = {'pre','during','none'};
                                for et = 1:3
                                outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).(bouttypes{bt}).MeanWF_Event.(maxresponse_labels{p}{m}).(eventtimes{et}){r}(g_indx(group),:)= NaN(1,length(outgroup.(Grouplabels{group}).FP.(ProcessData{p}).peaktimearray.All));
                                end
                                
                                for et = 1:2
                                outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).(bouttypes{bt}).MeanWF_Bout.(maxresponse_labels{p}{m}).(eventtimes{et}){r}(g_indx(group),:) = NaN(1,length(outdata.Bouts.(ProcessData{p}).(bouttypes{bt}).FP.(conds{c}).(maxresponse_labels{p}{m}).time));
                                outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).(bouttypes{bt}).TrialWF_Bout.(maxresponse_labels{p}{m}).(eventtimes{et}){r,g_indx(group)} = [];
                                end

                            end
                                outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).(bouttypes{bt}).Perctrials.(maxresponse_labels{p}{m}).num{r}(g_indx(group),:) = NaN;
                                outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).(bouttypes{bt}).PerctrialsAll.(maxresponse_labels{p}{m}).num{r}(g_indx(group),:) = NaN;
                                outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).(bouttypes{bt}).Numevents.(maxresponse_labels{p}{m}).mean{r}(g_indx(group),:) = NaN;
                                outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).(bouttypes{bt}).Latency.(maxresponse_labels{p}{m}).mean{r}(g_indx(group),:) = NaN;
                                outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).(bouttypes{bt}).LatencyAll.(maxresponse_labels{p}{m}).mean{r}(g_indx(group),:) = NaN;
                                outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).(bouttypes{bt}).Duration.(maxresponse_labels{p}{m}).mean{r}(g_indx(group),:) = NaN;
                                outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).(bouttypes{bt}).TimeAll.(maxresponse_labels{p}{m}).mean{r}(g_indx(group),:) = NaN;                          
                                outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).(bouttypes{bt}).PercAll.(maxresponse_labels{p}{m}).mean{r}(g_indx(group),:) = NaN;
                                outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).(bouttypes{bt}).Time.(maxresponse_labels{p}{m}).mean{r}(g_indx(group),:) = NaN;                          
                                outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).(bouttypes{bt}).Perc.(maxresponse_labels{p}{m}).mean{r}(g_indx(group),:) = NaN;
                        end
                        end
                    end
                    end
                    end
                    
                    
                    % %get DLC measures
                    for b = 1:length(DLCmeasures)
                    numsubfields = length(DLCsubfields.(DLCmeasures{b}));
                    flds = DLCsubfields.(DLCmeasures{b}){1};
                    for x =1:length(flds)
                    switch numsubfields                                       
                        case 1 %one subfield
                            for m = 1:length(maxresponse_labels{p})
                            outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).Peak.(maxresponse_labels{p}{m}).mean{r}(g_indx(group),:) = outdata.DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).Peak.(maxresponse_labels{p}{m}).mean((recs(f,r)),:);
                            outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).Peak.(maxresponse_labels{p}{m}).sem{r}(g_indx(group),:) = outdata.DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).Peak.(maxresponse_labels{p}{m}).sem((recs(f,r)),:);
                            outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).Peak.(maxresponse_labels{p}{m}).int.mean{r}(g_indx(group),:) = outdata.DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).Peak.(maxresponse_labels{p}{m}).mean((recs(f,r)),:);
                            outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).Peak.(maxresponse_labels{p}{m}).int.sem{r}(g_indx(group),:) = outdata.DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).Peak.(maxresponse_labels{p}{m}).sem((recs(f,r)),:);
                            end
                                %get max DLC data for each win (speed and
                                %move dist
                                if strcmp('Speed',(DLCmeasures{b})) || strcmp('MoveDist',(DLCmeasures{b}))
                                    %get metrics for correl
                                    %get DLC data for correlations
                                     DLCdatatypes = {'MaxVal','Average','MaxTs'};
                                     FPdatatypes = {'peakval','latency','AUC','rise','fall'};
                                         for m = 1:length(maxresponse_labels{p}) 
                                         if ~isempty(outdata.DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).Peak.(maxresponse_labels{p}{m}).MaxVal.trials{recs(f,r),1})
                                            for dd = 1:length(DLCdatatypes)
                                            outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).Corr.(flds{x}).(maxresponse_labels{p}{m}).(DLCdatatypes{dd}).trialn = outdata.perievent.(ProcessData{p}).(conds{c}).trialn{recs(f,r),1};
                                            outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).Corr.(flds{x}).(maxresponse_labels{p}{m}).(DLCdatatypes{dd}).trials{r,g_indx(group)} = outdata.DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).Peak.(maxresponse_labels{p}{m}).(DLCdatatypes{dd}).trials{recs(f,r),1};
                                             %get mean
                                            outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).(DLCdatatypes{dd}).(maxresponse_labels{p}{m}).mean{r}(g_indx(group),:) = mean(outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).Corr.(flds{x}).(maxresponse_labels{p}{m}).(DLCdatatypes{dd}).trials{r,g_indx(group)},'omitnan');
                                            end
                                            if FPAnalysis && FPCorrs
                                            %get FP data for correlations
                                            for xx = 1: length(FPdatatypes) %#ok<UNRCH>
                                                for cw = 1:length(FPcorrwin{p})
                                                    % if strcmp(maxresponse_labels{p}{m},FPcorrwin{p}{cw})
                                                    outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).Corr.(flds{x}).Z_dFF.Peak.(FPdatatypes{xx}).(FPcorrwin{p}{cw}).(maxresponse_labels{p}{m}).trials{r,g_indx(group)} = outdata.perievent.(ProcessData{p}).(conds{c}).Z_dFF.Peak.(FPdatatypes{xx}).(FPcorrwin{p}{cw}).trials{recs(f,r),1};
                                                    %outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).Corr.(flds{x}).Z_dFF.Peak.(FPdatatypes{xx}).(FPcorrwin{p}{cw}).trialn{r,g_indx(group)} = outdata.perievent.(ProcessData{p}).(conds{c}).Z_dFF.Peak.(FPdatatypes{xx}).(FPcorrwin{p}{cw}).trialn{recs(f,r),1};
                                                    % end
                                                end
                                            end
                                            end
                                        else 
                                            for dd = 1: length(DLCdatatypes)
                                                % if FPcorrs
                                                % outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).Corr.(flds{x}).(maxresponse_labels{p}{m}).(DLCdatatypes{dd}).trials{r,g_indx(group)}  = [];
                                                % end
                                                outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).(DLCdatatypes{dd}).(maxresponse_labels{p}{m}).mean{r}(g_indx(group),:)  = NaN;
                                            end 
                                            % if FPAnalysis && FPCorrs
                                            % for xx = 1: length(FPdatatypes) %#ok<UNRCH>
                                            %     for cw = 1:length(FPcorrwin{p})
                                            %     if strcmp(maxresponse_labels{p}{m},FPcorrwin{p}{cw})
                                            %     outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).Corr.(flds{x}).(FPplottype{d}).Peak.(FPdatatypes{xx}).(FPcorrwin{p}{cw}).trials{r,g_indx(group)}  = [];
                                            %     end
                                            %     end
                                            % end
                                            % end
                                         end
                                         end
                                end
                        if paddata %fill in missing values for low sampling rate and save separately
                        padtimearray = outgroup.(Grouplabels{group}).DLC.paddata.padtimearray{r}(g_indx(group),:);
                        padtimearray = padtimearray{p};
                            for m = 1:length(maxresponse_labels{p})
                            indxmissing = ~ismember(outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).peaktimearray.(maxresponse_labels{p}{m}),padtimearray); 
                            outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).Peak.(maxresponse_labels{p}{m}).int.mean{r}(g_indx(group),:) = outdata.DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).Peak.(maxresponse_labels{p}{m}).mean((recs(f,r)),:);
                            i = 1:numel(indxmissing);
                            outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).Peak.(maxresponse_labels{p}{m}).int.mean{r}(g_indx(group),indxmissing)= interp1(i(~indxmissing), outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).Peak.(maxresponse_labels{p}{m}).int.mean{r}(g_indx(group),~indxmissing),i(indxmissing),'linear');
                            end
                            clear paddtimearray
                        end
                                               
                        case 2 %two subfields
                        refr = DLCsubfields.(DLCmeasures{b}){2}{x};
                        for y = 1:length(refr)
                                for m = 1:length(maxresponse_labels{p})
                                outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).(refr{y}).Peak.(maxresponse_labels{p}{m}).mean{r}(g_indx(group),:) = outdata.DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).(refr{y}).Peak.(maxresponse_labels{p}{m}).mean((recs(f,r)),:);
                                outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).(refr{y}).Peak.(maxresponse_labels{p}{m}).sem{r}(g_indx(group),:) = outdata.DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).(refr{y}).Peak.(maxresponse_labels{p}{m}).sem((recs(f,r)),:);
                                outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).(refr{y}).Peak.(maxresponse_labels{p}{m}).int.mean{r}(g_indx(group),:) = outdata.DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).(refr{y}).Peak.(maxresponse_labels{p}{m}).mean((recs(f,r)),:);
                                outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).(refr{y}).Peak.(maxresponse_labels{p}{m}).int.sem{r}(g_indx(group),:) = outdata.DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).(refr{y}).Peak.(maxresponse_labels{p}{m}).sem((recs(f,r)),:);
                                end
                                
                                % Get Approach Data
                                if isfield(outdata,'Bouts') 
                                if isfield(outdata.Bouts.(ProcessData{p}),'Approach') && strcmp((DLCmeasures{b}),'DistTo')
                                    %get boutmetrics for correl
                                    %get DLC data for correlations
                                    for m = 1:length(maxresponse_labels{p}) 
                                    getdata = true;
                                    if isempty(outdata.Bouts.(ProcessData{p}).Approach.(flds{x}).(refr{y}).DLC.(conds{c}).(maxresponse_labels{p}{m}).latency.trials)
                                    getdata = false;
                                    else
                                    if length(outdata.Bouts.(ProcessData{p}).Approach.(flds{x}).(refr{y}).DLC.(conds{c}).(maxresponse_labels{p}{m}).latency.trials) < recs(f,r)
                                    getdata = false;
                                    else
                                        if isempty(outdata.Bouts.(ProcessData{p}).Approach.(flds{x}).(refr{y}).DLC.(conds{c}).(maxresponse_labels{p}{m}).latency.trials{recs(f,r),1})
                                        getdata = false;
                                        end
                                    end    
                                    end
                                    if getdata
                                        boutindx = outdata.Bouts.(ProcessData{p}).Approach.(flds{x}).(refr{y}).DLC.(conds{c}).(maxresponse_labels{p}{m}).latency.trials{recs(f,r),1} > 0; %only get data for trials where there were bouts for correlations
                                        boutindxall = sum(~isnan(outdata.Bouts.(ProcessData{p}).Approach.(flds{x}).(refr{y}).DLC.(conds{c}).(maxresponse_labels{p}{m}).latency.trials{recs(f,r),1})); %all trials with bouts (incl those started before win onset)
                                        totaltrials = sum(~isnan(outdata.Bouts.(ProcessData{p}).Approach.(flds{x}).(refr{y}).DLC.(conds{c}).(maxresponse_labels{p}{m}).numbouts.trials{recs(f,r),1}));
                                        outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Approach.Corr.(flds{x}).(refr{y}).trialn.(maxresponse_labels{p}{m}). trials {r,g_indx(group)} = outdata.perievent.(ProcessData{p}).(conds{c}).trialn{recs(f,r),1}(boutindx);
                                        outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Approach.Corr.(flds{x}).(refr{y}).Latency.(maxresponse_labels{p}{m}).trials{r,g_indx(group)} = outdata.Bouts.(ProcessData{p}).Approach.(flds{x}).(refr{y}).DLC.(conds{c}).(maxresponse_labels{p}{m}).latency.trials{recs(f,r),1}(boutindx);
                                        outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Approach.Corr.(flds{x}).(refr{y}).Duration.(maxresponse_labels{p}{m}).trials{r,g_indx(group)} = outdata.Bouts.(ProcessData{p}).Approach.(flds{x}).(refr{y}).DLC.(conds{c}).(maxresponse_labels{p}{m}).duration.trials{recs(f,r),1}(boutindx);  
                                        outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Approach.Corr.(flds{x}).(refr{y}).Time.(maxresponse_labels{p}{m}).trials{r,g_indx(group)} = outdata.Bouts.(ProcessData{p}).Approach.(flds{x}).(refr{y}).DLC.(conds{c}).(maxresponse_labels{p}{m}).bouttime.trials{recs(f,r),1}(boutindx);
                                        outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Approach.Corr.(flds{x}).(refr{y}).Perc.(maxresponse_labels{p}{m}).trials{r,g_indx(group)} = outdata.Bouts.(ProcessData{p}).Approach.(flds{x}).(refr{y}).DLC.(conds{c}).(maxresponse_labels{p}{m}).boutperc.trials{recs(f,r),1}(boutindx);
                                        % outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Approach.Corr.trialn.(maxresponse_labels{p}{m}).trials {r,g_indx(group)} = outdata.perievent.(ProcessData{p}).(conds{c}).trialn{recs(f,r),1}(boutindx);
                                        % outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Approach.Corr.Latency.(maxresponse_labels{p}{m}).trials{r,g_indx(group)} = outdata.Bouts.(ProcessData{p}).Approach.(flds{x}).(refr{y}).DLC.(conds{c}).(maxresponse_labels{p}{m}).latency.trials{recs(f,r),1}(boutindx);
                                        % outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Approach.Corr.Duration.(maxresponse_labels{p}{m}).trials{r,g_indx(group)} = outdata.Bouts.(ProcessData{p}).Approach.(flds{x}).(refr{y}).DLC.(conds{c}).(maxresponse_labels{p}{m}).duration.trials{recs(f,r),1}(boutindx);  
                                        % outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Approach.Corr.Time.(maxresponse_labels{p}{m}).trials{r,g_indx(group)} = outdata.Bouts.(ProcessData{p}).Approach.(flds{x}).(refr{y}).DLC.(conds{c}).(maxresponse_labels{p}{m}).bouttime.trials{recs(f,r),1}(boutindx);
                                        % outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Approach.Corr.Perc.(maxresponse_labels{p}{m}).trials{r,g_indx(group)} = outdata.Bouts.(ProcessData{p}).Approach.(flds{x}).(refr{y}).DLC.(conds{c}).(maxresponse_labels{p}{m}).boutperc.trials{recs(f,r),1}(boutindx);
                                        % 
                                        % if sum(boutindx) == 0
                                        % outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Approach.Corr.(flds{x}).(refr{y}).Latency.(maxresponse_labels{p}{m}).trials{r,g_indx(group)} = NaN;
                                        % % outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Approach.Corr.Latency.(maxresponse_labels{p}{m}).trials{r,g_indx(group)} = NaN;
                                        % end
                                        
                                        if FPAnalysis 
                                        %get FP data for correlations
                                        FPdatatypes = {'peakval','latency','AUC','rise','fall'};
                                            for xx = 1: length(FPdatatypes)
                                                if FPCorrs
                                                for cw = 1:length(FPcorrwin{p})
                                                % if strcmp(maxresponse_labels{p}{m},FPcorrwin{p}{cw})
                                                outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).Approach.Corr.(flds{x}).(refr{y}).Z_dFF.Peak.(FPdatatypes{xx}).(FPcorrwin{p}{cw}).(maxresponse_labels{p}{m}).trials{r,g_indx(group)} = outdata.perievent.(ProcessData{p}).(conds{c}).Z_dFF.Peak.(FPdatatypes{xx}).(FPcorrwin{p}{cw}).trials{recs(f,r),1}(boutindx);
                                                %outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).Approach.Corr.Z_dFF.Peak.(FPdatatypes{xx}).(maxresponse_labels{p}{m}).trials{r,g_indx(group)} = outdata.perievent.(ProcessData{p}).(conds{c}).Z_dFF.Peak.(FPdatatypes{xx}).(FPcorrwin{p}).trials{recs(f,r),1}(boutindx);
                                                % end
                                                end
                                                end
                                            end
                                            eventtimes = {'pre','during','none'};
                                            wflength = size(outdata.timearray.(ProcessData{p}).FP.perievent{recs(f,r),1},2);
                                            for et = 1:3
                                                if isfield(outdata.Bouts.(ProcessData{p}).Approach.(flds{x}).(refr{y}).FP.(conds{c}).(maxresponse_labels{p}{m}).Z_dFF.trials{recs(f,r),1},(eventtimes{et}))
                                                    if size(outdata.Bouts.(ProcessData{p}).Approach.(flds{x}).(refr{y}).FP.(conds{c}).(maxresponse_labels{p}{m}).Z_dFF.trials{recs(f,r),1}.(eventtimes{et}),1) > 1 %if there are enough trials to average get data
                                                        outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).Approach.(flds{x}).(refr{y}).MeanWF_Event.(maxresponse_labels{p}{m}).(eventtimes{et}){r}(g_indx(group),:) =  mean(outdata.Bouts.(ProcessData{p}).Approach.(flds{x}).(refr{y}).FP.(conds{c}).(maxresponse_labels{p}{m}).Z_dFF.trials{recs(f,r),1}.(eventtimes{et}),'omitnan');
                                                    else
                                                        outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).Approach.(flds{x}).(refr{y}).MeanWF_Event.(maxresponse_labels{p}{m}).(eventtimes{et}){r}(g_indx(group),:)= nan(1,wflength);
                                                    end
                                                else
                                                    outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).Approach.(flds{x}).(refr{y}).MeanWF_Event.(maxresponse_labels{p}{m}).(eventtimes{et}){r}(g_indx(group),:)= nan(1,wflength);
                                                end
                                            end   

                                            %Get bout aligned FP data
                                            for et = 1:2                     
                                            if isfield(outdata.Bouts.(ProcessData{p}).Approach.(flds{x}).(refr{y}).FP.(conds{c}).(maxresponse_labels{p}{m}).zscored,(eventtimes{et})) %if there are data for the window
                                            tracelength = length(outdata.Bouts.(ProcessData{p}).Approach.(flds{x}).(refr{y}).FP.(conds{c}).(maxresponse_labels{p}{m}).time);
                                            outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).Approach.(flds{x}).(refr{y}).MeanWF_Bout.time = outdata.Bouts.(ProcessData{p}).Approach.(flds{x}).(refr{y}).FP.(conds{c}).(maxresponse_labels{p}{m}).time;
                                            if sum(isnan(outdata.Bouts.(ProcessData{p}).Approach.(flds{x}).(refr{y}).FP.(conds{c}).(maxresponse_labels{p}{m}).zscored.(eventtimes{et}).mean{recs(f,r),1})) == length(outdata.Bouts.(ProcessData{p}).Approach.(flds{x}).(refr{y}).FP.(conds{c}).(maxresponse_labels{p}{m}).zscored.(eventtimes{et}).mean{recs(f,r),1})
                                            outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).Approach.(flds{x}).(refr{y}).MeanWF_Bout.(maxresponse_labels{p}{m}).(eventtimes{et}){r}(g_indx(group),:) = NaN(1,tracelength);  
                                            else
                                            outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).Approach.(flds{x}).(refr{y}).MeanWF_Bout.(maxresponse_labels{p}{m}).(eventtimes{et}){r}(g_indx(group),:) = outdata.Bouts.(ProcessData{p}).Approach.(flds{x}).(refr{y}).FP.(conds{c}).(maxresponse_labels{p}{m}).zscored.(eventtimes{et}).mean{recs(f,r),1};
                                            end
                                            
                                            if sum(isnan(outdata.Bouts.(ProcessData{p}).Approach.(flds{x}).(refr{y}).FP.(conds{c}).(maxresponse_labels{p}{m}).zscored.(eventtimes{et}).mean{recs(f,r),1})) == length(outdata.Bouts.(ProcessData{p}).Approach.(flds{x}).(refr{y}).FP.(conds{c}).(maxresponse_labels{p}{m}).zscored.(eventtimes{et}).mean{recs(f,r),1})
                                            outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).Approach.(flds{x}).(refr{y}).TrialWF_Bout.(maxresponse_labels{p}{m}).(eventtimes{et}){r,g_indx(group)} = NaN(1,tracelength);
                                            else
                                                if length(outdata.Bouts.(ProcessData{p}).Approach.(flds{x}).(refr{y}).FP.(conds{c}).(maxresponse_labels{p}{m}).zscored.trials) >= recs(f,r)
                                                outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).Approach.(flds{x}).(refr{y}).TrialWF_Bout.(maxresponse_labels{p}{m}).(eventtimes{et}){r,g_indx(group)} = outdata.Bouts.(ProcessData{p}).Approach.(flds{x}).(refr{y}).FP.(conds{c}).(maxresponse_labels{p}{m}).zscored.trials{recs(f,r),1}.(eventtimes{et});
                                                end
                                            end
                                            end
                                            end
                                        end
                                        
                                        %get mean
                                        outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Approach.(flds{x}).(refr{y}).Perctrials.(maxresponse_labels{p}{m}).num{r}(g_indx(group),:) = (sum(boutindx)/totaltrials)*100;
                                        outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Approach.(flds{x}).(refr{y}).PerctrialsAll.(maxresponse_labels{p}{m}).num{r}(g_indx(group),:) = (sum(boutindxall)/totaltrials)*100;
                                        outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Approach.(flds{x}).(refr{y}).Numevents.(maxresponse_labels{p}{m}).mean{r}(g_indx(group),:) = mean(outdata.Bouts.(ProcessData{p}).Approach.(flds{x}).(refr{y}).DLC.(conds{c}).(maxresponse_labels{p}{m}).numbouts.trials{recs(f,r),1}(boutindx),'omitnan');
                                        outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Approach.(flds{x}).(refr{y}).Latency.(maxresponse_labels{p}{m}).mean{r}(g_indx(group),:) = mean(outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Approach.Corr.(flds{x}).(refr{y}).Latency.(maxresponse_labels{p}{m}).trials{r,g_indx(group)},'omitnan');
                                        outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Approach.(flds{x}).(refr{y}).LatencyAll.(maxresponse_labels{p}{m}).mean{r}(g_indx(group),:) = mean(outdata.Bouts.(ProcessData{p}).Approach.(flds{x}).(refr{y}).DLC.(conds{c}).(maxresponse_labels{p}{m}).latency.trials{recs(f,r),1},'omitnan');
                                        outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Approach.(flds{x}).(refr{y}).Duration.(maxresponse_labels{p}{m}).mean{r}(g_indx(group),:) = mean(outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Approach.Corr.(flds{x}).(refr{y}).Duration.(maxresponse_labels{p}{m}).trials{r,g_indx(group)},'omitnan');
                                        outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Approach.(flds{x}).(refr{y}).TimeAll.(maxresponse_labels{p}{m}).mean{r}(g_indx(group),:) = mean(outdata.Bouts.(ProcessData{p}).Approach.(flds{x}).(refr{y}).DLC.(conds{c}).(maxresponse_labels{p}{m}).bouttime.trials{recs(f,r),1},'omitnan');
                                        outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Approach.(flds{x}).(refr{y}).PercAll.(maxresponse_labels{p}{m}).mean{r}(g_indx(group),:) = mean(outdata.Bouts.(ProcessData{p}).Approach.(flds{x}).(refr{y}).DLC.(conds{c}).(maxresponse_labels{p}{m}).boutperc.trials{recs(f,r),1},'omitnan');
                                        outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Approach.(flds{x}).(refr{y}).Time.(maxresponse_labels{p}{m}).mean{r}(g_indx(group),:) = mean(outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Approach.Corr.(flds{x}).(refr{y}).Time.(maxresponse_labels{p}{m}).trials{r,g_indx(group)},'omitnan');
                                        outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Approach.(flds{x}).(refr{y}).Perc.(maxresponse_labels{p}{m}).mean{r}(g_indx(group),:) = mean(outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Approach.Corr.(flds{x}).(refr{y}).Perc.(maxresponse_labels{p}{m}).trials{r,g_indx(group)},'omitnan');
                                        
                                    else
                                        % outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Approach.Corr.(flds{x}).(refr{y}).trialn.(maxresponse_labels{p}{m}). trials {r,g_indx(group)} = [];
                                        % outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Approach.Corr.(flds{x}).(refr{y}).Latency.(maxresponse_labels{p}{m}).trials{r,g_indx(group)} = [];
                                        % outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Approach.Corr.(flds{x}).(refr{y}).Duration.(maxresponse_labels{p}{m}).trials{r,g_indx(group)} = [];
                                        % outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Approach.Corr.(flds{x}).(refr{y}).Time.(maxresponse_labels{p}{m}).trials{r,g_indx(group)} = [];
                                        % outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Approach.Corr.(flds{x}).(refr{y}).Perc.(maxresponse_labels{p}{m}).trials{r,g_indx(group)} = [];

                                        if FPAnalysis
                                        % FPdatatypes = {'peakval','latency','AUC','rise','fall'};
                                        % for xx = 1: length(FPdatatypes)
                                        %     if FPCorrs    
                                        %         for cw = 1:length(FPcorrwin{p})
                                        %         if strcmp(maxresponse_labels{p}{m},FPcorrwin{p}{cw})
                                        %         %outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).Approach.Corr.(flds{x}).(refr{y}).(FPplottype{d}).Peak.(FPdatatypes{xx}).(maxresponse_labels{p}{m}).trials{r,g_indx(group)} = [];
                                        %         outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).Approach.Corr.(flds{x}).(refr{y}).(FPplottype{d}).Peak.(FPdatatypes{xx}).(FPcorrwin{p}{cw}).trials{r,g_indx(group)} = [];                   
                                        %         end
                                        %         end
                                        %     end
                                        % end
                                        eventtimes = {'pre','during','none'};
                                        for et = 1:3
                                        outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).Approach.(flds{x}).(refr{y}).MeanWF_Event.(maxresponse_labels{p}{m}).(eventtimes{et}){r}(g_indx(group),:)= NaN(1,length(outgroup.(Grouplabels{group}).FP.(ProcessData{p}).peaktimearray.All));
                                        end

                                        for et = 1:2
                                        outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).Approach.(flds{x}).(refr{y}).MeanWF_Bout.(maxresponse_labels{p}{m}).(eventtimes{et}){r}(g_indx(group),:) = NaN(1,length(outdata.Bouts.(ProcessData{p}).Approach.(flds{x}).(refr{y}).FP.(conds{c}).(maxresponse_labels{p}{m}).time));
                                        outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).Approach.(flds{x}).(refr{y}).TrialWF_Bout.(maxresponse_labels{p}{m}).(eventtimes{et}){r,g_indx(group)} = [];
                                        end
                                        end
                              
                                        outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Approach.(flds{x}).(refr{y}).Perctrials.(maxresponse_labels{p}{m}).num{r}(g_indx(group),:) = NaN;
                                        outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Approach.(flds{x}).(refr{y}).PerctrialsAll.(maxresponse_labels{p}{m}).num{r}(g_indx(group),:) = NaN;
                                        outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Approach.(flds{x}).(refr{y}).Numevents.(maxresponse_labels{p}{m}).mean{r}(g_indx(group),:) = NaN;
                                        outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Approach.(flds{x}).(refr{y}).Latency.(maxresponse_labels{p}{m}).mean{r}(g_indx(group),:) = NaN;
                                        outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Approach.(flds{x}).(refr{y}).LatencyAll.(maxresponse_labels{p}{m}).mean{r}(g_indx(group),:) = NaN;
                                        outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Approach.(flds{x}).(refr{y}).Duration.(maxresponse_labels{p}{m}).mean{r}(g_indx(group),:) = NaN;
                                        outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Approach.(flds{x}).(refr{y}).TimeAll.(maxresponse_labels{p}{m}).mean{r}(g_indx(group),:) = NaN;
                                        outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Approach.(flds{x}).(refr{y}).PercAll.(maxresponse_labels{p}{m}).mean{r}(g_indx(group),:) = NaN;
                                        outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Approach.(flds{x}).(refr{y}).Time.(maxresponse_labels{p}{m}).mean{r}(g_indx(group),:) = NaN;
                                        outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Approach.(flds{x}).(refr{y}).Perc.(maxresponse_labels{p}{m}).mean{r}(g_indx(group),:) = NaN;
                                    end
                                    end
                                end
                                end

                                %get max DLC data for each win (speed and
                                %move dist
                                if strcmp('AngularVelocity',(DLCmeasures{b}))
                                    %get metrics for correl
                                    %get DLC data for correlations
                                     DLCdatatypes = {'MaxVal','Average','MaxTs'};
                                     FPdatatypes = {'peakval','latency','AUC','rise','fall'};
                                         for m = 1:length(maxresponse_labels{p}) 
                                         if ~isempty(outdata.DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).(refr{y}).Peak.(maxresponse_labels{p}{m}).MaxVal.trials{recs(f,r),1})
                                            for dd = 1:length(DLCdatatypes)
                                            outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).Corr.(flds{x}).(refr{y}).(maxresponse_labels{p}{m}).(DLCdatatypes{dd}).trialn = outdata.perievent.(ProcessData{p}).(conds{c}).trialn{recs(f,r),1};
                                            outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).Corr.(flds{x}).(refr{y}).(maxresponse_labels{p}{m}).(DLCdatatypes{dd}).trials{r,g_indx(group)} = outdata.DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).(refr{y}).Peak.(maxresponse_labels{p}{m}).(DLCdatatypes{dd}).trials{recs(f,r),1};
                                             %get mean
                                            outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).(refr{y}).(DLCdatatypes{dd}).(maxresponse_labels{p}{m}).mean{r}(g_indx(group),:) = mean(outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).Corr.(flds{x}).(refr{y}).(maxresponse_labels{p}{m}).(DLCdatatypes{dd}).trials{r,g_indx(group)},'omitnan');
                                            end
                                            if FPAnalysis && FPCorrs
                                            %get FP data for correlations
                                            for xx = 1: length(FPdatatypes) %#ok<UNRCH>
                                                for cw = 1:length(FPcorrwin{p})
                                                % if strcmp(maxresponse_labels{p}{m},FPcorrwin{p}{cw})
                                                outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).Corr.(flds{x}).(refr{y}).Z_dFF.Peak.(FPdatatypes{xx}).(FPcorrwin{p}{cw}).(maxresponse_labels{p}{m}).trials{r,g_indx(group)} = outdata.perievent.(ProcessData{p}).(conds{c}).Z_dFF.Peak.(FPdatatypes{xx}).(FPcorrwin{p}{cw}).trials{recs(f,r),1};
                                                % end
                                                end
                                            end
                                            end
                                        else 
                                            for dd = 1: length(DLCdatatypes)
                                                % outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).Corr.(flds{x}).(refr{y}).(maxresponse_labels{p}{m}).(DLCdatatypes{dd}).trials{r,g_indx(group)}  = [];
                                                outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).(refr{y}).(DLCdatatypes{dd}).(maxresponse_labels{p}{m}).mean{r}(g_indx(group),:)  = NaN;
                                            end 
                                            % if FPAnalysis
                                            % for xx = 1: length(FPdatatypes) %#ok<UNRCH>
                                            %     if FPCorrs
                                            %     for cw = 1:length(FPcorrwin{p})
                                            %     if strcmp(maxresponse_labels{p}{m},FPcorrwin{p}{cw})
                                            %     outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).Corr.(flds{x}).(refr{y}).(FPplottype{d}).Peak.(FPdatatypes{xx}).(FPcorrwin{p}{cw}).trials{r,g_indx(group)}  = [];
                                            %     end
                                            %     end
                                            %     end
                                            % end
                                            % end
                                         end
                                         end
                                end
                                
                        if paddata %fill in missing values for low sampling rate and save separately
                        padtimearray = outgroup.(Grouplabels{group}).DLC.paddata.padtimearray{r}(g_indx(group),:);
                        padtimearray = padtimearray{p};
                            for m = 1:length(maxresponse_labels{p})
                            outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).(refr{y}).Peak.(maxresponse_labels{p}{m}).int.mean{r}(g_indx(group),:) = outdata.DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).(refr{y}).Peak.(maxresponse_labels{p}{m}).mean((recs(f,r)),:);
                            indxmissing = ~ismember(outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).peaktimearray.(maxresponse_labels{p}{m}),padtimearray); 
                            i = 1:numel(indxmissing);
                            outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).(refr{y}).Peak.(maxresponse_labels{p}{m}).int.mean{r}(g_indx(group),indxmissing) = interp1(i(~indxmissing), outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).(refr{y}).Peak.(maxresponse_labels{p}{m}).int.mean{r}(g_indx(group),~indxmissing),i(indxmissing),'linear');
                            end 
                        end
                            clear paddtimearray
                        end
                 
                                            
                        case 3 %three subfields
                        refr = DLCsubfields.(DLCmeasures{b}){2}{x};
                            for y = 1:length(refr)
                            typ = DLCsubfields.(DLCmeasures{b}){3}{y};
                                for z = 1:length(typ)
                                        for m = 1:length(maxresponse_labels{p})
                                        outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).(refr{y}).(typ{z}).Peak.(maxresponse_labels{p}{m}).mean{r}(g_indx(group),:) = outdata.DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).(refr{y}).(typ{z}).Peak.(maxresponse_labels{p}{m}).mean((recs(f,r)),:);
                                        outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).(refr{y}).(typ{z}).Peak.(maxresponse_labels{p}{m}).sem{r}(g_indx(group),:) = outdata.DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).(refr{y}).(typ{z}).Peak.(maxresponse_labels{p}{m}).sem((recs(f,r)),:);
                                        outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).(refr{y}).(typ{z}).Peak.(maxresponse_labels{p}{m}).int.mean{r}(g_indx(group),:) = outdata.DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).(refr{y}).(typ{z}).Peak.(maxresponse_labels{p}{m}).mean((recs(f,r)),:);
                                        outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).(refr{y}).(typ{z}).Peak.(maxresponse_labels{p}{m}).int.sem{r}(g_indx(group),:) = outdata.DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).(refr{y}).(typ{z}).Peak.(maxresponse_labels{p}{m}).sem((recs(f,r)),:);
                                        end
                                        
                                %% Get  Orient Data
                                if isfield(outdata,'Bouts') 
                                if isfield(outdata.Bouts.(ProcessData{p}),'Orient') && strcmp((DLCmeasures{b}),'Angle')
                                    for m = 1:length(maxresponse_labels{p}) 
                                    %get boutmetrics for correl
                                    %get DLC data for correlations
                                    getdata = true;
                                    if isempty(outdata.Bouts.(ProcessData{p}).Orient.(flds{x}).(refr{y}).DLC.(conds{c}).(maxresponse_labels{p}{m}).latency.trials)
                                        getdata = false;
                                    else
                                        if length(outdata.Bouts.(ProcessData{p}).Orient.(flds{x}).(refr{y}).DLC.(conds{c}).(maxresponse_labels{p}{m}).latency.trials) < recs(f,r) 
                                        getdata = false;
                                        else
                                            if isempty(outdata.Bouts.(ProcessData{p}).Orient.(flds{x}).(refr{y}).DLC.(conds{c}).(maxresponse_labels{p}{m}).latency.trials {recs(f,r),1})
                                                getdata = false;
                                            end
                                        end
                                    end
                                    if getdata
                                        boutindx = outdata.Bouts.(ProcessData{p}).Orient.(flds{x}).(refr{y}).DLC.(conds{c}).(maxresponse_labels{p}{m}).latency.trials{recs(f,r),1} > 0; %only get data for trials where there were bouts for correlations
                                        boutindxall = sum(~isnan(outdata.Bouts.(ProcessData{p}).Orient.(flds{x}).(refr{y}).DLC.(conds{c}).(maxresponse_labels{p}{m}).latency.trials{recs(f,r),1})); % get indx for any trial containing bout in window
                                        totaltrials = sum(~isnan(outdata.Bouts.(ProcessData{p}).Orient.(flds{x}).(refr{y}).DLC.(conds{c}).(maxresponse_labels{p}{m}).numbouts.trials{recs(f,r),1}));
                                        outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Orient.Corr.(flds{x}).(refr{y}).trialn.(maxresponse_labels{p}{m}).trials{r,g_indx(group)} = outdata.perievent.(ProcessData{p}).(conds{c}).trialn{recs(f,r),1}(boutindx);
                                        outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Orient.Corr.(flds{x}).(refr{y}).Latency.(maxresponse_labels{p}{m}).trials{r,g_indx(group)} = outdata.Bouts.(ProcessData{p}).Orient.(flds{x}).(refr{y}).DLC.(conds{c}).(maxresponse_labels{p}{m}).latency.trials{recs(f,r),1}(boutindx);
                                        outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Orient.Corr.(flds{x}).(refr{y}).Duration.(maxresponse_labels{p}{m}).trials{r,g_indx(group)} = outdata.Bouts.(ProcessData{p}).Orient.(flds{x}).(refr{y}).DLC.(conds{c}).(maxresponse_labels{p}{m}).duration.trials{recs(f,r),1}(boutindx);
                                        outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Orient.Corr.(flds{x}).(refr{y}).Time.(maxresponse_labels{p}{m}).trials{r,g_indx(group)} = outdata.Bouts.(ProcessData{p}).Orient.(flds{x}).(refr{y}).DLC.(conds{c}).(maxresponse_labels{p}{m}).bouttime.trials{recs(f,r),1}(boutindx);
                                        outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Orient.Corr.(flds{x}).(refr{y}).Perc.(maxresponse_labels{p}{m}).trials{r,g_indx(group)} = outdata.Bouts.(ProcessData{p}).Orient.(flds{x}).(refr{y}).DLC.(conds{c}).(maxresponse_labels{p}{m}).boutperc.trials{recs(f,r),1}(boutindx);                                       
                                        
                                        if sum(boutindx) == 0
                                        %outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Orient.Corr.(flds{x}).(refr{y}).Latency.(maxresponse_labels{p}{m}).trials{r,g_indx(group)} = NaN;
                                        %outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Orient.Corr.Latency.(maxresponse_labels{p}{m}).trials{r,g_indx(group)} = NaN;
                                        end      
                                        if FPAnalysis
                                        %get FP data for correlations
                                        FPdatatypes = {'peakval','latency','AUC','rise','fall'};
                                            for xx = 1: length(FPdatatypes)
                                                if FPCorrs
                                                    for cw = 1:length(FPcorrwin{p})
                                                % if strcmp(maxresponse_labels{p}{m},FPcorrwin{p}{cw})
                                                outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).Orient.Corr.(flds{x}).(refr{y}).Z_dFF.Peak.(FPdatatypes{xx}).(FPcorrwin{p}{cw}).(maxresponse_labels{p}{m}).trials{r,g_indx(group)} = outdata.perievent.(ProcessData{p}).(conds{c}).Z_dFF.Peak.(FPdatatypes{xx}).(FPcorrwin{p}{cw}).trials{recs(f,r),1}(boutindx);
                                                %outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).Orient.Corr.Z_dFF.Peak.(FPdatatypes{xx}).(maxresponse_labels{p}{m}).trials{r,g_indx(group)} = outdata.perievent.(ProcessData{p}).(conds{c}).Z_dFF.Peak.(FPdatatypes{xx}).(FPcorrwin{p}).trials{recs(f,r),1}(boutindx);
                                                % end 
                                                    end
                                                end
                                            end
                                        eventtimes = {'pre','during','none'};
                                        wflength = size(outdata.timearray.(ProcessData{p}).FP.perievent{recs(f,r),1},2);
                                            for et = 1:3
                                                if isfield(outdata.Bouts.(ProcessData{p}).Orient.(flds{x}).(refr{y}).FP.(conds{c}).(maxresponse_labels{p}{m}).Z_dFF.trials{recs(f,r),1},(eventtimes{et}))
                                                    if size(outdata.Bouts.(ProcessData{p}).Orient.(flds{x}).(refr{y}).FP.(conds{c}).(maxresponse_labels{p}{m}).Z_dFF.trials{recs(f,r),1}.(eventtimes{et}),1) > 1 %if there are enough trials to average get data
                                                        outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).Orient.(flds{x}).(refr{y}).MeanWF_Event.(maxresponse_labels{p}{m}).(eventtimes{et}){r}(g_indx(group),:) =  mean(outdata.Bouts.(ProcessData{p}).Orient.(flds{x}).(refr{y}).FP.(conds{c}).(maxresponse_labels{p}{m}).Z_dFF.trials{recs(f,r),1}.(eventtimes{et}),'omitnan');
                                                    else
                                                        outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).Orient.(flds{x}).(refr{y}).MeanWF_Event.(maxresponse_labels{p}{m}).(eventtimes{et}){r}(g_indx(group),:)= nan(1,wflength);
                                                    end
                                                else
                                                    outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).Orient.(flds{x}).(refr{y}).MeanWF_Event.(maxresponse_labels{p}{m}).(eventtimes{et}){r}(g_indx(group),:)= nan(1,wflength);
                                                end
                                            end

                                            for et = 1:2                     
                                            if isfield(outdata.Bouts.(ProcessData{p}).Orient.(flds{x}).(refr{y}).FP.(conds{c}).(maxresponse_labels{p}{m}).zscored,(eventtimes{et})) %if there are data for the window
                                            tracelength = length(outdata.Bouts.(ProcessData{p}).Orient.(flds{x}).(refr{y}).FP.(conds{c}).(maxresponse_labels{p}{m}).time);
                                            outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).Orient.(flds{x}).(refr{y}).MeanWF_Bout.time = outdata.Bouts.(ProcessData{p}).Orient.(flds{x}).(refr{y}).FP.(conds{c}).(maxresponse_labels{p}{m}).time;
                                            if sum(isnan(outdata.Bouts.(ProcessData{p}).Orient.(flds{x}).(refr{y}).FP.(conds{c}).(maxresponse_labels{p}{m}).zscored.(eventtimes{et}).mean{recs(f,r),1})) == length(outdata.Bouts.(ProcessData{p}).Orient.(flds{x}).(refr{y}).FP.(conds{c}).(maxresponse_labels{p}{m}).zscored.(eventtimes{et}).mean{recs(f,r),1})
                                            outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).Orient.(flds{x}).(refr{y}).MeanWF_Bout.(maxresponse_labels{p}{m}).(eventtimes{et}){r}(g_indx(group),:) = NaN(1,tracelength);
                                            else
                                            outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).Orient.(flds{x}).(refr{y}).MeanWF_Bout.(maxresponse_labels{p}{m}).(eventtimes{et}){r}(g_indx(group),:) = outdata.Bouts.(ProcessData{p}).Orient.(flds{x}).(refr{y}).FP.(conds{c}).(maxresponse_labels{p}{m}).zscored.(eventtimes{et}).mean{recs(f,r),1};
                                            end
                                            
                                            if sum(isnan(outdata.Bouts.(ProcessData{p}).Orient.(flds{x}).(refr{y}).FP.(conds{c}).(maxresponse_labels{p}{m}).zscored.(eventtimes{et}).mean{recs(f,r),1})) == length(outdata.Bouts.(ProcessData{p}).Orient.(flds{x}).(refr{y}).FP.(conds{c}).(maxresponse_labels{p}{m}).zscored.(eventtimes{et}).mean{recs(f,r),1})
                                            outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).Orient.(flds{x}).(refr{y}).TrialWF_Bout.(maxresponse_labels{p}{m}).(eventtimes{et}){r,g_indx(group)} = NaN(1,tracelength);
                                            else
                                            if length(outdata.Bouts.(ProcessData{p}).Orient.(flds{x}).(refr{y}).FP.(conds{c}).(maxresponse_labels{p}{m}).zscored.trials) >= recs(f,r)
                                            outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).Orient.(flds{x}).(refr{y}).TrialWF_Bout.(maxresponse_labels{p}{m}).(eventtimes{et}){r,g_indx(group)} = outdata.Bouts.(ProcessData{p}).Orient.(flds{x}).(refr{y}).FP.(conds{c}).(maxresponse_labels{p}{m}).zscored.trials{recs(f,r),1}.(eventtimes{et});
                                            end
                                            end
                                            end
                                            end
                       
                                        end
                                        %get mean
                                        outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Orient.(flds{x}).(refr{y}).Perctrials.(maxresponse_labels{p}{m}).num{r}(g_indx(group),:) = (sum(boutindx)/totaltrials)*100;
                                        outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Orient.(flds{x}).(refr{y}).PerctrialsAll.(maxresponse_labels{p}{m}).num{r}(g_indx(group),:) = (sum(boutindxall)/totaltrials)*100;
                                        outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Orient.(flds{x}).(refr{y}).Numevents.(maxresponse_labels{p}{m}).mean{r}(g_indx(group),:) = mean(outdata.Bouts.(ProcessData{p}).Orient.(flds{x}).(refr{y}).DLC.(conds{c}).(maxresponse_labels{p}{m}).numbouts.trials{recs(f,r),1}(boutindx),'omitnan');
                                        outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Orient.(flds{x}).(refr{y}).Latency.(maxresponse_labels{p}{m}).mean{r}(g_indx(group),:) = mean(outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Orient.Corr.(flds{x}).(refr{y}).Latency.(maxresponse_labels{p}{m}).trials{r,g_indx(group)},'omitnan');
                                        outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Orient.(flds{x}).(refr{y}).LatencyAll.(maxresponse_labels{p}{m}).mean{r}(g_indx(group),:) = mean(outdata.Bouts.(ProcessData{p}).Orient.(flds{x}).(refr{y}).DLC.(conds{c}).(maxresponse_labels{p}{m}).latency.trials{recs(f,r),1},'omitnan');
                                        outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Orient.(flds{x}).(refr{y}).Duration.(maxresponse_labels{p}{m}).mean{r}(g_indx(group),:) = mean(outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Orient.Corr.(flds{x}).(refr{y}).Duration.(maxresponse_labels{p}{m}).trials{r,g_indx(group)},'omitnan');
                                        outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Orient.(flds{x}).(refr{y}).TimeAll.(maxresponse_labels{p}{m}).mean{r}(g_indx(group),:) = mean(outdata.Bouts.(ProcessData{p}).Orient.(flds{x}).(refr{y}).DLC.(conds{c}).(maxresponse_labels{p}{m}).bouttime.trials{recs(f,r),1},'omitnan');
                                        outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Orient.(flds{x}).(refr{y}).PercAll.(maxresponse_labels{p}{m}).mean{r}(g_indx(group),:) = mean(outdata.Bouts.(ProcessData{p}).Orient.(flds{x}).(refr{y}).DLC.(conds{c}).(maxresponse_labels{p}{m}).boutperc.trials{recs(f,r),1},'omitnan');
                                        outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Orient.(flds{x}).(refr{y}).Time.(maxresponse_labels{p}{m}).mean{r}(g_indx(group),:) = mean(outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Orient.Corr.(flds{x}).(refr{y}).Time.(maxresponse_labels{p}{m}).trials{r,g_indx(group)},'omitnan');
                                        outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Orient.(flds{x}).(refr{y}).Perc.(maxresponse_labels{p}{m}).mean{r}(g_indx(group),:) = mean(outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Orient.Corr.(flds{x}).(refr{y}).Perc.(maxresponse_labels{p}{m}).trials{r,g_indx(group)},'omitnan');
                                        
                                    else   
                                        % outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Orient.Corr.(flds{x}).(refr{y}).trialn.(maxresponse_labels{p}{m}).trials{r,g_indx(group)} = [];
                                        % outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Orient.Corr.(flds{x}).(refr{y}).Latency.(maxresponse_labels{p}{m}).trials{r,g_indx(group)} = [];
                                        % outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Orient.Corr.(flds{x}).(refr{y}).Duration.(maxresponse_labels{p}{m}).trials{r,g_indx(group)} = [];
                                        % outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Orient.Corr.(flds{x}).(refr{y}).Time.(maxresponse_labels{p}{m}).trials{r,g_indx(group)} = [];
                                        % outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Orient.Corr.(flds{x}).(refr{y}).Perc.(maxresponse_labels{p}{m}).trials{r,g_indx(group)} = [];
                                       
                                        if FPAnalysis
                                        FPdatatypes = {'peakval','latency','AUC','rise','fall'};
                                        % if FPCorrs 
                                        %     if FPCorrs
                                        %     for xx = 1: length(FPdatatypes)
                                        %         for cw = 1:length(FPcorrwin{p})
                                        %         if strcmp(maxresponse_labels{p}{m},FPcorrwin{p}{cw})
                                        %         outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).Orient.Corr.(flds{x}).(refr{y}).Z_dFF.Peak.(FPdatatypes{xx}).(FPcorrwin{p}{cw}).trials{r,g_indx(group)} = [];
                                        %         %outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).Approach.Orient.Z_dFF.Peak.(FPdatatypes{xx}).(maxresponse_labels{p}{m}).trials{r,g_indx(group)} = [];
                                        %         end
                                        %          end
                                        %     end
                                        %     end
                                        % end
                                        eventtimes = {'pre','during','none'};
                                        for et = 1:3
                                        outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).Orient.(flds{x}).(refr{y}).MeanWF_Event.(maxresponse_labels{p}{m}).(eventtimes{et}){r}(g_indx(group),:)= NaN(1,length(outgroup.(Grouplabels{group}).FP.(ProcessData{p}).peaktimearray.All));
                                        end
                                        for et = 1:2
                                        outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).Orient.(flds{x}).(refr{y}).MeanWF_Bout.(maxresponse_labels{p}{m}).(eventtimes{et}){r}(g_indx(group),:) = NaN(1,length(outdata.Bouts.(ProcessData{p}).Orient.(flds{x}).(refr{y}).FP.(conds{c}).(maxresponse_labels{p}{m}).time));
                                        outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).Orient.(flds{x}).(refr{y}).TrialWF_Bout.(maxresponse_labels{p}{m}).(eventtimes{et}){r,g_indx(group)} = [];
                                        end
                                        end
                                        outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Orient.(flds{x}).(refr{y}).Perctrials.(maxresponse_labels{p}{m}).num{r}(g_indx(group),:) = NaN;
                                        outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Orient.(flds{x}).(refr{y}).PerctrialsAll.(maxresponse_labels{p}{m}).num{r}(g_indx(group),:) = NaN;
                                        outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Orient.(flds{x}).(refr{y}).Numevents.(maxresponse_labels{p}{m}).mean{r}(g_indx(group),:) = NaN;
                                        outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Orient.(flds{x}).(refr{y}).Latency.(maxresponse_labels{p}{m}).mean{r}(g_indx(group),:) = NaN;
                                        outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Orient.(flds{x}).(refr{y}).LatencyAll.(maxresponse_labels{p}{m}).mean{r}(g_indx(group),:) = NaN;
                                        outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Orient.(flds{x}).(refr{y}).Duration.(maxresponse_labels{p}{m}).mean{r}(g_indx(group),:) = NaN;
                                        outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Orient.(flds{x}).(refr{y}).TimeAll.(maxresponse_labels{p}{m}).mean{r}(g_indx(group),:) = NaN;
                                        outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Orient.(flds{x}).(refr{y}).PercAll.(maxresponse_labels{p}{m}).mean{r}(g_indx(group),:) = NaN;
                                        outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Orient.(flds{x}).(refr{y}).Time.(maxresponse_labels{p}{m}).mean{r}(g_indx(group),:) = NaN;
                                        outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Orient.(flds{x}).(refr{y}).Perc.(maxresponse_labels{p}{m}).mean{r}(g_indx(group),:) = NaN;
                                    end
                                    end
                                end
                                end

                                    if paddata %fill in missing values for low sampling rate and save separately
                                    padtimearray = outgroup.(Grouplabels{group}).DLC.paddata.padtimearray{r}(g_indx(group),:);
                                    padtimearray = padtimearray{p};
                                    for m = 1:length(maxresponse_labels{p})
                                    outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).(refr{y}).(typ{z}).Peak.(maxresponse_labels{p}{m}).int.mean{r,g_indx(group)} = outdata.DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).(refr{y}).(typ{z}).Peak.(maxresponse_labels{p}{m}).mean((recs(f,r)),:);
                                    indxmissing = ~ismember(outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).peaktimearray.(maxresponse_labels{p}{m}),padtimearray); 
                                    i = 1:numel(indxmissing);
                                    outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).(refr{y}).(typ{z}).Peak.(maxresponse_labels{p}{m}).int.mean{r,g_indx(group)}(:,indxmissing)= interp1(i(~indxmissing), outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).(refr{y}).(typ{z}).Peak.(maxresponse_labels{p}{m}).int.mean{r,g_indx(group)}(i(~indxmissing)),i(indxmissing),'linear');
                                    end 
                                    end
                                    clear paddtimearray
                                    end
                            end
                    end
                    end
                    end
                    
%                     for m = 1:length(maxresponse_labels{p})
%                     outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).PolarPlot.(maxresponse_labels{p}{m}).trials.int{r,g_indx(group)}= outdata.DLC.(ProcessData{p}).(conds{c}).Angle.Cue.ItoNT.degrees_180.Peak.(maxresponse_labels{p}{m}).trials{(recs(f,r)),1};
%                     %polar plot data
%                     if paddata %fill in missing values for low sampling rate and save separately
%                     indxmissing = false(1, size(outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).PolarPlot.(maxresponse_labels{p}{m}).trials.int{r,g_indx(group)},2));
%                     indxmissing(2:2:end) = true;
%                     i = 1:numel(indxmissing);
%                     for t = 1:size(outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).PolarPlot.(maxresponse_labels{p}{m}).trials.int{r,g_indx(group)},1)
%                     outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).PolarPlot.(maxresponse_labels{p}{m}).trials.int{r,g_indx(group)}(t,i(indxmissing))= interp1(i(~indxmissing), outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).PolarPlot.(maxresponse_labels{p}{m}).trials.int{r,g_indx(group)}(t,i(~indxmissing)),i(1,indxmissing),'linear');
%                     end 
%                     end
%                     clear paddtimearray
%                     end
                    end
      
                    
                else % if this recording should be skipped then put NaN instead of data
                    if FPAnalysis
                        for m = 1:length(maxresponse_labels{p}) %get maxresponses 
                            for d = 1:length(FPplottype)
                            outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).(FPplottype{d}).Peak.MeanTrace.trace.(maxresponse_labels{p}{m}){r}(g_indx(group),:)= NaN(1,length(outgroup.(Grouplabels{group}).FP.(ProcessData{p}).peaktimearray.(maxresponse_labels{p}{m})));
                            %        outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).(FPplottype{d}).Peak.MeanTrace.trace.(maxresponse_labels{p}{m}).sem{r}(g_indx(group),:) = NaN(1,length(outgroup.(Grouplabels{group}).FP.(ProcessData{p}).peaktimearray.(maxresponse_labels{p}{m})));
                            outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).(FPplottype{d}).Peak.MeanTrace.PeakVal.(maxresponse_labels{p}{m}){r}(g_indx(group),:) = NaN;
                            outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).(FPplottype{d}).Peak.MeanTrace.Latency.(maxresponse_labels{p}{m}){r}(g_indx(group),:) = NaN;    
                            outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).(FPplottype{d}).Peak.MeanTrace.Indx.(maxresponse_labels{p}{m}){r}(g_indx(group),:) = NaN;
                            outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).(FPplottype{d}).Peak.MeanTrace.AUC.(maxresponse_labels{p}{m}){r}(g_indx(group),:) = NaN;
                            outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).(FPplottype{d}).Peak.MeanTrace.RiseSlope.(maxresponse_labels{p}{m}){r}(g_indx(group),:) = NaN;
                            outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).(FPplottype{d}).Peak.MeanTrace.FallSlope.(maxresponse_labels{p}{m}){r}(g_indx(group),:) = NaN;
                            outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).(FPplottype{d}).Trough.MeanTrace.PeakVal.(maxresponse_labels{p}{m}){r}(g_indx(group),:) = NaN;
                            outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).(FPplottype{d}).Trough.MeanTrace.Latency.(maxresponse_labels{p}{m}){r}(g_indx(group),:) = NaN;    
                            outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).(FPplottype{d}).Trough.MeanTrace.Indx.(maxresponse_labels{p}{m}){r}(g_indx(group),:) = NaN;
                            outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).(FPplottype{d}).Trough.MeanTrace.AUC.(maxresponse_labels{p}{m}){r}(g_indx(group),:) = NaN;
                            outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).(FPplottype{d}).Trough.MeanTrace.RiseSlope.(maxresponse_labels{p}{m}){r}(g_indx(group),:) = NaN;
                            outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).(FPplottype{d}).Trough.MeanTrace.FallSlope.(maxresponse_labels{p}{m}){r}(g_indx(group),:) = NaN;
                            outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).(FPplottype{d}).Peak.MeanTrace.AverageFP.(maxresponse_labels{p}{m}){r}(g_indx(group),:) = NaN;
                            outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).(FPplottype{d}).Trough.MeanTrace.AverageFP.(maxresponse_labels{p}{m}){r}(g_indx(group),:)= NaN;
                            end
                        end
                    end

                    if DLCanalysis   

                    % Get Quadrant Data               
                    if isfield (DLCsubfields,'Quadrant')
                    Quadrant = {'LT','LB','RT','RB'};
                    qbps = DLCsubfields.Quadrant{1};
                    for bp = 1:length(qbps)
                    for m = 1:length(maxresponse_labels{p})                  
                        for q = 1:4
                            outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Quadrant.(qbps{bp}).(Quadrant{q}).Peak.(maxresponse_labels{p}{m}).mean{r}(g_indx(group),:) = NaN;
                            outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Quadrant.(qbps{bp}).(Quadrant{q}).Peak.(maxresponse_labels{p}{m}).sem{r}(g_indx(group),:) = NaN;
                        end
                    end
                    end
                    end

                    if isfield(outdata,'Bouts')
                    bouttypes = {'Locomotion','Freeze'};
                    for bt = 1:length(bouttypes)
                    if isfield(outdata.Bouts.(ProcessData{p}),(bouttypes{bt}))   
                    for m = 1:length(maxresponse_labels{p})
                            % outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).(bouttypes{bt}).Corr.trialn.(maxresponse_labels{p}{m}).trials{r,g_indx(group)} = [];
                            % outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).(bouttypes{bt}).Corr.Latency.(maxresponse_labels{p}{m}).trials{r,g_indx(group)} = [];
                            % outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).(bouttypes{bt}).Corr.Duration.(maxresponse_labels{p}{m}).trials{r,g_indx(group)} = [];
                            % outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).(bouttypes{bt}).Corr.Time.(maxresponse_labels{p}{m}).trials{r,g_indx(group)} = [];
                            % outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).(bouttypes{bt}).Corr.Perc.(maxresponse_labels{p}{m}).trials{r,g_indx(group)} = [];
                            % if FPAnalysis
                            % FPdatatypes = {'peakval','latency','AUC','rise','fall'}; 
                            % for x = 1: length(FPdatatypes)
                            % outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).(bouttypes{bt}).Corr.Z_dFF.Peak.(FPdatatypes{x}).(maxresponse_labels{p}{m}).trials{r,g_indx(group)} = [];
                            % end
                            % end
                            outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).(bouttypes{bt}).Perctrials.(maxresponse_labels{p}{m}).num{r}(g_indx(group),:) = NaN;
                            outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).(bouttypes{bt}).PerctrialsAll.(maxresponse_labels{p}{m}).num{r}(g_indx(group),:) = NaN;
                            outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).(bouttypes{bt}).Numevents.(maxresponse_labels{p}{m}).mean{r}(g_indx(group),:) = NaN;
                            outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).(bouttypes{bt}).Latency.(maxresponse_labels{p}{m}).mean{r}(g_indx(group),:) = NaN;
                            outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).(bouttypes{bt}).LatencyAll.(maxresponse_labels{p}{m}).mean{r}(g_indx(group),:) = NaN;
                            outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).(bouttypes{bt}).Duration.(maxresponse_labels{p}{m}).mean{r}(g_indx(group),:) = NaN;
                            outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).(bouttypes{bt}).TimeAll.(maxresponse_labels{p}{m}).mean{r}(g_indx(group),:) = NaN;                          
                            outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).(bouttypes{bt}).PercAll.(maxresponse_labels{p}{m}).mean{r}(g_indx(group),:) = NaN;
                            outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).(bouttypes{bt}).Time.(maxresponse_labels{p}{m}).mean{r}(g_indx(group),:) = NaN;                          
                            outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).(bouttypes{bt}).Perc.(maxresponse_labels{p}{m}).mean{r}(g_indx(group),:) = NaN;
                       if FPAnalysis
                       eventtimes = {'pre','during','none'};
                       for et = 1:3
                       outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).(bouttypes{bt}).MeanWF_Event.(maxresponse_labels{p}{m}).(eventtimes{et}){r}(g_indx(group),:)= NaN(1,length(outgroup.(Grouplabels{group}).FP.(ProcessData{p}).peaktimearray.All));
                       end

                       for et = 1:2
                       outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).(bouttypes{bt}).MeanWF_Bout.(maxresponse_labels{p}{m}).(eventtimes{et}){r}(g_indx(group),:) = NaN(1,length(outdata.Bouts.(ProcessData{p}).(bouttypes{bt}).FP.(conds{c}).(maxresponse_labels{p}{m}).time));
                       outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).(bouttypes{bt}).TrialWF_Bout.(maxresponse_labels{p}{m}).(eventtimes{et}){r,g_indx(group)} = [];
                       end
                       end
                        % outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).(bouttypes{bt}).Corr.Latency.(maxresponse_labels{p}{m}).trials{r,g_indx(group)} = NaN;  
                    end
                    end
                    end
                    end
                                    
                        arraysize = length(outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).time);
                        for b = 1:length(DLCmeasures)
                        numsubfields = length(DLCsubfields.(DLCmeasures{b}));
                        flds = DLCsubfields.(DLCmeasures{b}){1};
                            for x =1:length(flds)
                            switch numsubfields
                            case 1 %one subfield
                                for m = 1:length(maxresponse_labels{p})
                                    peakarraysize = length(outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).peaktimearray.(maxresponse_labels{p}{m}));
                                    outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).Peak.(maxresponse_labels{p}{m}).mean{r}(g_indx(group),:) = NaN(1,peakarraysize);
                                    outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).Peak.(maxresponse_labels{p}{m}).sem{r}(g_indx(group),:) =NaN(1,peakarraysize);
                                    outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).Peak.(maxresponse_labels{p}{m}).int.mean{r}(g_indx(group),:) = NaN(1,peakarraysize);
                                    outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).Peak.(maxresponse_labels{p}{m}).int.sem{r}(g_indx(group),:) =NaN(1,peakarraysize);  
                                end
                                
                                    if strcmp('Speed',(DLCmeasures{b})) || strcmp('MoveDist',(DLCmeasures{b})) 
                                    %get metrics for correl
                                    %get DLC data for correlations
                                     DLCdatatypes = {'MaxVal','Average','MaxTs'};
                                     FPdatatypes = {'peakval','latency','AUC','rise','fall'};
                                        for m = 1:length(maxresponse_labels{p}) %Get only data for 1 and 2s post cue 
                                            for dd = 1: length(DLCdatatypes)
                                                % outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).Corr.(flds{x}).(maxresponse_labels{p}{m}).(DLCdatatypes{dd}).trials{r,g_indx(group)}  = [];
                                                outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).(DLCdatatypes{dd}).(maxresponse_labels{p}{m}).mean{r}(g_indx(group),:)  = NaN;
                                            end  
                                            % if FPAnalysis
                                            % for xx = 1: length(FPdatatypes)
                                            %     outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).Corr.(flds{x}).Z_dFF.Peak.(FPdatatypes{xx}).(maxresponse_labels{p}{m}).trials{r,g_indx(group)}  = [];
                                            % end
                                            % end
                                        end
                                    end

                                            
                            case 2 %two subfields
                            refr = DLCsubfields.(DLCmeasures{b}){2}{x};
                            for y = 1:length(refr)
                                    for m = 1:length(maxresponse_labels{p})
                                    peakarraysize = length(outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).peaktimearray.(maxresponse_labels{p}{m}));
                                    outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).(refr{y}).Peak.(maxresponse_labels{p}{m}).mean{r}(g_indx(group),:) = NaN(1,peakarraysize);
                                    outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).(refr{y}).Peak.(maxresponse_labels{p}{m}).sem{r}(g_indx(group),:) = NaN(1,peakarraysize);
                                    outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).(refr{y}).Peak.(maxresponse_labels{p}{m}).int.mean{r}(g_indx(group),:) = NaN(1,peakarraysize);
                                    outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).(refr{y}).Peak.(maxresponse_labels{p}{m}).int.sem{r}(g_indx(group),:) = NaN(1,peakarraysize);
                                    end

                                    if strcmp('AngularVelocity',(DLCmeasures{b})) 
                                    %get metrics for correl
                                    %get DLC data for correlations
                                     DLCdatatypes = {'MaxVal','Average','MaxTs'};
                                     FPdatatypes = {'peakval','latency','AUC','rise','fall'};
                                        for m = 1:length(maxresponse_labels{p}) %Get only data for 1 and 2s post cue 
                                            for dd = 1: length(DLCdatatypes)
                                                % outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).Corr.(flds{x}).(refr{y}).(maxresponse_labels{p}{m}).(DLCdatatypes{dd}).trials{r,g_indx(group)}  = [];
                                                outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).(refr{y}).(DLCdatatypes{dd}).(maxresponse_labels{p}{m}).mean{r}(g_indx(group),:)  = NaN;
                                            end  
                                            % if FPAnalysis 
                                            % for xx = 1: length(FPdatatypes)
                                            %     outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).Corr.(flds{x}).(refr{y}).Z_dFF.Peak.(FPdatatypes{xx}).(maxresponse_labels{p}{m}).trials{r,g_indx(group)}  = [];
                                            % end
                                            % end
                                        end
                                    end
                                
                                % Get Approach Data
                                if isfield(outdata,'Bouts')
                                if isfield(outdata.Bouts.(ProcessData{p}),'Approach') && strcmp((DLCmeasures{b}),'DistTo')
                                    %get boutmetrics for correl
                                    %get DLC data for correlations
                                    for m = 1:length(maxresponse_labels{p}) %Get only data for 1 and 2s post cue
                                        % outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Approach.Corr.(flds{x}).(refr{y}).trialn.(maxresponse_labels{p}{m}). trials {r,g_indx(group)} = [];
                                        % outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Approach.Corr.(flds{x}).(refr{y}).Latency.(maxresponse_labels{p}{m}).trials{r,g_indx(group)} = [];
                                        % outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Approach.Corr.(flds{x}).(refr{y}).Duration.(maxresponse_labels{p}{m}).trials{r,g_indx(group)} = [];
                                        % outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Approach.Corr.(flds{x}).(refr{y}).Time.(maxresponse_labels{p}{m}).trials{r,g_indx(group)} = [];
                                        % outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Approach.Corr.(flds{x}).(refr{y}).Perc.(maxresponse_labels{p}{m}).trials{r,g_indx(group)} = [];
                                        if FPAnalysis
                                        % FPdatatypes = {'peakval','latency','AUC','rise','fall'};
                                        % if FPCorrs
                                        %     for xx = 1: length(FPdatatypes)
                                        %         outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).Approach.Corr.(flds{x}).(refr{y}).Z_dFF.Peak.(FPdatatypes{xx}).(maxresponse_labels{p}{m}).trials{r,g_indx(group)} = [];
                                        %     end
                                        % end
                                           eventtimes = {'pre','during','none'};
                                           for et = 1:3
                                           outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).Approach.(flds{x}).(refr{y}).MeanWF_Event.(maxresponse_labels{p}{m}).(eventtimes{et}){r}(g_indx(group),:)= NaN(1,length(outgroup.(Grouplabels{group}).FP.(ProcessData{p}).peaktimearray.All));
                                           end
                                           for et = 1:2
                                           outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).Approach.(flds{x}).(refr{y}).MeanWF_Bout.(maxresponse_labels{p}{m}).(eventtimes{et}){r}(g_indx(group),:) = NaN(1,length(outdata.Bouts.(ProcessData{p}).Approach.(flds{x}).(refr{y}).FP.(conds{c}).(maxresponse_labels{p}{m}).time));
                                           outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).Approach.(flds{x}).(refr{y}).TrialWF_Bout.(maxresponse_labels{p}{m}).(eventtimes{et}){r,g_indx(group)} = [];
                                           end
                                        end
                                        outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Approach.(flds{x}).(refr{y}).Perctrials.(maxresponse_labels{p}{m}).num{r}(g_indx(group),:) = NaN;
                                        outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Approach.(flds{x}).(refr{y}).PerctrialsAll.(maxresponse_labels{p}{m}).num{r}(g_indx(group),:) = NaN;
                                        outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Approach.(flds{x}).(refr{y}).Numevents.(maxresponse_labels{p}{m}).mean{r}(g_indx(group),:) = NaN;
                                        outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Approach.(flds{x}).(refr{y}).Latency.(maxresponse_labels{p}{m}).mean{r}(g_indx(group),:) = NaN;
                                        outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Approach.(flds{x}).(refr{y}).LatencyAll.(maxresponse_labels{p}{m}).mean{r}(g_indx(group),:) = NaN;
                                        outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Approach.(flds{x}).(refr{y}).Duration.(maxresponse_labels{p}{m}).mean{r}(g_indx(group),:) = NaN;
                                        outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Approach.(flds{x}).(refr{y}).TimeAll.(maxresponse_labels{p}{m}).mean{r}(g_indx(group),:) = NaN;
                                        outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Approach.(flds{x}).(refr{y}).PercAll.(maxresponse_labels{p}{m}).mean{r}(g_indx(group),:) = NaN;
                                        outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Approach.(flds{x}).(refr{y}).Time.(maxresponse_labels{p}{m}).mean{r}(g_indx(group),:) = NaN;
                                        outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Approach.(flds{x}).(refr{y}).Perc.(maxresponse_labels{p}{m}).mean{r}(g_indx(group),:) = NaN;
                                    end
                                end
                                end
                            end
                                            
                            case 3 %three subfields
                            refr = DLCsubfields.(DLCmeasures{b}){2}{x};
                            for y = 1:length(refr)
                                typ = DLCsubfields.(DLCmeasures{b}){3}{y};
                                for z = 1:length(typ)
                                    for m = 1:length(maxresponse_labels{p})
                                        peakarraysize = length(outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).peaktimearray.(maxresponse_labels{p}{m}));
                                        outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).(refr{y}).(typ{z}).Peak.(maxresponse_labels{p}{m}).mean{r}(g_indx(group),:) = NaN(1,peakarraysize);
                                        outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).(refr{y}).(typ{z}).Peak.(maxresponse_labels{p}{m}).sem{r}(g_indx(group),:) = NaN(1,peakarraysize);
                                        outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).(refr{y}).(typ{z}).Peak.(maxresponse_labels{p}{m}).int.mean{r}(g_indx(group),:) = NaN(1,peakarraysize);
                                        outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).(refr{y}).(typ{z}).Peak.(maxresponse_labels{p}{m}).int.sem{r}(g_indx(group),:) = NaN(1,peakarraysize);
                                        if z == 1
                                        outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).PolarPlot.(maxresponse_labels{p}{m}).trials.int{r,g_indx(group)} =  [];
                                        end
                                    end
                                    %% Get  Orient Data
                                if isfield(outdata,'Bouts')
                                if isfield(outdata.Bouts.(ProcessData{p}),'Orient')
                                    for m = 1:length(maxresponse_labels{p}) %Get only data for 1 and 2s post cue
                                    %get boutmetrics for correl
                                    %get DLC data for correlations   
                                        % outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Orient.Corr.(flds{x}).(refr{y}).trialn.(maxresponse_labels{p}{m}).trials{r,g_indx(group)} = [];
                                        % outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Orient.Corr.(flds{x}).(refr{y}).Latency.(maxresponse_labels{p}{m}).trials{r,g_indx(group)} = [];
                                        % outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Orient.Corr.(flds{x}).(refr{y}).Duration.(maxresponse_labels{p}{m}).trials{r,g_indx(group)} = [];
                                        % outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Orient.Corr.(flds{x}).(refr{y}).Time.(maxresponse_labels{p}{m}).trials{r,g_indx(group)} = [];
                                        % outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Orient.Corr.(flds{x}).(refr{y}).Perc.(maxresponse_labels{p}{m}).trials{r,g_indx(group)} = [];
                                        if FPAnalysis
                                        % FPdatatypes = {'peakval','latency','AUC','rise','fall'};
                                        % if FPCorrs
                                        %     for xx = 1: length(FPdatatypes)
                                        %         outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).Orient.Corr.(flds{x}).(refr{y}).Z_dFF.Peak.(FPdatatypes{xx}).(maxresponse_labels{p}{m}).trials{r,g_indx(group)} = [];
                                        %     end
                                        % end
                                        eventtimes = {'pre','during','none'};
                                           for et = 1:3
                                           outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).Orient.(flds{x}).(refr{y}).MeanWF_Event.(maxresponse_labels{p}{m}).(eventtimes{et}){r}(g_indx(group),:)= NaN(1,length(outgroup.(Grouplabels{group}).FP.(ProcessData{p}).peaktimearray.All));
                                           end
                                           for et = 1:2
                                           outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).Orient.(flds{x}).(refr{y}).MeanWF_Bout.(maxresponse_labels{p}{m}).(eventtimes{et}){r}(g_indx(group),:) = NaN(1,length(outdata.Bouts.(ProcessData{p}).Orient.(flds{x}).(refr{y}).FP.(conds{c}).(maxresponse_labels{p}{m}).time));
                                           outgroup.(Grouplabels{group}).FP.(ProcessData{p}).(conds{c}).Orient.(flds{x}).(refr{y}).TrialWF_Bout.(maxresponse_labels{p}{m}).(eventtimes{et}){r,g_indx(group)} = [];
                                           end
                                        end
                                        outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Orient.(flds{x}).(refr{y}).Perctrials.(maxresponse_labels{p}{m}).num{r}(g_indx(group),:) = NaN;
                                        outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Orient.(flds{x}).(refr{y}).PerctrialsAll.(maxresponse_labels{p}{m}).num{r}(g_indx(group),:) = NaN;
                                        outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Orient.(flds{x}).(refr{y}).Numevents.(maxresponse_labels{p}{m}).mean{r}(g_indx(group),:) = NaN;
                                        outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Orient.(flds{x}).(refr{y}).Latency.(maxresponse_labels{p}{m}).mean{r}(g_indx(group),:) = NaN;
                                        outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Orient.(flds{x}).(refr{y}).LatencyAll.(maxresponse_labels{p}{m}).mean{r}(g_indx(group),:) = NaN;
                                        outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Orient.(flds{x}).(refr{y}).Duration.(maxresponse_labels{p}{m}).mean{r}(g_indx(group),:) = NaN;
                                        outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Orient.(flds{x}).(refr{y}).TimeAll.(maxresponse_labels{p}{m}).mean{r}(g_indx(group),:) = NaN;
                                        outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Orient.(flds{x}).(refr{y}).PercAll.(maxresponse_labels{p}{m}).mean{r}(g_indx(group),:) = NaN;
                                        outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Orient.(flds{x}).(refr{y}).Time.(maxresponse_labels{p}{m}).mean{r}(g_indx(group),:) = NaN;
                                        outgroup.(Grouplabels{group}).DLC.(ProcessData{p}).(conds{c}).Orient.(flds{x}).(refr{y}).Perc.(maxresponse_labels{p}{m}).mean{r}(g_indx(group),:) = NaN;
                                    end
                                end
                                end     
                                end
                            end
                            end
                            end
                        end
                    end
                end
            end
        end
    end %end of recording loop
    outgroup.(Grouplabels{group}).animalID{g_indx(group)} = listdata{f,C}; % add animal ID to outfile
    g_indx(group) = g_indx(group)+1; % add to indx for this group
    clear outdata %remove outdata before loading next file
end %end of file loop
clear A B C D listdata group g c r f
     
clear spreadsheetsavename savedirxls row_labels spreadsheetsavename2
%% Calculate Group Means and Error for Plots
for g = 1:numgroups
for r = 1:numrecs
  for p = 1:length(ProcessData)
    conds = setcond.(ProcessData{p}){2}; %get labels for  possible trial types from metadata 
    for c = 1:length(conds)
        if FPAnalysis
        for d = 1:length(FPplottype)
        %only get mean if there are enough datapoints to average
        peaktypes = {'PeakVal','Latency','AUC','RiseSlope','FallSlope','trace'};   
        for m = 1:length(maxresponse_labels{p})
            for x = 1:length(peaktypes) 
            outgroup.plot.(Grouplabels{g}).FP.(ProcessData{p}).(conds{c}).(FPplottype{d}).Peak.(peaktypes{x}).(maxresponse_labels{p}{m}).mean(r,:) = mean(outgroup.(Grouplabels{g}).FP.(ProcessData{p}).(conds{c}).(FPplottype{d}).Peak.MeanTrace.(peaktypes{x}).(maxresponse_labels{p}{m}){r},'omitnan');
            outgroup.plot.(Grouplabels{g}).FP.(ProcessData{p}).(conds{c}).(FPplottype{d}).Peak.(peaktypes{x}).(maxresponse_labels{p}{m}).stdev(r,:) = std(outgroup.(Grouplabels{g}).FP.(ProcessData{p}).(conds{c}).(FPplottype{d}).Peak.MeanTrace.(peaktypes{x}).(maxresponse_labels{p}{m}){r},'omitnan');
            outgroup.plot.(Grouplabels{g}).FP.(ProcessData{p}).(conds{c}).(FPplottype{d}).Peak.(peaktypes{x}).(maxresponse_labels{p}{m}).n(r,:) = sum(~isnan(outgroup.(Grouplabels{g}).FP.(ProcessData{p}).(conds{c}).(FPplottype{d}).Peak.MeanTrace.(peaktypes{x}).(maxresponse_labels{p}{m}){r}));
            if x == 6
                for y = 1:size(outgroup.plot.(Grouplabels{g}).FP.(ProcessData{p}).(conds{c}).(FPplottype{d}).Peak.(peaktypes{x}).(maxresponse_labels{p}{m}).n(r,:),2)
                outgroup.plot.(Grouplabels{g}).FP.(ProcessData{p}).(conds{c}).(FPplottype{d}).Peak.(peaktypes{x}).(maxresponse_labels{p}{m}).sem(r,y) = outgroup.plot.(Grouplabels{g}).FP.(ProcessData{p}).(conds{c}).(FPplottype{d}).Peak.(peaktypes{x}).(maxresponse_labels{p}{m}).stdev(r,y)/sqrt(outgroup.plot.(Grouplabels{g}).FP.(ProcessData{p}).(conds{c}).(FPplottype{d}).Peak.(peaktypes{x}).(maxresponse_labels{p}{m}).n(r,y)); 
                end
            else
            outgroup.plot.(Grouplabels{g}).FP.(ProcessData{p}).(conds{c}).(FPplottype{d}).Peak.(peaktypes{x}).(maxresponse_labels{p}{m}).sem(r,:) = outgroup.plot.(Grouplabels{g}).FP.(ProcessData{p}).(conds{c}).(FPplottype{d}).Peak.(peaktypes{x}).(maxresponse_labels{p}{m}).stdev(r,:)/sqrt(outgroup.plot.(Grouplabels{g}).FP.(ProcessData{p}).(conds{c}).(FPplottype{d}).Peak.(peaktypes{x}).(maxresponse_labels{p}{m}).n(r,:));     
            end
            end 
        end
        end
        end
            %% Get DLC data
            if DLCanalysis %need to mark which animals all data is padded for (i.e. where every 2nd value is NaN, add in peak values extraction
            % LOCOMOTION/FREEZING BOUTS
            bouttypes = {'Locomotion','Freeze'};
            for bt = 1:length(bouttypes)  
            if isfield(outgroup.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}),(bouttypes{bt}))
             %extract mean bout data  
             for m = 1:length(maxresponse_labels{p})
             outgroup.plot.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).(bouttypes{bt}).Perctrials.(maxresponse_labels{p}{m}).mean {r} = mean(outgroup.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).(bouttypes{bt}).Perctrials.(maxresponse_labels{p}{m}).num{r},'omitnan');
             outgroup.plot.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).(bouttypes{bt}).Perctrials.(maxresponse_labels{p}{m}).std {r} = std(outgroup.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).(bouttypes{bt}).Perctrials.(maxresponse_labels{p}{m}).num{r},'omitnan');
             outgroup.plot.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).(bouttypes{bt}).Perctrials.(maxresponse_labels{p}{m}).n {r} = sum(~isnan(outgroup.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).(bouttypes{bt}).Perctrials.(maxresponse_labels{p}{m}).num{r}));
             outgroup.plot.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).(bouttypes{bt}).Perctrials.(maxresponse_labels{p}{m}).sem {r} = outgroup.plot.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).(bouttypes{bt}).Perctrials.(maxresponse_labels{p}{m}).std {r}/sqrt(outgroup.plot.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).(bouttypes{bt}).Perctrials.(maxresponse_labels{p}{m}).n {r});
             outgroup.plot.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).(bouttypes{bt}).PerctrialsAll.(maxresponse_labels{p}{m}).mean {r} = mean(outgroup.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).(bouttypes{bt}).PerctrialsAll.(maxresponse_labels{p}{m}).num{r},'omitnan');
             outgroup.plot.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).(bouttypes{bt}).PerctrialsAll.(maxresponse_labels{p}{m}).std {r} = std(outgroup.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).(bouttypes{bt}).PerctrialsAll.(maxresponse_labels{p}{m}).num{r},'omitnan');
             outgroup.plot.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).(bouttypes{bt}).PerctrialsAll.(maxresponse_labels{p}{m}).n {r} = sum(~isnan(outgroup.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).(bouttypes{bt}).PerctrialsAll.(maxresponse_labels{p}{m}).num{r}));
             outgroup.plot.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).(bouttypes{bt}).PerctrialsAll.(maxresponse_labels{p}{m}).sem {r} = outgroup.plot.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).(bouttypes{bt}).PerctrialsAll.(maxresponse_labels{p}{m}).std {r}/sqrt(outgroup.plot.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).(bouttypes{bt}).PerctrialsAll.(maxresponse_labels{p}{m}).n {r});
       
             datatype = {'Numevents','Latency','LatencyAll','Duration','TimeAll','PercAll','Time','Perc'};
             for dd = 1:length(datatype)
             outgroup.plot.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).(bouttypes{bt}).(datatype{dd}).(maxresponse_labels{p}{m}).mean {r} = mean(outgroup.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).(bouttypes{bt}).(datatype{dd}).(maxresponse_labels{p}{m}).mean{r},'omitnan');
             outgroup.plot.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).(bouttypes{bt}).(datatype{dd}).(maxresponse_labels{p}{m}).std {r} = std(outgroup.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).(bouttypes{bt}).(datatype{dd}).(maxresponse_labels{p}{m}).mean{r},'omitnan');
             outgroup.plot.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).(bouttypes{bt}).(datatype{dd}).(maxresponse_labels{p}{m}).n {r} = sum(~isnan(outgroup.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).(bouttypes{bt}).(datatype{dd}).(maxresponse_labels{p}{m}).mean{r}));
             outgroup.plot.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).(bouttypes{bt}).(datatype{dd}).(maxresponse_labels{p}{m}).sem {r} = outgroup.plot.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).(bouttypes{bt}).(datatype{dd}).(maxresponse_labels{p}{m}).std {r}/sqrt(outgroup.plot.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).(bouttypes{bt}).(datatype{dd}).(maxresponse_labels{p}{m}).n {r});
             end
             %extract data for correlations
            end
            end
            end
           
            
            for b = 1:length(DLCmeasures)
            numsubfields = length(DLCsubfields.(DLCmeasures{b}));
            flds = DLCsubfields.(DLCmeasures{b}){1};
            for x =1:length(flds)
            switch numsubfields  
                
            case 1 %one subfield
                for m = 1:length(maxresponse_labels{p})
                outgroup.plot.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).Peak.(maxresponse_labels{p}{m}).mean(r,:)= mean(outgroup.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).Peak.(maxresponse_labels{p}{m}).mean{r},'omitnan');
                outgroup.plot.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).Peak.(maxresponse_labels{p}{m}).stdev(r,:)= std(outgroup.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).Peak.(maxresponse_labels{p}{m}).mean{r},'omitnan');
                
                outgroup.plot.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).Peak.(maxresponse_labels{p}{m}).int.mean(r,:)= mean(outgroup.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).Peak.(maxresponse_labels{p}{m}).int.mean{r},'omitnan');
                outgroup.plot.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).Peak.(maxresponse_labels{p}{m}).int.stdev(r,:)= std(outgroup.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).Peak.(maxresponse_labels{p}{m}).int.mean{r},'omitnan');
                
                for i = 1:size(outgroup.(Grouplabels{g}).DLC.(ProcessData{p}).peaktimearray.(maxresponse_labels{p}{m}),2)
                outgroup.plot.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).Peak.(maxresponse_labels{p}{m}).n(r,i) = sum(~isnan(outgroup.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).Peak.(maxresponse_labels{p}{m}).mean{r}(:,i)));
                outgroup.plot.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).Peak.(maxresponse_labels{p}{m}).sem(r,i) = outgroup.plot.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).Peak.(maxresponse_labels{p}{m}).stdev(r,i)/sqrt(outgroup.plot.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).Peak.(maxresponse_labels{p}{m}).n(r,i)); 
                
                outgroup.plot.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).Peak.(maxresponse_labels{p}{m}).int.n(r,i) = sum(~isnan(outgroup.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).Peak.(maxresponse_labels{p}{m}).int.mean{r}(:,i)));
                outgroup.plot.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).Peak.(maxresponse_labels{p}{m}).int.sem(r,i) = outgroup.plot.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).Peak.(maxresponse_labels{p}{m}).int.stdev(r,i)/sqrt(outgroup.plot.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).Peak.(maxresponse_labels{p}{m}).int.n(r,i)); 
                end
                end
            
            case 2% two subfields
            refr = DLCsubfields.(DLCmeasures{b}){2}{x};
            for y = 1:length(refr)
                    for m = 1:length(maxresponse_labels{p})
                    outgroup.plot.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).(refr{y}).Peak.(maxresponse_labels{p}{m}).mean(r,:)= mean(outgroup.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).(refr{y}).Peak.(maxresponse_labels{p}{m}).mean{r},'omitnan');
                    outgroup.plot.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).(refr{y}).Peak.(maxresponse_labels{p}{m}).stdev(r,:)= std(outgroup.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).(refr{y}).Peak.(maxresponse_labels{p}{m}).mean{r},'omitnan');
                    
                    outgroup.plot.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).(refr{y}).Peak.(maxresponse_labels{p}{m}).int.mean(r,:)= mean(outgroup.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).(refr{y}).Peak.(maxresponse_labels{p}{m}).int.mean{r},'omitnan');
                    outgroup.plot.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).(refr{y}).Peak.(maxresponse_labels{p}{m}).int.stdev(r,:)= std(outgroup.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).(refr{y}).Peak.(maxresponse_labels{p}{m}).int.mean{r},'omitnan');
                    
                    for i = 1:length(outgroup.(Grouplabels{g}).DLC.(ProcessData{p}).peaktimearray.(maxresponse_labels{p}{m}))
                    outgroup.plot.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).(refr{y}).Peak.(maxresponse_labels{p}{m}).n(r,i) = sum(~isnan(outgroup.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).(refr{y}).Peak.(maxresponse_labels{p}{m}).mean{r}(:,i)));
                    outgroup.plot.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).(refr{y}).Peak.(maxresponse_labels{p}{m}).sem(r,i) = outgroup.plot.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).(refr{y}).Peak.(maxresponse_labels{p}{m}).stdev(r,i)/sqrt(outgroup.plot.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).(refr{y}).Peak.(maxresponse_labels{p}{m}).n(r,i)); 
                    
                    outgroup.plot.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).(refr{y}).Peak.(maxresponse_labels{p}{m}).int.n(r,i) = sum(~isnan(outgroup.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).(refr{y}).Peak.(maxresponse_labels{p}{m}).int.mean{r}(:,i)));
                    outgroup.plot.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).(refr{y}).Peak.(maxresponse_labels{p}{m}).int.sem(r,i) = outgroup.plot.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).(refr{y}).Peak.(maxresponse_labels{p}{m}).int.stdev(r,i)/sqrt(outgroup.plot.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).(refr{y}).Peak.(maxresponse_labels{p}{m}).int.n(r,i)); 
                    end
                    end
            end
            
            case 3 %three subfields
            refr = DLCsubfields.(DLCmeasures{b}){2}{x};
            for y = 1:length(refr)
            typ = DLCsubfields.(DLCmeasures{b}){3}{y};
                for z = 1:length(typ)  
                 for m = 1:length(maxresponse_labels{p})
                    outgroup.plot.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).(refr{y}).(typ{z}).Peak.(maxresponse_labels{p}{m}).mean(r,:)= mean(outgroup.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).(refr{y}).(typ{z}).Peak.(maxresponse_labels{p}{m}).mean{r},'omitnan');
                    outgroup.plot.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).(refr{y}).(typ{z}).Peak.(maxresponse_labels{p}{m}).stdev(r,:)= std(outgroup.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).(refr{y}).(typ{z}).Peak.(maxresponse_labels{p}{m}).mean{r},'omitnan');
                    
                    outgroup.plot.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).(refr{y}).(typ{z}).Peak.(maxresponse_labels{p}{m}).int.mean(r,:)= mean(outgroup.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).(refr{y}).(typ{z}).Peak.(maxresponse_labels{p}{m}).int.mean{r},'omitnan');
                    outgroup.plot.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).(refr{y}).(typ{z}).Peak.(maxresponse_labels{p}{m}).int.stdev(r,:)= std(outgroup.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).(refr{y}).(typ{z}).Peak.(maxresponse_labels{p}{m}).int.mean{r},'omitnan');

                    for i = 1:length(outgroup.(Grouplabels{g}).DLC.(ProcessData{p}).peaktimearray.(maxresponse_labels{p}{m}))
                    outgroup.plot.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).(refr{y}).(typ{z}).Peak.(maxresponse_labels{p}{m}).n(r,i) = sum(~isnan(outgroup.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).(refr{y}).(typ{z}).Peak.(maxresponse_labels{p}{m}).mean{r}(:,i)));
                    outgroup.plot.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).(refr{y}).(typ{z}).Peak.(maxresponse_labels{p}{m}).sem(r,i) = outgroup.plot.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).(refr{y}).(typ{z}).Peak.(maxresponse_labels{p}{m}).stdev(r,i)/sqrt(outgroup.plot.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).(refr{y}).(typ{z}).Peak.(maxresponse_labels{p}{m}).n(r,i)); 
                    
                    outgroup.plot.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).(refr{y}).(typ{z}).Peak.(maxresponse_labels{p}{m}).int.n(r,i) = sum(~isnan(outgroup.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).(refr{y}).(typ{z}).Peak.(maxresponse_labels{p}{m}).int.mean{r}(:,i)));
                    outgroup.plot.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).(refr{y}).(typ{z}).Peak.(maxresponse_labels{p}{m}).int.sem(r,i) = outgroup.plot.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).(refr{y}).(typ{z}).Peak.(maxresponse_labels{p}{m}).int.stdev(r,i)/sqrt(outgroup.plot.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).(refr{y}).(typ{z}).Peak.(maxresponse_labels{p}{m}).int.n(r,i)); 
                    end
                    end
                end
            end
            end
            end
            end
            end
        %% save data to excel sheet
    
        %% Export FP traces for all windows
        if r == numrecs %for last recording save group data to excel sheet
        if ~isempty(Reclabels)
        row_labels = Reclabels';
        else
            for i = 1:numrecs
            row_labels{i,1} = strcat('Rec-',num2str(i));
            end
        end

        if FPAnalysis
        for d = 1:length(FPplottype)
        for x = 1: length(maxresponse_labels{p})
                    savedirxls = strcat(PATH,savefolder,fsep,'StatsOutput-FP',fsep,(ProcessData{p}),fsep,'Traces',fsep,(maxresponse_labels{p}{x}),fsep,(FPplottype{d}),fsep);
                    if ~exist(savedirxls, 'dir')
                    mkdir(savedirxls);
                    end
            spreadsheetsavename = strcat(savedirxls,'FPTraces-',(Grouplabels{g}),'.xlsx');
            %setup column and row headerssavefolder
            for n = 1: numrecs
            %setup blank array
            outexcel = cell(length(outgroup.(Grouplabels{g}).animalID)+1,length(outgroup.(Grouplabels{g}).FP.(ProcessData{p}).peaktimearray.(maxresponse_labels{p}{x}))+1);         
            %fill headers
            outexcel(1,2:end) = num2cell(outgroup.(Grouplabels{g}).FP.(ProcessData{p}).peaktimearray.(maxresponse_labels{p}{x})); 
            outexcel(2:end,1) = outgroup.(Grouplabels{g}).animalID;
            %getdata
            outexcel(2:end,2:end) = num2cell(outgroup.(Grouplabels{g}).FP.(ProcessData{p}).(conds{c}).(FPplottype{d}).Peak.MeanTrace.trace.(maxresponse_labels{p}{x}){n});          
            writecell(outexcel,spreadsheetsavename,'filetype','spreadsheet','Sheet',strcat(row_labels{n},'-',(conds{c})));
            clear outexcel
            end
        end
                  
            
            %% export peak/trough vals calculated from mean waveforms
            peaklabs = {'PeakVal','Latency','AUC','RiseSlope','FallSlope','AverageFP'};
            peaktypes = {'Peak','Trough'};
            for x = 1: length(maxresponse_labels{p})
                for pt = 1:2
                    savedirxls = strcat(PATH,savefolder,fsep,'StatsOutput-FP',fsep,(ProcessData{p}),fsep,'MeanWF-',(peaktypes{pt}),fsep,(maxresponse_labels{p}{x}),fsep,(FPplottype{d}),fsep);
                    if ~exist(savedirxls, 'dir')
                    mkdir(savedirxls);
                    end
                spreadsheetsavename = strcat(savedirxls,'FP',(peaktypes{pt}),'-',(Grouplabels{g}),'.xlsx');
                for y = 1:length(peaklabs)
                        %setup blank array
                        outexcel = cell(length(outgroup.(Grouplabels{g}).animalID)+1,length(row_labels)+1);
                        %headers
                        outexcel(1,2:length(row_labels)+1) = row_labels';   
                        outexcel(2:length(outgroup.(Grouplabels{g}).animalID)+1,1) = outgroup.(Grouplabels{g}).animalID';
                        %get data
                        for n = 1:numrecs 
                        outexcel(2:end,n+1)= num2cell(outgroup.(Grouplabels{g}).FP.(ProcessData{p}).(conds{c}).(FPplottype{d}).(peaktypes{pt}).MeanTrace.(peaklabs{y}).(maxresponse_labels{p}{x}){n});
                        end
                        writecell(outexcel,spreadsheetsavename,'filetype','spreadsheet','Sheet',strcat((peaklabs{y}),'-',(conds{c})));
                        clear outexcel   
                end
                end
            end
        end
        end
  
            
            if DLCanalysis                
            %% Export mean data locomotion/freezing bouts
            bouttypes = {'Locomotion','Freeze'};
            for bt = 1:length(bouttypes)  
            if isfield(outgroup.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}),(bouttypes{bt}))
             %extract mean bout data  
            for m = 1:length(maxresponse_labels{p})
                    savedirxls = strcat(PATH,savefolder,fsep,'StatsOutput-DLC',fsep,(ProcessData{p}),fsep,(bouttypes{bt}),fsep,(maxresponse_labels{p}{m}),fsep);
                    if ~exist(savedirxls, 'dir')
                    mkdir(savedirxls);
                    end
                spreadsheetsavename = strcat(savedirxls,(bouttypes{bt}),'Bout-',(Grouplabels{g}),'.xlsx');
                     %setup blank array
                        outexcel = cell(length(outgroup.(Grouplabels{g}).animalID)+1,length(row_labels)+1);
                        %headers
                        outexcel(1,2:length(row_labels)+1) = row_labels';   
                        outexcel(2:length(outgroup.(Grouplabels{g}).animalID)+1,1) = outgroup.(Grouplabels{g}).animalID';
                        %get data
                        for n = 1:numrecs 
                        outexcel(2:end,n+1)= num2cell(outgroup.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).(bouttypes{bt}).Perctrials.(maxresponse_labels{p}{m}).num{n});
                        end
                        writecell(outexcel,spreadsheetsavename,'filetype','spreadsheet','Sheet',strcat('Perctrials','-',(conds{c})));
                        clear outexcel   
                        outexcel(1,2:length(row_labels)+1) = row_labels';   
                        outexcel(2:length(outgroup.(Grouplabels{g}).animalID)+1,1) = outgroup.(Grouplabels{g}).animalID';
                        for n = 1:numrecs 
                        outexcel(2:end,n+1)= num2cell(outgroup.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).(bouttypes{bt}).PerctrialsAll.(maxresponse_labels{p}{m}).num{n});
                        end
                        writecell(outexcel,spreadsheetsavename,'filetype','spreadsheet','Sheet',strcat('PerctrialsAll','-',(conds{c})));
                        clear outexcel   
             
                        datatype = {'Numevents','Latency','Duration','TimeAll','PercAll','Time','Perc'};
                        for dd = 1:length(datatype)
                 %setup blank array
                        outexcel = cell(length(outgroup.(Grouplabels{g}).animalID)+1,length(row_labels)+1);
                        %headers
                        outexcel(1,2:length(row_labels)+1) = row_labels';   
                        outexcel(2:length(outgroup.(Grouplabels{g}).animalID)+1,1) = outgroup.(Grouplabels{g}).animalID';
                        %get data
                        for n = 1:numrecs 
                        outexcel(2:end,n+1)= num2cell(outgroup.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).(bouttypes{bt}).(datatype{dd}).(maxresponse_labels{p}{m}).mean{n});
                        end
                        writecell(outexcel,spreadsheetsavename,'filetype','spreadsheet','Sheet',strcat((datatype{dd}),'-',(conds{c})));
                        clear outexcel   
                        end

                        if FPAnalysis
             %extract cue-locked waveforms for trials with/without bouts            
             savedirxls = strcat(PATH,savefolder,fsep,'StatsOutput-DLC',fsep,(ProcessData{p}),fsep,(bouttypes{bt}),fsep,(maxresponse_labels{p}{m}),fsep);
                    if ~exist(savedirxls, 'dir')
                    mkdir(savedirxls);
                    end
                spreadsheetsavename = strcat(savedirxls,(bouttypes{bt}),'Bout',(Grouplabels{g}),'_EventWaveforms.xlsx');
                for n = 1:numrecs 
                for et = 1:3
                    outexcel = cell(length(outgroup.(Grouplabels{g}).animalID)+1,length(outgroup.(Grouplabels{g}).FP.(ProcessData{p}).peaktimearray.All)+1);         
                    %fill headers
                    outexcel(1,2:end) = num2cell(outgroup.(Grouplabels{g}).FP.(ProcessData{p}).peaktimearray.All); 
                    outexcel(2:end,1) = outgroup.(Grouplabels{g}).animalID;
                    %getdata
                    outexcel(2:end,2:end) = num2cell(outgroup.(Grouplabels{g}).FP.(ProcessData{p}).(conds{c}).(bouttypes{bt}).MeanWF_Event.(maxresponse_labels{p}{m}).(eventtimes{et}){n});
                    writecell(outexcel,spreadsheetsavename,'filetype','spreadsheet','Sheet',strcat(row_labels{n},'-',(conds{c}),'_',(eventtimes{et})));
                    clear outexcel   
                end
                end
                %extract bout-locked waveforms
                        %extract cue-locked waveforms for trials with/without bouts            
                    savedirxls = strcat(PATH,savefolder,fsep,'StatsOutput-DLC',fsep,(ProcessData{p}),fsep,(bouttypes{bt}),fsep,(maxresponse_labels{p}{m}),fsep);
                    if ~exist(savedirxls, 'dir')
                    mkdir(savedirxls);
                    end
                spreadsheetsavename = strcat(savedirxls,(bouttypes{bt}),'Bout',(Grouplabels{g}),'_BoutWaveforms.xlsx');
                for n = 1:numrecs 
                for et = 1:2
                    outexcel = cell(length(outgroup.(Grouplabels{g}).animalID)+1,length(outgroup.(Grouplabels{g}).FP.(ProcessData{p}).(conds{c}).(bouttypes{bt}).MeanWF_Bout.time)+1);         
                    %fill headers
                    outexcel(1,2:end) = num2cell(outgroup.(Grouplabels{g}).FP.(ProcessData{p}).(conds{c}).(bouttypes{bt}).MeanWF_Bout.time); 
                    outexcel(2:end,1) = outgroup.(Grouplabels{g}).animalID;
                    %getdata
                    outexcel(2:end,2:end) = num2cell(outgroup.(Grouplabels{g}).FP.(ProcessData{p}).(conds{c}).(bouttypes{bt}).MeanWF_Bout.(maxresponse_labels{p}{m}).(eventtimes{et}){n});
                    writecell(outexcel,spreadsheetsavename,'filetype','spreadsheet','Sheet',strcat(row_labels{n},'-',(conds{c}),'_',(eventtimes{et})));
                    clear outexcel   
                end
                end
                        end
            end
            end
            end
                    
            
                %% Export DLC traces
                for b = 1:length(DLCmeasures)
                numsubfields = length(DLCsubfields.(DLCmeasures{b}));
                flds = DLCsubfields.(DLCmeasures{b}){1};
                for x =1:length(flds)
                switch numsubfields  
                
                case 1 %one subfield
                    %traces for peak analysis wins
                    for m = 1:length(maxresponse_labels{p})
                    savedirxls = strcat(PATH,savefolder,fsep,'StatsOutput-DLC',fsep,(ProcessData{p}),fsep,'Traces',fsep,(DLCmeasures{b}),fsep,(flds{x}),fsep,(maxresponse_labels{p}{m}),fsep);
                    if ~exist(savedirxls, 'dir')
                    mkdir(savedirxls);
                    end
                    spreadsheetsavename = strcat(savedirxls,'DLCTrace-',(Grouplabels{g}),'.xlsx');
                    spreadsheetsavename_int = strcat(savedirxls,'DLCTrace-',(Grouplabels{g}),'int.xlsx');                    
                    for n = 1:numrecs
                    %setup blank array
                    outexcel = cell(length(outgroup.(Grouplabels{g}).animalID)+1,length(outgroup.(Grouplabels{g}).DLC.(ProcessData{p}).peaktimearray.(maxresponse_labels{p}{m}))+1);
                    outexcel_int = cell(length(outgroup.(Grouplabels{g}).animalID)+1,length(outgroup.(Grouplabels{g}).DLC.(ProcessData{p}).peaktimearray.(maxresponse_labels{p}{m}))+1);      
                    %headers
                    outexcel(1,2:end) = num2cell(outgroup.(Grouplabels{g}).DLC.(ProcessData{p}).peaktimearray.(maxresponse_labels{p}{m}));
                    outexcel(2:end,1) = outgroup.(Grouplabels{g}).animalID;
                    outexcel_int(1,2:end) = num2cell(outgroup.(Grouplabels{g}).DLC.(ProcessData{p}).peaktimearray.(maxresponse_labels{p}{m}));
                    outexcel_int(2:end,1) = outgroup.(Grouplabels{g}).animalID;
                    %getdata
                    outexcel(2:end,2:end) = num2cell(outgroup.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).Peak.(maxresponse_labels{p}{m}).mean{n});
                    outexcel_int(2:end,2:end) = num2cell(outgroup.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).Peak.(maxresponse_labels{p}{m}).int.mean{n});
                    %save sheet
                    writecell(outexcel,spreadsheetsavename,'filetype','spreadsheet','Sheet',strcat((row_labels{n}),'-',(conds{c})));
                    writecell(outexcel_int,spreadsheetsavename_int,'filetype','spreadsheet','Sheet',strcat((row_labels{n}),'-',(conds{c})));    
                    clear outexcel outexcel_int
                    end
                    end
                    
                    
                    
                    %Get Peak data
                    if isfield(outgroup.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}),(DLCmeasures{b}))
                        if strcmp((DLCmeasures{b}),'MoveDist') | strcmp((DLCmeasures{b}),'Speed')
                        for m = 1:length(maxresponse_labels{p})
                        savedirxls = strcat(PATH,savefolder,fsep,'StatsOutput-DLC',fsep,(ProcessData{p}),fsep,(DLCmeasures{b}),fsep,(flds{x}),fsep,(maxresponse_labels{p}{m}),fsep);
                        if ~exist(savedirxls, 'dir')
                        mkdir(savedirxls);
                        end
                        spreadsheetsavename = strcat(savedirxls,'DLCPeak-',(Grouplabels{g}),'.xlsx');
                        %setup blank array
                        outexcel = cell(length(outgroup.(Grouplabels{g}).animalID)+1,length(row_labels)+1);
                        %headers
                        outexcel(1,2:length(row_labels)+1) = row_labels';   
                        outexcel(2:length(outgroup.(Grouplabels{g}).animalID)+1,1) = outgroup.(Grouplabels{g}).animalID';
                        %get data 
                        datatype = {'MaxVal','Average','MaxTs'};
                        for dd = 1:length(datatype)
                        %setup blank array
                        outexcel = cell(length(outgroup.(Grouplabels{g}).animalID)+1,length(row_labels)+1);
                        %headers
                        outexcel(1,2:length(row_labels)+1) = row_labels';   
                        outexcel(2:length(outgroup.(Grouplabels{g}).animalID)+1,1) = outgroup.(Grouplabels{g}).animalID';
                        %get data
                        for n = 1:numrecs 
                        outexcel(2:end,n+1)= num2cell(outgroup.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).(datatype{dd}).(maxresponse_labels{p}{m}).mean{n});
                        end
                        writecell(outexcel,spreadsheetsavename,'filetype','spreadsheet','Sheet',strcat((datatype{dd}),'-',(conds{c})));
                        clear outexcel   
                        end
                            %extract data for correlations
                        end
                        end
                    end
                    
                    case 2 %two subfields
                    refr = DLCsubfields.(DLCmeasures{b}){2}{x};
                    for y = 1:length(refr)
                    %traces for peak analysis wins
                    for m = 1:length(maxresponse_labels{p})
                    savedirxls = strcat(PATH,savefolder,fsep,'StatsOutput-DLC',fsep,(ProcessData{p}),fsep,'Traces',fsep,(DLCmeasures{b}),fsep,(flds{x}),'-',(refr{y}),fsep,(maxresponse_labels{p}{m}),fsep);
                    if ~exist(savedirxls, 'dir')
                    mkdir(savedirxls);
                    end
                    spreadsheetsavename = strcat(savedirxls,'DLCTrace-',(Grouplabels{g}),'.xlsx');
                    spreadsheetsavename_int = strcat(savedirxls,'DLCTrace-',(Grouplabels{g}),'int.xlsx');                    
                    for n = 1:numrecs
                    %setup blank array
                    outexcel = cell(length(outgroup.(Grouplabels{g}).animalID)+1,length(outgroup.(Grouplabels{g}).DLC.(ProcessData{p}).peaktimearray.(maxresponse_labels{p}{m}))+1);
                    outexcel_int = cell(length(outgroup.(Grouplabels{g}).animalID)+1,length(outgroup.(Grouplabels{g}).DLC.(ProcessData{p}).peaktimearray.(maxresponse_labels{p}{m}))+1);      
                    %headers
                    outexcel(1,2:end) = num2cell(outgroup.(Grouplabels{g}).DLC.(ProcessData{p}).peaktimearray.(maxresponse_labels{p}{m}));
                    outexcel(2:end,1) = outgroup.(Grouplabels{g}).animalID;
                    outexcel_int(1,2:end) = num2cell(outgroup.(Grouplabels{g}).DLC.(ProcessData{p}).peaktimearray.(maxresponse_labels{p}{m}));
                    outexcel_int(2:end,1) = outgroup.(Grouplabels{g}).animalID;
                    %getdata
                    outexcel(2:end,2:end) = num2cell(outgroup.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).(refr{y}).Peak.(maxresponse_labels{p}{m}).mean{n});
                    outexcel_int(2:end,2:end) = num2cell(outgroup.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).(refr{y}).Peak.(maxresponse_labels{p}{m}).int.mean{n});
                    %save sheet
                    writecell(outexcel,spreadsheetsavename,'filetype','spreadsheet','Sheet',strcat((row_labels{n}),'-',(conds{c})));
                    writecell(outexcel_int,spreadsheetsavename_int,'filetype','spreadsheet','Sheet',strcat((row_labels{n}),'-',(conds{c})));    
                    clear outexcel outexcel_int
                    end
                    end

                    %Get Peak data
                    if isfield(outgroup.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}),(DLCmeasures{b}))
                        if strcmp((DLCmeasures{b}),'AngularVelocity') 
                        for m = 1:length(maxresponse_labels{p})
                        savedirxls = strcat(PATH,savefolder,fsep,'StatsOutput-DLC',fsep,(ProcessData{p}),fsep,(DLCmeasures{b}),fsep,(flds{x}),'-',(refr{y}),fsep,(maxresponse_labels{p}{m}),fsep);
                        if ~exist(savedirxls, 'dir')
                        mkdir(savedirxls);
                        end
                        spreadsheetsavename = strcat(savedirxls,'DLCPeak-',(Grouplabels{g}),'.xlsx');
                        %setup blank array
                        outexcel = cell(length(outgroup.(Grouplabels{g}).animalID)+1,length(row_labels)+1);
                        %headers
                        outexcel(1,2:length(row_labels)+1) = row_labels';   
                        outexcel(2:length(outgroup.(Grouplabels{g}).animalID)+1,1) = outgroup.(Grouplabels{g}).animalID';
                        %get data 
                        datatype = {'MaxVal','Average','MaxTs'};
                        for dd = 1:length(datatype)
                        %setup blank array
                        outexcel = cell(length(outgroup.(Grouplabels{g}).animalID)+1,length(row_labels)+1);
                        %headers
                        outexcel(1,2:length(row_labels)+1) = row_labels';   
                        outexcel(2:length(outgroup.(Grouplabels{g}).animalID)+1,1) = outgroup.(Grouplabels{g}).animalID';
                        %get data
                        for n = 1:numrecs 
                        outexcel(2:end,n+1)= num2cell(outgroup.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).(refr{y}).(datatype{dd}).(maxresponse_labels{p}{m}).mean{n});
                        end
                        writecell(outexcel,spreadsheetsavename,'filetype','spreadsheet','Sheet',strcat((datatype{dd}),'-',(conds{c})));
                        clear outexcel   
                        end
                            %extract data for correlations
                        end
                        end
                    end
                    
                    
            
            if isfield(outgroup.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}),'Approach') && strcmp((DLCmeasures{b}),'DistTo')
             %extract approach data  
                    for m = 1:length(maxresponse_labels{p})
                    savedirxls = strcat(PATH,savefolder,fsep,'StatsOutput-DLC',fsep,(ProcessData{p}),fsep,'Approach',fsep,(flds{x}),'-',(refr{y}),fsep,(maxresponse_labels{p}{m}),fsep);
                    if ~exist(savedirxls, 'dir')
                    mkdir(savedirxls);
                    end
                    spreadsheetsavename = strcat(savedirxls,'Approach-',(Grouplabels{g}),'.xlsx');
                     %setup blank array
                        outexcel = cell(length(outgroup.(Grouplabels{g}).animalID)+1,length(row_labels)+1);
                        %headers
                        outexcel(1,2:length(row_labels)+1) = row_labels';   
                        outexcel(2:length(outgroup.(Grouplabels{g}).animalID)+1,1) = outgroup.(Grouplabels{g}).animalID';
                        %get data
                        for n = 1:numrecs 
                        outexcel(2:end,n+1)= num2cell(outgroup.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).Approach.(flds{x}).(refr{y}).Perctrials.(maxresponse_labels{p}{m}).num{n});
                        end
                        writecell(outexcel,spreadsheetsavename,'filetype','spreadsheet','Sheet',strcat('Perctrials','-',(conds{c})));
                        clear outexcel 
                        outexcel(1,2:length(row_labels)+1) = row_labels';   
                        outexcel(2:length(outgroup.(Grouplabels{g}).animalID)+1,1) = outgroup.(Grouplabels{g}).animalID';
                        for n = 1:numrecs 
                        outexcel(2:end,n+1)= num2cell(outgroup.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).Approach.(flds{x}).(refr{y}).PerctrialsAll.(maxresponse_labels{p}{m}).num{n});
                        end
                        writecell(outexcel,spreadsheetsavename,'filetype','spreadsheet','Sheet',strcat('PerctrialsAll','-',(conds{c})));
                        clear outexcel   
             
                        datatype = {'Numevents','Latency','LatencyAll','Duration','TimeAll','PercAll','Time','Perc'};
                        for dd = 1:length(datatype)
                 %setup blank array
                        outexcel = cell(length(outgroup.(Grouplabels{g}).animalID)+1,length(row_labels)+1);
                        %headers
                        outexcel(1,2:length(row_labels)+1) = row_labels';   
                        outexcel(2:length(outgroup.(Grouplabels{g}).animalID)+1,1) = outgroup.(Grouplabels{g}).animalID';
                        %get data
                        for n = 1:numrecs 
                        outexcel(2:end,n+1)= num2cell(outgroup.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).Approach.(flds{x}).(refr{y}).(datatype{dd}).(maxresponse_labels{p}{m}).mean{n});
                        end
                        writecell(outexcel,spreadsheetsavename,'filetype','spreadsheet','Sheet',strcat((datatype{dd}),'-',(conds{c})));
                        clear outexcel   
                        end
             %extract data for correlations

             if FPAnalysis
                 %extract cue-locked waveforms for trials with/without bouts
                 if ~exist(savedirxls, 'dir')
                     mkdir(savedirxls);
                 end
                 spreadsheetsavename = strcat(savedirxls,'ApproachBout-',(Grouplabels{g}),'_EventWaveforms.xlsx');
                 for n = 1:numrecs
                     for et = 1:3
                         outexcel = cell(length(outgroup.(Grouplabels{g}).animalID)+1,length(outgroup.(Grouplabels{g}).FP.(ProcessData{p}).peaktimearray.All)+1);
                         %fill headers
                         outexcel(1,2:end) = num2cell(outgroup.(Grouplabels{g}).FP.(ProcessData{p}).peaktimearray.All);
                         outexcel(2:end,1) = outgroup.(Grouplabels{g}).animalID;
                         %getdata
                         outexcel(2:end,2:end) = num2cell(outgroup.(Grouplabels{g}).FP.(ProcessData{p}).(conds{c}).Approach.(flds{x}).(refr{y}).MeanWF_Event.(maxresponse_labels{p}{m}).(eventtimes{et}){n});
                         writecell(outexcel,spreadsheetsavename,'filetype','spreadsheet','Sheet',strcat(row_labels{n},'-',(conds{c}),'_',(eventtimes{et})));
                         clear outexcel
                     end
                 end
                 %extract bout-locked waveforms
      
                spreadsheetsavename = strcat(savedirxls,'ApproachBout-',(Grouplabels{g}),'_BoutWaveforms.xlsx');
                for n = 1:numrecs 
                for et = 1:2
                    outexcel = cell(length(outgroup.(Grouplabels{g}).animalID)+1,length(outgroup.(Grouplabels{g}).FP.(ProcessData{p}).(conds{c}).Approach.(flds{x}).(refr{y}).MeanWF_Bout.time)+1);         
                    %fill headers
                    outexcel(1,2:end) = num2cell(outgroup.(Grouplabels{g}).FP.(ProcessData{p}).(conds{c}).Approach.(flds{x}).(refr{y}).MeanWF_Bout.time); 
                    outexcel(2:end,1) = outgroup.(Grouplabels{g}).animalID;
                    %getdata
                    outexcel(2:end,2:end) = num2cell(outgroup.(Grouplabels{g}).FP.(ProcessData{p}).(conds{c}).Approach.(flds{x}).(refr{y}).MeanWF_Bout.(maxresponse_labels{p}{m}).(eventtimes{et}){n});
                    writecell(outexcel,spreadsheetsavename,'filetype','spreadsheet','Sheet',strcat(row_labels{n},'-',(conds{c}),'_',(eventtimes{et})));
                    clear outexcel   
                end
                end
             end
            end
            end
                    end
           
                case 3 %three subfields
                    refr = DLCsubfields.(DLCmeasures{b}){2}{x};
                    for y = 1:length(refr)
                    typ = DLCsubfields.(DLCmeasures{b}){3}{y};
                    
                    if isfield(outgroup.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}),'Orient') && strcmp((DLCmeasures{b}),'Angle')
                    %extract approach data  
                    for m = 1:length(maxresponse_labels{p})
                    savedirxls = strcat(PATH,savefolder,fsep,'StatsOutput-DLC',fsep,(ProcessData{p}),fsep,'Orient',fsep,(flds{x}),'-',(refr{y}),fsep,(maxresponse_labels{p}{m}),fsep);
                    if ~exist(savedirxls, 'dir')
                    mkdir(savedirxls);
                    end
                    spreadsheetsavename = strcat(savedirxls,'Orient-',(Grouplabels{g}),'.xlsx');
                     %setup blank array
                        outexcel = cell(length(outgroup.(Grouplabels{g}).animalID)+1,length(row_labels)+1);
                        %headers
                        outexcel(1,2:length(row_labels)+1) = row_labels';   
                        outexcel(2:length(outgroup.(Grouplabels{g}).animalID)+1,1) = outgroup.(Grouplabels{g}).animalID';
                        %get data
                        for n = 1:numrecs 
                        outexcel(2:end,n+1)= num2cell(outgroup.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).Orient.(flds{x}).(refr{y}).Perctrials.(maxresponse_labels{p}{m}).num{n});
                        end
                        writecell(outexcel,spreadsheetsavename,'filetype','spreadsheet','Sheet',strcat('Perctrials','-',(conds{c})));
                        clear outexcel 
                        outexcel(1,2:length(row_labels)+1) = row_labels';   
                        outexcel(2:length(outgroup.(Grouplabels{g}).animalID)+1,1) = outgroup.(Grouplabels{g}).animalID';
                        for n = 1:numrecs 
                        outexcel(2:end,n+1)= num2cell(outgroup.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).Orient.(flds{x}).(refr{y}).PerctrialsAll.(maxresponse_labels{p}{m}).num{n});
                        end
                        writecell(outexcel,spreadsheetsavename,'filetype','spreadsheet','Sheet',strcat('PerctrialsAll','-',(conds{c})));
                        clear outexcel   
             
                        datatype = {'Numevents','Latency','LatencyAll','Duration','TimeAll','PercAll','Time','Perc'};
                        for dd = 1:length(datatype)
                 %setup blank array
                        outexcel = cell(length(outgroup.(Grouplabels{g}).animalID)+1,length(row_labels)+1);
                        %headers
                        outexcel(1,2:length(row_labels)+1) = row_labels';   
                        outexcel(2:length(outgroup.(Grouplabels{g}).animalID)+1,1) = outgroup.(Grouplabels{g}).animalID';
                        %get data
                        for n = 1:numrecs 
                        outexcel(2:end,n+1)= num2cell(outgroup.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).Orient.(flds{x}).(refr{y}).(datatype{dd}).(maxresponse_labels{p}{m}).mean{n});
                        end
                        writecell(outexcel,spreadsheetsavename,'filetype','spreadsheet','Sheet',strcat((datatype{dd}),'-',(conds{c})));
                        clear outexcel   
                        end
                        %extract data for correlations

                        if FPAnalysis
                            %extract cue-locked waveforms for trials with/without bouts
                            if ~exist(savedirxls, 'dir')
                                mkdir(savedirxls);
                            end
                            spreadsheetsavename = strcat(savedirxls,'OrientBout-',(Grouplabels{g}),'_waveforms.xlsx');
                            for n = 1:numrecs
                                for et = 1:3
                                    outexcel = cell(length(outgroup.(Grouplabels{g}).animalID)+1,length(outgroup.(Grouplabels{g}).FP.(ProcessData{p}).peaktimearray.All)+1);
                                    %fill headers
                                    outexcel(1,2:end) = num2cell(outgroup.(Grouplabels{g}).FP.(ProcessData{p}).peaktimearray.All);
                                    outexcel(2:end,1) = outgroup.(Grouplabels{g}).animalID;
                                    %getdata
                                    outexcel(2:end,2:end) = num2cell(outgroup.(Grouplabels{g}).FP.(ProcessData{p}).(conds{c}).Orient.(flds{x}).(refr{y}).MeanWF_Event.(maxresponse_labels{p}{m}).(eventtimes{et}){n});
                                    writecell(outexcel,spreadsheetsavename,'filetype','spreadsheet','Sheet',strcat(row_labels{n},'-',(conds{c}),'_',(eventtimes{et})));
                                    clear outexcel
                                end
                            end

                            %extract bout-locked waveforms
      
                spreadsheetsavename = strcat(savedirxls,'OrientBout-',(Grouplabels{g}),'_BoutWaveforms.xlsx');
                for n = 1:numrecs 
                for et = 1:2
                    outexcel = cell(length(outgroup.(Grouplabels{g}).animalID)+1,length(outgroup.(Grouplabels{g}).FP.(ProcessData{p}).(conds{c}).Orient.(flds{x}).(refr{y}).MeanWF_Bout.time)+1);         
                    %fill headers
                    outexcel(1,2:end) = num2cell(outgroup.(Grouplabels{g}).FP.(ProcessData{p}).(conds{c}).Orient.(flds{x}).(refr{y}).MeanWF_Bout.time); 
                    outexcel(2:end,1) = outgroup.(Grouplabels{g}).animalID;
                    %getdata
                    outexcel(2:end,2:end) = num2cell(outgroup.(Grouplabels{g}).FP.(ProcessData{p}).(conds{c}).Orient.(flds{x}).(refr{y}).MeanWF_Bout.(maxresponse_labels{p}{m}).(eventtimes{et}){n});
                    writecell(outexcel,spreadsheetsavename,'filetype','spreadsheet','Sheet',strcat(row_labels{n},'-',(conds{c}),'_',(eventtimes{et})));
                    clear outexcel   
                end
                end
                        end
                    end
                    end
                                        
                    %peak analysis wins
                    for m = 1:length(maxresponse_labels{p})
                    savedirxls = strcat(PATH,savefolder,fsep,'StatsOutput-DLC',fsep,(ProcessData{p}),fsep,'Traces',fsep,(DLCmeasures{b}),fsep,(flds{x}),'-',(refr{y}),'-',(typ{z}),fsep,(maxresponse_labels{p}{m}),fsep);
                    if ~exist(savedirxls, 'dir')
                    mkdir(savedirxls);
                    end
                    spreadsheetsavename = strcat(savedirxls,'DLCTrace-',(Grouplabels{g}),'.xlsx');
                    spreadsheetsavename_int = strcat(savedirxls,'DLCTrace-',(Grouplabels{g}),'int.xlsx');                    
                    for n = 1:numrecs
                    %setup blank array
                    outexcel = cell(length(outgroup.(Grouplabels{g}).animalID)+1,length(outgroup.(Grouplabels{g}).DLC.(ProcessData{p}).peaktimearray.(maxresponse_labels{p}{m}))+1);
                    outexcel_int = cell(length(outgroup.(Grouplabels{g}).animalID)+1,length(outgroup.(Grouplabels{g}).DLC.(ProcessData{p}).peaktimearray.(maxresponse_labels{p}{m}))+1);      
                    %headers
                    outexcel(1,2:end) = num2cell(outgroup.(Grouplabels{g}).DLC.(ProcessData{p}).peaktimearray.(maxresponse_labels{p}{m}));
                    outexcel(2:end,1) = outgroup.(Grouplabels{g}).animalID;
                    outexcel_int(1,2:end) = num2cell(outgroup.(Grouplabels{g}).DLC.(ProcessData{p}).peaktimearray.(maxresponse_labels{p}{m}));
                    outexcel_int(2:end,1) = outgroup.(Grouplabels{g}).animalID;
                    %getdata
                    outexcel(2:end,2:end) = num2cell(outgroup.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).(refr{y}).(typ{z}).Peak.(maxresponse_labels{p}{m}).mean{n});
                    outexcel_int(2:end,2:end) = num2cell(outgroup.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).(DLCmeasures{b}).(flds{x}).(refr{y}).(typ{z}).Peak.(maxresponse_labels{p}{m}).int.mean{n});
                    %save sheet
                    writecell(outexcel,spreadsheetsavename,'filetype','spreadsheet','Sheet',strcat((row_labels{n}),'-',(conds{c})));
                    writecell(outexcel_int,spreadsheetsavename_int,'filetype','spreadsheet','Sheet',strcat((row_labels{n}),'-',(conds{c})));    
                    clear outexcel outexcel_int
                    end
                    end
                    
                    end
                    end 
                end
                end
                % Get Quadrant Data               
                    if isfield (outgroup.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}),'Quadrant')
                    Quadrant = {'LT','LB','RT','RB'};
                    qbps = DLCsubfields.Quadrant{1};
                    for bp = 1:length(qbps)
                    for m = 1:length(maxresponse_labels{p}) 
                    savedirxls = strcat(PATH,savefolder,fsep,'StatsOutput-DLC',fsep,(ProcessData{p}),fsep,'Quadrant',fsep,(qbps{bp}),fsep,(maxresponse_labels{p}{m}),fsep);
                    if ~exist(savedirxls, 'dir')
                    mkdir(savedirxls);
                    end
                    spreadsheetsavename = strcat(savedirxls,'DLCQuadrant-',(Grouplabels{g}),'.xlsx');
                    for q = 1:4
                    %setup blank array
                    outexcel = cell(length(outgroup.(Grouplabels{g}).animalID)+1,numrecs+1);
                    %headers
                    outexcel(1,2:end) = row_labels;
                    outexcel(2:end,1) = outgroup.(Grouplabels{g}).animalID;
                    for n = 1:numrecs
                    %getdata
                    outexcel(2:end,n+1) = num2cell(outgroup.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).Quadrant.(qbps{bp}).(Quadrant{q}).Peak.(maxresponse_labels{p}{m}).mean{n});    
                    end
                    %save sheet
                    writecell(outexcel,spreadsheetsavename,'filetype','spreadsheet','Sheet',strcat((Quadrant{q}),'-',(conds{c})));  
                    clear outexcel
                    end
                    end
                    end
                    end
                end
            end
    end
  end %end of processdata loop
end %end of rec loop

if DLCanalysis && FPAnalysis
% %get trial correl values
if FPCorrs
%Locomotion bouts
bouttypes = {'Locomotion','Freeze'};
FPdatatypes = {'peakval','latency','AUC'};
DLCdatatypes = {'Latency','Duration','Time'};
for bt = 1:length(bouttypes)
for p = 1:length(ProcessData)       
for cw = 1:length(FPcorrwin{p})
for m = 1:length(maxresponse_labels{p})

conds = setcond.(ProcessData{p}){2}; %get labels for  possible trial types from metadata 
for c = 1
if isfield(outgroup.(Grouplabels{g}).FP.(ProcessData{p}),(conds{c})) 
if isfield(outgroup.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}),(bouttypes{bt}))
    savedirxls = strcat(PATH,savefolder,fsep,'StatsOutput-Correl',fsep,(bouttypes{bt}),fsep,'FP-',FPcorrwin{p}{cw},fsep);
    if ~exist(savedirxls, 'dir')
    mkdir(savedirxls);
    end
    for x = 1:length(FPdatatypes)
    for r = 1:numrecs
     outexcel{1,1} = strcat('FP-',(FPdatatypes{x}));
     outexcel(1,2:length(DLCdatatypes)+1) = DLCdatatypes;
     spreadsheetsavename = strcat(savedirxls,(maxresponse_labels{p}{m}),'_',(Grouplabels{g}),'.xlsx');
     outindx = 1;
     numss = size(outgroup.(Grouplabels{g}).FP.(ProcessData{p}).(conds{c}).(bouttypes{bt}).Corr.Z_dFF.Peak.(FPdatatypes{x}).(FPcorrwin{p}{cw}).(maxresponse_labels{p}{m}).trials,2);
     for a = 1:numss %for each animal
     datalength = size(outgroup.(Grouplabels{g}).FP.(ProcessData{p}).(conds{c}).(bouttypes{bt}).Corr.Z_dFF.Peak.(FPdatatypes{x}).(FPcorrwin{p}{cw}).(maxresponse_labels{p}{m}).trials{r,a},1); %number of trials
     outexcel(outindx+1:outindx+datalength,1) = num2cell(outgroup.(Grouplabels{g}).FP.(ProcessData{p}).(conds{c}).(bouttypes{bt}).Corr.Z_dFF.Peak.(FPdatatypes{x}).(FPcorrwin{p}{cw}).(maxresponse_labels{p}{m}).trials{r,a});
         for d = 1:length(DLCdatatypes) %get DLCdata               
         outexcel(outindx+1:outindx+datalength,d+1) = num2cell(outgroup.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).(bouttypes{bt}).Corr.(DLCdatatypes{d}).(maxresponse_labels{p}{m}).trials{r,a});
         end
         outindx = length(outexcel(:,1));
     end
    writecell(outexcel,spreadsheetsavename,'filetype','spreadsheet','Sheet',strcat((FPdatatypes{x}),'-',(row_labels{r})));    
    clear outexcel
    end
    end
end
end
end
end
end
end
end
end

% %get trial correl values
%speed
if FPCorrs
behavmeas = {'Speed','MoveDist'};
FPdatatypes = {'peakval','latency','AUC'};
DLCdatatypes = {'MaxVal','Average','MaxTs'};
for p  = 1:length(ProcessData)
for cw = 1:length(FPcorrwin{p})
for bm = 1:length(behavmeas)
for m = 1:length(maxresponse_labels{p})                                      
conds = setcond.(ProcessData{p}){2}; %get labels for  possible trial types from metadata 
for c = 1
if isfield(outgroup.(Grouplabels{g}).FP.(ProcessData{p}),(conds{c})) 
if isfield(outgroup.(Grouplabels{g}).FP.(ProcessData{p}).(conds{c}),(behavmeas{bm}))

 flds = DLCsubfields.((behavmeas{bm})){1};
 for z = 1:length(flds)
savedirxls = strcat(PATH,savefolder,fsep,'StatsOutput-Correl',fsep,(behavmeas{bm}),fsep,(flds{z}),fsep,'FP-',FPcorrwin{p}{cw},fsep);
if ~exist(savedirxls, 'dir')
mkdir(savedirxls);
end
    for x = 1:length(FPdatatypes)
    for r = 1:numrecs
     outexcel{1,1} = strcat('FP-',(FPdatatypes{x}));
     outexcel(1,2:length(DLCdatatypes)+1) = DLCdatatypes;
     spreadsheetsavename = strcat(savedirxls,(maxresponse_labels{p}{m}),'_',(Grouplabels{g}),'.xlsx');
     outindx = 1;
     numss = size(outgroup.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).(behavmeas{bm}).Corr.(flds{z}).(maxresponse_labels{p}{m}).(DLCdatatypes{d}).trials,2);
     for a = 1:numss %for each animal
     datalength = size(outgroup.(Grouplabels{g}).FP.(ProcessData{p}).(conds{c}).(behavmeas{bm}).Corr.(flds{z}).Z_dFF.Peak.(FPdatatypes{x}).(FPcorrwin{p}{cw}).(maxresponse_labels{p}{m}).trials{r,a},1); %number of trials
     outexcel(outindx+1:outindx+datalength,1) = num2cell(outgroup.(Grouplabels{g}).FP.(ProcessData{p}).(conds{c}).(behavmeas{bm}).Corr.(flds{z}).Z_dFF.Peak.(FPdatatypes{x}).(FPcorrwin{p}{cw}).(maxresponse_labels{p}{m}).trials{r,a});
         for d = 1:length(DLCdatatypes) %get DLCdata               
         outexcel(outindx+1:outindx+datalength,d+1) = num2cell(outgroup.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).(behavmeas{bm}).Corr.(flds{z}).(maxresponse_labels{p}{m}).(DLCdatatypes{d}).trials{r,a});
         end
         outindx = length(outexcel(:,1));
     end
    writecell(outexcel,spreadsheetsavename,'filetype','spreadsheet','Sheet',strcat((FPdatatypes{x}),'-',(row_labels{r})));    
    clear outexcel
    end
    end
    end
end
end
end
end
end
end
end


% %get trial correl values
%Approach and Orient bouts
clear bouttypes
idx = 1
if isfield(DLCsubfields,'DistTo')
    bouttypes{idx} = 'Approach';
    idx = idx + 1;
end
if isfield(DLCsubfields,'Angle')
    bouttypes{idx} = 'Orient';
    idx = idx + 1;
end
    
FPdatatypes = {'peakval','latency','AUC'};
DLCdatatypes = {'Latency','Duration','Time'};
for bt = 1:length(bouttypes)
for p  = 1:length(ProcessData)
    for cw = 1:length(FPcorrwin{p})

    if strcmp(bouttypes{bt},'Approach')
        measure = 'DistTo';
    end
    if strcmp(bouttypes{bt},'Orient')
        measure = 'Angle';
    end
    flds = DLCsubfields.(measure){1};
    for z = 1:length(flds)
    refr = DLCsubfields.(measure){2}{z};
    for y = 1:length(refr)

for m = 1:length(maxresponse_labels{p})
conds = setcond.(ProcessData{p}){2}; %get labels for  possible trial types from metadata 
for c = 1
if isfield(outgroup.(Grouplabels{g}).FP.(ProcessData{p}),(conds{c}))  
if isfield(outgroup.(Grouplabels{g}).FP.(ProcessData{p}).(conds{c}),(bouttypes{bt})) 
savedirxls = strcat(PATH,savefolder,fsep,'StatsOutput-Correl',fsep,(bouttypes{bt}),fsep,'FP-',FPcorrwin{p}{cw},fsep);
if ~exist(savedirxls, 'dir')
mkdir(savedirxls);
end
    for x = 1:length(FPdatatypes)
    for r = 1:numrecs
     outexcel{1,1} = strcat('FP-',(FPdatatypes{x}));
     outexcel(1,2:length(DLCdatatypes)+1) = DLCdatatypes;
     spreadsheetsavename = strcat(savedirxls,(flds{z}),'_',(refr{y}),(maxresponse_labels{p}{m}),'_',(Grouplabels{g}),'.xlsx');
     outindx = 1;
     numss = size(outgroup.(Grouplabels{g}).FP.(ProcessData{p}).(conds{c}).(bouttypes{bt}).Corr.(flds{z}).(refr{y}).Z_dFF.Peak.(FPdatatypes{x}).(FPcorrwin{p}{cw}).(maxresponse_labels{p}{m}).trials,2);
     for a = 1:numss %for each animal
     datalength = size(outgroup.(Grouplabels{g}).FP.(ProcessData{p}).(conds{c}).(bouttypes{bt}).Corr.(flds{z}).(refr{y}).Z_dFF.Peak.(FPdatatypes{x}).(FPcorrwin{p}{cw}).(maxresponse_labels{p}{m}).trials{r,a},1); %number of trials
     outexcel(outindx+1:outindx+datalength,1) = num2cell(outgroup.(Grouplabels{g}).FP.(ProcessData{p}).(conds{c}).(bouttypes{bt}).Corr.(flds{z}).(refr{y}).Z_dFF.Peak.(FPdatatypes{x}).(FPcorrwin{p}{cw}).(maxresponse_labels{p}{m}).trials{r,a});
         for d = 1:length(DLCdatatypes) %get DLCdata               
         outexcel(outindx+1:outindx+datalength,d+1) = num2cell(outgroup.(Grouplabels{g}).DLC.(ProcessData{p}).(conds{c}).(bouttypes{bt}).Corr.(flds{z}).(refr{y}).(DLCdatatypes{d}).(maxresponse_labels{p}{m}).trials{r,a});
         end
         outindx = length(outexcel(:,1));
     end
    writecell(outexcel,spreadsheetsavename,'filetype','spreadsheet','Sheet',strcat((FPdatatypes{x}),'-',(row_labels{r})));    
    clear outexcel
    end
    end
end
end
end
end
end
end
end
end
end
end
end
end %end of group loop

loadname = loadfilename(find(loadfilename == fsep,1,'last')+1:end);
savename = strcat(PATH,savefolder,fsep,loadname,'.mat'); %save outdata for group as .mat folder
save (savename,'outgroup')
clearvars
disp ('analysis complete');
