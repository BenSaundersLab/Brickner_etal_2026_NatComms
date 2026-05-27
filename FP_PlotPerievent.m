function [outdata]= FP_PlotPerievent(f,outdata,figdir,sniplabel,conditions,primarylabel,eventstart,eventduration,eventlabel)
           
%A Wolff 15/2/21
%% Function to generate perievent plots for photometry data
%Inputs:
%f - required to locate data in outfile
%outdata -  data for input and output%
%UserVals- used to get user settings for plots
%figdir - string - directory to save files
%sniplabel - processdata type
%primarylabel- event lock to cue or event lock to control window t0
%conditions - cell array of labels for each condition
%eventstart - time of event start relative to t = 0 in secs
%eventduration - duration of event in secs
%eventlabel- label for eventline
%last 2 inputs not required for function to run, but both needed to plot eventline
saveaspdf = outdata.UserVals.saveaspdf;
plotbuffermagnitude = outdata.UserVals.plotbuffermagnitude;

if nargin > 6
    ploteventline = true;
else
    ploteventline = false;
end

%% Set up Figure Labels
figlabelvals = {'Z scored dFF','\DeltaF/F','Z Scored Fluorescence','Raw Fluorescence'}; %labels for figure y axis
plotdatavals = {'Z_dFF','dFF','Z_raw','raw'}; %data to access for each plot

for p = 1:length(plotdatavals)
perifiglabel = figlabelvals{p};
plotdata = plotdatavals{p};
       
plotname = strcat({'FP Perievent Plot: '},outdata.metadata.subjID{1,f},{'__F'},num2str(f));
plotname = (plotname{1});


    linemax = 0;
    temp =  max(max(outdata.perievent.(sniplabel).(conditions{1}).(plotdata).trials{f,1}));
    if ~isnan(temp)
       linemax = temp;
    end
    clear temp
    temp = min(min(outdata.perievent.(sniplabel).(conditions{1}).(plotdata).trials{f,1}));
    if ~isnan(temp)
       linemin = temp;
    else
        linemin = linemax -0.1;
    end
    clear temp
    
        if length(conditions) > 1 % if there are probe trials
        for c = 2:length(conditions)
        linemin2 = min(min(outdata.perievent.(sniplabel).(conditions{c}).(plotdata).trials{f,1}));
        linemax2 = max(max(outdata.perievent.(sniplabel).(conditions{c}).(plotdata).trials{f,1}));
            if linemin2 < linemin
            linemin = linemin2;
            end
            if linemax2 > linemax
            linemax = linemax2;
            end
        end
        end
    
    plotbuffer = (linemax-linemin)*plotbuffermagnitude;
    linemin = linemin - plotbuffer;
    eventoffset = linemin + (plotbuffer/2);
    linemax = linemax + plotbuffer; 
    
    if ploteventline
    eventlinestart = find(outdata.perievent.(sniplabel).time{f,1} >= eventstart,1,'first');%find start and end of event to plot
    eventlineend = find(outdata.perievent.(sniplabel).time{f,1} <=  eventstart+eventduration,1,'last');
    eventlinex = outdata.perievent.(sniplabel).time{f,1}(eventlinestart:eventlineend);
    eventliney = ones(length(eventlinex))*eventoffset;
    end

pindx = 1;
%% plot individual traces
if outdata.UserVals.hideplots
    f2 = figure('name',plotname,'Position',[700, 0, 800,700 * length(conditions)],'visible','off');
else
    f2 = figure('name',plotname,'Position',[700, 0, 800,700 * length(conditions)]);
end
 for c = 1:length(conditions)
% plot condition 1
if c == 1
cmap = spring(256);
else
cmap = cool(256);
end
numtraces = length(outdata.perievent.(sniplabel).(conditions{c}).dFF.trials{f,1}(:,1));
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
  
    subplot((2*length(conditions))+1,1,pindx,'Parent',f2);
    for i = 1:numtraces %plot individual traces for each trial
    plot(outdata.timearray.(sniplabel).FP.perievent{f,1},outdata.perievent.(sniplabel).(conditions{c}).(plotdata).trials{f,1}(i,:),'Color',cmaparray(i*multiplier,:));
    hold on
    end
    %labels
    if length(conditions) > 1
    title(strcat({'Peri-Event Traces '},(conditions{c})),'fontsize',12);
    else
    title('Peri-Event Traces','fontsize',12);
    end
    xlabel(strcat({'Time from '},(primarylabel),{' (s)'}),'fontsize',10);  
    ylabel (perifiglabel,'fontsize',10);
    xline(0,'--k','Linewidth',1.5,'Alpha',0.3); %plot line to show cue onset
    if ploteventline
    line(eventlinex,eventliney, 'color','k','Linewidth',4); %plot line to show event duration
    end
    
    axis tight
    ylim([linemin linemax]);

    %xlim([round(outdata.perievent.(sniplabel).time{f,1}(1)) round(outdata.perievent.(sniplabel).time{f,1}(end))]);
    % Make an invisible colorbar so this plot aligns with one below it
    colorbar('Visible', 'off');
    pindx = pindx+1;
 end


%% plot mean trace
l = 1;
legendlabs = cell(1,length(conditions)); 
legendincl = gobjects(1,length(conditions));
p1 = gobjects(1,length(conditions));

linemax = 0;
temp = max(max(outdata.perievent.(sniplabel).(conditions{1}).(plotdata).mean(f,:)));
if ~isnan(temp)
    linemax = temp;
end
clear temp
temp = min(min(outdata.perievent.(sniplabel).(conditions{1}).(plotdata).mean(f,:)));
if ~isnan(temp)
    linemin = temp;
else
    linemin = linemax - 0.1;
end

if length(conditions) > 1
linemin2 = min(min(outdata.perievent.(sniplabel).(conditions{2}).(plotdata).mean(f,:)));
linemax2 = max(max(outdata.perievent.(sniplabel).(conditions{2}).(plotdata).mean(f,:)));
     if linemin2 < linemin
         linemin = linemin2;
     end
     if linemax2 > linemax
         linemax = linemax2;
     end
     clear linemin2 linemax2
end
    plotbuffer = (linemax-linemin)*plotbuffermagnitude;
    linemin = linemin - plotbuffer;
    eventoffset = linemin + (plotbuffer/2);
    linemax = linemax + plotbuffer; 
    if ploteventline
    eventliney = ones(length(eventlinex))*eventoffset;
    end

subplot((2*length(conditions))+1,1,pindx,'Parent',f2);
for c = 1: length(conditions)
    
if c == 1
cmap = spring(256);
else
cmap = cool(256);
end
meancolor = cmap(20,:);
errorcolor = cmap(30,:);

% plot mean
peri_time = outdata.timearray.(sniplabel).FP.perievent{f,:};
perimean = outdata.perievent.(sniplabel).(conditions{c}).(plotdata).mean(f,:);
perisem = outdata.perievent.(sniplabel).(conditions{c}).(plotdata).sem(f,:);


% Make a standard error fill for mean signal
xx = [peri_time, fliplr(peri_time)];
yy = [(perimean) + (perisem),...
    fliplr((perimean) - (perisem))];
h1 = fill(xx, yy, errorcolor); % plot this first for overlay purposes
hold on;
set(h1, 'facealpha', 0.25, 'edgecolor', 'none');
% Plot the signals and the mean signal
p1(c) = plot(peri_time, perimean, 'color',meancolor, 'LineWidth', 3);
legendincl(l) = p1(c);
legendlabs{l} = (conditions{c});
l = l+1;
end
    axis tight;
    colorbar('Visible', 'off');
    xl = xline(0,'--k','Linewidth',1.5,'Alpha',0.3);
    legendincl(l) = xl;
    legendlabs{l} = (primarylabel);
    l = l+1;
    if ploteventline
    el = line([eventlinex(1) eventlinex(end)],[eventliney(1) eventliney(1)], 'color','k','Linewidth',4);
    legendincl(l) = el;
    legendlabs{l} = (eventlabel);
    end
    ylim([linemin linemax]);
    %xlim([round(peri_time(1)) round(peri_time(end))]);
   
% Make a legend and do other plot things
legend(legendincl,legendlabs,'fontsize',7,'Position',[0.86 0.463 0.1 0.1]);
legend('boxoff')
clear legendlabs legendincl p1 x1 el

title('Peri-Event Mean','fontsize',12);
ylabel((perifiglabel),'fontsize',10);
xlabel(strcat({'Time from '},(primarylabel),{' (s)'}),'fontsize',10); 

% Make an invisible colorbar so this plot aligns with one below it
pindx = pindx+1;

%% Heat map plot
for c = 1: length(conditions)
subplot((2*length(conditions))+1,1,pindx,'Parent',f2);
peridata = outdata.perievent.(sniplabel).(conditions{c}).(plotdata).trials{f,1};

    imagesc(peri_time, 1, peridata); % this is the heatmap
    set(gca,'YDir','normal') % put the trial numbers in better order on y-axis
    colormap(bone()) % colormap otherwise defaults to perula
    title(strcat((sniplabel),{' Heat Map-'},(conditions{c})),'fontsize',12)
    ylabel('Trial Number','fontsize',10)
    xlabel(strcat({'Time from '},(primarylabel),{' (s)'}),'fontsize',10)
    cb = colorbar;
    ylabel(cb, (plotdata),'fontsize',10)
    lims = ([1 length(peridata(:,1))]);
    ylim(lims)
    %xlim([round(peri_time(1)) round(peri_time(end))]);
    ticks = (lims(1):10:lims(2));
    yticks (ticks)
    set(gca, 'YDir','reverse')
    axis tight;
    pindx = pindx+1;
end

%% Generate filenames and save plots
savename = strcat(figdir,(outdata.metadata.subjID{1,f}),{'-'},(plotdata),'_',num2str(f));
savename = savename{1};
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

