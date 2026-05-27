function [UserVals]=DLC_SelectUserOptions(UserVals)
%% DLC setup
    UserVals.DLC.bps = {'Nose','Implant','L_ear','R_ear','L_eye','R_eye','Shoulder','MidBack','TopBack','BottomBack','Tail_base','CofHead','CathPort'};
    UserVals.DLC.environfeats = {'Cue_location','LeftTop','LeftBottom','RightTop','RightBottom','TopPort','BottomPort','Top_light','LeftMag','RightMag'};
    UserVals.DLC.environfeatlabs = {'BottomLight','LeftTop','LeftBottom','RightTop','RightBottom','TopPort','BottomPort','TopLight','LeftMag','RightMag','CenterofEnviron','BottomLever','TopLever'};
    UserVals.DLC.LED = {'Bot_LED','Mid_LED','Top_LED'};
   
if ~isfield(UserVals,'DLCsetup') 
    DLCmeasures = {'Speed','Angle','DistTo','MoveDist','AngularVelocity','Quadrant','HeadvsBody'};
    DLCaxislabels = {'(cm/sec)','degrees','(cm)','(cm)','Deg/s','perc','Ang'};
    Subfields = struct;
if UserVals.DLCAnalysis
if ~UserVals.DLC.Analyseall %only ask for user selections if needed
    %user to select DLC measures
    [indx] = listdlg('ListString',DLCmeasures,'PromptString',{'Select DLC measures' ...
        '(DistTo required for approach/'...
        'Angle required for Orient)'},'CancelString','No Selection'); %user to select DLC datatypes 
    if isempty(indx)
    DLCsetup.measures = [];
    DLCsetup.axislabels = [];
    DLCsetup.Subfields = [];
    else
    DLCsetup.measures = DLCmeasures(indx);
    DLCsetup.axislabels = DLCaxislabels(indx);
    clear indx
    end
else
    DLCsetup.measures = DLCmeasures;
    DLCsetup.axislabels = DLCaxislabels;
end

measures.MoveDist{1} =  {'Nose','Implant','Shoulder','MidBack'};
measures.DistTo{1} = {'BottomLight','TopLight','LeftTop','LeftBottom','RightTop','RightBottom','TopPort','BottomPort','LeftMag','RightMag','BottomLever','TopLever'};
measures.DistTo{2}(1,:) = {'Nose','Implant'};
measures.Speed{1} = {'Nose','Implant','L_ear','R_ear','L_eye','R_eye','Shoulder','MidBack','TopBack','BottomBack','Tail_base'};
measures.Angle{1} = {'BottomLight','TopLight','LeftTop','LeftBottom','RightTop','RightBottom','TopPort','BottomPort','LeftMag','RightMag','BottomLever','TopLever'};
measures.Angle{2}(1,:) = {'ItoNT','MtoI','ItoS'};
measures.Angle{3}(1,:) = {'degrees_180','degrees_dir','degrees_360'};
Subfields.VectorCoord{1} = {'ItoNT','MtoI','StoB','StoM','ItoS'};

measures.AngularVelocity{1} = {'StoM','ItoNT'};
measures.Quadrant{1} = {'Implant','Shoulder','MidBack'};
% Subfields.AngularVelocity{1} = {'StoM','ItoNT'};

measures.Quadrant{1} = {'Implant','MidBack'};
measures.HeadvsBody{1} = {'Ang'};

if ~UserVals.locobouts && ~UserVals.freezingbouts && ~UserVals.approaches && ~UserVals.orienting && isempty(DLCsetup.measures)
    UserVals.DLCAnalysis = false;
end

if UserVals.DLCAnalysis
    y = 1;
for m = 1:length(DLCsetup.measures)
    numsubfields = length(measures.(DLCsetup.measures{m}));
if ~UserVals.DLC.Analyseall %only ask for user selections if needed
    flds = measures.(DLCsetup.measures{m}){1};
    if length(flds) > 1% if there is more than one option prompt for choice
    [x_indx] = listdlg('ListString',flds,'PromptString',{'Select DLC subcategories for:',...
            (DLCsetup.measures{m}),''},'CancelString','No Selection'); %user to select DLC datatypes 
            if ~isempty(x_indx)
            Subfields.(DLCsetup.measures{m}){1} = measures.(DLCsetup.measures{m}){1}(x_indx);%save selected categories
            else
            Rmindx(y) = m; %if required subcategories not selected save indx to remove measure
            y = y+1;
            end
    else
            Subfields.(DLCsetup.measures{m}){1} = measures.(DLCsetup.measures{m}){1}(1);%save selected categories
            x_indx = 1;
    end

    switch numsubfields
    case 2
            if ~isempty(x_indx)%if there are categories choseen               
            for x = 1:length(x_indx)%for selected subcategories save reference points
                refr = measures.(DLCsetup.measures{m}){2};
                if length(refr) > 1 %if there is more than one reference point prompt for choice
                prompttext = strcat((DLCsetup.measures{m}),':',(Subfields.(DLCsetup.measures{m}){1}{x}));
                if length(refr) > 1 %if there is more than one reference point prompt for choice
                [r_indx] = listdlg('ListString',refr,'PromptString',{'Select ref points for :'...
                (prompttext),''}); %user to select DLC reference points for selected measures 
                    if ~isempty(r_indx)
                    Subfields.(DLCsetup.measures{m}){2}{x}= refr(r_indx);
                    else
                    Rmindx(y) = m; %if required subcategories not selected save indx to remove measure
                    y = y+1;
                    end
                else
                Subfields.(DLCsetup.measures{m}){2}{x}= refr;
                r_indx = 1; %#ok<NASGU>
                end
                end
            end
            end
            
    case 3  
            if ~isempty(x_indx)%if there are categories chosen select reference points               
            for x = 1:length(x_indx)%for selected subcategories save reference points
                refr = measures.(DLCsetup.measures{m}){2};
                prompttext = strcat((DLCsetup.measures{m}),':',(Subfields.(DLCsetup.measures{m}){1}{x}));
                if length(refr) > 1 %if there is more than one reference point prompt for choice
                [r_indx] = listdlg('ListString',refr,'PromptString',{'Select ref points for :'...
                (prompttext),''}); %user to select DLC reference points for selected measures 
                    if ~isempty(r_indx)
                    Subfields.(DLCsetup.measures{m}){2}{x}= refr(r_indx);
                    else
                    Rmindx(y) = m; %if required subcategories not selected save indx to remove measure
                    y = y+1;
                    end
                else
                Subfields.(DLCsetup.measures{m}){2}{x}= refr;
                r_indx = 1;
                end
            
                for r = 1:length(r_indx)%for selected referencepoints get measures %will need to change this if more than angle
                degs = measures.(DLCsetup.measures{m}){3}; 
                Subfields.(DLCsetup.measures{m}){3}{x,r}= degs;
                end
            end
            end
    end
else
    flds = measures.(DLCsetup.measures{m}){1};
        switch numsubfields
                case 1 
                Subfields.(DLCsetup.measures{m}){1} = measures.(DLCsetup.measures{m}){1};  
                clear x flds
                case 2
                refr = measures.(DLCsetup.measures{m}){2};
                Subfields.(DLCsetup.measures{m}){1} = measures.(DLCsetup.measures{m}){1};
                for x = 1:length(flds)
                    Subfields.(DLCsetup.measures{m}){2}{x}= refr;
                end
                clear refr x flds
                
                case 3
                Subfields.(DLCsetup.measures{m}){1} = measures.(DLCsetup.measures{m}){1};
                refr = measures.(DLCsetup.measures{m}){2};
                degs = measures.(DLCsetup.measures{m}){3};
                for x = 1:length(flds)
                    Subfields.(DLCsetup.measures{m}){2}{x}= refr;
                    for r = 1:length(refr)
                        Subfields.(DLCsetup.measures{m}){3}{x,r}= degs;
                    end
                end
                clear x r flds degs 
        end   
        
end
end

if isfield(Subfields,'Quadrant')
if sum(strcmp (DLCsetup.measures,'Quadrant')) == 1
    for x = 1:length(Subfields.Quadrant{1})
    Subfields.Quadrant{2}{x}  = {'LT','LB','RT','RB'};
    end
end
end

if isfield(Subfields,'AngularVelocity')
if sum(strcmp(DLCsetup.measures,'AngularVelocity')) == 1
    for x = 1:length(Subfields.AngularVelocity{1})
    Subfields.AngularVelocity{2}{x}  = {'Ang','AbsAng','Velocity','AbsVelocity'};
    end
end
end

if sum(strcmp(DLCsetup.measures,'HeadvsBody')) == 1
    Subfields.HeadvsBody{1}  = {'Ang','AbsAng','Velocity','AbsVelocity'};
end

if exist('Rmindx','var')
DLCsetup.measures(Rmindx) = []; %remove fields without valid subcategories
end
if isempty(DLCsetup.measures)
    clear DLCsetup
end
end
clear DLCmeasures measures DLCaxislabels m numsubfields y

  if ~exist('DLCsetup','var')
        DLCsetup.measures = [];
        DLCsetup.axislabels = [];
        DLCsetup.Subfields = [];
  end  
   
if UserVals.freezingbouts || UserVals.locobouts  
   if UserVals.freezingbouts
    if ~isfield(UserVals,'freezebps') % select bodyparts only once
        Freezelist = {'Use Default','Select Bodyparts'};
        [indx] = listdlg('ListString',Freezelist,'PromptString',{'Bodyparts to use for' ... 
            'freezing bouts'},'CancelString','No Selection'); %user to select DLC datatypes
        if indx == 1
        DLCsetup.freezebps = {'Nose','Implant','L_ear','R_ear','Shoulder','MidBack','TopBack','BottomBack'};
        clear indx
        else
            if ~isempty(indx)
            %User selects which bps to use for freeze analysis
            [indx] = listdlg('ListString',UserVals.bps,'PromptString',{'Select bodyparts for' ... 
            'freezing bouts'},'CancelString','No Selection'); %user to select DLC datatypes
            else
            indx = [];
            end
            while length(indx) < 2 
            if isempty(indx) 
            UserVals.freezingbouts = false;
            DLCsetup.freezebps = [];
            clear indx
            uiwait(msgbox("Freezing analysis will be skipped - insufficient selections","Error","error"));
            break
            end
            %User selects which bps to use for freeze analysis
            uiwait(msgbox("At least 2 bodyparts are required for freezing bout analysis, select additional bodyparts or choose 'no selection' to skip bout analysis","Error","error"));
            [indx] = listdlg('ListString',UserVals.DLC.bps,'PromptString',{'Select bodyparts for' ... 
                'freezing bouts'},'CancelString','No Selection'); %user to select DLC datatypes 
            end
            if exist('indx','var')
            DLCsetup.freezebps = UserVals.DLC.bps(indx);
            clear indx
            end
        end
    end
    if isempty(DLCsetup.freezebps)
        UserVals.freezingbouts = false;
    end   
   end
   
   if UserVals.locobouts
    if ~isfield(UserVals,'locobps') % select bodyparts only once
        %User selects which bps to use for locobouts analysis
        [indx] = listdlg('ListString',UserVals.DLC.bps,'PromptString',{'Select bodyparts for' ... 
            'locomotion bouts'},'CancelString','No Selection'); %user to select DLC datatypes 
        while length(indx) < 2 
        if isempty(indx) 
        UserVals.locobouts = false;
        DLCsetup.locobps = [];
        clear indx
        break
        end
        uiwait(msgbox("At least 2 bodyparts are required for locomotion bout analysis, select additional bodyparts or choose 'no selection' to skip bout analysis","Error","error"));
        [indx] = listdlg('ListString',UserVals.DLC.bps,'PromptString',{'Select bodyparts for' ... 
            'locomotion bouts'},'CancelString','No Selection'); %user to select DLC datatypes 
        end
        if exist('indx','var')
        DLCsetup.locobps = UserVals.DLC.bps(indx);
        clear indx
        end
    end
    if isempty(DLCsetup.locobps)
       UserVals.locobouts = false;
       uiwait(msgbox("Locomotion analysis will be skipped - insufficient selections","Error","error"));
    end   
   end
end

if UserVals.approaches && ~isfield(Subfields,'DistTo')
    uiwait(msgbox("Approach analysis will be skipped - insufficient measures for DistTo were selected","Error","error"));
    UserVals.approaches = false;
end

if UserVals.orienting && ~isfield(Subfields,'Angle')
    uiwait(msgbox("Orienting analysis will be skipped - insufficient measures for Angle were selected","Error","error"));
    UserVals.orienting = false;
end

%check if DLCsetup is still valid
if UserVals.DLCAnalysis
if ~UserVals.locobouts && ~UserVals.freezingbouts && ~UserVals.approaches && ~UserVals.orienting && isempty(DLCsetup.measures)
    UserVals.DLCAnalysis = false; % if there are no selections for DLC analysis then set to false
    DLCsetup.Subfields = [];
    UserVals.DLCsetup = DLCsetup;
else
    DLCsetup.Subfields = Subfields;
    
    findfield = strcmp(DLCsetup.measures,'Quadrant');
    if sum(findfield) == 1 %if field exists
        DLCsetup.measures(findfield) = [];
    end
    UserVals.DLCsetup = DLCsetup;
    
end
end
else
DLCsetup.measures = [];
DLCsetup.axislabels = [];
DLCsetup.Subfields = [];
UserVals.DLCsetup = DLCsetup;
end
end
