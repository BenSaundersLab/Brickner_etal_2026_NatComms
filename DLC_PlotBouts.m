function []=DLC_PlotBouts(f,outdata,bouttype,figdir)
fsep= filesep;
ymax = 1;
ymin = 0;

if outdata.UserVals.ProcessSubset
    ProcessData = outdata.UserVals.DefineData(SubsetIndx);
else
    ProcessData = outdata.UserVals.DefineData;
end

cmapoptions = {spring(256),winter(256),summer(256),autumn(256),bone(256),copper(256)};

for p = 1:length(ProcessData)
    wins = outdata.metadata.perievent.maxwins.label{p};
    wintimes = outdata.metadata.perievent.maxwins.timepoints{p};
    for w = 1:length(wins)
    conditions = outdata.UserVals.setcond.(ProcessData{p}){2};
    xmin = wintimes{w}(1);
    xmax = wintimes{w}(2);
    %set figuresize for different numbers of conditions here
    plotname = strcat((ProcessData{p}),'-',(wins{w}));   
        f1 = figure('name',plotname,'Position',[700, 0, 1000, 1600]);
        pindx = 1;
        l = 1;
    for c = 1:length(conditions)
    cmap = cmapoptions{1,c};
    subplot(1+length(outdata.metadata.availcond{f,1}{p}),1,pindx)   
    time = outdata.Bouts.(ProcessData{p}).(conditions{c}).(bouttype).FP.(wins{w}).time;
        if isfield(outdata.eventdata.(ProcessData{p}),(outdata.UserVals.setcond.(ProcessData{p}){2}{c}))   %only plot if there is data for this condition
            maxval = max(max(outdata.Bouts.(ProcessData{p}).(conditions{c}).(bouttype).DLC.(wins{w}).duration.trials{f,1}));
            minval = min(min(outdata.Bouts.(ProcessData{p}).(conditions{c}).(bouttype).DLC.(wins{w}).duration.trials{f,1}));
            if maxval > ymax
                ymax = maxval;
            end
            if minval < ymin
                ymin = minval;
            end
            if isnan(xmax)
                xmax = time(end);
            end
            if isnan(xmin)
                xmin = time(1);
            end
            xmaxval = max(max(outdata.Bouts.(ProcessData{p}).(conditions{c}).(bouttype).DLC.(wins{w}).latency.trials{f,1}));
            xminval = min(min(outdata.Bouts.(ProcessData{p}).(conditions{c}).(bouttype).DLC.(wins{w}).latency.trials{f,1}));
            if xmaxval > xmax
                xmax = xmaxval;
            end
            if xminval < xmin
               xmin = xminval;
            end
            clear maxval minval
            multiplier = round(255/length(outdata.Bouts.(ProcessData{p}).(conditions{c}).(bouttype).DLC.(wins{w}).duration.trials{f,1}(:,1)));
            
        end
    end
    
    %% Plot means
    subplot(1+length(outdata.metadata.availcond{f,1}{p}),1,pindx);
    ymin = 0; 
    ymax = 1;
    xmin = wintimes{w}(1);
    xmax = wintimes{w}(2);
    if isnan(xmax)
        xmax = time(end);
    end
    if isnan(xmin)
        xmin = time(1);
    end
    for i = 1:length(conditions)
        if isfield(outdata.eventdata.(ProcessData{p}),(outdata.UserVals.setcond.(ProcessData{p}){2}{i}))
        plotdatax = outdata.Bouts.(ProcessData{p}).(conditions{i}).(bouttype).DLC.(wins{w}).latency.mean{f,1};
        ploterrorx = outdata.Bouts.(ProcessData{p}).(conditions{i}).(bouttype).DLC.(wins{w}).latency.sem{f,1};
        plotdatay = outdata.Bouts.(ProcessData{p}).(conditions{i}).(bouttype).DLC.(wins{w}).duration.mean{f,1};
        ploterrory = outdata.Bouts.(ProcessData{p}).(conditions{i}).(bouttype).DLC.(wins{w}).duration.sem{f,1};
        meancolor = cmapoptions{1,i}(20,:);
        
        % Plot the signals and the mean signal
        errorbar(plotdatax,plotdatay,ploterrory,'Color','k');
        hold on
        errorbar(plotdatax,plotdatay,ploterrorx,'horizontal','Color','k');
        p1(l) = plot(plotdatax,plotdatay,'Marker','o','MarkerFaceColor',meancolor,'MarkerEdgeColor','k','Color','k','MarkerSize',4);
        legendincl(l) = p1(l);
        legendlabs{l} = (conditions{i});
        l = l+1;   
        minval = (min(plotdatay-ploterrory));
        maxval = (max(plotdatay+ploterrory));
        if minval < ymin
            ymin = minval;
        end
        if maxval > ymax
            ymax = maxval;
        end
        minval = (min(plotdatax-ploterrorx));
        maxval = (max(plotdatax+ploterrorx));
        if minval < xmin
            xmin = minval;
        end
        if maxval > xmax
            xmax = maxval;
        end
        end
    end
    %update labels and axes
    plotbuffer = (xmax-xmin)*plotbuffermagnitude;
    xmin = xmin - plotbuffer;
    xmax = xmax + plotbuffer; 
    xlim([xmin xmax]);
    xlabel('Latency (s)');
    
    plotbuffer = (ymax-ymin)*plotbuffermagnitude;
    ymin = ymin - plotbuffer;
    ymax = ymax + plotbuffer; 
    ylim([ymin ymax]);
    ylabel('Duration (s)');
    pl1 = xline(0,'--k','Linewidth',1.5,'Alpha',0.3);
    legendlabs{l} = 'Window Start';
    legendincl(l) = pl1;
    l = l+1;

savedir = strcat(figdir,fsep,(ProcessData{p}),fsep,(bouttype));
if ~exist(savedir, 'dir')
       mkdir(savedir);
end
savename = strcat(savedir,fsep,'BoutMetrics','_',(wins{w}),'-f',num2str(f));
if saveaspdf
savename = strcat(savename,'.pdf');
f1.Renderer='Painters'; %makes sure figure can be manipulated in illustrator
print(savename,'-dpdf','-bestfit');
else
savename = strcat(savename,'.png');
plotme=getframe(gcf);
imwrite(plotme.cdata,savename);
clear plotme
%saveas(f1,savename);
end
close all

    end
end
end