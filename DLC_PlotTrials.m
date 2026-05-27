function [outdata]=DLC_PlotTrials(f,outdata,figdir,condition,c,sniplabel,measure,subfields,axislabel,eventstart,eventduration)
%A Wolff 15/2/21
%% function to plot individual DLC trials 
%Inputs:
%f - required to locate data in outfile
%outdata -  data for input and output
%figdir - string: directory to save files
%saveaspdf - flag to trigger saving as pdf or jpg
%condition - string: cond1 or cond2 trial type
%c - indx to current condition type
%sniplabel - string: event lock to cue or event lock to control window t0
%measure - string: behav measure to plot
%axis label - string: axis label to use on y axis for current behavior measure
%eventstart - time of event start relative to t = 0 in secs 
%eventduration - duration of event in secs
%last 2 inputs optional, but both are needed if you want to plot event
fsep = filesep;
paddata = outdata.rawdata.DLC{f,1}.paddata;
saveaspdf = outdata.UserVals.saveaspdf;
plotbuffermagnitude = outdata.UserVals.DLC.Plotbuffermagnitude;

if nargin > 9
    ploteventline = true;
else 
    ploteventline = false;
end

        time = outdata.DLC.(sniplabel).time{f,1};
        if paddata
            temp = NaN(1,length(outdata.DLC.(sniplabel).time{f,1}));
            temp(1:2:end) = time(1:2:end);
            time = temp;
        end
        arraysz = size(outdata.DLC.(sniplabel).(condition).ts{f,1});
        trials = arraysz(1);

        % Make some pretty colors for plotting
        % http://math.loyola.edu/~loberbro/matlab/html/colorsInMatlab.html
        purple = [0.4940, 0.1840, 0.5560];

        if ploteventline
        %generate line for plotting event onset
        eventlinestart = find(time >= eventstart,1,'first');%find start and end of event to plot
        eventlineend = find(time <=  eventstart+eventduration,1,'last');
        eventlinex = time(eventlinestart:eventlineend);
        end
        
        numfigs = ceil(trials/25);
        letters = 'abcdefghijklmnopqrstuvwxyz';
        lettindx = 1;
          if numfigs == 0
             numfigs = 1;
          end
        newfigval = 25;
        newlettval = 26;
        lettindx = 1;
        
        numsubfields = length(outdata.UserVals.DLCsetup.Subfields.(measure));
        flds = outdata.UserVals.DLCsetup.Subfields.(measure){1};  
        for x = 1:length(flds)
            newfig = true;
            nf = 1;
            limits(1,1) = 0;
            limits(1,2) = 1;
            switch numsubfields
            case 1
            %set axis limits for plotting
            if floor(min(min(outdata.DLC.(sniplabel).(condition).(measure).(flds{x}).trials{f,1}))) < limits(1,1)
            limits(1,1) = floor(min(min(outdata.DLC.(sniplabel).(condition).(measure).(flds{x}).trials{f,1})));
            end
            if ceil(max(max(outdata.DLC.(sniplabel).(condition).(measure).(flds{x}).trials{f,1}))) > limits(1,2)
            limits(1,2) = ceil(max(max(outdata.DLC.(sniplabel).(condition).(measure).(flds{x}).trials{f,1})));
            end

            if limits(1,1) == limits(1,2)
               limits(1,1) = limits(1,2)-1;
            end

            plotbuffer = (limits(1,2)-limits(1,1))*plotbuffermagnitude;
            limits(1,1) = limits(1,1) - plotbuffer;
            eventoffset = limits(1,1)+ (plotbuffer/2);
            limits(1,2) = limits(1,2) + plotbuffer;
            if ploteventline
            eventliney = ones(length(eventlinex))*eventoffset;
            end
            
            for t = 1:trials %plot each trial
            if newfig %if a new figure should be generated 
                if outdata.UserVals.hideplots
                f1 = figure('Position',[700, 0, 1000, 1600],'visible','off');
                else
                f1 = figure('Position',[700, 0, 1000, 1600]);
                end
            newfig = false;
            subplotindx = 1;
            end
            subplot(5,5,subplotindx,'Parent',f1)
            if paddata
            plotindx = find(~isnan(time));
            plot(time(plotindx),outdata.DLC.(sniplabel).(condition).(measure).(flds{x}).trials{f,1}(t,plotindx),'color',purple)
            else 
            plot(time,outdata.DLC.(sniplabel).(condition).(measure).(flds{x}).trials{f,1}(t,:),'color',purple)
            end    
            xline(0,'k','Linewidth',1,'Alpha',0.3); %cue onset line
            if ploteventline
            if c == 1
            line(eventlinex,eventliney, 'color','k','Linewidth',1); %event duration line
            else
            line(eventlinex,eventliney, 'color',[0.7 0.7 0.7],'Linewidth',1, 'Linestyle',':'); %event duration line
            end
            end
            hold off
            title(strcat('T-',num2str(outdata.perievent.(sniplabel).(condition).trialn{f,1}(t))),'fontsize',12);
            xlabel('Time from Cue Onset (s)','fontsize',6);  
            ylabel ((axislabel),'fontsize',6); 
            ylim (limits(1,:))
            subplotindx = subplotindx+1;
            
            if subplotindx == newfigval || t == trials %save plot before generating new one
                figsavedir = strcat(figdir,(flds{x}),fsep);
                    if ~exist(figsavedir, 'dir')
                    mkdir(figsavedir);
                    end 
                if numfigs > 1
                    if nf > 26
                    savename = strcat(figsavedir,(outdata.metadata.subjID{1,f}),'_',(condition),{'-'},num2str(f),'_',letters(floor(nf/26)),letters(lettindx)); 
                    lettindx = lettindx + 1;
                    if lettindx > 26
                        lettindx = 1;
                    end
                    else
                    savename = strcat(figsavedir,(outdata.metadata.subjID{1,f}),'_',(condition),{'-'},num2str(f),'_',letters(lettindx));    
                    lettindx = lettindx + 1;
                    if lettindx > 26 %reset figure label indx
                        lettindx = 1;
                    end
                    end
                else 
                savename = strcat(figsavedir,(outdata.metadata.subjID{1,f}),'_',(condition),{'-'},num2str(f));
                end              
            savename = savename{1};
            clear figsavedir
                if saveaspdf
                    savename = strcat(savename,'.pdf');
                    f1.Renderer='Painters'; %makes sure figure can be manipulated in illustrator
                    print(savename,'-dpdf','-bestfit');
                else
                    savename = strcat(savename,'.jpg');
                    saveas(f1,savename);
                end
            close all
            newfig = true;
            nf = nf+1;
            end
            end
            
            case 2
            refpoints = subfields{2}{x};
            for r = 1:length(refpoints)
            newfig = true;
            nf = 1;
            limits(1,1) = 0;
            limits(1,2)= 1;
            %set axis limits for plotting
            if floor(min(min(outdata.DLC.(sniplabel).(condition).(measure).(flds{x}).(refpoints{r}).trials{f,1}))) < limits(1,1)
            limits(1,1) = floor(min(min(outdata.DLC.(sniplabel).(condition).(measure).(flds{x}).(refpoints{r}).trials{f,1})));
            end
            if ceil(max(max(outdata.DLC.(sniplabel).(condition).(measure).(flds{x}).(refpoints{r}).trials{f,1}))) > limits(1,2)
            limits(1,2) = ceil(max(max(outdata.DLC.(sniplabel).(condition).(measure).(flds{x}).(refpoints{r}).trials{f,1})));
            end
            if limits(1,1) == limits(1,2) 
               limits(1,1) = limits(1,2)-1;
            end
            plotbuffer = (limits(1,2)-limits(1,1))*plotbuffermagnitude;
            limits(1,1) = limits(1,1) - plotbuffer;
            eventoffset = limits(1,1)+ (plotbuffer/2);
            limits(1,2) = limits(1,2) + plotbuffer;
            if ploteventline
            eventliney = ones(length(eventlinex))*eventoffset;
            end
            
            for t = 1:trials %plot each trial
            if newfig %if a new figure should be generated 
                if outdata.UserVals.hideplots
                f1 = figure('Position',[700, 0, 1000, 1600],'visible','off');
                else
                f1 = figure('Position',[700, 0, 1000, 1600]);
                end
            newfig = false;
            subplotindx = 1;
            end
            subplot(5,5,subplotindx,'Parent',f1)
            if paddata
            plotindx = find(~isnan(time));
            plot(time(plotindx),outdata.DLC.(sniplabel).(condition).(measure).(flds{x}).(refpoints{r}).trials{f,1}(t,plotindx),'color',purple)
            else
            plot(time,outdata.DLC.(sniplabel).(condition).(measure).(flds{x}).(refpoints{r}).trials{f,1}(t,:),'color',purple)
            end
            xline(0,'k','Linewidth',1,'Alpha',0.3); %cue onset line
            if ploteventline
            if c == 1
            line(eventlinex,eventliney, 'color','k','Linewidth',1); %event duration line
            else
            line(eventlinex,eventliney, 'color',[0.7 0.7 0.7],'Linewidth',1, 'Linestyle',':'); %event duration line
            end
            end
            hold off
            title(strcat('T-',num2str(outdata.perievent.(sniplabel).(condition).trialn{f,1}(t))),'fontsize',12);
            xlabel('Time from Cue Onset (s)','fontsize',6);  
            ylabel ((axislabel),'fontsize',6); 
            ylim (limits(1,:))
            subplotindx = subplotindx+1;
            
            if subplotindx == newfigval || t == trials %save plot before generating new one
                figsavedir = strcat(figdir,(flds{x}),fsep,(refpoints{r}),fsep);
                    if ~exist(figsavedir, 'dir')
                    mkdir(figsavedir);
                    end 
                if numfigs > 1
                    if nf > 26
                    savename = strcat(figsavedir,(outdata.metadata.subjID{1,f}),'_',(condition),{'-'},num2str(f),'_',letters(floor(nf/27)),letters(lettindx)); 
                    lettindx = lettindx + 1;
                    if lettindx > 26
                        lettindx = 1;
                    end
                    else
                    savename = strcat(figsavedir,(outdata.metadata.subjID{1,f}),'_',(condition),{'-'},num2str(f),'_',letters(lettindx));    
                    lettindx = lettindx + 1;
                    if lettindx > 26 %reset figure label indx
                        lettindx = 1;
                    end
                    end
                else
                savename = strcat(figsavedir,(outdata.metadata.subjID{1,f}),'_',(condition),{'-'},num2str(f));
                end              

            savename = savename{1};
            clear figsavedir
                if saveaspdf
                    savename = strcat(savename,'.pdf');
                    f1.Renderer='Painters'; %makes sure figure can be manipulated in illustrator
                    print(savename,'-dpdf','-bestfit');
                else
                    savename = strcat(savename,'.jpg');
                    saveas(f1,savename);
                end
            close all
            newfig = true;
            nf = nf+1;
            end
            end
            end
            
            case 3
            refpoints = subfields{2}{x};
            for r = 1:length(refpoints)
            degs = outdata.UserVals.DLCsetup.Subfields.(measure){3}{x,r};
            for d = 1:length(degs)
            newfig = true;
            nf = 1;
            %set axis limits for plotting
            limits(1,1) = 0;
            limits(1,2) = 1;
            if floor(min(min(outdata.DLC.(sniplabel).(condition).(measure).(flds{x}).(refpoints{r}).(degs{d}).trials{f,1}))) < limits(1,1)
            limits(1,1) = floor(min(min(outdata.DLC.(sniplabel).(condition).(measure).(flds{x}).(refpoints{r}).(degs{d}).trials{f,1})));
            end
            if ceil(max(max(outdata.DLC.(sniplabel).(condition).(measure).(flds{x}).(refpoints{r}).(degs{d}).trials{f,1}))) > limits(1,2)
            limits(1,2) = ceil(max(max(outdata.DLC.(sniplabel).(condition).(measure).(flds{x}).(refpoints{r}).(degs{d}).trials{f,1})));
            end

            if limits(1,1) == limits(1,2) 
               limits(1,1) = limits(1,2)-1;
            end
            
            plotbuffer = (limits(1,2)-limits(1,1))*plotbuffermagnitude;
            limits(1,1) = limits(1,1) - plotbuffer;
            eventoffset = limits(1,1)+ (plotbuffer/2);
            limits(1,2) = limits(1,2) + plotbuffer;
            if ploteventline
            eventliney = ones(length(eventlinex))*eventoffset;
            end
            
            for t = 1:trials %plot each trial
            if newfig %if a new figure should be generated 
                if outdata.UserVals.hideplots
                f1 = figure('Position',[700, 0, 1000, 1600],'visible','off');
                else
                f1 = figure('Position',[700, 0, 1000, 1600]);
                end
            newfig = false;
            subplotindx = 1;
            end
            subplot(5,5,subplotindx,'Parent',f1)
            if paddata
            plotindx = find(~isnan(time));
            plot(time(plotindx),outdata.DLC.(sniplabel).(condition).(measure).(flds{x}).(refpoints{r}).(degs{d}).trials{f,1}(t,plotindx),'color',purple);
            else
            plot(time,outdata.DLC.(sniplabel).(condition).(measure).(flds{x}).(refpoints{r}).(degs{d}).trials{f,1}(t,:),'color',purple);
            end
            xline(0,'k','Linewidth',1,'Alpha',0.3); %cue onset line
            if ploteventline
            if c == 1
            line(eventlinex,eventliney, 'color','k','Linewidth',1); %event duration line
            else
            line(eventlinex,eventliney, 'color',[0.7 0.7 0.7],'Linewidth',1, 'Linestyle',':'); %event duration line
            end
            end
            hold off
            title(strcat('T-',num2str(outdata.perievent.(sniplabel).(condition).trialn{f,1}(t))),'fontsize',12);
            xlabel('Time from Cue Onset (s)','fontsize',6);  
            ylabel ((axislabel),'fontsize',6); 
            ylim (limits(1,:))
            subplotindx = subplotindx+1;
            
            if subplotindx == newfigval || t == trials %save plot before generating new one
                figsavedir = strcat(figdir,(flds{x}),fsep,(refpoints{r}),fsep,(degs{d}),fsep);
                    if ~exist(figsavedir, 'dir')
                    mkdir(figsavedir);
                    end 
                if numfigs > 1
                    if nf > 26
                    savename = strcat(figsavedir,(outdata.metadata.subjID{1,f}),'_',(condition),{'-'},num2str(f),'_',letters(floor(nf/27)),letters(lettindx)); 
                    lettindx = lettindx + 1;
                    if lettindx > 26
                        lettindx = 1;
                    end
                    else
                    savename = strcat(figsavedir,(outdata.metadata.subjID{1,f}),'_',(condition),{'-'},num2str(f),'_',letters(lettindx));    
                    lettindx = lettindx + 1;
                    if lettindx > 26 %reset figure label indx
                        lettindx = 1;
                    end
                    end
                else
                savename = strcat(figsavedir,(outdata.metadata.subjID{1,f}),'_',(condition),{'-'},num2str(f));
                end              
            savename = savename{1};
            clear figsavedir
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
            newfig = true;
            nf = nf+1;
            end
            end
            end
            end            
            end
        end
end

