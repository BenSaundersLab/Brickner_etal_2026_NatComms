function [outdata]= DLC_PlotPerievent(f,outdata,figdir,conds,sniplabel,measures,eventstart,eventduration,eventlabel)
%A Wolff 15/2/21
%% Function for plotting mean perievent behavior traces 
%Inputs
%f - required to locate data in outfile
%outdata -  data for input and output
%figdir - string: directory to save files
%saveaspdf - flag to trigger saving as pdf or jpg
%sniplabel - string: event type label
%conds - cell array of labels for each condition (strings)
%measures - string: behav measures to plot(string- used to find data in output array)
%eventstart - time of event start relative to t = 0 in secs
%eventduration - duration of event in secs
%eventlabel - label for eventline event type
%last 3 inputs optional, but all are needed if you want to plot event
fsep = filesep;
paddata = outdata.rawdata.DLC{f,1}.paddata;
saveaspdf = outdata.UserVals.saveaspdf;
plotbuffermagnitude = outdata.UserVals.DLC.Plotbuffermagnitude;

if nargin > 7
    ploteventline = true;
else
    ploteventline = false;
end


%preallocate

meancolor = NaN(length(conds),3);
errorcolor = NaN(length(conds),3);

%% Set up Figure Labels
figlabelvals = outdata.UserVals.DLCsetup.axislabels; %labels for figure y axis
time = outdata.DLC.(sniplabel).time{f,1};
if paddata
            temp = NaN(1,length(time));
            temp(1:2:end) = time(1:2:end);
            time = temp;
            plotindx = find(~isnan(time));
end


for m = 1:length(measures)
perifiglabel = figlabelvals{m};
plotdata = measures{m};
       
plotname = strcat({'DLC Perievent Plot: '},outdata.metadata.subjID{1,f},{'__F'},num2str(f));
plotname = (plotname{1});
  
numsubfields = length(outdata.UserVals.DLCsetup.Subfields.(measures{m}));
flds = outdata.UserVals.DLCsetup.Subfields.(measures{m}){1};  
for x = 1:length(flds)
switch numsubfields
 case 1
 if length(conds) > 1 % if there are probe trials set up subplots for them
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
 
    l = 1;
    legendlabs = cell(1,length(conds)); 
    legendincl = gobjects(1,length(conds));
    p1 = gobjects(1,length(conds));
    
 linemin = 0; %find max and min values to normalize y axis
 linemax = 1;
        for i = 1:length(conds)
            linemin2 = min(min(outdata.DLC.(sniplabel).(conds{i}).(plotdata).(flds{x}).trials{f,1}));
            linemax2 = max(max(outdata.DLC.(sniplabel).(conds{i}).(plotdata).(flds{x}).trials{f,1}));
            if linemin2 < linemin
                linemin = linemin2;
            end
            if linemax2 > linemax
                linemax = linemax2;
            end
        end

        if linemin == linemax
        linemin = linemax-1;
        end
        
    plotbuffer = (linemax-linemin)*plotbuffermagnitude;
    linemin = linemin - plotbuffer;
    eventoffset = linemin + (plotbuffer/2);
    linemax = linemax + plotbuffer; 
    
    if ploteventline
    eventlinestart = find(time >= eventstart,1,'first');%find start and end of event to plot
    eventlineend = find(time <=  eventstart+eventduration,1,'last');
    eventlinex = time(eventlinestart:eventlineend);
    eventliney = ones(length(eventlinex))*eventoffset;
    end
        
 pindx = 1;    
 for c = 1:length(conds)
 %set plot colors
 if c == 1
 cmap = spring(256);
 else
 cmap = cool(256);
 end
 meancolor(c,:) = cmap(20,:);
 errorcolor(c,:) = cmap(30,:);

 
 numtraces = length(outdata.perievent.(sniplabel).(conds{c}).trialn{f,1}(:,1));
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
         
    subplot((length(conds)*2 + 1),1,(pindx),'Parent',f2);
    
    for i = 1:numtraces %plot individual traces for each trial
        if paddata
        plot(time(plotindx),outdata.DLC.(sniplabel).(conds{c}).(plotdata).(flds{x}).trials{f,1}(i,plotindx),'Color',cmaparray(i*multiplier,:));
        hold on
        else   
        plot(time,outdata.DLC.(sniplabel).(conds{c}).(plotdata).(flds{x}).trials{f,1}(i,:),'Color',cmaparray(i*multiplier,:));
        hold on
        end
    end
   
    %labels
    title(strcat({'Peri-Event Traces '},(conds{c})),'fontsize',12);
    xlabel(strcat({'Time from '},(sniplabel),{' (s)'}),'fontsize',10);  
    ylabel (perifiglabel,'fontsize',10);
    xline(0,'--k','Linewidth',1.5,'Alpha',0.3); %plot line to show cue onset
    if ploteventline
    line(eventlinex,eventliney, 'color','k','Linewidth',4); %plot line to show event duration
    end
    ylim([linemin linemax]);
    % Make an invisible colorbar so this plot aligns with one below it
    colorbar('Visible', 'off');
    pindx = pindx+1;
 end

%% plot mean trace
subplot((length(conds)*2 + 1),1,(pindx),'Parent',f2);
linemin = 0;
linemax = 1;
for c = 1:length(conds)
linemin2 = min(min(outdata.DLC.(sniplabel).(conds{c}).(plotdata).(flds{x}).mean(f,:)));
linemax2 = max(max(outdata.DLC.(sniplabel).(conds{c}).(plotdata).(flds{x}).mean(f,:)));
     if linemin2 < linemin
         linemin = linemin2;
     end
     if linemax2 > linemax
         linemax = linemax2;
     end
     clear linemin2 linemax2
end
if linemin == linemax 
    linemin = linemax -1;
end
    plotbuffer = (linemax-linemin)*plotbuffermagnitude;
    linemin = linemin - plotbuffer;
    eventoffset = linemin + (plotbuffer/2);
    linemax = linemax + plotbuffer; 
    if ploteventline
    eventliney = ones(length(eventlinex))*eventoffset;
    end

% l = 1;
for c = 1:length(conds)
% plot mean
clear xx yy
if paddata 
peri_time = time(plotindx);
perimean = outdata.DLC.(sniplabel).(conds{c}).(plotdata).(flds{x}).mean(f,plotindx);
perisem = outdata.DLC.(sniplabel).(conds{c}).(plotdata).(flds{x}).sem(f,plotindx);
else
peri_time = time;
perimean = outdata.DLC.(sniplabel).(conds{c}).(plotdata).(flds{x}).mean(f,:);
perisem = outdata.DLC.(sniplabel).(conds{c}).(plotdata).(flds{x}).sem(f,:);
end


% Make a standard error fill for mean signal
xx = [peri_time, fliplr(peri_time)];
yy = [(perimean) + (perisem),...
    fliplr((perimean) - (perisem))];
h1 = fill(xx, yy, errorcolor(c,:)); % plot this first for overlay purposes
hold on;
set(h1, 'facealpha', 0.25, 'edgecolor', 'none');
% Plot the signals and the mean signal
p1(c) = plot(peri_time, perimean, 'color', meancolor(c,:), 'LineWidth', 3);
axis tight;
legendincl(l) = p1(c);
legendlabs{l} = (conds{c});
l = l+1;
end
    
    xl = xline(0,'--k','Linewidth',1.5,'Alpha',0.3);
    legendincl(l) = xl;
    legendlabs{l} = (sniplabel);
    l = l+1;
    if ploteventline
    el = line([eventlinex(1) eventlinex(end)],[eventliney(1) eventliney(1)], 'color','k','Linewidth',4);
    legendincl(l) = el;
    legendlabs{l} = (eventlabel);
    end
    ylim([linemin linemax]);
   
% Make a legend and do other plot things
    legend(legendincl,legendlabs,'fontsize',7,'Position',[0.86 0.463 0.1 0.1]);
    legend('boxoff')
    clear legendlabs legendincl p1 x1 el

title('Peri-Event Mean','fontsize',12);
ylabel((perifiglabel),'fontsize',10);
xlabel(strcat({'Time from '},(sniplabel),{' (s)'}),'fontsize',10); 

% Make an invisible colorbar so this plot aligns with one below it
colorbar('Visible', 'off');
pindx = pindx+1;

%% Heat map plot
for c = 1:length(conds)
subplot((length(conds)*2 + 1),1,(pindx),'Parent',f2);    
if paddata
peridata = outdata.DLC.(sniplabel).(conds{c}).(plotdata).(flds{x}).trials{f,1}(:,plotindx);
else
peridata = outdata.DLC.(sniplabel).(conds{c}).(plotdata).(flds{x}).trials{f,1};
end
    imagesc(peri_time, 1, peridata); % this is the heatmap
    set(gca,'YDir','normal') % put the trial numbers in better order on y-axis
    colormap(bone()) % colormap otherwise defaults to perula
    title(strcat((sniplabel),{' Heat Map-'},(conds{c})),'fontsize',12)
    ylabel('Trial Number','fontsize',10)
    xlabel(strcat({'Time from '},(sniplabel),{' (s)'}),'fontsize',10)
    cb = colorbar;
    ylabel(cb, (figlabelvals{m}),'fontsize',10)
    if length(peridata(:,1)) > 1
        lims = ([1 length(peridata(:,1))]);
    else
        lims = ([1 2]);
    end
    ylim(lims)
    ticks = (lims(1):10:lims(2));
    yticks (ticks)
    set(gca, 'YDir','reverse')
    axis tight;
    pindx = pindx+1;
end
%% Generate filenames and save plots
savedir = strcat(figdir,(measures{m}),fsep,(flds{x}),fsep);
        if ~exist(savedir, 'dir')
         mkdir(savedir);
        end 

if saveaspdf
savename = strcat(savedir,(outdata.metadata.subjID{1,f}),'_',num2str(f),'.pdf');
f2.Renderer='Painters'; %makes sure figure can be manipulated in illustrator
print(savename,'-dpdf','-bestfit');
else
savename = strcat(savedir,(outdata.metadata.subjID{1,f}),'_',num2str(f),'.jpg');
saveas(f2,savename);
end
close all

 case 2
 refr = outdata.UserVals.DLCsetup.Subfields.(measures{m}){2}{x};
 for r = 1:length(refr)
    l = 1;
    legendlabs = cell(1,length(conds)); 
    legendincl = gobjects(1,length(conds));
    p1 = gobjects(1,length(conds));
    
    if length(conds) > 1 % if there are probe trials set up subplots for them
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
 
    linemin = 0;
    linemax = 1;
        for i = 1:length(conds)
            linemin2 = min(min(outdata.DLC.(sniplabel).(conds{i}).(plotdata).(flds{x}).(refr{r}).trials{f,1}));
            linemax2 = max(max(outdata.DLC.(sniplabel).(conds{i}).(plotdata).(flds{x}).(refr{r}).trials{f,1}));
            if linemin2 < linemin
                linemin = linemin2;
            end
            if linemax2 > linemax
                linemax = linemax2;
            end
        end

        if linemin == linemax 
            linemin = linemax-1;
        end
    plotbuffer = (linemax-linemin)*plotbuffermagnitude;
    linemin = linemin - plotbuffer;
    eventoffset = linemin + (plotbuffer/2);
    linemax = linemax + plotbuffer; 
    
    if ploteventline
    eventlinestart = find(time >= eventstart,1,'first');%find start and end of event to plot
    eventlineend = find(time <=  eventstart+eventduration,1,'last');
    eventlinex = time(eventlinestart:eventlineend);
    eventliney = ones(length(eventlinex))*eventoffset;
    end
        
 pindx = 1;    
 for c = 1:length(conds)
     if c == 1
         cmap = spring(256);
     else
         cmap = cool(256);
     end
     meancolor(c,:) = cmap(20,:);
     errorcolor(c,:) = cmap(30,:);
     
 numtraces = length(outdata.perievent.(sniplabel).(conds{c}).trialn{f,1}(:,1));
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
 
    subplot((length(conds)*2 + 1),1,(pindx),'Parent',f2);
    for i = 1:numtraces %plot individual traces for each trial
    if paddata
    plot(time(plotindx),outdata.DLC.(sniplabel).(conds{c}).(plotdata).(flds{x}).(refr{r}).trials{f,1}(i,plotindx),'Color',cmaparray(i*multiplier,:));
    hold on
    else
    plot(time,outdata.DLC.(sniplabel).(conds{c}).(plotdata).(flds{x}).(refr{r}).trials{f,1}(i,:),'Color',cmaparray(i*multiplier,:));
    hold on
    end
    end
   
    %labels
    title(strcat({'Peri-Event Traces '},(conds{c})),'fontsize',12);
    xlabel(strcat({'Time from '},(sniplabel),{' (s)'}),'fontsize',10);  
    ylabel (perifiglabel,'fontsize',10);
    xline(0,'--k','Linewidth',1.5,'Alpha',0.3); %plot line to show cue onset
    if ploteventline
    line(eventlinex,eventliney, 'color','k','Linewidth',4); %plot line to show event duration
    end
    ylim([linemin linemax]);
    % Make an invisible colorbar so this plot aligns with one below it
    colorbar('Visible', 'off');
    pindx = pindx+1;
 end

%% plot mean trace
subplot((length(conds)*2 + 1),1,(pindx),'Parent',f2);

linemin = 0;
linemax = 1;
for c = 1:length(conds)
linemin2 = min(min(outdata.DLC.(sniplabel).(conds{c}).(plotdata).(flds{x}).(refr{r}).mean(f,:)));
linemax2 = max(max(outdata.DLC.(sniplabel).(conds{c}).(plotdata).(flds{x}).(refr{r}).mean(f,:)));
     if linemin2 < linemin
         linemin = linemin2;
     end
     if linemax2 > linemax
         linemax = linemax2;
     end
     clear linemin2 linemax2
end
if linemin == linemax
    linemin = linemax - 1;
end
    plotbuffer = (linemax-linemin)*plotbuffermagnitude;
    linemin = linemin - plotbuffer;
    eventoffset = linemin + (plotbuffer/2);
    linemax = linemax + plotbuffer; 
    if ploteventline
    eventliney = ones(length(eventlinex))*eventoffset;
    end

% l = 1;
for c = 1:length(conds)
% plot mean
if paddata
peri_time = time(plotindx);
perimean = outdata.DLC.(sniplabel).(conds{c}).(plotdata).(flds{x}).(refr{r}).mean(f,plotindx);
perisem = outdata.DLC.(sniplabel).(conds{c}).(plotdata).(flds{x}).(refr{r}).sem(f,plotindx);
else
peri_time = time;
perimean = outdata.DLC.(sniplabel).(conds{c}).(plotdata).(flds{x}).(refr{r}).mean(f,:);
perisem = outdata.DLC.(sniplabel).(conds{c}).(plotdata).(flds{x}).(refr{r}).sem(f,:);
end

% Make a standard error fill for mean signal
xx = [peri_time, fliplr(peri_time)];
yy = [(perimean) + (perisem),...
    fliplr((perimean) - (perisem))];
h1 = fill(xx, yy, errorcolor(c,:)); % plot this first for overlay purposes
hold on;
set(h1, 'facealpha', 0.25, 'edgecolor', 'none');
% Plot the signals and the mean signal
p1(c) = plot(peri_time, perimean, 'color', meancolor(c,:), 'LineWidth', 3);
axis tight;
legendincl(l) = p1(c);
legendlabs{l} = (conds{c});
l = l+1;
end
    
    xl = xline(0,'--k','Linewidth',1.5,'Alpha',0.3);
    legendincl(l) = xl;
    legendlabs{l} = (sniplabel);
    l = l+1;
    if ploteventline
    el = line([eventlinex(1) eventlinex(end)],[eventliney(1) eventliney(1)], 'color','k','Linewidth',4);
    legendincl(l) = el;
    legendlabs{l} = (eventlabel);
    end
    ylim([linemin linemax]);
   
% Make a legend and do other plot things
    legend(legendincl,legendlabs,'fontsize',7,'Position',[0.86 0.463 0.1 0.1]);
    legend('boxoff')
    clear legendlabs legendincl p1 x1 el

title('Peri-Event Mean','fontsize',12);
ylabel((perifiglabel),'fontsize',10);
xlabel(strcat({'Time from '},(sniplabel),{' (s)'}),'fontsize',10); 

% Make an invisible colorbar so this plot aligns with one below it
colorbar('Visible', 'off');
pindx = pindx+1;

%% Heat map plot
for c = 1:length(conds)
subplot((length(conds)*2 + 1),1,(pindx),'Parent',f2);    
if paddata
peridata = outdata.DLC.(sniplabel).(conds{c}).(plotdata).(flds{x}).(refr{r}).trials{f,1}(:,plotindx);
else
peridata = outdata.DLC.(sniplabel).(conds{c}).(plotdata).(flds{x}).(refr{r}).trials{f,1};
end
    imagesc(peri_time, 1, peridata); % this is the heatmap
    set(gca,'YDir','normal') % put the trial numbers in better order on y-axis
    colormap(bone()) % colormap otherwise defaults to perula
    title(strcat((sniplabel),{' Heat Map-'},(conds{c})),'fontsize',12)
    ylabel('Trial Number','fontsize',10)
    xlabel(strcat({'Time from '},(sniplabel),{' (s)'}),'fontsize',10)
    cb = colorbar;
    ylabel(cb, (figlabelvals{m}),'fontsize',10)
    lims = ([1 length(peridata(:,1))]);
    ylim(lims)
    ticks = (lims(1):10:lims(2));
    yticks (ticks)
    set(gca, 'YDir','reverse')
    axis tight;
    pindx = pindx+1;
end
%% Generate filenames and save plots
savedir = strcat(figdir,(measures{m}),fsep,(flds{x}),fsep,(refr{r}),fsep);
        if ~exist(savedir, 'dir')
         mkdir(savedir);
        end 

if saveaspdf
savename = strcat(savedir,(outdata.metadata.subjID{1,f}),'_',num2str(f),'.pdf');
f2.Renderer='Painters'; %makes sure figure can be manipulated in illustrator
print(savename,'-dpdf','-bestfit');
else
savename = strcat(savedir,(outdata.metadata.subjID{1,f}),'_',num2str(f),'.jpg');
saveas(f2,savename);
end
close all
end
 
case 3
 refr = outdata.UserVals.DLCsetup.Subfields.(measures{m}){2}{x};
 for r = 1:length(refr)
 degs = outdata.UserVals.DLCsetup.Subfields.(measures{m}){3}{x,r};
 for d = 1:length(degs)
     
     l = 1;
     legendlabs = cell(1,length(conds)); 
     legendincl = gobjects(1,length(conds));
     p1 = gobjects(1,length(conds));
    
     if length(conds) > 1 % if there are probe trials set up subplots for them
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
 linemin = 0; %find max and min values to normalize y axis
 linemax = 1;
        for i = 1:length(conds)
            linemin2 = min(min(outdata.DLC.(sniplabel).(conds{i}).(plotdata).(flds{x}).(refr{r}).(degs{d}).trials{f,1}));
            linemax2 = max(max(outdata.DLC.(sniplabel).(conds{i}).(plotdata).(flds{x}).(refr{r}).(degs{d}).trials{f,1}));
            if linemin2 < linemin
                linemin = linemin2;
            end
            if linemax2 > linemax
                linemax = linemax2;
            end
        end

    if linemin == linemax
        linemin = linemax - 1;
    end
    plotbuffer = (linemax-linemin)*plotbuffermagnitude;
    linemin = linemin - plotbuffer;
    eventoffset = linemin + (plotbuffer/2);
    linemax = linemax + plotbuffer; 
    
    if ploteventline
    eventlinestart = find(time >= eventstart,1,'first');%find start and end of event to plot
    eventlineend = find(time <=  eventstart+eventduration,1,'last');
    eventlinex = time(eventlinestart:eventlineend);
    eventliney = ones(length(eventlinex))*eventoffset;
    end
        
 pindx = 1;    
 for c = 1:length(conds)
     if c == 1
         cmap = spring(256);
     else
         cmap = cool(256);
     end
     meancolor(c,:) = cmap(20,:);
     errorcolor(c,:) = cmap(30,:);
     
 numtraces = length(outdata.perievent.(sniplabel).(conds{c}).trialn{f,1}(:,1));
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
         
    subplot((length(conds)*2 + 1),1,(pindx),'Parent',f2);
    for i = 1:numtraces %plot individual traces for each trial
    if paddata
    plot(time(plotindx),outdata.DLC.(sniplabel).(conds{c}).(plotdata).(flds{x}).(refr{r}).(degs{d}).trials{f,1}(i,plotindx),'Color',cmaparray(i*multiplier,:));
    hold on
    else     
    plot(time,outdata.DLC.(sniplabel).(conds{c}).(plotdata).(flds{x}).(refr{r}).(degs{d}).trials{f,1}(i,:),'Color',cmaparray(i*multiplier,:));
    hold on
    end
    end
   
    %labels
    title(strcat({'Peri-Event Traces '},(conds{c})),'fontsize',12);
    xlabel(strcat({'Time from '},(sniplabel),{' (s)'}),'fontsize',10);  
    ylabel (perifiglabel,'fontsize',10);
    xline(0,'--k','Linewidth',1.5,'Alpha',0.3); %plot line to show cue onset
    if ploteventline
    line(eventlinex,eventliney, 'color','k','Linewidth',4); %plot line to show event duration
    end
    ylim([linemin linemax]);
    % Make an invisible colorbar so this plot aligns with one below it
    colorbar('Visible', 'off');
    pindx = pindx+1;
 end

%% plot mean trace
subplot((length(conds)*2 + 1),1,(pindx),'Parent',f2);

linemin = 0;
linemax = 1;
for c = 1:length(conds)
linemin2 = min(min(outdata.DLC.(sniplabel).(conds{c}).(plotdata).(flds{x}).(refr{r}).(degs{d}).mean(f,:)));
linemax2 = max(max(outdata.DLC.(sniplabel).(conds{c}).(plotdata).(flds{x}).(refr{r}).(degs{d}).mean(f,:)));
     if linemin2 < linemin
         linemin = linemin2;
     end
     if linemax2 > linemax
         linemax = linemax2;
     end
     clear linemin2 linemax2
end
if linemin == linemax
    linemin = linemax -1;
end

    plotbuffer = (linemax-linemin)*plotbuffermagnitude;
    linemin = linemin - plotbuffer;
    eventoffset = linemin + (plotbuffer/2);
    linemax = linemax + plotbuffer; 
    if ploteventline
    eventliney = ones(length(eventlinex))*eventoffset;
    end

% l = 1;
for c = 1:length(conds)
% plot mean
if paddata
peri_time = time(plotindx);
perimean = outdata.DLC.(sniplabel).(conds{c}).(plotdata).(flds{x}).(refr{r}).(degs{d}).mean(f,plotindx);
perisem = outdata.DLC.(sniplabel).(conds{c}).(plotdata).(flds{x}).(refr{r}).(degs{d}).sem(f,plotindx);
else
peri_time = time;
perimean = outdata.DLC.(sniplabel).(conds{c}).(plotdata).(flds{x}).(refr{r}).(degs{d}).mean(f,:);
perisem = outdata.DLC.(sniplabel).(conds{c}).(plotdata).(flds{x}).(refr{r}).(degs{d}).sem(f,:);
end
% Make a standard error fill for mean signal
xx = [peri_time, fliplr(peri_time)];
yy = [(perimean) + (perisem),...
    fliplr((perimean) - (perisem))];
h1 = fill(xx, yy, errorcolor(c,:)); % plot this first for overlay purposes
hold on;
set(h1, 'facealpha', 0.25, 'edgecolor', 'none');
% Plot the signals and the mean signal
p1(c) = plot(peri_time, perimean, 'color', meancolor(c,:), 'LineWidth', 3);
axis tight;
legendincl(l) = p1(c);
legendlabs{l} = (conds{c});
l = l+1;
end
    
    xl = xline(0,'--k','Linewidth',1.5,'Alpha',0.3);
    legendincl(l) = xl;
    legendlabs{l} = (sniplabel);
    l = l+1;
    if ploteventline
    el = line([eventlinex(1) eventlinex(end)],[eventliney(1) eventliney(1)], 'color','k','Linewidth',4);
    legendincl(l) = el;
    legendlabs{l} = (eventlabel);
    end
    ylim([linemin linemax]);
   
% Make a legend and do other plot things
    legend(legendincl,legendlabs,'fontsize',7,'Position',[0.86 0.463 0.1 0.1]);
    legend('boxoff')
    clear legendlabs legendincl p1 x1 el

title('Peri-Event Mean','fontsize',12);
ylabel((perifiglabel),'fontsize',10);
xlabel(strcat({'Time from '},(sniplabel),{' (s)'}),'fontsize',10); 

% Make an invisible colorbar so this plot aligns with one below it
colorbar('Visible', 'off');
pindx = pindx+1;

%% Heat map plot
for c = 1:length(conds)
subplot((length(conds)*2 + 1),1,(pindx),'Parent',f2);  
if paddata
peridata = outdata.DLC.(sniplabel).(conds{c}).(plotdata).(flds{x}).(refr{r}).(degs{d}).trials{f,1}(:,plotindx);
else  
peridata = outdata.DLC.(sniplabel).(conds{c}).(plotdata).(flds{x}).(refr{r}).(degs{d}).trials{f,1};
end
    imagesc(peri_time, 1, peridata); % this is the heatmap
    set(gca,'YDir','normal') % put the trial numbers in better order on y-axis
    colormap(bone()) % colormap otherwise defaults to perula
    title(strcat((sniplabel),{' Heat Map-'},(conds{c})),'fontsize',12)
    ylabel('Trial Number','fontsize',10)
    xlabel(strcat({'Time from '},(sniplabel),{' (s)'}),'fontsize',10)
    cb = colorbar;
    ylabel(cb, (figlabelvals{m}),'fontsize',10)
    lims = ([1 length(peridata(:,1))]);
    ylim(lims)
    ticks = (lims(1):10:lims(2));
    yticks (ticks)
    set(gca, 'YDir','reverse')
    axis tight;
    pindx = pindx+1;
end
%% Generate filenames and save plots
savedir = strcat(figdir,(measures{m}),fsep,(flds{x}),fsep,(refr{r}),fsep,(degs{d}),fsep);
        if ~exist(savedir, 'dir')
         mkdir(savedir);
        end 

if saveaspdf
savename = strcat(savedir,(outdata.metadata.subjID{1,f}),'_',num2str(f),'.pdf');
f2.Renderer='Painters'; %makes sure figure can be manipulated in illustrator
print(savename,'-dpdf','-bestfit');
else
savename = strcat(savedir,(outdata.metadata.subjID{1,f}),'_',num2str(f),'.png');
plotme=getframe(gcf);
imwrite(plotme.cdata,savename);
clear plotme
%saveas(f2,savename);
end
close all
end
end
end
end
end

end

