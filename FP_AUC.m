function [AUC]= FP_AUC(timearray,traces,searchwin)
%A Wolff 15/2/21
%% Function to extract max reponses within a timewindow
%Inputs:
%timearray - timestamps that match trace length centered around event @t0
%traces - individual traces to search for max response
%searchwin - window to search for peak (in s) [winstart,winend] - input [] to search whole trace, NaN to default to start/end of trace
     
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
        
     cliptime = timearray(indx1:indx2);%extract the time array for just the selected window       
     cliptrace = traces(:,indx1:indx2);%extract the trace for just the selected window
     for t = 1:size(cliptrace,1);
     AUC.trials(t,:) = trapz(cliptrace(t,:));  
     end
     AUC.mean = trapz(mean(cliptrace)); %find AUC for mean trace
     
end