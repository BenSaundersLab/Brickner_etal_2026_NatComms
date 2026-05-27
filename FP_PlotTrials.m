function FP_PlotTrials(f,outdata,sniplabel,primarylabel,condition,c,datatype,figdir,eventstart,eventduration)

%A Wolff 15/2/21
%% Function to plot photometry traces for individual trials
% Inputs:
% f - current file number used for indexing
% outdata - output data array
% sniplabel - string: perievent data centered to event or control snip
% primarylabel - eventtype at t0
% condition - string: cond1 or cond2 trial type
% c - indx to current condtion
% datatype to analyze - string: used to locate data in output array 
% figdir - string: path to save plots
% saveaspdf - flag to save figs as pdf instead of jpg
% eventstart - time of event relative to t0 in s
% eventduration - duration of event in s
%last 2 inputs not required for function to run, but both needed to plot event
saveaspdf = outdata.UserVals.saveaspdf;
plotbuffermagnitude = outdata.UserVals.plotbuffermagnitude;

if nargin > 9
    eventlineplot = true;
else
    eventlineplot = false;
end

    
        mean_trace = outdata.perievent.(sniplabel).(condition).(datatype).mean(f,:);
        mean_sem= outdata.perievent.(sniplabel).(condition).(datatype).sem(f,:);
        time = outdata.timearray.(sniplabel).FP.perievent{f,1};
        arraysz = size(outdata.perievent.(sniplabel).(condition).(datatype).trials{f,1});
        trials = arraysz(1);
        
        %set axis limits for plotting
        limits(1,2) = 0; 
        temp = max(max(outdata.perievent.(sniplabel).(condition).(datatype).trials{f,1}));
        if ~isnan(temp) 
        limits(1,2) = temp;
        end
        clear temp
        temp = min(min(outdata.perievent.(sniplabel).(condition).(datatype).trials{f,1}));
        if ~isnan(temp)
        limits(1,1) = temp;
        else
        limits(1,1) = limits(1,2) - 0.1;
        end
        clear temp
        
        plotbuffer = (limits(1,2)-limits(1,1))*plotbuffermagnitude;
        limits(1,1) = limits(1,1) - plotbuffer;
        eventoffset = limits(1,1)+ (plotbuffer/2);
        limits(1,2) = limits(1,2) + plotbuffer;

       
        % Make some pretty colors for plotting
        % http://math.loyola.edu/~loberbro/matlab/html/colorsInMatlab.html
        purple = [0.4940, 0.1840, 0.5560];
        purple2 = [0.75, 0.1, 0.75];
        blue1 = [0, 0.4470, 0.7410];
        
        %fill for mean +- STD
        xx = [time, fliplr(time)];
        yy = [(mean_trace) + (mean_sem),...
            fliplr((mean_trace) - (mean_sem))];
        
        %generate line for plotting event onset
        if eventlineplot
        eventlinestart = find(time >= eventstart,1,'first');%find start and end of event to plot
        eventlineend = find(time <=  eventstart+eventduration,1,'last');
        eventlinex = time(eventlinestart:eventlineend);
        eventliney = ones(length(eventlinex))*eventoffset;
        end
        
        numfigs = ceil(trials/25);
        letters = 'abcdefghijklmnopqrstuvwxyz';
        lettindx = 1;
          if numfigs == 0
             numfigs = 1;
          end
        
        subplotindx = 1;
        newfigval = 25;
        newfig = true;
        nf = 1;
        for t = 1:trials %plot each trial 
            if newfig %if a new figure should be generated
                if outdata.UserVals.hideplots
                f1 = figure('Position',[700, 0, 1000, 1600],'visible','off');
                else
                f1 = figure('Position',[700, 0, 1000, 1600]);
                end
            newfig = false;
            end
            subplot(5,5,subplotindx,'Parent',f1);
            h1 = fill(xx, yy, purple); % plot this first for overlay purposes  
            hold on;
            set(h1, 'facealpha', 0.25, 'edgecolor', 'none');
            plot (time,mean_trace,'color',purple2)
            plot(time,outdata.perievent.(sniplabel).(condition).(datatype).trials{f,1}(t,:),'color',blue1)
            xline(0,'k','Linewidth',1,'Alpha',0.3); %cue onset line
            if eventlineplot
            if c == 1
            line(eventlinex,eventliney, 'color','k','Linewidth',1); %event duration line
            else
            line(eventlinex,eventliney, 'color',[0.7 0.7 0.7],'Linewidth',1, 'Linestyle',':'); %event duration line
            end
            end
            hold off
            title(strcat('T-',num2str(outdata.perievent.(sniplabel).(condition).trialn{f,1}(t))),'fontsize',12);
            xlabel(strcat({'Time from '},(primarylabel),{' (s)'}),'fontsize',6);  
            ylabel ((datatype),'fontsize',6); 
            ylim (limits);
            xlim ([time(1) time(end)])
            subplotindx = subplotindx+1;
            
            if t == newfigval || t == trials %save plot before generating new one
                if numfigs > 1
                    if nf > 26
                    savename = strcat(figdir,(outdata.metadata.subjID{1,f}),'_',(condition),{'-'},num2str(f),'_',letters(floor(nf/27)),letters(lettindx)); 
                    lettindx = lettindx + 1;
                    if lettindx > 26
                        lettindx = 1;
                    end
                    else
                    savename = strcat(figdir,(outdata.metadata.subjID{1,f}),'_',(condition),{'-'},num2str(f),'_',letters(lettindx));    
                    lettindx = lettindx + 1;
                    if lettindx > 26 %reset figure label indx
                        lettindx = 1;
                    end
                    end
                else
                    savename = strcat(figdir,(outdata.metadata.subjID{1,f}),'_',(condition),{'-'},num2str(f));
                end
            savename = savename{1};
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
            newfigval = newfigval+25;
            nf = nf+1;
            subplotindx = 1;
            end 
        end
 
end