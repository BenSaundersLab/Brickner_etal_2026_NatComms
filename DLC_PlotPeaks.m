function [outdata]= DLC_PlotPeaks(f,outdata,figdir,sniplabel,primarylabel,conditions,wins,maxresponselabs,maxfiglabels,eventstart,eventduration,eventlabel)
                     
%A Wolff 8/31/21
%% Function to generate perievent plots for photometry data
%Inputs:
%f - required to locate data in outfile
%outdata -  data for input and output
%figdir - string - directory to save files
%saveaspdf - flag to save figs as pdf instead of jpg
%plotbuffermagnitude - used to set axis limits beyond range of data
%sniplabel - label for type of data filtering set by user
%primarylabel - label for event @ t0
%conditions - cell array of labels for each condition within the type of data filtering
%wins - time windows of data set for peak analysis
%maxresponselabels - labels for types of data analysed for each window of peak analysis
%maxfiglabels - labels for figure axis
%**eventstart - time of event start relative to t = 0 in secs
%**eventduration - duration of event in secs
%**eventlabel - label for event
%**these inputs not required for function to run, but both needed to plot eventline
saveaspdf = outdata.UserVals.saveaspdf;
plotbuffermagnitude = outdata.UserVals.DLC.Plotbuffermagnitude;

if nargin == 13
    ploteventline = true;
else
    ploteventline = false;
end

paddata = outdata.rawdata.DLC{f,1}.paddata;
fsep = filesep;

%% Set up Figure Labels
figlabelvals = {'Z scored \DeltaF/F'}; %labels for figure y axis
plotdatavals = {'Z_dFF'}; %data to access for each

plotdata = maxresponselabs;
perifiglabel = maxfiglabels;
     
%% plot individual trials
 for m = 1: length(plotdata)  
 for w = 1: length(wins) 
    plotname = strcat({'DLC Peak Plot: '},(wins{w}),'(',(plotdata{m}),')-',outdata.metadata.subjID{1,f},{'__F'},num2str(f));
    plotname = (plotname{1});
    %preallocate legend and plot arrays
    clear legendlabs legendincl
    
    meancolor = NaN(length(conditions),3);
    errorcolor = NaN(length(conditions),3);
    
    numsubfields = length(outdata.UserVals.DLCsetup.Subfields.(plotdata{m}));
    flds = outdata.UserVals.DLCsetup.Subfields.(plotdata{m}){1};
    
    
switch numsubfields
    case 1
     pindx = 1;   
     if  length(conditions) > 1  % if there are probe trials set up subplots for them
         if outdata.UserVals.hideplots
            f2 = figure('name',plotname,'Position',[700, 0, 1000, 1600],'visible','off');
         else
            f2 = figure('name',plotname,'Position',[700, 0, 1000, 1600]);
         end
     else %if there are no probes set up subplot numbers accordingly
         if outdata.UserVals.hideplots
            f2 = figure('name',plotname,'Position',[700, 0, 800, 1000],'visible','off');
         else
            f2 = figure('name',plotname,'Position',[700, 0, 800, 1000]);
         end
     end  

     if isfield(outdata.rawdata,'ISOs') %determine plotn depending on whether FP needs to be plotted
         plotn = length(flds)+1;
     else
         plotn = length(flds);
     end
for x = 1:plotn %+1 to add photometry trace   
    linemin = 0;
    linemax = 1;
for c = 1: length(conditions) 
    %calculate y limits for trial data
        if x == length(flds)+1 %for FP get FP data
            linemintemp = min(min(outdata.perievent.(sniplabel).(conditions{c}).(plotdatavals{1}).Peak.trace.(wins{w}).trials{f,1})); %find max and min values to normalize y axis
            linemaxtemp = max(max(outdata.perievent.(sniplabel).(conditions{c}).(plotdatavals{1}).Peak.trace.(wins{w}).trials{f,1}));
            else %for DLC get DLC data
        linemintemp = min(min(outdata.DLC.(sniplabel).(conditions{c}).(plotdata{m}).(flds{x}).Peak.(wins{w}).trials{f,1})); %find max and min values to normalize y axis
        linemaxtemp = max(max(outdata.DLC.(sniplabel).(conditions{c}).(plotdata{m}).(flds{x}).Peak.(wins{w}).trials{f,1}));   
        end
            if linemintemp < linemin
            linemin = linemintemp;
            end
            if linemaxtemp > linemax
            linemax = linemaxtemp;
            end
            clear linemintemp linemaxtemp  

    if linemin == linemax
        linemin = linemax-1;
    end
    
    plotbuffer = (linemax-linemin)*plotbuffermagnitude;
    linemin = linemin - plotbuffer;
    eventoffset = linemin + (plotbuffer/2);
    linemax = linemax + plotbuffer;   

if x == length(flds)+1 % for FP get FP data
numtraces = length(outdata.perievent.(sniplabel).(conditions{c}).(plotdatavals{1}).Peak.trace.(wins{w}).trials{f,1}(:,1));
peri_time = outdata.timearray.(sniplabel).FP.Peak.(wins{w}){f,1};
else % for DLC get DLC data
numtraces = length(outdata.DLC.(sniplabel).(conditions{c}).(plotdata{m}).(flds{x}).Peak.(wins{w}).trials{f,1}(:,1));
peri_time = outdata.timearray.(sniplabel).DLC.Peak.(wins{w}){f,1};
if paddata 
    temp = NaN(1,length(peri_time));
    temp(1:2:end) = peri_time(1:2:end);
    peri_time = temp;
    plotindx = find(~isnan(peri_time));
end
end

subplot(length(flds)+1,length(conditions)+1,(pindx),'Parent',f2);
 
if c == 1
 cmap = spring(256);
else
 cmap = cool(256);
end   
 meancolor(c,:) = cmap(20,:);
 errorcolor(c,:) = cmap(30,:);
 if numtraces < 256
    if numtraces < 250
    multiplier = floor((length(cmap)-4)/numtraces);
    else
    multiplier = 1;
    end
    cmaparray = cmap;
else
    clear cmaparray
    cmaparray(:,1) = ones(numtraces,1)*(cmap(256/2,1));
    cmaparray(:,2) = ones(numtraces,1)*(cmap(256/2,2));
    cmaparray(:,3) = ones(numtraces,1)*(cmap(256/2,3));
    multiplier = 1;
 end

 cmap = cmaparray;
         
 % multiplier = floor(length(cmap)/numtraces);
 % while length(cmap)< numtraces   
 %     cmap(end+1:(end)+length(cmap),:)=cmap;
 %     multiplier = floor(length(cmap)/numtraces);
 % end
    
    for i = 1:numtraces %plot individual traces for each trial
        if x == length(flds)+1
        plot(peri_time,outdata.perievent.(sniplabel).(conditions{c}).(plotdatavals{1}).Peak.trace.(wins{w}).trials{f,1}(i,:),'Color',cmap(i*multiplier,:));
        hold on
        else
         if paddata
         plot(peri_time(plotindx),outdata.DLC.(sniplabel).(conditions{c}).(plotdata{m}).(flds{x}).Peak.(wins{w}).trials{f,1}(i,plotindx),'Color',cmap(i*multiplier,:));
         hold on
         else
         plot(peri_time,outdata.DLC.(sniplabel).(conditions{c}).(plotdata{m}).(flds{x}).Peak.(wins{w}).trials{f,1}(i,:),'Color',cmap(i*multiplier,:));
         hold on
         end
        end   
    end

      if x == 1 % get eventline and primary line data once only
      if ploteventline  %if the eventline should be plotted figure out what portion (if any) is in the range of x axis 
        eventlinestart = find(peri_time >= eventstart,1,'first');%find start and end of event to plot
        eventlineend = find(peri_time >  eventstart+eventduration,1,'first');
        eventlineend = eventlineend-1;
        if isempty(eventlinestart) && isempty(eventlineend) %if the start and end aren't in the window don't plot
         eventinwin = false;
         clear eventlinestart eventlineend
        else
         eventinwin = true;
        end
      else
          eventinwin = false;
      end
        
        if eventinwin 
            if ~isempty(eventlinestart) && ~isempty(eventlineend) %if both start and end are in plot window then use onset and offset for plotting   
        	eventlinex = peri_time(eventlinestart:eventlineend);          
            else
                if ~isempty(eventlinestart)%if start is not in window set start to beginning of window
                    if eventlineend ~= 1 %only include if end of event is not start of win
                    eventlinex = peri_time(1:eventlineend);
                    else
                    eventinwin = false;
                    end
                else %if end is not in window then set end to end of window
                    if eventlinestart ~= length(peri_time) %only include if start of event is not end of win   
                    eventlinex = peri_time(eventlinestart:end);
                    else
                    eventinwin = false; 
                    end
                end
            end
        end

        
        temp = find(peri_time == 0);
        if ~isempty(temp)
            if temp ~= 1 && temp ~= length(peri_time) %if t0 is not the start or end of trace then plot eventline
            priminwin = true;
            else 
            priminwin = false;
            end
        else
            priminwin = false;
        end
        clear temp
      end

     
    %labels
    if length(conditions) > 1 
        if x < length(flds)+1
        title(strcat((wins{w}),'-',(plotdata{m}),'-',(flds{x}),'-',(conditions{c})),'fontsize',10);
        else
        title(strcat((wins{w}),'-FP Trace-',(conditions{c})),'fontsize',10);   
        end
    else
        if x < length(flds)+1
        title(strcat((wins{w}),'-',(plotdata{m}),'--',(flds{x})),'fontsize',10);
        else
        title(strcat((wins{w}),'-FP Trace'),'fontsize',10); 
        end
    end
    clear temp
    
    if x == length(flds)+1
        ylabel (figlabelvals{1},'fontsize',8);
    else
    ylabel (perifiglabel{m},'fontsize',8);
    end
    temp = strcat({'Time from '},primarylabel,{' (s)'});
    temp = temp{1};
    xlabel(temp,'fontsize',8);
    clear temp

        if priminwin
        xline(0,'--k','Linewidth',1.5,'Alpha',0.3); %plot line to show cue onset
        end
      
        if eventinwin
        eventliney = ones(length(eventlinex))*eventoffset; %set array for eventline
        line(eventlinex,eventliney, 'color','k','Linewidth',2.5); %plot line to show event duration
        end   
        
    ylim([linemin linemax]);
    xlim([peri_time(1) peri_time(end)]);
    pindx = pindx+1;  
end
clear linemin linemax eventliney
%% plot mean 
subplot(length(flds)+1,length(conditions)+1,(pindx),'Parent',f2);
l = 1;
legendlabs = cell(1,length(conditions)); 
legendincl = gobjects(1,length(conditions));
p1 = gobjects(1,length(conditions));

linemin = 0;
linemax = 1;
%calculate y lims for mean data
    if length(conditions) > 1
        for c = 1: length(conditions)
            if x == length(flds)+1 % for FP get FP data
            linemintemp = min(min(outdata.perievent.(sniplabel).(conditions{c}).(plotdatavals{1}).Peak.trace.(wins{w}).mean(f,:))); %find max and min values to normalize y axis
            linemaxtemp = max(max(outdata.perievent.(sniplabel).(conditions{c}).(plotdatavals{1}).Peak.trace.(wins{w}).mean(f,:)));
            else
            linemintemp = min(min(outdata.DLC.(sniplabel).(conditions{c}).(plotdata{m}).(flds{x}).Peak.(wins{w}).mean(f,:))); %find max and min values to normalize y axis
            linemaxtemp = max(max(outdata.DLC.(sniplabel).(conditions{c}).(plotdata{m}).(flds{x}).Peak.(wins{w}).mean(f,:)));
            end
            if linemintemp < linemin
            linemin = linemintemp;
            end
            if linemaxtemp > linemax
            linemax = linemaxtemp;
            end
            clear linemintemp linemaxtemp
        end
    end
    if linemin == linemax
        linemin = linemax-1;
    end
    
    plotbuffer = (linemax-linemin)*(plotbuffermagnitude*4);
    linemin = linemin - plotbuffer;
    eventoffset = linemin + (plotbuffer/2);
    linemax = linemax + plotbuffer; 
    if eventinwin
    eventliney = ones(length(eventlinex))*eventoffset;
    end
    
for c = 1: length(conditions)
    if x == length(flds)+1
    perimean1 = outdata.perievent.(sniplabel).(conditions{c}).(plotdatavals{1}).Peak.trace.(wins{w}).mean(f,:);
    perisem1 = outdata.perievent.(sniplabel).(conditions{c}).(plotdatavals{1}).Peak.trace.(wins{w}).sem(f,:);
    else
    if paddata
    if c ==1
    peri_time = peri_time(plotindx);
    end
    perimean1 = outdata.DLC.(sniplabel).(conditions{c}).(plotdata{m}).(flds{x}).Peak.(wins{w}).mean(f,plotindx);
    perisem1 = outdata.DLC.(sniplabel).(conditions{c}).(plotdata{m}).(flds{x}).Peak.(wins{w}).sem(f,plotindx); 
    else
    perimean1 = outdata.DLC.(sniplabel).(conditions{c}).(plotdata{m}).(flds{x}).Peak.(wins{w}).mean(f,:);
    perisem1 = outdata.DLC.(sniplabel).(conditions{c}).(plotdata{m}).(flds{x}).Peak.(wins{w}).sem(f,:); 
    end
    end

% Make a standard error fill for mean signal

        xx = [peri_time, fliplr(peri_time)];
        yy = [(perimean1) + (perisem1),...
        fliplr((perimean1) - (perisem1))];
        h1 = fill(xx, yy, errorcolor(c,:)); % plot this first for overlay purposes
        hold on;
        set(h1, 'facealpha', 0.25, 'edgecolor', 'none');
        % Plot the signals and the mean signal
        p1(c)= plot(peri_time, perimean1, 'color', meancolor(c,:), 'LineWidth', 1.5);
        legendlabs{l} = (conditions{c});
        legendincl(l) = p1(c);
        l = l+1;
    clear perimean1 perisem1  
end

        if priminwin %if t0 is not the start or end of trace then plot eventline
        pl1 = xline(0,'--k','Linewidth',1.5,'Alpha',0.3); %plot line to show cue onset
        legendlabs{l} = primarylabel;
        legendincl(l) = pl1;
        l = l+1;
        end
        
        if eventinwin
        el1 = line([eventlinex(1) eventlinex(end)],[eventliney(1) eventliney(end)],'color','k','Linewidth',2.5); %plot line to show event duration
        legendlabs{l} = eventlabel;
        legendincl(l) = el1;
        end
        
    ylim([linemin linemax]); 
    xlim([peri_time(1) peri_time(end)]);
    clear peri_time clear el1 pl1 
   
    legend(legendincl,legendlabs,'Location','northeast','Fontsize',5);
    legend('boxoff')
    clear legendlabs legendincl l p1

    if x < length(flds)+1
    title(strcat((wins{w}),'-',(plotdata{m}),'-',(flds{x})),'fontsize',10);
    else      
    title(strcat((wins{w}),'-FP Trace'),'fontsize',10);
    end

    temp = strcat({'Time from '},primarylabel,{' (s)'});
    temp = temp{1};
    xlabel(temp,'fontsize',8);
    clear temp
    if x == length(flds)+1
        ylabel (figlabelvals{1},'fontsize',8);
    else
    ylabel (perifiglabel{m},'fontsize',8);
    end
    pindx = pindx+1;
    clear linemin linemax el1 eventliney
end
    clear priminwin eventinwin
    if isfield(outdata.rawdata,'ISOs')
    savefigdir = strcat(figdir,(plotdata{m}),fsep,(flds{x-1}),fsep,wins{w},fsep);
    else
    savefigdir = strcat(figdir,(plotdata{m}),fsep,(flds{x}),fsep,wins{w},fsep);
    end

if ~exist(savefigdir, 'dir')
       mkdir(savefigdir);
end
%% Generate filenames and save plots - all cases
savename = strcat(savefigdir,outdata.metadata.subjID{1,f},'_',num2str(f));
if saveaspdf
savename = strcat(savename,'.pdf');
f2.Renderer='Painters'; %makes sure figure can be manipulated in illustrator
print(savename,'-dpdf','-bestfit');
else
savename = strcat(savename,'.jpg');
saveas(f2,savename);
end
close all

case 2
for x = 1:length(flds)
        refr = outdata.UserVals.DLCsetup.Subfields.(plotdata{m}){2}{x};
        if  length(conditions) > 1  % if there are probe trials set up subplots for them
         if outdata.UserVals.hideplots
            f2 = figure('name',plotname,'Position',[700, 0, 1000, 1600],'visible','off');
         else
            f2 = figure('name',plotname,'Position',[700, 0, 1000, 1600]);
         end
        else %if there are no probes set up subplot numbers accordingly
         if outdata.UserVals.hideplots
            f2 = figure('name',plotname,'Position',[700, 0, 800, 1000],'visible','off');
         else
            f2 = figure('name',plotname,'Position',[700, 0, 800, 1000]);
         end
        end  
    pindx = 1;
    if isfield(outdata.rawdata,'ISOs')
        numfigs = length(refr)+1; %+1 to add photometry trace
    else
        numfigs = length(refr);
    end
    for r = 1:numfigs %+1 to add photometry trace
    %calculate y limits for trial data
    linemin = 0;
    linemax = 1;
    if length(conditions) > 1
        for c = 1: length(conditions)
        if r == length(refr)+1%for FP get FP data
        linemintemp = min(min(outdata.perievent.(sniplabel).(conditions{c}).(plotdatavals{1}).Peak.trace.(wins{w}).trials{f,1})); %find max and min values to normalize y axis
        linemaxtemp = max(max(outdata.perievent.(sniplabel).(conditions{c}).(plotdatavals{1}).Peak.trace.(wins{w}).trials{f,1}));
        else %for DLC get DLC data
        linemintemp = min(min(outdata.DLC.(sniplabel).(conditions{c}).(plotdata{m}).(flds{x}).(refr{r}).Peak.(wins{w}).trials{f,1})); %find max and min values to normalize y axis
        linemaxtemp = max(max(outdata.DLC.(sniplabel).(conditions{c}).(plotdata{m}).(flds{x}).(refr{r}).Peak.(wins{w}).trials{f,1}));   
        end
            if linemintemp < linemin
            linemin = linemintemp;
            end
            if linemaxtemp > linemax
            linemax = linemaxtemp;
            end
            clear linemintemp linemaxtemp
        end
    end

    if linemin == linemax
        linemin = linemax-1;
    end
    
    plotbuffer = (linemax-linemin)*plotbuffermagnitude;
    linemin = linemin - plotbuffer;
    eventoffset = linemin + (plotbuffer/2);
    linemax = linemax + plotbuffer;   
    
for c = 1: length(conditions)  
if r == length(refr)+1 % for FP get FP data
numtraces = length(outdata.perievent.(sniplabel).(conditions{c}).(plotdatavals{1}).Peak.trace.(wins{w}).trials{f,1}(:,1));
peri_time = outdata.timearray.(sniplabel).FP.Peak.(wins{w}){f,1};
else % for DLC get DLC data
numtraces = length(outdata.DLC.(sniplabel).(conditions{c}).(plotdata{m}).(flds{x}).(refr{r}).Peak.(wins{w}).trials{f,1}(:,1));
peri_time = outdata.timearray.(sniplabel).DLC.Peak.(wins{w}){f,1};
if paddata
    temp = NaN(1,length(peri_time));
    temp(1:2:end) = peri_time(1:2:end);
    peri_time = temp;
    plotindx = find(~isnan(peri_time));
end
end

subplot(length(refr)+1,length(conditions)+1,(pindx),'Parent',f2);
   
if c == 1
 cmap = spring(256);
else
 cmap = cool(256);
end   


 if numtraces < 256
    if numtraces < 250
    multiplier = floor((length(cmap)-4)/numtraces);
    else
    multiplier = 1;
    end
    cmaparray = cmap;
else
    clear cmaparray
    cmaparray(:,1) = ones(numtraces,1)*(cmap(256/2,1));
    cmaparray(:,2) = ones(numtraces,1)*(cmap(256/2,2));
    cmaparray(:,3) = ones(numtraces,1)*(cmap(256/2,3));
    multiplier = 1;
 end

 cmap = cmaparray; 

 meancolor(c,:) = cmap(20,:);
 errorcolor(c,:) = cmap(30,:);

    for i = 1:numtraces %plot individual traces for each trial
        if r == length(refr)+1
        plot(peri_time,outdata.perievent.(sniplabel).(conditions{c}).(plotdatavals{1}).Peak.trace.(wins{w}).trials{f,1}(i,:),'Color',cmap(i*multiplier,:));
        hold on
        else
            if paddata
                plot(peri_time(plotindx),outdata.DLC.(sniplabel).(conditions{c}).(plotdata{m}).(flds{x}).(refr{r}).Peak.(wins{w}).trials{f,1}(i,plotindx),'Color',cmap(i*multiplier,:));
                hold on
            else
                plot(peri_time,outdata.DLC.(sniplabel).(conditions{c}).(plotdata{m}).(flds{x}).(refr{r}).Peak.(wins{w}).trials{f,1}(i,:),'Color',cmap(i*multiplier,:));
                hold on
            end
        end   
    end

      if x == 1 % get eventline and primary line data once only
      if ploteventline  %if the eventline should be plotted figure out what portion (if any) is in the range of x axis 
        eventlinestart = find(peri_time >= eventstart,1,'first');%find start and end of event to plot       
        eventlineend = find(peri_time >  eventstart+eventduration,1,'first');
        eventlineend = eventlineend-1;
        if isempty(eventlinestart) && isempty(eventlineend) %if the start and end aren't in the window don't plot
         eventinwin = false;
         clear eventlinestart eventlineend
        else
         eventinwin = true;
        end
      else
          eventinwin = false;
      end
        
        if eventinwin 
            if ~isempty(eventlinestart) && ~isempty(eventlineend) %if both start and end are in plot window then use onset and offset for plotting   
        	eventlinex = peri_time(eventlinestart:eventlineend);
            else
                if ~isempty(eventlinestart)%if start is not in window set start to beginning of window
                    if eventlineend ~= 1 %only include if end of event is not start of win
                    eventlinex = peri_time(1:eventlineend);
                    else
                    eventinwin = false;
                    end
                else %if end is not in window then set end to end of window
                    if eventlinestart ~= length(peri_time) %only include if start of event is not end of win   
                    eventlinex = peri_time(eventlinestart:end);
                 else
                    eventinwin = false; 
                    end
                end
            end
        end

        
        temp = find(peri_time == 0);
        if ~isempty(temp)
            if temp ~= 1 && temp ~= length(peri_time) %if t0 is not the start or end of trace then plot eventline
            priminwin = true;
            else 
            priminwin = false;
            end
        else
            priminwin = false;
        end
        clear temp
      end

     
    %labels
    if length(conditions) > 1 
        if r < length(refr)+1
        title(strcat((wins{w}),'-',(plotdata{m}),'-',(flds{x}),'(',(refr{r}),')','-',(conditions{c})),'fontsize',10);
        else
        title(strcat((wins{w}),'-FP Trace-',(conditions{c})),'fontsize',10);    
        end
    else
        if r < length(refr)+1
        title(strcat((wins{w}),'-',(plotdata{m}),'-',(flds{x}),'(',(refr{r}),')'),'fontsize',10);
        else
        title(strcat((wins{w}),'-FP Trace'),'fontsize',10); 
        end
    end
    clear temp
    
    if r == length(refr)+1
    ylabel (figlabelvals{1},'fontsize',8);
    else
    ylabel (perifiglabel{m},'fontsize',8);
    end
    temp = strcat({'Time from '},primarylabel,{' (s)'});
    temp = temp{1};
    xlabel(temp,'fontsize',8);
    clear temp

        if priminwin
        xline(0,'--k','Linewidth',1.5,'Alpha',0.3); %plot line to show cue onset
        end
      
        if eventinwin
        eventliney = ones(length(eventlinex))*eventoffset; %set array for eventline
        line(eventlinex,eventliney, 'color','k','Linewidth',2.5); %plot line to show event duration
        end

    ylim([linemin linemax]);
    xlim([peri_time(1) peri_time(end)]);
    pindx = pindx+1;  
end
clear linemin linemax eventliney

%% plot mean 
subplot(length(refr)+1,length(conditions)+1,(pindx),'Parent',f2);
l = 1;
legendlabs = cell(1,length(conditions)); 
legendincl = gobjects(1,length(conditions));
p1 = gobjects(1,length(conditions));
linemin = 0;
linemax = 1;
%calculate y lims for mean data
    if length(conditions) > 1
        for c = 1: length(conditions)
            if r == length(refr)+1 % for FP get FP data
            linemintemp = min(min(outdata.perievent.(sniplabel).(conditions{c}).(plotdatavals{1}).Peak.trace.(wins{w}).mean(f,:))); %find max and min values to normalize y axis
            linemaxtemp = max(max(outdata.perievent.(sniplabel).(conditions{c}).(plotdatavals{1}).Peak.trace.(wins{w}).mean(f,:)));
            else
            linemintemp = min(min(outdata.DLC.(sniplabel).(conditions{c}).(plotdata{m}).(flds{x}).(refr{r}).Peak.(wins{w}).mean(f,:))); %find max and min values to normalize y axis
            linemaxtemp = max(max(outdata.DLC.(sniplabel).(conditions{c}).(plotdata{m}).(flds{x}).(refr{r}).Peak.(wins{w}).mean(f,:)));
            end
            if linemintemp < linemin
            linemin = linemintemp;
            end
            if linemaxtemp > linemax
            linemax = linemaxtemp;
            end
            clear linemintemp linemaxtemp
        end
    end

    if linemin == linemax
        linemin = linemax-1;
    end
    
    plotbuffer = (linemax-linemin)*(plotbuffermagnitude*4);
    linemin = linemin - plotbuffer;
    eventoffset = linemin + (plotbuffer/2);
    linemax = linemax + plotbuffer; 
    if eventinwin
    eventliney = ones(length(eventlinex))*eventoffset;
    end
    
for c = 1: length(conditions)
    if r == length(refr)+1
    perimean1 = outdata.perievent.(sniplabel).(conditions{c}).(plotdatavals{1}).Peak.trace.(wins{w}).mean(f,:);
    perisem1 = outdata.perievent.(sniplabel).(conditions{c}).(plotdatavals{1}).Peak.trace.(wins{w}).sem(f,:);
    else
        if paddata
            if c == 1
            peri_time = peri_time(plotindx);
            end
            perimean1 = outdata.DLC.(sniplabel).(conditions{c}).(plotdata{m}).(flds{x}).(refr{r}).Peak.(wins{w}).mean(f,plotindx);
            perisem1 = outdata.DLC.(sniplabel).(conditions{c}).(plotdata{m}).(flds{x}).(refr{r}).Peak.(wins{w}).sem(f,plotindx);
        else
            perimean1 = outdata.DLC.(sniplabel).(conditions{c}).(plotdata{m}).(flds{x}).(refr{r}).Peak.(wins{w}).mean(f,:);
            perisem1 = outdata.DLC.(sniplabel).(conditions{c}).(plotdata{m}).(flds{x}).(refr{r}).Peak.(wins{w}).sem(f,:);
        end
    end

% Make a standard error fill for mean signal
        xx = [peri_time, fliplr(peri_time)];
        yy = [(perimean1) + (perisem1),...
        fliplr((perimean1) - (perisem1))];
        h1 = fill(xx, yy, errorcolor(c,:)); % plot this first for overlay purposes
        hold on;
        set(h1, 'facealpha', 0.25, 'edgecolor', 'none');
        % Plot the signals and the mean signal
        p1(c)= plot(peri_time, perimean1, 'color', meancolor(c,:), 'LineWidth', 1.5);
        legendlabs{l} = (conditions{c});
        legendincl(l) = p1(c);
        l = l+1;
clear perimean1 perisem1 
end
        if priminwin %if t0 is not the start or end of trace then plot eventline
        pl1 = xline(0,'--k','Linewidth',1.5,'Alpha',0.3); %plot line to show cue onset
        legendlabs{l} = primarylabel;
        legendincl(l) = pl1;
        l = l+1;
        end
        
        if eventinwin
        el1 = line([eventlinex(1) eventlinex(end)],[eventliney(1) eventliney(end)],'color','k','Linewidth',2.5); %plot line to show event duration
        legendlabs{l} = eventlabel;
        legendincl(l) = el1;
        end
        
    ylim([linemin linemax]); 
    xlim([peri_time(1) peri_time(end)]);
    clear peri_time clear el1 pl1 linemin linemax eventliney
   
    legend(legendincl,legendlabs,'Location','northeast','Fontsize',5);
    legend('boxoff');
    clear legendlabs legendincl l p1

    if r < length(refr)+1
    title(strcat((wins{w}),'-',(plotdata{m}),'-',(flds{x}),'(',(refr{r}),')'),'fontsize',10);
    else
    title(strcat((wins{w}),'-FP Trace'),'fontsize',10);
    end

    temp = strcat({'Time from '},primarylabel,{' (s)'});
    temp = temp{1};
    xlabel(temp,'fontsize',8);
    clear temp
    if r == length(refr)+1
    ylabel (figlabelvals{1},'fontsize',8);
    else
    ylabel (perifiglabel{m},'fontsize',8);
    end
    pindx = pindx+1;
    end
    
    savefigdir = strcat(figdir,(plotdata{m}),fsep,(flds{x}),fsep,wins{w},fsep);
if ~exist(savefigdir, 'dir')
       mkdir(savefigdir);
end


%% Generate filenames and save plots - all cases
savename = strcat(savefigdir,outdata.metadata.subjID{1,f},'_',num2str(f));
if saveaspdf
savename = strcat(savename,'.pdf');
f2.Renderer='Painters'; %makes sure figure can be manipulated in illustrator
print(savename,'-dpdf','-bestfit');
else
savename = strcat(savename,'.jpg');
saveas(f2,savename);
end
close all
end

case 3
    for x = 1:length(flds)
        refr = outdata.UserVals.DLCsetup.Subfields.(plotdata{m}){2}{x};      
    for r = 1:length(refr)
        pindx = 1;        
        if  length(conditions) > 1  % if there are probe trials set up subplots for them
         if outdata.UserVals.hideplots
            f2 = figure('name',plotname,'Position',[700, 0, 1000, 1600],'visible','off');
         else
            f2 = figure('name',plotname,'Position',[700, 0, 1000, 1600]);
         end
        else %if there are no probes set up subplot numbers accordingly
         if outdata.UserVals.hideplots
            f2 = figure('name',plotname,'Position',[700, 0, 800, 1000],'visible','off');
         else
            f2 = figure('name',plotname,'Position',[700, 0, 800, 1000]);
         end
        end        
    degs = outdata.UserVals.DLCsetup.Subfields.(plotdata{m}){3}{x,r};
    if isfield(outdata.rawdata,'ISOs')
        nfigs = length(degs)+1;%+1 to add photometry trace
    else
        nfigs = length(degs);
    end
    for d = 1:nfigs     
    %calculate y limits for trial data
     linemin = 0;
     linemax = 1;
    if length(conditions) > 1
        for c = 1: length(conditions)
        if d == length(degs)+1%for FP get FP data
        linemintemp = min(min(outdata.perievent.(sniplabel).(conditions{c}).(plotdatavals{1}).Peak.trace.(wins{w}).trials{f,1})); %find max and min values to normalize y axis
        linemaxtemp = max(max(outdata.perievent.(sniplabel).(conditions{c}).(plotdatavals{1}).Peak.trace.(wins{w}).trials{f,1}));
        else %for DLC get DLC data
        linemintemp = min(min(outdata.DLC.(sniplabel).(conditions{c}).(plotdata{m}).(flds{x}).(refr{r}).(degs{d}).Peak.(wins{w}).trials{f,1})); %find max and min values to normalize y axis
        linemaxtemp = max(max(outdata.DLC.(sniplabel).(conditions{c}).(plotdata{m}).(flds{x}).(refr{r}).(degs{d}).Peak.(wins{w}).trials{f,1}));   
        end
            if linemintemp < linemin
            linemin = linemintemp;
            end
            if linemaxtemp > linemax
            linemax = linemaxtemp;
            end
            clear linemintemp linemaxtemp
        end
    end
    
    if linemin == linemax
        linemin = linemax-1;
    end
    
    plotbuffer = (linemax-linemin)*plotbuffermagnitude;
    linemin = linemin - plotbuffer;
    eventoffset = linemin + (plotbuffer/2);
    linemax = linemax + plotbuffer;   

for c = 1: length(conditions)  
     
if d == length(degs)+1 % for FP get FP data
numtraces = length(outdata.perievent.(sniplabel).(conditions{c}).(plotdatavals{1}).Peak.trace.(wins{w}).trials{f,1}(:,1));
peri_time = outdata.timearray.(sniplabel).FP.Peak.(wins{w}){f,1};
else % for DLC get DLC data
numtraces = length(outdata.DLC.(sniplabel).(conditions{c}).(plotdata{m}).(flds{x}).(refr{r}).(degs{d}).Peak.(wins{w}).trials{f,1}(:,1));
peri_time = outdata.timearray.(sniplabel).DLC.Peak.(wins{w}){f,1};
if paddata
    temp = NaN(1,length(peri_time));
    temp(1:2:end) = peri_time(1:2:end);
    peri_time = temp;
    plotindx = find(~isnan(peri_time));
end
end

subplot(length(degs)+1,length(conditions)+1,(pindx),'Parent',f2);
   
if c == 1
 cmap = spring(256);
else
 cmap = cool(256);
end   
 meancolor(c,:) = cmap(20,:);
 errorcolor(c,:) = cmap(30,:);
 % multiplier = floor(length(cmap)/numtraces);
 if numtraces < 256
    if numtraces < 250
    multiplier = floor((length(cmap)-4)/numtraces);
    else
    multiplier = 1;
    end
    cmaparray = cmap;
else
    clear cmaparray
    cmaparray(:,1) = ones(numtraces,1)*(cmap(256/2,1));
    cmaparray(:,2) = ones(numtraces,1)*(cmap(256/2,2));
    cmaparray(:,3) = ones(numtraces,1)*(cmap(256/2,3));
    multiplier = 1;
end

cmap = cmaparray;

    for i = 1:numtraces %plot individual traces for each trial
        if d == length(degs)+1
        plot(peri_time,outdata.perievent.(sniplabel).(conditions{c}).(plotdatavals{1}).Peak.trace.(wins{w}).trials{f,1}(i,:),'Color',cmap(i*multiplier,:));
        hold on
        else
            if paddata
                plot(peri_time(plotindx),outdata.DLC.(sniplabel).(conditions{c}).(plotdata{m}).(flds{x}).(refr{r}).(degs{d}).Peak.(wins{w}).trials{f,1}(i,plotindx),'Color',cmap(i*multiplier,:));
                hold on
            else
                plot(peri_time,outdata.DLC.(sniplabel).(conditions{c}).(plotdata{m}).(flds{x}).(refr{r}).(degs{d}).Peak.(wins{w}).trials{f,1}(i,:),'Color',cmap(i*multiplier,:));
                hold on
            end
        end   
    end

      if x == 1 % get eventline and primary line data once only
      if ploteventline  %if the eventline should be plotted figure out what portion (if any) is in the range of x axis 
        eventlinestart = find(peri_time >= eventstart,1,'first');%find start and end of event to plot
        eventlineend = find(peri_time >=  eventstart+eventduration,1,'first');
        eventlineend = eventlineend-1;
        if isempty(eventlinestart) && isempty(eventlineend) %if the start and end aren't in the window don't plot
         eventinwin = false;
         clear eventlinestart eventlineend
        else
         eventinwin = true;
        end
      else
          eventinwin = false;
      end
        
        if eventinwin 
            if ~isempty(eventlinestart) && ~isempty(eventlineend) %if both start and end are in plot window then use onset and offset for plotting   
        	eventlinex = peri_time(eventlinestart:eventlineend);           
            else
                if ~isempty(eventlinestart)%if start is not in window set start to beginning of window
                    if eventlineend ~= 1 %only include if end of event is not start of win
                    eventlinex = peri_time(1:eventlineend);
                    else
                    eventinwin = false;
                    end
                else %if end is not in window then set end to end of window
                    if eventlinestart ~= length(peri_time) %only include if start of event is not end of win   
                    eventlinex = peri_time(eventlinestart:end);
                    else
                    eventinwin = false; 
                    end
                end
            end
        end

        
        temp = find(peri_time == 0);
        if ~isempty(temp)
            if temp ~= 1 && temp ~= length(peri_time) %if t0 is not the start or end of trace then plot eventline
            priminwin = true;
            else 
            priminwin = false;
            end
        else
            priminwin = false;
        end
        clear temp
      end

     
    %labels
    if length(conditions) > 1 
        if d < length(degs)+1
        title(strcat((wins{w}),'-',(plotdata{m}),'-',(flds{x}),'(',(refr{r}),'-',(degs{d}),')-',(conditions{c})),'fontsize',10);
        else
        title(strcat((wins{w}),'-FP Trace-',(conditions{c})),'fontsize',10);    
        end
    else
        if d < length(degs)+1
        title(strcat((wins{w}),'-',(plotdata{m}),'-',(flds{x}),'(',(refr{r}),(degs{d}),')'),'fontsize',10);
        else
        title(strcat((wins{w}),'-FP Trace'),'fontsize',10); 
        end
    end
    clear temp
    
    if d == length(degs)+1
    ylabel (figlabelvals{1},'fontsize',8);
    else
    ylabel (perifiglabel{m},'fontsize',8);
    end
    temp = strcat({'Time from '},primarylabel,{' (s)'});
    temp = temp{1};
    xlabel(temp,'fontsize',8);
    clear temp

        if priminwin
        xline(0,'--k','Linewidth',1.5,'Alpha',0.3); %plot line to show cue onset
        end
      
        if eventinwin
        eventliney = ones(length(eventlinex))*eventoffset; %set array for eventline    
        line(eventlinex,eventliney, 'color','k','Linewidth',2.5); %plot line to show event duration
        end

    ylim([linemin linemax]);
    xlim([peri_time(1) peri_time(end)]);
    pindx = pindx+1;   
end
clear linemin linemax eventliney

%% plot mean 
subplot(length(degs)+1,length(conditions)+1,(pindx),'Parent',f2);
l = 1;
legendlabs = cell(1,length(conditions)); 
legendincl = gobjects(1,length(conditions));
p1 = gobjects(1,length(conditions));
linemin = 0;
linemax = 1;
%calculate y lims for mean data
   
    if length(conditions) > 1
        for c = 1: length(conditions)
            if d == length(degs)+1 % for FP get FP data
            linemintemp = min(min(outdata.perievent.(sniplabel).(conditions{c}).(plotdatavals{1}).Peak.trace.(wins{w}).mean(f,:))); %find max and min values to normalize y axis
            linemaxtemp = max(max(outdata.perievent.(sniplabel).(conditions{c}).(plotdatavals{1}).Peak.trace.(wins{w}).mean(f,:)));
            else
            linemintemp = min(min(outdata.DLC.(sniplabel).(conditions{c}).(plotdata{m}).(flds{x}).(refr{r}).(degs{d}).Peak.(wins{w}).mean(f,:))); %find max and min values to normalize y axis
            linemaxtemp = max(max(outdata.DLC.(sniplabel).(conditions{c}).(plotdata{m}).(flds{x}).(refr{r}).(degs{d}).Peak.(wins{w}).mean(f,:)));
            end
            if linemintemp < linemin
            linemin = linemintemp;
            end
            if linemaxtemp > linemax
            linemax = linemaxtemp;
            end
            clear linemintemp linemaxtemp
        end
    end
    
    if linemin == linemax
        linemin = linemax-1;
    end
    
    plotbuffer = (linemax-linemin)*(plotbuffermagnitude*4);
    linemin = linemin - plotbuffer;
    eventoffset = linemin + (plotbuffer/2);
    linemax = linemax + plotbuffer; 
    if eventinwin
    eventliney = ones(length(eventlinex))*eventoffset;
    end
    
for c = 1: length(conditions)
    if d == length(degs)+1
    perimean1 = outdata.perievent.(sniplabel).(conditions{c}).(plotdatavals{1}).Peak.trace.(wins{w}).mean(f,:);
    perisem1 = outdata.perievent.(sniplabel).(conditions{c}).(plotdatavals{1}).Peak.trace.(wins{w}).sem(f,:);
    else
        if paddata
            if c == 1
            peri_time = peri_time(plotindx);
            end
            perimean1 = outdata.DLC.(sniplabel).(conditions{c}).(plotdata{m}).(flds{x}).(refr{r}).(degs{d}).Peak.(wins{w}).mean(f,plotindx);
            perisem1 = outdata.DLC.(sniplabel).(conditions{c}).(plotdata{m}).(flds{x}).(refr{r}).(degs{d}).Peak.(wins{w}).sem(f,plotindx);
        else
            perimean1 = outdata.DLC.(sniplabel).(conditions{c}).(plotdata{m}).(flds{x}).(refr{r}).(degs{d}).Peak.(wins{w}).mean(f,:);
            perisem1 = outdata.DLC.(sniplabel).(conditions{c}).(plotdata{m}).(flds{x}).(refr{r}).(degs{d}).Peak.(wins{w}).sem(f,:);
        end
    end

% Make a standard error fill for mean signal
        xx = [peri_time, fliplr(peri_time)];
        yy = [(perimean1) + (perisem1),...
        fliplr((perimean1) - (perisem1))];
        h1 = fill(xx, yy, errorcolor(c,:)); % plot this first for overlay purposes
        hold on;
        set(h1, 'facealpha', 0.25, 'edgecolor', 'none');
        % Plot the signals and the mean signal
        p1(c)= plot(peri_time, perimean1, 'color', meancolor(c,:), 'LineWidth', 1.5);
        legendlabs{l} = (conditions{c});
        legendincl(l) = p1(c);
        l = l+1;
clear perimean1 perisem1 
end
        if priminwin %if t0 is not the start or end of trace then plot eventline
        pl1 = xline(0,'--k','Linewidth',1.5,'Alpha',0.3); %plot line to show cue onset
        legendlabs{l} = primarylabel;
        legendincl(l) = pl1;
        l = l+1;
        end
        
        if eventinwin
        el1 = line([eventlinex(1) eventlinex(end)],[eventliney(1) eventliney(end)],'color','k','Linewidth',2.5); %plot line to show event duration
        legendlabs{l} = eventlabel;
        legendincl(l) = el1;
        end
        
    ylim([linemin linemax]); 
    xlim([peri_time(1) peri_time(end)]);
    clear peri_time clear el1 pl1 clear linemin linemax eventliney
   
    legend(legendincl,legendlabs,'Location','northeast','Fontsize',5);
    legend('boxoff')
    clear legendlabs legendincl l p1

    if d < length(degs)+1
    title(strcat((wins{w}),'-',(plotdata{m}),'-',(flds{x}),'(',(refr{r}),'-',(degs{d}),')'),'fontsize',10);
    else
    title(strcat((wins{w}),'-FP Trace'),'fontsize',10);
    end

    temp = strcat({'Time from '},primarylabel,{' (s)'});
    temp = temp{1};
    xlabel(temp,'fontsize',8);
    clear temp
    if d == length(degs)+1
    ylabel (figlabelvals{1},'fontsize',8);
    else
    ylabel (perifiglabel{m},'fontsize',8);
    end
    pindx = pindx+1;
    end
    
    savefigdir = strcat(figdir,(plotdata{m}),fsep,(flds{x}),fsep,(refr{r}),fsep,wins{w},fsep);
if ~exist(savefigdir, 'dir')
       mkdir(savefigdir);
end
%% Generate filenames and save plots - all cases
savename = strcat(savefigdir,outdata.metadata.subjID{1,f},'_',num2str(f));
if saveaspdf
savename = strcat(savename,'.pdf');
f2.Renderer='Painters'; %makes sure figure can be manipulated in illustrator
print(savename,'-dpdf','-bestfit');
else
savename = strcat(savename,'.png');
plotme=getframe(gcf);
imwrite(plotme.cdata,savename);
clear plotme
%saveas(f2,savename);
end
close all
    end
    end
end
clear priminwin eventinwin 
end
end
end

