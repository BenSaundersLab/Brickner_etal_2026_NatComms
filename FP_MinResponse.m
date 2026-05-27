function [trials]= FP_MinResponse(timearray,traces,searchwin,peakwin)

%Amy Wolff 1/2/23
%detection of peak (max value) can be retricted to portion of the total
%window using peak win input - slope/latency are calculated on the trace for the full window
%AUC is calculated across the trace for the full window / AUC norm is calculated across the normalized trace for the full window

%% Function to extract max reponses within a timewindow
%Inputs:
%timearray - timestamps that match trace length centered around event @t0
%traces - individual traces to search for max response
%searchwin - window to search for peak (in s) [winstart,winend] - input [] to search whole trace, NaN to default to start/end of trace
%peakwin - restrict peak detection to smaller portion of window - optional 

if nargin > 3
    restrictpeak = true;
else
    restrictpeak = false;
end

%preallocate outarray:
trials.peakts = NaN(length(traces(:,1)),1);
trials.peakval = NaN(length(traces(:,1)),1);
trials.peakval_norm = NaN(length(traces(:,1)),1);
trials.maxval = NaN(length(traces(:,1)),1);
trials.AUC = NaN(length(traces(:,1)),1); 
trials.AUC_norm = NaN(length(traces(:,1)),1);
trials.peaklatency = NaN(length(traces(:,1)),1); 
trials.riseslope = NaN(length(traces(:,1)),1); 
trials.riseslope_norm = NaN(length(traces(:,1)),1); 
trials.fallslope = NaN(length(traces(:,1)),1); 
trials.fallslope_norm = NaN(length(traces(:,1)),1); 
trials.normval = NaN(length(traces(:,1)),1); 
trials.avFP = NaN(length(traces(:,1)),1); 
trials.avFP_norm = NaN(length(traces(:,1)),1); 


     if ~isempty(searchwin) %if any portion of the search window is defined use these values to index
         %start window
         if ~isnan(searchwin(1)) %if the start window is defined use it
          indx1 = find(timearray >= searchwin(1),1,'first'); %find start of window
         else
          indx1 = 1; %if start window is not defined use start of trace as start window 
         end
        %end of window
        if ~isnan(searchwin(2)) %if end window is defined use it
            indx2 = find(timearray <= searchwin(2),1,'last');%find end of window
        else
        indx2 = length(timearray);%if end window is not defined make end of trace end window
        end
     else %if no times are defined search whole trace
         indx1 =1;
         indx2 = length(timearray);
     end
     
     trials.peaktimearray= timearray(indx1:indx2); %extract the time array for just the selected window
     trials.peaktrace = traces(:,indx1:indx2);%extract the trace for just the selected window 
     trials.peaktrace_norm = NaN(length(trials.peaktrace(:,1)),length(trials.peaktrace(1,:)));
     
if restrictpeak
    if isnan(peakwin(1))
    begintime = trials.peaktimearray(1); %set win to start
    else
    begintime = (peakwin(1));%set win to userdefined
    end
    
    if isnan(peakwin(2))
    endtime = trials.peaktimearray(end); %set win to end
    else      
    endtime = peakwin(2);%set end as user defined
    end
else
begintime = trials.peaktimearray(1);
endtime = trials.peaktimearray(end);
end

     %extract peak detection window only
     strace = find(trials.peaktimearray >= begintime,1,'first');
     etrace = find(trials.peaktimearray <=endtime,1,'last');
     peakwin =trials.peaktrace(:,strace:etrace);  
     peakwindx = (strace:etrace); %index peak detection window (if not user specified whole trace is used)
     [trials.peakval,trials.peakindx] = min(peakwin,[],2); %finds the peak within  window     
     trials.peakindx = peakwindx(trials.peakindx); %normalize indexing to whole trace
     trials.peakts = trials.peaktimearray(trials.peakindx); %get time relative to whole trace
     trials.peaklatency = trials.peakts- trials.peaktimearray(1); %get latency of peak relative to whole trace

     %calculate rise and fall slope/AUC for non-normalized peaks
     for i =1:length(trials.peakindx) % for each trial   
     slopeval = trials.peakval(i)/2; % find val = 50% peak
     slopearray = find(trials.peaktrace(i,:) > slopeval); %indx array of all vals lower than 50% of peakval
     risestart = find(slopearray < trials.peakindx(i), 1,'last');% find indx of the last value below 50% of peak that occurs before peak
     if isempty(risestart)
     [~,risestart] = max(trials.peaktrace(i,1:trials.peakindx(i)));%if slope values before peak are all above 50% set max timepoint between start of window and peak as start of slope measurement
     else
     risestart = slopearray(risestart)+1; %set first val > 50% as start of slope measurement
     end
     
     fallend = find(slopearray > trials.peakindx(i), 1,'first');% find indx of the first value below 50% of peak that occurs after peak
     if isempty(fallend)
     [~,fallend] = max(trials.peaktrace(i,trials.peakindx(i):end)); %if values post peak don't decay to 50% set slope measurement to min point between peak and end of window
     reftraceindx = trials.peakindx(i): length(trials.peaktrace(i,:));
     fallend = reftraceindx(fallend);
     else
     fallend = slopearray(fallend)-1;%set last val > 50% as end of slope measurement;
     end
     
     
     %rise
     x1 = trials.peaktimearray(risestart);
     x2 = trials.peakts(i);
     y1 = trials.peaktrace(i,risestart);
     y2 = trials.peakval(i);   
     trials.riseslope (i) = (y2-y1)/(x2-x1);
     clear x1 x2 y1 y2
     %fall
     x1 = trials.peakts(i);
     x2 = trials.peaktimearray(fallend);
     y1 = trials.peakval(i);
     y2 = trials.peaktrace(i,fallend);
     trials.fallslope (i) = (y2-y1)/(x2-x1);
     clear x1 x2 y1 y2
     
     trials.AUC(i)= trapz(trials.peaktrace(i,:));
     trials.avFP(i) = mean(trials.peaktrace(i,:),'omitnan');
     end
     

     %norm traces
     for i =1:length(trials.peakindx) % for each trial
     %find max val between start of window and peak to normalize traces
     [trials.maxval(i), ~] = max(trials.peaktrace(i,1:trials.peakindx(i))); %find min val for this trial (between start of window and peak)
        
     if ~isnan(trials.maxval(i))
     trials.normval(i) = 0-trials.maxval(i); %get value for normalization of data
     trials.peakval_norm(i) = trials.peakval(i) + trials.normval(i); %normalize peak
     trials.peaktrace_norm(i,:) = trials.peaktrace(i,:)+ trials.normval(i);%normalize trace
     slopeval = trials.peakval_norm(i)/2; % find val = 50% peak
     slopearray = find(trials.peaktrace_norm(i,:) > slopeval); %indx array of all vals lower than 50% of peakval
     risestart = find(slopearray < trials.peakindx(i), 1,'last');% find indx of the last value below 50% of peak that occurs before peak
     if isempty(risestart)
     [~,risestart] = max(trials.peaktrace_norm(i,1:trials.peakindx(i)));%if slope values before peak are all above 50% set min timepoint between start of window and peak as start of slope measurement
     else
     risestart = slopearray(risestart)+1; %set first val > 50% as start of slope measurement
     end
     
     fallend = find(slopearray > trials.peakindx(i), 1,'first');% find indx of the first value below 50% of peak that occurs after peak
     if isempty(fallend)
     [~,fallend] = max(trials.peaktrace_norm(i,trials.peakindx(i):end)); %if values post peak don't decay to 50% set slope measurement to end at min value between peak and end of window
     reftraceindx = trials.peakindx(i): length(trials.peaktrace(i,:));
     fallend = reftraceindx(fallend);
     else
     fallend = slopearray(fallend)-1;%set last val > 50% as end of slope measurement;
     end
  
     %rise
     x1 = trials.peaktimearray(risestart);
     x2 = trials.peakts(i);
     y1 = trials.peaktrace_norm(i,risestart);
     y2 = trials.peakval_norm(i);   
     trials.riseslope_norm (i) = (y2-y1)/(x2-x1);
     clear x1 x2 y1 y2
     %fall
     x1 = trials.peakts(i);
     x2 = trials.peaktimearray(fallend);
     y1 = trials.peakval_norm(i);
     y2 = trials.peaktrace_norm(i,fallend);
     trials.fallslope_norm (i) = (y2-y1)/(x2-x1);
     clear x1 x2 y1 y2
     
     trials.AUC_norm(i)= trapz(trials.peaktrace_norm(i,:));
     trials.avFP_norm(i) = mean(trials.peaktrace_norm(i,:),'omitnan');
     end
     end  
     end
        %plot traces
%          fig1 = figure;
%          plot(trials.peaktimearray,peaktrace_norm(i,:),'color','k');
%          hold on
%          plot(trials.peaktimearray,peaktrace(i,:),'color','b');
%          yline(0,'color','k')
%          plot(trials.peaktimearray(WFindx),peaktrace_norm(i,WFindx),'Color','r','LineWidth',1.5);
%          plot(peaktime(i),peakval_norm(i),'Marker','o','MarkerFaceColor','r','MarkerEdgeColor','k','Color','k','MarkerSize',6)
%          plot(decaytime,peaktrace_norm(i,fallindx),'Marker','*','MarkerEdgeColor','r','Color','r','MarkerSize',8)
%          hold off
%          pause(2)
%          figdir = ('C:\Users\Saund\Desktop\Work\NormExamples\');
%          if ~exist(figdir, 'dir')
%             mkdir(figdir);
%          end
%          savename = strcat(figdir,'SNC5_F1Cue2s_T',num2str(i),'.jpg');
%          saveas(fig1,savename);
%         close all
        
%             temparray = (zeros(1,length(trials.peaktimearray(WFindx))));
%             xx = [trials.peaktimearray(WFindx), fliplr(trials.peaktimearray(WFindx))];
%             yy = [0 + peaktrace_norm(i,WFindx),...
%             fliplr(temparray - temparray)];
%             %h1 = fill(xx, yy,'r'); % plot this first for overlay purposes
%             hold on;
%             %set(h1, 'facealpha', 0.25, 'edgecolor', 'none');
     
     %calculate peak vals of mean traces here?
     %output individual trials as struct array instead?
