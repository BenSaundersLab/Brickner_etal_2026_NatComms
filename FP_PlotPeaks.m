function [outdata]= FP_PlotPeaks(f,outdata,figdir,sniplabel,primarylabel,conditions,wins,maxresponselabs,maxfiglabels,eventstart,eventduration,eventlabel)
                     
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
plotbuffermagnitude = outdata.UserVals.plotbuffermagnitude;

if nargin == 12
    ploteventline = true;
else
    ploteventline = false;
end

fsep = filesep;
%% Set up Figure Labels
figlabelvals = {'Z scored dFF','\DeltaF/F','Z Scored','Raw'}; %labels for figure y axis
plotdatavals = {'Z_dFF','dFF','Z_raw','raw'}; %data to access for each


for p = 1:length(plotdatavals)   
perifiglabel = figlabelvals{p};
plotdata = plotdatavals{p};

for w = 1: length(wins)   

plotname = strcat({'FP Peak Plot: '},(wins{w}),'-',outdata.metadata.subjID{1,f},{'__F'},num2str(f));
plotname = (plotname{1});
pindx = 1;

%% plot individual traces
if outdata.UserVals.hideplots
    f2 = figure('name',plotname,'Position',[700, 0, 800, 1000* length(conditions)],'visible','off');
else
    f2 = figure('name',plotname,'Position',[700, 0, 800, 1000* length(conditions)]);
end
 for m = [1,3,4]
    
    clear legendlabs legendincl
    l = 1;
    legendlabs = cell(1,length(conditions)); 
    legendincl = gobjects(1,length(conditions));
    p1 = gobjects(1,length(conditions));
    
    linemin = 0; %find max and min values to normalize y axis
    linemax =0.1;
        for c = 1: length(conditions)
        linemintemp = min(min(outdata.perievent.(sniplabel).(conditions{c}).(plotdata).Peak.(maxresponselabs{m}).(wins{w}).trials{f,1})); %find max and min values to normalize y axis
        linemaxtemp = max(max(outdata.perievent.(sniplabel).(conditions{c}).(plotdata).Peak.(maxresponselabs{m}).(wins{w}).trials{f,1}));
            if linemintemp < linemin
            linemin = linemintemp;
            end
            if linemaxtemp > linemax
            linemax = linemaxtemp;
            end
            clear linemintemp linemaxtemp
        end
    
    linemin = floor(linemin);
    linemax = ceil(linemax);
    plotbuffer = (linemax-linemin)*plotbuffermagnitude;
    linemin = linemin - plotbuffer;
    eventoffset = linemin + (plotbuffer/2);
    linemax = linemax + plotbuffer; 
    

meancolor = NaN(length(conditions),3);
errorcolor = NaN(length(conditions),3);
  
for c = 1: length(conditions)  
numtraces = length(outdata.perievent.(sniplabel).(conditions{c}).(plotdata).Peak.(maxresponselabs{1}).(wins{w}).trials{f,1}(:,1));
subplot(3,length(conditions)+1,(pindx),'Parent',f2);
peri_time = outdata.timearray.(sniplabel).FP.Peak.(wins{w}){f,1};

     if ploteventline  %if the eventline should be plotted figure out what portion (if any) is in the range of x axis     
     if m == 1 % get eventline data once only
        eventlinestart = find(peri_time >= eventstart,1,'first');%find start and end of event to plot
        eventlineend = find(peri_time <=  eventstart+eventduration,1,'last');
        if isempty(eventlinestart) && isempty(eventlineend)
         eventinwin = false;
         clear eventlinestart eventlineend
        else
         eventinwin = true;
        end
        
        if eventinwin 
            if ~isempty(eventlinestart) && ~isempty(eventlineend)    
        	eventlinex = peri_time(eventlinestart:eventlineend);
            else
                if ~isempty(eventlinestart)%if start is missing set start to beginning of window
                    if eventlineend ~= 1 %only include if end of event is not start of win
                    eventlinex = peri_time(1:eventlineend);
                    else
                    eventinwin = false;
                    end
                else %if end is missing then set end to end of window
                    if eventlinestart ~= length(peri_time) %only include if start of event is not end of win   
                    eventlinex = peri_time(eventlinestart:end);
                    else
                    eventinwin = false; 
                    end
                end
           end
        end
     end
     else
     eventinwin = false;
     end
     
     if eventinwin
         eventliney = ones(length(eventlinex))*eventoffset;
     end

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

    for i = 1:numtraces %plot individual traces for each trial
        if m == 1 
            plot(outdata.perievent.(sniplabel).(conditions{c}).(plotdata).Peak.(maxresponselabs{2}).(wins{w}).trials{f,1}(i),outdata.perievent.(sniplabel).(conditions{c}).(plotdata).Peak.(maxresponselabs{m}).(wins{w}).trials{f,1}(i,:),'Marker','o','MarkerFaceColor',cmaparray(i*multiplier,:),'MarkerEdgeColor','k','Color','k','MarkerSize',4);
            hold on
        else
            if m == 3
            plot(outdata.timearray.(sniplabel).FP.Peak.(wins{w}){f,1},outdata.perievent.(sniplabel).(conditions{c}).(plotdata).Peak.(maxresponselabs{m}).(wins{w}).trials{f,1}(i,:),'Color',cmaparray(i*multiplier,:));
            hold on
            end
            if m == 4
            plot(1,outdata.perievent.(sniplabel).(conditions{c}).(plotdata).Peak.(maxresponselabs{m}).(wins{w}).trials{f,1}(i,:),'Marker','o','MarkerFaceColor',cmaparray(i*multiplier,:),'MarkerEdgeColor','k','Color','k','MarkerSize',4);
            hold on
            end
        end   
    end

    %labels
    if length(conditions) > 1
    title(strcat((wins{w}),':',(maxfiglabels{m}),'-',(conditions{c})),'fontsize',10);
    else
    title(strcat((wins{w}),':',(maxfiglabels{m})),'fontsize',10); 
    end
    
    ylabel (strcat(maxfiglabels{m},'(',perifiglabel,')'),'fontsize',8);
   
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
        
        if priminwin && m ~= 4
        xline(0,'--k','Linewidth',1.5,'Alpha',0.3); %plot line to show cue onset
        end
        
        if eventinwin && m ~= 4
        line(eventlinex,eventliney, 'color','k','Linewidth',2.5); %plot line to show event duration
        end
        
    axis tight   
    ylim([floor(linemin) ceil(linemax)]);

    if m ~= 4 
    if sum([peri_time(1), peri_time(end)])~= 0
    xlim([peri_time(1) peri_time(end)]);
    else
        xlim([0 1]);
    end
    temp = strcat({'Time from '},primarylabel,{' (s)'});
    temp = temp{1};
    xlabel(temp,'fontsize',8);
    clear temp
    else
    xlim([0.5 1.5]);
    xticks([]);
    end
    pindx = pindx+1;
end
%% plot mean 
subplot(3,length(conditions)+1,(pindx),'Parent',f2);
for c = 1: length(conditions)
% plot mean
if m == 4
perimean1 = outdata.perievent.(sniplabel).(conditions{c}).(plotdata).Peak.(maxresponselabs{m}).(wins{w}).mean(f,:);
perisem1 = outdata.perievent.(sniplabel).(conditions{c}).(plotdata).Peak.(maxresponselabs{m}).(wins{w}).sem(f,:);   
else
peri_time = outdata.timearray.(sniplabel).FP.Peak.(wins{w}){f,1};
perimean1 = outdata.perievent.(sniplabel).(conditions{c}).(plotdata).Peak.(maxresponselabs{m}).(wins{w}).mean(f,:);
perisem1 = outdata.perievent.(sniplabel).(conditions{c}).(plotdata).Peak.(maxresponselabs{m}).(wins{w}).sem(f,:);
    if m < 2
    perimean2 = outdata.perievent.(sniplabel).(conditions{c}).(plotdata).Peak.(maxresponselabs{2}).(wins{w}).mean(f,:);
    perisem2 = outdata.perievent.(sniplabel).(conditions{c}).(plotdata).Peak.(maxresponselabs{2}).(wins{w}).sem(f,:);
    end
end

% Make a standard error fill for mean signal
if m == 3
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
else
        if m ==1 
        errorbar(perimean2,perimean1,perisem1,'Color','k');
        hold on
        errorbar(perimean2,perimean1,perisem2,'horizontal','Color','k');
        p1(c) = plot(perimean2,perimean1,'Marker','o','MarkerFaceColor',meancolor(c,:),'MarkerEdgeColor','k','Color','k','MarkerSize',4);
        legendlabs{l} = (conditions{c});
        legendincl(l) = p1(c);
        l = l+1;
        else
        errorbar(1,perimean1,perisem1,'Color','k');
        hold on
        p1(c) = plot(1,perimean1,'Marker','o','MarkerFaceColor',meancolor(c,:),'MarkerEdgeColor','k','Color','k','MarkerSize',4);
        legendlabs{l} = (conditions{c});
        legendincl(l) = p1(c);
        l = l+1;
        end
end
clear perimean1 perimean2 perisem1 perisem2 
end

        if priminwin && m ~= 4 %if t0 is not the start or end of trace then plot eventline
        pl1 = xline(0,'--k','Linewidth',1.5,'Alpha',0.3); %plot line to show cue onset
        priminwin = true;
        legendlabs{l} = primarylabel;
        legendincl(l) = pl1;
        l = l+1;
        end
        
        if eventinwin && m ~= 4
        el1 = line([eventlinex(1) eventlinex(end)],[eventliney(1) eventliney(end)],'color','k','Linewidth',2.5); %plot line to show event duration
        legendlabs{l} = eventlabel;
        legendincl(l) = el1;
        end
     
    axis tight    
    ylim([linemin linemax]); 
    if m ~= 4
    if sum([peri_time(1), peri_time(end)])~= 0
    xlim([peri_time(1) peri_time(end)]);
    else
        xlim([0 1]);
    end
    temp = strcat({'Time from '},primarylabel,{' (s)'});
    temp = temp{1};
    xlabel(temp,'fontsize',8);
    else
    xlim ([0.5 1.5]);
    xticks([]);
    end
    clear peri_time clear el1 pl1
   
    legend(legendincl,legendlabs,'Location','northeast','Fontsize',5);
    legend('boxoff')
    title(strcat((wins{w}),':',(maxfiglabels{m})),'fontsize',10);
    clear temp
    ylabel (strcat(maxfiglabels{m},'(',perifiglabel,')'),'fontsize',8);
    pindx = pindx+1;
 end

%% Generate filenames and save plots
savefigdir = strcat(figdir,(plotdata),fsep,wins{w},fsep);
if ~exist(savefigdir, 'dir')
       mkdir(savefigdir);
end
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

