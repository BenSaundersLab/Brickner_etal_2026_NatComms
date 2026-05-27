%Add DLC to VIDS
clearvars
fsep = filesep;
onefileonly = true; %set to false if you would like to add DLC data to videos from more than one animal
googledrive = true; %check to see if path is to google drive and use personal path to access
%personalpath = '/Users/amywolff/Library/CloudStorage/GoogleDrive-awolff@umn.edu' ; %path from your computer to googledrive
personalpath = 'G:\' ; %path from your computer to googledrive

if onefileonly
%      listdata{1,1} = ['/Users/amywolff/Library/CloudStorage/GoogleDrive-awolff@umn.edu/Shared drives/AmyWolff/SCanalysis/New/OptoPav_EventLocked_Exclusion_Actual'];%G:\Shared drives\AmyWolff\MatlabTemp\Freeze';
%      listdata{1,2} = 'SC1.mat'; %name of .mat file including full path
listdata{1,1} = ['/Users/amywolff/Library/CloudStorage/GoogleDrive-awolff@umn.edu/Shared drives/MargaretStelzner2/Photometry/Gad/Analyzed/Conflict/ShockZoneApproach'];%G:\Shared drives\AmyWolff\MatlabTemp\Freeze';
listdata{1,2} = 'GadGCaMP3.mat';
else   
    loadfilelist = 'G:\Shared drives\AmyWolff/SCanalysis/New/OptoPav_EventLocked\Eventvidlist.xlsx'; %#ok<UNRCH> %list of .matfiles to load path/.mat file
    [~,~,listdata] = xlsread(loadfilelist);  
end

nfiles = size(listdata,1); 

for f = 1:nfiles
    PATH = listdata{f,1};
    FILE = listdata{f,2};
        if PATH(end) ~= '\' && PATH(end) ~= '/'
        PATH= strcat(PATH,fsep);
        end
    filetoload = strcat(PATH,FILE);
    if googledrive
    filetoload = googleconvert_fname(filetoload,personalpath)
    end
    filetoload = formatconvert_fname(filetoload);

    load(filetoload);
    clear filetoload

if f == 1 %only get user selections/metadata for first file
%% metadata
if outdata.UserVals.ProcessSubset 
    ProcessData = outdata.UserVals.DefineData(outdata.UserVals.SubsetIndx);
else
    ProcessData = outdata.UserVals.DefineData;
end
setcond = outdata.UserVals.setcond;
maxwins.label = outdata.metadata.perievent.maxwins.label;
maxwins.timepoints = outdata.metadata.perievent.maxwins.timepoints;

%% user selects datatypes
[indx] = listdlg('ListString',ProcessData,'PromptString','Select data types' ); %user to select processdata
ProcessData = ProcessData(indx);
maxwins.label = maxwins.label(indx);
maxwins.timepoints = maxwins.timepoints(indx);
clear indx 
%% user selects time windows
for p = 1:length(ProcessData)
[indx] = listdlg('ListString',maxwins.label{p},'PromptString',strcat('Select time windows for ',ProcessData{p})); %user to select DLC datatypes
maxwins.label{p} = maxwins.label{p}(indx);
maxwins.timepoints{p} = maxwins.timepoints{p}(indx);
end
%% user selects DLCdata
%measures selection
DLC.measures = outdata.UserVals.DLCsetup.measures;
DLC.labels = outdata.UserVals.DLCsetup.axislabels;
if ~isempty(DLC.measures)
[indx] = listdlg('ListString',DLC.measures,'PromptString','Select DLC data to add to videos','CancelString','No Selection'); %user to select DLC datatypes
DLC.measures = DLC.measures(indx);
DLC.labels = DLC.labels(indx);
    for i = 1:length(indx) %extract subfields for selected measures
    subfields.(DLC.measures{1,(i)}) = outdata.UserVals.DLCsetup.Subfields.(DLC.measures{1,(i)});   
    end
clear indx i

%subfield selection
for m = 1: length(DLC.measures)
flds =  subfields.(DLC.measures{m}){1}; %always get first subcat - exists for all measures
if length(flds) > 1 %if there is more than one choice prompt user
    [indx] = listdlg('ListString',flds,'PromptString',{'Select Subfield for:',...
    (DLC.measures{m})},'CancelString','No Selection'); %user to select DLC datatypes
    DLC.subfields.(DLC.measures{m}){1} = flds(indx);
else
    DLC.subfields.(DLC.measures{m}){1} = flds;
    indx = 1;
end
        if isempty(indx) %if nothing selected remove measure from subsequent analysis
        subfields = rmfield(subfields,(DLC.measures{m})); 
        DLC.measures(m) = []; 
        flds = [];
        else %if data is selected then continue to look for further subcategories
            numsubcats = length(subfields.(DLC.measures{m}));
            switch numsubcats
            case 2
                for x = 1:length(flds)
                refr = subfields.(DLC.measures{m}){2}(x,:); %get refr points
                if length(refr) > 1 % if there is more than one option prompt for choice
                [indx] = listdlg('ListString',refr,'PromptString',{'Select reference for:',...
                strcat(DLC.measures{m},':',(flds{x}))}); %user to select DLC datatypes
                DLC.subfields.(DLC.measures{m}){2}(x,:) = refr(indx);
                else
                DLC.subfields.(DLC.measures{m}){2}(x,:) = refr;
                end
                clear refr
                end
                
            case 3
                for x = 1:length(flds)
                refr = subfields.(DLC.measures{m}){2}(x,:); %get refr points 
                if length(refr) > 1 % if there is more than one option prompt for choice
                [indx] = listdlg('ListString',refr,'PromptString',{'Select reference for:',...
                strcat(DLC.measures{m},':',(flds{x}))}); %user to select DLC datatypes
                DLC.subfields.(DLC.measures{m}){2}(x,:) = refr(indx);
                else
                DLC.subfields.(DLC.measures{m}){2}(x,:) = refr;
                end 
                    for r = 1:length(DLC.subfields.(DLC.measures{m}){2}(x,:))%with user selected list go through and extract relevant measures
                        degs = subfields.(DLC.measures{m}){3}(indx(r),:);
                        if length(degs) > 1 % if there is more than one choice prompt user
                            [dindx] = listdlg('ListString',degs{x,r},'PromptString',{'Select reference for:',...
                            strcat(DLC.measures{m},':',(flds{x}),'-',(DLC.subfields.(DLC.measures{m}){2}{x}{r}))}); %user to select DLC datatypes
                            DLC.subfields.(DLC.measures{m}){3}{x,r} = degs(dindx);
                        else
                            DLC.subfields.(DLC.measures{m}){3}{x,r} = degs;
                        end
                    end
                    clear indx refr degs dindx
                end               
            end  
        end
end
end
clear subfields
%vector selection
vectorcoords  = outdata.UserVals.DLCsetup.Subfields.VectorCoord{1,1}; %get vector list
[indx] = listdlg('ListString',vectorcoords,'PromptString','Select vectors to plot','CancelString','No Selection'); %user to select DLC datatypes
DLC.vectorcoords = vectorcoords(indx);
clear indx
%bodypart label selection
bps  = outdata.UserVals.DLC.bps; %get bodyparts list
[indx] = listdlg('ListString',bps,'PromptString','Select bodyparts to label','CancelString','No Selection'); %user to select DLC datatypes
DLC.bps = bps(indx);
clear indx
%environment feature label selection
environfeats  = outdata.UserVals.DLC.environfeatlabs; %get environfeat list
[indx] = listdlg('ListString',environfeats,'PromptString','Select environ feats to label','CancelString','No Selection'); %user to select DLC datatypes
DLC.environfeats = environfeats(indx);
clear indx

%LED label selection
LEDs  = outdata.UserVals.DLC.LED; %get LED list
[indx] = listdlg('ListString',LEDs,'PromptString','Select LEDs to label','CancelString','No Selection'); %user to select DLC datatypes
DLC.LEDs = LEDs(indx);
clear indx


%approach selection
if isfield(outdata.UserVals,'approaches') && sum(strcmp(outdata.UserVals.DLCsetup.measures,'DistTo')) == 1
if outdata.UserVals.approaches
    choicelist = {'Yes','No'};
    [indx] = listdlg('ListString',choicelist,'PromptString','Plot approach? y/n','CancelString','No Selection'); %user to select DLC datatypes
        if indx == 1
        DLC.approach = true;
        %get further selections
        %EnvironFeat
        if length(outdata.UserVals.DLCsetup.Subfields.DistTo{1}) > 1
        approachenvironfeats  = outdata.UserVals.DLCsetup.Subfields.DistTo{1,1}; %get vector list
        [indx] = listdlg('ListString',approachenvironfeats,'PromptString','Select environment feature for approach','CancelString','No Selection',SelectionMode='single'); %user to select DLC datatypes
        DLC.approachenvironfeat = approachenvironfeats{indx};
        if isempty(indx)
            DLC.approach = false;
        end
        else
        mb = msgbox ("Using only available environment feature for approach: " + outdata.UserVals.DLCsetup.Subfields.DistTo{1,1}{1});
        uiwait(mb)
        DLC.approachenvironfeat = outdata.UserVals.DLCsetup.Subfields.DistTo{1,1}{1};
        indx = 1;
        end
        else
        DLC.approach = false;
        end
        
        if DLC.approach %if an approaches and an environment feature were selected then choose a bodypart
        approachbodyparts  = outdata.UserVals.DLCsetup.Subfields.DistTo{1,2}{indx}; %get vector list    
        if length(approachbodyparts) > 1
        [indx] = listdlg('ListString',approachbodyparts,'PromptString','Select bodypart for approach','CancelString','No Selection','SelectionMode','single'); %user to select DLC datatypes
        if ~isempty(indx)
        DLC.approachbodypart = approachbodyparts{indx};
        DLC.approach = true;
        else
            DLC.approach = false;
        end
        else
            DLC.approachbodypart = approachbodyparts{1};
        end
        end
end 
end

%orient selection
if isfield(outdata.UserVals,'orienting') && sum(strcmp(outdata.UserVals.DLCsetup.measures,'Angle')) == 1;
if outdata.UserVals.orienting
    choicelist = {'Yes','No'};
    [indx] = listdlg('ListString',choicelist,'PromptString','Plot orients? y/n','CancelString','No Selection'); %user to select DLC datatypes
        if indx == 1
        DLC.orient = true;
        %get further selections
        %EnvironFeat
        if length(outdata.UserVals.DLCsetup.Subfields.Angle{1}) > 1
        orientenvironfeats  = outdata.UserVals.DLCsetup.Subfields.Angle{1,1}; %get vector list
        [indx] = listdlg('ListString',orientenvironfeats,'PromptString','Select environment feature for orients','CancelString','No Selection','SelectionMode','single'); %user to select DLC datatypes
        DLC.orientenvironfeat = orientenvironfeats{indx};
        if isempty(indx)
            DLC.orient = false;
        end
        else
        mb = msgbox ("Using only available environment feature for orient: " + outdata.UserVals.DLCsetup.Subfields.Angle{1,1}{1});
        uiwait(mb)
        DLC.orientenvironfeat = outdata.UserVals.DLCsetup.Subfields.Angle{1,1}{1};
        indx = 1;
        end
        else
        DLC.orient = false;
        end
        
        if DLC.orient %if an approaches and an environment feature were selected then choose a bodypart
        orientbodyparts  = outdata.UserVals.DLCsetup.Subfields.Angle{1,2}{indx}; %get vector list
        if length(orientbodyparts) > 1
        [indx] = listdlg('ListString',orientbodyparts,'PromptString','Select vector for orient','CancelString','No Selection','SelectionMode','single'); %user to select DLC datatypes
        if ~isempty(indx)
        DLC.orientbodypart = orientbodyparts{indx};
        else
            DLC.orient = false;
        end        
        else
        DLC.orientbodypart = orientbodyparts{1};
        end
        end
end 
end


%bout selection
    if outdata.UserVals.locobouts
    choicelist = {'Yes','No'};
    [indx] = listdlg('ListString',choicelist,'PromptString','Plot locobouts? y/n','CancelString','No Selection'); %user to select DLC datatypes
        if indx == 1
        DLC.locobouts = true;
        else
        DLC.locobouts = false;
        end
    end
    if outdata.UserVals.freezingbouts
    choicelist = {'Yes','No'};
    [indx] = listdlg('ListString',choicelist,'PromptString','Plot freeze bouts? y/n','CancelString','No Selection'); %user to select DLC datatypes
        if indx == 1
        DLC.freezebouts = true;
        else
        DLC.freezebouts = false;
        end
    end
end

numrecs = length(outdata.metadata.subj(:,1));
for r = 1:numrecs
%find conditions for current datatypen
for p = 1:length(ProcessData)
conditions = setcond.(ProcessData{p}){1,2};
savepath = strcat(PATH,'DLCvids',fsep,(ProcessData{p}));
if googledrive
    savepath = googleconvert_fname(savepath,personalpath)
end
%createDLCvids_cumulang(r,outdata,ProcessData{p},conditions,DLC,maxwins.label{p},maxwins.timepoints{p},savepath,googledrive, personalpath);
createDLCvids_kaisa(r,outdata,ProcessData{p},conditions,DLC,maxwins.label{p},maxwins.timepoints{p},savepath,googledrive, personalpath);

end
end
end %end file loop
