function []=FP_PlotBouts(f,outdata,bouttype,datatypes,datalabels,figdir)


fsep= filesep;
boutonset = {'pre','during'};
saveaspdf = outdata.UserVals.saveaspdf;
plotbuffermagnitude = outdata.UserVals.plotbuffermagnitude;

if outdata.UserVals.ProcessSubset
    ProcessData = outdata.UserVals.DefineData(outdata.UserVals.SubsetIndx);
else
    ProcessData = outdata.UserVals.DefineData;
end

cmapoptions = {spring(256),winter(256),summer(256),autumn(256),bone(256),copper(256)};
if strcmp(bouttype,'Approach') || strcmp(bouttype,'Orient')
nsubfields = 2;
else
nsubfields = 1;
end

if nsubfields == 2
    if strcmp(bouttype,'Approach')
        subfields = outdata.UserVals.DLCsetup.Subfields.DistTo;
    else
        subfields = outdata.UserVals.DLCsetup.Subfields.Angle;
    end
end

if nsubfields == 1
for p = 1:length(ProcessData)
    if isfield(outdata.perievent,(ProcessData{p})) && ~isempty(outdata.metadata.availcond{f,1}{p})
    wins = outdata.metadata.perievent.maxwins.label{p};
    for w = 1:length(wins)
    conditions = outdata.UserVals.setcond.(ProcessData{p}){2};
    %set figuresize for different numbers of conditions here
    plotname = strcat((ProcessData{p}),'-',(wins{w}));
    if outdata.UserVals.hideplots
        f1 = figure('name',plotname,'Position',[700, 0, (500* length(length(outdata.metadata.availcond{f,1}{p}))), 1600],'visible','off');
    else
        f1 = figure('name',plotname,'Position',[700, 0, (500* length(length(outdata.metadata.availcond{f,1}{p}))), 1600]);
    end
        pindx = 1;
        l = 1;

    %%Plot Bout Metrics
    ymax = 1;
    ymin = 0;
    plotbuffer = (ymax-ymin)*plotbuffermagnitude;
    ymin = ymin - plotbuffer;
    ymax = ymax + plotbuffer; 
    for c = 1:length(conditions) 
            hindx(c) = 1;
            ymaxtemp = ceil(outdata.Bouts.(ProcessData{p}).(bouttype).DLC.plot.duration.maxval.trial);
            ymintemp = floor(outdata.Bouts.(ProcessData{p}).(bouttype).DLC.plot.duration.minval.trial);
            plotbuffertemp = (ymaxtemp-ymintemp)*plotbuffermagnitude;
            ymintemp = ymintemp - plotbuffertemp;
            ymaxtemp = ymaxtemp + plotbuffertemp; 
            if ymaxtemp > ymax
                ymax = ymaxtemp;
            end
            if ymintemp < ymin
                ymin = ymintemp;
            end
            xmax= ceil(outdata.Bouts.(ProcessData{p}).(bouttype).DLC.plot.latency.maxval.trial);
            xmin = floor(outdata.Bouts.(ProcessData{p}).(bouttype).DLC.plot.latency.minval.trial);          
            plotbuffer = (xmax-xmin)*plotbuffermagnitude;
            xmin = xmin - plotbuffer;
            xmax = xmax + plotbuffer; 
            plotbuffer = (ymax-ymin)*plotbuffermagnitude;
            ymin = ymin - plotbuffer;
            ymax = ymax + plotbuffer;
    
    if isfield(outdata.eventdata.(ProcessData{p}),(outdata.UserVals.setcond.(ProcessData{p}){2}{c}))   %only plot if there is data for this condition
        subplot(6,(length(outdata.metadata.availcond{f,1}{p})),pindx)       
        cmap = cmapoptions{1,c};
        for b = 1:length(boutonset)
        if isfield(outdata.Bouts.(ProcessData{p}).(bouttype).DLC.(conditions{c}).(wins{w}).latency,(boutonset{b}))
        if isfield(outdata.Bouts.(ProcessData{p}).(bouttype).DLC.(conditions{c}).(wins{w}).latency.(boutonset{b}),'trials')
        if length(outdata.Bouts.(ProcessData{p}).(bouttype).DLC.(conditions{c}).(wins{w}).latency.(boutonset{b}).trials) >= f
        if ~isempty(outdata.Bouts.(ProcessData{p}).(bouttype).DLC.(conditions{c}).(wins{w}).latency.(boutonset{b}).trials{f,1})
            numtraces = length(outdata.Bouts.(ProcessData{p}).(bouttype).DLC.(conditions{c}).(wins{w}).latency.(boutonset{b}).trials{f,1}(:,1));
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
       % multiplier = floor(250/length(outdata.Bouts.(ProcessData{p}).(bouttype).DLC.(conditions{c}).(wins{w}).duration.(boutonset{b}).trials{f,1}(:,1)));
        for t = 1:length(outdata.Bouts.(ProcessData{p}).(bouttype).DLC.(conditions{c}).(wins{w}).duration.(boutonset{b}).trials{f,1}(:,1))
            plotdatax = outdata.Bouts.(ProcessData{p}).(bouttype).DLC.(conditions{c}).(wins{w}).latency.(boutonset{b}).trials{f,1}(t,:);
            plotdatay = outdata.Bouts.(ProcessData{p}).(bouttype).DLC.(conditions{c}).(wins{w}).duration.(boutonset{b}).trials{f,1}(t,:);
            plot(plotdatax,plotdatay,'Marker','o','MarkerFaceColor',cmaparray(t*multiplier,:),'MarkerEdgeColor','k','Color','k','MarkerSize',4);
            hold on
            outdata.Bouts.(ProcessData{p}).(bouttype).DLC.(conditions{c}).(wins{w}).heatarray.trials(hindx(c)) = outdata.Bouts.(ProcessData{p}).(bouttype).DLC.(conditions{c}).(wins{w}).trialn.(boutonset{b}){f,1}(t);
            outdata.Bouts.(ProcessData{p}).(bouttype).DLC.(conditions{c}).(wins{w}).heatarray.latency(hindx(c)) = plotdatax;
            outdata.Bouts.(ProcessData{p}).(bouttype).DLC.(conditions{c}).(wins{w}).heatarray.duration(hindx(c)) = plotdatay;
            for d = 1:length(datatypes)
            outdata.Bouts.(ProcessData{p}).(bouttype).DLC.(conditions{c}).(wins{w}).heatarray.trace(hindx(c),:) = outdata.Bouts.(ProcessData{p}).(bouttype).FP.(conditions{c}).(wins{w}).(datatypes{d}).trials{f,1}.(boutonset{b})(t,:);
            end
            hindx(c) = hindx(c)+1;
        end
        end
        end
        end 
        end
        end
            %update labels and axes
            xlim([xmin xmax]);
            ylim([ymin ymax]);
            ylabel('Duration (s)');
            xlabel('Latency (s)');
            xline(0,'--k','Linewidth',1.5,'Alpha',0.3);
            title ((conditions{c}))
            pindx = pindx+1;
    end
    
    end
    
    %% Plot means
    %set axis limits
    ymax = ceil(outdata.Bouts.(ProcessData{p}).(bouttype).DLC.plot.duration.maxval.mean);
    ymin = floor(outdata.Bouts.(ProcessData{p}).(bouttype).DLC.plot.duration.minval.mean);
    xmax= ceil(outdata.Bouts.(ProcessData{p}).(bouttype).DLC.plot.latency.maxval.mean);
    xmin = floor(outdata.Bouts.(ProcessData{p}).(bouttype).DLC.plot.latency.minval.mean);
    plotbuffer = (ymax-ymin)*plotbuffermagnitude;
    ymin = ymin - plotbuffer;
    ymax = ymax + plotbuffer; 
    plotbuffer = (xmax-xmin)*plotbuffermagnitude;
    xmin = xmin - plotbuffer;
    xmax = xmax + plotbuffer; 

    for c = 1:length(conditions)   
        l = 1;
        if isfield(outdata.eventdata.(ProcessData{p}),(outdata.UserVals.setcond.(ProcessData{p}){2}{c}))
        subplot(6,(length(outdata.metadata.availcond{f,1}{p})),pindx)       
        cmap = cmapoptions{1,c}; 
        
        for b = 1:length(boutonset)
        if isfield(outdata.Bouts.(ProcessData{p}).(bouttype).DLC.(conditions{c}).(wins{w}).latency,(boutonset{b}))
        if isfield(outdata.Bouts.(ProcessData{p}).(bouttype).DLC.(conditions{c}).(wins{w}).latency.(boutonset{b}),'mean')
        plotdatax = outdata.Bouts.(ProcessData{p}).(bouttype).DLC.(conditions{c}).(wins{w}).latency.(boutonset{b}).mean{f,1};
        ploterrorx = outdata.Bouts.(ProcessData{p}).(bouttype).DLC.(conditions{c}).(wins{w}).latency.(boutonset{b}).sem{f,1};
        plotdatay = outdata.Bouts.(ProcessData{p}).(bouttype).DLC.(conditions{c}).(wins{w}).duration.(boutonset{b}).mean{f,1};
        ploterrory = outdata.Bouts.(ProcessData{p}).(bouttype).DLC.(conditions{c}).(wins{w}).duration.(boutonset{b}).sem{f,1};
        meancolor = cmap(20,:);
        
        % Plot the signals and the mean signal
        errorbar(plotdatax,plotdatay,ploterrory,'Color','k');
        hold on
        errorbar(plotdatax,plotdatay,ploterrorx,'horizontal','Color','k');
        p1(l) = plot(plotdatax,plotdatay,'Marker','o','MarkerFaceColor',meancolor,'MarkerEdgeColor','k','Color','k','MarkerSize',4);
        end
        end
        end
            %update labels and axes
    xlim([xmin xmax]);
    xlabel('Latency (s)');
    ylim([ymin ymax]);
    ylabel('Duration (s)');
    pl1 = xline(0,'--k','Linewidth',1.5,'Alpha',0.3);
    legendlabs{l} = 'Window Start';
    legendincl(l) = pl1;
    title((conditions{c}))
    legend(legendincl,legendlabs,'Location','northeast','Fontsize',5);
    legend('boxoff')
    pindx = pindx+1;
    clear legendincl legendlabs
    l = 1;
        end
    end
    
    resetpindx = pindx;
    
        %% Plot FP Traces
        for d = 1:length(datatypes)
        pindx = resetpindx;
        for b = 1:length(boutonset)
        for c = 1:length(conditions)
        cmap = cmapoptions{1,c};      
        if isfield(outdata.eventdata.(ProcessData{p}),(outdata.UserVals.setcond.(ProcessData{p}){2}{c}))   %only plot if there is data for this condition
            delete(subplot(6,(length(outdata.metadata.availcond{f,1}{p})),pindx))
            subplot(subplot(6,(length(outdata.metadata.availcond{f,1}{p})),pindx))
            ymax = ceil(outdata.Bouts.(ProcessData{p}).(bouttype).FP.plot.(datatypes{d}).maxval.trial);
            ymin = floor(outdata.Bouts.(ProcessData{p}).(bouttype).FP.plot.(datatypes{d}).minval.trial);
            plotbuffer = (ymax-ymin)*plotbuffermagnitude;
            ymin = ymin - plotbuffer;
            ymax = ymax + plotbuffer; 
            time = outdata.Bouts.(ProcessData{p}).(bouttype).FP.(conditions{c}).(wins{w}).time;
            if isfield(outdata.Bouts.(ProcessData{p}).(bouttype).FP.(conditions{c}).(wins{w}).(datatypes{d}),'trials') 
            if length(outdata.Bouts.(ProcessData{p}).(bouttype).FP.(conditions{c}).(wins{w}).(datatypes{d}).trials(:,1)) == f;
            if isfield(outdata.Bouts.(ProcessData{p}).(bouttype).FP.(conditions{c}).(wins{w}).(datatypes{d}).trials{f,1},(boutonset{b}))
                numtraces = length(outdata.Bouts.(ProcessData{p}).(bouttype).FP.(conditions{c}).(wins{w}).(datatypes{d}).trials{f,1}.(boutonset{b})(:,1));
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
            %multiplier = floor(250/length(outdata.Bouts.(ProcessData{p}).(bouttype).FP.(conditions{c}).(wins{w}).(datatypes{d}).trials{f,1}.(boutonset{b})(:,1)));
            for t = 1:length(outdata.Bouts.(ProcessData{p}).(bouttype).FP.(conditions{c}).(wins{w}).(datatypes{d}).trials{f,1}.(boutonset{b})(:,1))
            plotdata = outdata.Bouts.(ProcessData{p}).(bouttype).FP.(conditions{c}).(wins{w}).(datatypes{d}).trials{f,1}.(boutonset{b})(t,:);
            plot(time,plotdata,'Color',cmaparray(t*multiplier,:));
            hold on
            end
            end
            end
            end
            clear plotdata
            %update labels and axes
            xlim([time(1) time(end)])
            ylim([ymin ymax]);
            ylabel((datalabels{d}));
            xline(0,'--k','Linewidth',1.5,'Alpha',0.3);
            title ((boutonset{b}))        
            pindx = pindx+1;
        end
        end
        end
    %% Plot Heatmap
    for c = 1:length(conditions)
        
    if isfield(outdata.eventdata.(ProcessData{p}),(outdata.UserVals.setcond.(ProcessData{p}){2}{c}))   %only plot if there is data for this condition
     delete(subplot(6,(length(outdata.metadata.availcond{f,1}{p})),pindx))
     subplot(6,(length(outdata.metadata.availcond{f,1}{p})),pindx)     
     if isfield (outdata.Bouts.(ProcessData{p}).(bouttype).DLC.(conditions{c}).(wins{w}),'heatarray')
    [~,I] = sort(outdata.Bouts.(ProcessData{p}).(bouttype).DLC.(conditions{c}).(wins{w}).heatarray.latency);
    for i = 1:(length(I))
        peridata(i,:) = outdata.Bouts.(ProcessData{p}).(bouttype).DLC.(conditions{c}).(wins{w}).heatarray.trace(I(i),:);
    end
    if length(peridata(:,1)) > 1
    imagesc(time, 1, peridata); % this is the heatmap
    set(gca,'YDir','normal') % put the trial numbers in better order on y-axis
    colormap(bone()) % colormap otherwise defaults to perula
    title(strcat(' Heat Map-',(conditions{c})))
    xlabel('Time from bout onset')
%     cb = colorbar;
%     ylabel(cb, ('Z score','fontsize',10)
    lims = ([1 length(peridata(:,1))]);
    ylim(lims)
    yticks([])
    set(gca, 'YDir','reverse')
    axis tight;
    end
    clear imagesc peridata S I
     end
    pindx = pindx+1;
    end
    end
    
    %% Plot means
            ymax = outdata.Bouts.(ProcessData{p}).(bouttype).FP.plot.(datatypes{d}).maxval.mean;
            ymin = outdata.Bouts.(ProcessData{p}).(bouttype).FP.plot.(datatypes{d}).minval.mean;
            plotbuffer = (ymax-ymin)*plotbuffermagnitude;
            ymin = ymin - plotbuffer;
            ymax = ymax + plotbuffer; 
    for i = 1:length(conditions)
    
    cmap = cmapoptions{1,i};
        if isfield(outdata.eventdata.(ProcessData{p}),(outdata.UserVals.setcond.(ProcessData{p}){2}{i}))
            delete(subplot(6,(length(outdata.metadata.availcond{f,1}{p})),pindx))
            subplot(6,(length(outdata.metadata.availcond{f,1}{p})),pindx) ;
        if isfield(outdata.Bouts.(ProcessData{p}).(bouttype).FP.(conditions{i}).(wins{w}).(datatypes{d}),(boutonset{b}))
        for b = 1:length(boutonset) 
        plotdata = outdata.Bouts.(ProcessData{p}).(bouttype).FP.(conditions{i}).(wins{w}).(datatypes{d}).(boutonset{b}).mean{f,1};
        ploterror = outdata.Bouts.(ProcessData{p}).(bouttype).FP.(conditions{i}).(wins{w}).(datatypes{d}).(boutonset{b}).sem{f,1};
        meancolor = cmap(10*(10*b),:);
        errorcolor = cmap(10*(10*b),:);
        % Make a standard error fill for mean signal
        xx = [time, fliplr(time)];
        yy = [(plotdata) + (ploterror),...
        fliplr((plotdata) - (ploterror))];
        h1 = fill(xx, yy, errorcolor); % plot this first for overlay purposes
        hold on;
        set(h1, 'facealpha', 0.25, 'edgecolor', 'none');
        % Plot the signals and the mean signal
        p1(l) = plot(time, plotdata, 'color',meancolor, 'LineWidth', 3);
        legendincl(l) = p1(l);
        legendlabs{l} = (boutonset{b});
        l = l+1;   
        end
        end
        %update labels and axes
    xlim([time(1) time(end)]);    
    ylim([ymin ymax]);
    ylabel((datalabels{d}));
    pl1 = xline(0,'--k','Linewidth',1.5,'Alpha',0.3);
    legendlabs{l} = 'Bout Start';
    legendincl(l) = pl1;
    title((conditions{i}))
    legend(legendincl,legendlabs,'Location','northeast','Fontsize',5);
    legend('boxoff')
    pindx = pindx+1;
    clear legendincl legendlabs
    l = 1;
        end  
    end
savedir = strcat(figdir,fsep,(ProcessData{p}),fsep,(bouttype));
if ~exist(savedir, 'dir')
       mkdir(savedir);
end
savename = strcat(savedir,fsep,(datatypes{d}),'_',(wins{w}),'-f',num2str(f));
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
        end
    close all
    end
    end
end
else %% approach and orient
flds = subfields{1,1};
for x = 1:length(flds)
refr = subfields{2}{x};
for r = 1:length(refr)

    for p = 1:length(ProcessData)
    if isfield(outdata.perievent,(ProcessData{p})) && ~isempty(outdata.metadata.availcond{f,1}{p})
    wins = outdata.metadata.perievent.maxwins.label{p};
    for w = 1:length(wins)
    conditions = outdata.UserVals.setcond.(ProcessData{p}){2};
    %set figuresize for different numbers of conditions here
    plotname = strcat((ProcessData{p}),'-',(wins{w}));
    if outdata.UserVals.hideplots
        f1 = figure('name',plotname,'Position',[700, 0, (500* length(length(outdata.metadata.availcond{f,1}{p}))), 1600],'visible','off');
    else
        f1 = figure('name',plotname,'Position',[700, 0, (500* length(length(outdata.metadata.availcond{f,1}{p}))), 1600]);
    end
        pindx = 1;
        l = 1;

    %%Plot Bout Metrics
    ymax = 1;
    ymin = 0;
    plotbuffer = (ymax-ymin)*plotbuffermagnitude;
    ymin = ymin - plotbuffer;
    ymax = ymax + plotbuffer; 
    for c = 1:length(conditions) 
            hindx(c) = 1;
            ymaxtemp = ceil(outdata.Bouts.(ProcessData{p}).(bouttype).(flds{x}).(refr{r}).DLC.plot.duration.maxval.trial);
            ymintemp = floor(outdata.Bouts.(ProcessData{p}).(bouttype).(flds{x}).(refr{r}).DLC.plot.duration.minval.trial);
            plotbuffertemp = (ymaxtemp-ymintemp)*plotbuffermagnitude;
            ymintemp = ymintemp - plotbuffertemp;
            ymaxtemp = ymaxtemp + plotbuffertemp; 
            if ymaxtemp > ymax
                ymax = ymaxtemp;
            end
            if ymintemp < ymin
                ymin = ymintemp;
            end
            xmax= ceil(outdata.Bouts.(ProcessData{p}).(bouttype).(flds{x}).(refr{r}).DLC.plot.latency.maxval.trial);
            xmin = floor(outdata.Bouts.(ProcessData{p}).(bouttype).(flds{x}).(refr{r}).DLC.plot.latency.minval.trial);          
            plotbuffer = (xmax-xmin)*plotbuffermagnitude;
            xmin = xmin - plotbuffer;
            xmax = xmax + plotbuffer; 
            plotbuffer = (ymax-ymin)*plotbuffermagnitude;
            ymin = ymin - plotbuffer;
            ymax = ymax + plotbuffer;
    
    if isfield(outdata.eventdata.(ProcessData{p}),(outdata.UserVals.setcond.(ProcessData{p}){2}{c}))   %only plot if there is data for this condition
        subplot(6,(length(outdata.metadata.availcond{f,1}{p})),pindx)       
        cmap = cmapoptions{1,c};
        for b = 1:length(boutonset)
        if isfield(outdata.Bouts.(ProcessData{p}).(bouttype).(flds{x}).(refr{r}).DLC.(conditions{c}).(wins{w}).latency,(boutonset{b}))
        if isfield(outdata.Bouts.(ProcessData{p}).(bouttype).(flds{x}).(refr{r}).DLC.(conditions{c}).(wins{w}).latency.(boutonset{b}),'trials')
        if length(outdata.Bouts.(ProcessData{p}).(bouttype).(flds{x}).(refr{r}).DLC.(conditions{c}).(wins{w}).latency.(boutonset{b}).trials) >= f
        if ~isempty(outdata.Bouts.(ProcessData{p}).(bouttype).(flds{x}).(refr{r}).DLC.(conditions{c}).(wins{w}).latency.(boutonset{b}).trials{f,1})
            numtraces = length(outdata.Bouts.(ProcessData{p}).(bouttype).(flds{x}).(refr{r}).DLC.(conditions{c}).(wins{w}).latency.(boutonset{b}).trials{f,1}(:,1));
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
        %multiplier = floor(250/length(outdata.Bouts.(ProcessData{p}).(bouttype).(flds{x}).(refr{r}).DLC.(conditions{c}).(wins{w}).duration.(boutonset{b}).trials{f,1}(:,1)));
        for t = 1:length(outdata.Bouts.(ProcessData{p}).(bouttype).(flds{x}).(refr{r}).DLC.(conditions{c}).(wins{w}).duration.(boutonset{b}).trials{f,1}(:,1))
            plotdatax = outdata.Bouts.(ProcessData{p}).(bouttype).(flds{x}).(refr{r}).DLC.(conditions{c}).(wins{w}).latency.(boutonset{b}).trials{f,1}(t,:);
            plotdatay = outdata.Bouts.(ProcessData{p}).(bouttype).(flds{x}).(refr{r}).DLC.(conditions{c}).(wins{w}).duration.(boutonset{b}).trials{f,1}(t,:);
            plot(plotdatax,plotdatay,'Marker','o','MarkerFaceColor',cmaparray(t*multiplier,:),'MarkerEdgeColor','k','Color','k','MarkerSize',4);
            hold on
            outdata.Bouts.(ProcessData{p}).(bouttype).(flds{x}).(refr{r}).DLC.(conditions{c}).(wins{w}).heatarray.trials(hindx(c)) = outdata.Bouts.(ProcessData{p}).(bouttype).(flds{x}).(refr{r}).DLC.(conditions{c}).(wins{w}).trialn.(boutonset{b}){f,1}(t);
            outdata.Bouts.(ProcessData{p}).(bouttype).(flds{x}).(refr{r}).DLC.(conditions{c}).(wins{w}).heatarray.latency(hindx(c)) = plotdatax;
            outdata.Bouts.(ProcessData{p}).(bouttype).(flds{x}).(refr{r}).DLC.(conditions{c}).(wins{w}).heatarray.duration(hindx(c)) = plotdatay;
            for d = 1:length(datatypes)
            outdata.Bouts.(ProcessData{p}).(bouttype).(flds{x}).(refr{r}).DLC.(conditions{c}).(wins{w}).heatarray.trace(hindx(c),:) = outdata.Bouts.(ProcessData{p}).(bouttype).(flds{x}).(refr{r}).FP.(conditions{c}).(wins{w}).(datatypes{d}).trials{f,1}.(boutonset{b})(t,:);
            end
            hindx(c) = hindx(c)+1;
        end
        end
        end
        end 
        end
        end
            %update labels and axes
            xlim([xmin xmax]);
            ylim([ymin ymax]);
            ylabel('Duration (s)');
            xlabel('Latency (s)');
            xline(0,'--k','Linewidth',1.5,'Alpha',0.3);
            title ((conditions{c}))
            pindx = pindx+1;
    end
    
    end
    
    %% Plot means
    %set axis limits
    ymax = ceil(outdata.Bouts.(ProcessData{p}).(bouttype).(flds{x}).(refr{r}).DLC.plot.duration.maxval.mean);
    ymin = floor(outdata.Bouts.(ProcessData{p}).(bouttype).(flds{x}).(refr{r}).DLC.plot.duration.minval.mean);
    xmax= ceil(outdata.Bouts.(ProcessData{p}).(bouttype).(flds{x}).(refr{r}).DLC.plot.latency.maxval.mean);
    xmin = floor(outdata.Bouts.(ProcessData{p}).(bouttype).(flds{x}).(refr{r}).DLC.plot.latency.minval.mean);
    plotbuffer = (ymax-ymin)*plotbuffermagnitude;
    ymin = ymin - plotbuffer;
    ymax = ymax + plotbuffer; 
    plotbuffer = (xmax-xmin)*plotbuffermagnitude;
    xmin = xmin - plotbuffer;
    xmax = xmax + plotbuffer; 

    for c = 1:length(conditions)   
        l = 1;
        if isfield(outdata.eventdata.(ProcessData{p}),(outdata.UserVals.setcond.(ProcessData{p}){2}{c}))
        subplot(6,(length(outdata.metadata.availcond{f,1}{p})),pindx)       
        cmap = cmapoptions{1,c}; 
        
        for b = 1:length(boutonset)
        if isfield(outdata.Bouts.(ProcessData{p}).(bouttype).(flds{x}).(refr{r}).DLC.(conditions{c}).(wins{w}).latency,(boutonset{b}))
        if isfield(outdata.Bouts.(ProcessData{p}).(bouttype).(flds{x}).(refr{r}).DLC.(conditions{c}).(wins{w}).latency.(boutonset{b}),'mean')
        plotdatax = outdata.Bouts.(ProcessData{p}).(bouttype).(flds{x}).(refr{r}).DLC.(conditions{c}).(wins{w}).latency.(boutonset{b}).mean{f,1};
        ploterrorx = outdata.Bouts.(ProcessData{p}).(bouttype).(flds{x}).(refr{r}).DLC.(conditions{c}).(wins{w}).latency.(boutonset{b}).sem{f,1};
        plotdatay = outdata.Bouts.(ProcessData{p}).(bouttype).(flds{x}).(refr{r}).DLC.(conditions{c}).(wins{w}).duration.(boutonset{b}).mean{f,1};
        ploterrory = outdata.Bouts.(ProcessData{p}).(bouttype).(flds{x}).(refr{r}).DLC.(conditions{c}).(wins{w}).duration.(boutonset{b}).sem{f,1};
        meancolor = cmap(20,:);
        
        % Plot the signals and the mean signal
        errorbar(plotdatax,plotdatay,ploterrory,'Color','k');
        hold on
        errorbar(plotdatax,plotdatay,ploterrorx,'horizontal','Color','k');
        p1(l) = plot(plotdatax,plotdatay,'Marker','o','MarkerFaceColor',meancolor,'MarkerEdgeColor','k','Color','k','MarkerSize',4);
        end
        end
        end
            %update labels and axes
    xlim([xmin xmax]);
    xlabel('Latency (s)');
    ylim([ymin ymax]);
    ylabel('Duration (s)');
    pl1 = xline(0,'--k','Linewidth',1.5,'Alpha',0.3);
    legendlabs{l} = 'Window Start';
    legendincl(l) = pl1;
    title((conditions{c}))
    legend(legendincl,legendlabs,'Location','northeast','Fontsize',5);
    legend('boxoff')
    pindx = pindx+1;
    clear legendincl legendlabs
    l = 1;
        end
    end
    
    resetpindx = pindx;
    
        %% Plot FP Traces
        for d = 1:length(datatypes)
        pindx = resetpindx;
        for b = 1:length(boutonset)
        for c = 1:length(conditions)
        cmap = cmapoptions{1,c};      
        if isfield(outdata.eventdata.(ProcessData{p}),(outdata.UserVals.setcond.(ProcessData{p}){2}{c}))   %only plot if there is data for this condition
            delete(subplot(6,(length(outdata.metadata.availcond{f,1}{p})),pindx))
            subplot(subplot(6,(length(outdata.metadata.availcond{f,1}{p})),pindx))
            ymax = ceil(outdata.Bouts.(ProcessData{p}).(bouttype).(flds{x}).(refr{r}).FP.plot.(datatypes{d}).maxval.trial);
            ymin = floor(outdata.Bouts.(ProcessData{p}).(bouttype).(flds{x}).(refr{r}).FP.plot.(datatypes{d}).minval.trial);
            plotbuffer = (ymax-ymin)*plotbuffermagnitude;
            ymin = ymin - plotbuffer;
            ymax = ymax + plotbuffer; 
            time = outdata.Bouts.(ProcessData{p}).(bouttype).(flds{x}).(refr{r}).FP.(conditions{c}).(wins{w}).time;
            if isfield(outdata.Bouts.(ProcessData{p}).(bouttype).(flds{x}).(refr{r}).FP.(conditions{c}).(wins{w}).(datatypes{d}),'trials') 
            if length(outdata.Bouts.(ProcessData{p}).(bouttype).(flds{x}).(refr{r}).FP.(conditions{c}).(wins{w}).(datatypes{d}).trials(:,1)) == f;
            if isfield(outdata.Bouts.(ProcessData{p}).(bouttype).(flds{x}).(refr{r}).FP.(conditions{c}).(wins{w}).(datatypes{d}).trials{f,1},(boutonset{b}))
                if ~isempty(outdata.Bouts.(ProcessData{p}).(bouttype).(flds{x}).(refr{r}).FP.(conditions{c}).(wins{w}).(datatypes{d}).trials{f,1}.(boutonset{b}))
                numtraces = length(outdata.Bouts.(ProcessData{p}).(bouttype).(flds{x}).(refr{r}).FP.(conditions{c}).(wins{w}).(datatypes{d}).trials{f,1}.(boutonset{b})(:,1));
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
            % multiplier = floor(250/length(outdata.Bouts.(ProcessData{p}).(bouttype).(flds{x}).(refr{r}).FP.(conditions{c}).(wins{w}).(datatypes{d}).trials{f,1}.(boutonset{b})(:,1)));
            for t = 1:length(outdata.Bouts.(ProcessData{p}).(bouttype).(flds{x}).(refr{r}).FP.(conditions{c}).(wins{w}).(datatypes{d}).trials{f,1}.(boutonset{b})(:,1))
            plotdata = outdata.Bouts.(ProcessData{p}).(bouttype).(flds{x}).(refr{r}).FP.(conditions{c}).(wins{w}).(datatypes{d}).trials{f,1}.(boutonset{b})(t,:);
            plot(time,plotdata,'Color',cmaparray(t*multiplier,:));
            hold on
            end
            end
            end
            end
            end
            clear plotdata
            %update labels and axes
            xlim([time(1) time(end)])
            ylim([ymin ymax]);
            ylabel((datalabels{d}));
            xline(0,'--k','Linewidth',1.5,'Alpha',0.3);
            title ((boutonset{b}))        
            pindx = pindx+1;
        end
        end
        end
    %% Plot Heatmap
    for c = 1:length(conditions)
        
    if isfield(outdata.eventdata.(ProcessData{p}),(outdata.UserVals.setcond.(ProcessData{p}){2}{c}))   %only plot if there is data for this condition
     delete(subplot(6,(length(outdata.metadata.availcond{f,1}{p})),pindx))
     subplot(6,(length(outdata.metadata.availcond{f,1}{p})),pindx)     
     if isfield (outdata.Bouts.(ProcessData{p}).(bouttype).(flds{x}).(refr{r}).DLC.(conditions{c}).(wins{w}),'heatarray')
    [~,I] = sort(outdata.Bouts.(ProcessData{p}).(bouttype).(flds{x}).(refr{r}).DLC.(conditions{c}).(wins{w}).heatarray.latency);
    for i = 1:(length(I))
        peridata(i,:) = outdata.Bouts.(ProcessData{p}).(bouttype).(flds{x}).(refr{r}).DLC.(conditions{c}).(wins{w}).heatarray.trace(I(i),:);
    end
    if length(peridata(:,1)) > 1
    imagesc(time, 1, peridata); % this is the heatmap
    set(gca,'YDir','normal') % put the trial numbers in better order on y-axis
    colormap(bone()) % colormap otherwise defaults to perula
    title(strcat(' Heat Map-',(conditions{c})))
    xlabel('Time from bout onset')
%     cb = colorbar;
%     ylabel(cb, ('Z score','fontsize',10)
    lims = ([1 length(peridata(:,1))]);
    ylim(lims)
    yticks([])
    set(gca, 'YDir','reverse')
    axis tight;
    end
    clear imagesc peridata S I
     end
    pindx = pindx+1;
    end
    end
    
    %% Plot means
            ymax = outdata.Bouts.(ProcessData{p}).(bouttype).(flds{x}).(refr{r}).FP.plot.(datatypes{d}).maxval.mean;
            ymin = outdata.Bouts.(ProcessData{p}).(bouttype).(flds{x}).(refr{r}).FP.plot.(datatypes{d}).minval.mean;
            plotbuffer = (ymax-ymin)*plotbuffermagnitude;
            ymin = ymin - plotbuffer;
            ymax = ymax + plotbuffer; 
    for i = 1:length(conditions)
    
    cmap = cmapoptions{1,i};
        if isfield(outdata.eventdata.(ProcessData{p}),(outdata.UserVals.setcond.(ProcessData{p}){2}{i}))
            delete(subplot(6,(length(outdata.metadata.availcond{f,1}{p})),pindx))
            subplot(6,(length(outdata.metadata.availcond{f,1}{p})),pindx) ;
        if isfield(outdata.Bouts.(ProcessData{p}).(bouttype).(flds{x}).(refr{r}).FP.(conditions{i}).(wins{w}).(datatypes{d}),(boutonset{b}))
        for b = 1:length(boutonset) 
        plotdata = outdata.Bouts.(ProcessData{p}).(bouttype).(flds{x}).(refr{r}).FP.(conditions{i}).(wins{w}).(datatypes{d}).(boutonset{b}).mean{f,1};
        temp = sum(isnan(plotdata));
        if temp ~= length(plotdata)
        ploterror = outdata.Bouts.(ProcessData{p}).(bouttype).(flds{x}).(refr{r}).FP.(conditions{i}).(wins{w}).(datatypes{d}).(boutonset{b}).sem{f,1};
        meancolor = cmap(10*(10*b),:);
        errorcolor = cmap(10*(10*b),:);
        % Make a standard error fill for mean signal
        xx = [time, fliplr(time)];
        yy = [(plotdata) + (ploterror),...
        fliplr((plotdata) - (ploterror))];
        h1 = fill(xx, yy, errorcolor); % plot this first for overlay purposes
        hold on;
        set(h1, 'facealpha', 0.25, 'edgecolor', 'none');
        % Plot the signals and the mean signal
        p1(l) = plot(time, plotdata, 'color',meancolor, 'LineWidth', 3);
        legendincl(l) = p1(l);
        legendlabs{l} = (boutonset{b});
        l = l+1;   
        end
        end
        %update labels and axes
    xlim([time(1) time(end)]);    
    ylim([ymin ymax]);
    ylabel((datalabels{d}));
    pl1 = xline(0,'--k','Linewidth',1.5,'Alpha',0.3);
    legendlabs{l} = 'Bout Start';
    legendincl(l) = pl1;
    title((conditions{i}))
    legend(legendincl,legendlabs,'Location','northeast','Fontsize',5);
    legend('boxoff')
    pindx = pindx+1;
    clear legendincl legendlabs
    l = 1;
        end
        end
    end
savedir = strcat(figdir,fsep,(ProcessData{p}),fsep,(bouttype),fsep,(flds{x}),'_',(refr{r}));
if ~exist(savedir, 'dir')
       mkdir(savedir);
end
savename = strcat(savedir,fsep,(datatypes{d}),'_',(wins{w}),'-f',num2str(f));
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
        end
    close all
    end
    end
end
end
end
end

