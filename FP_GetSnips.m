function [dFF_snips, raw_snips, dFF_snips_ts, dFF_snips_trial,dFF_snips_indx,exclude,removecond] = FP_GetSnips(eventarray, TRANGE, time, data_dFF,data_raw,trials,trialexclude)
%A Wolff 15/2/21
%% Function to pull and bin data photometry data time locked to event onset
%eventarray - timestamps for event onset 
% TRANGE - number of data points each side of event onset to include in snip (determined by pre  and post time set by user and sampling rate)
% time - time array for whole recording
% data_dFF - dFF data array
% data_raw - raw data array 
% trials - trial number reference
% exclude - list of trials to exclude (based on user input)
numtrials = length(trials);
%preallocate arrays
dFF_snips = cell(numtrials,1);
raw_snips = cell(numtrials,1);
dFF_snips_ts = cell(numtrials,1);
dFF_snips_indx = cell(numtrials,1);
dFF_snips_trial = NaN(numtrials,1);
exclude = NaN(length(trialexclude),1);
ii = 1;     
       if ~isempty(trialexclude)
           for e =1:length(trialexclude)
%                if iscell(trialexclude)
               exclude(e,1) = trialexclude{1,e};
%                else
%                exclude(e,1) = trialexclude(1,e);
%                end
           end
       end
       
        for i = 1: numtrials
            % Find first time index after onset
            x = trials(i);
            if ~isnan(eventarray(i)) %if a timestamp exists
            array_ind = find(time > eventarray(i),1);
            %Find index corresponding to pre and post durations
            pre = array_ind + TRANGE(1);
            if isempty(pre)
                pre = 0;
            end
            post = array_ind + TRANGE(2);    
                if pre > 0 && post < (length(data_dFF))% only get snip if data for both pre and post stim times exist
                    if ~isempty(exclude) %if there are trials to exlude
                        ex = find (exclude == x,1);%see if the current trial is on the exclusion list
                        if isempty(ex)% only add snips if this trial is not on the exclusion list
                            dFF_snips{ii,1} = data_dFF(pre:post);
                            raw_snips{ii,1} = data_raw(pre:post);
                            dFF_snips_ts{ii,1} = time(pre:post);
                            dFF_snips_indx{ii,1} = (pre:post);
                            dFF_snips_trial(ii,1) = trials(i);
                            ii = ii+1;
                        else %if a trial should be excluded remove the end row from output
                        dFF_snips(end,:) = [];
                        raw_snips(end,:) = [];
                        dFF_snips_ts(end,:) = [];
                        dFF_snips_indx(end,:) = [];
                        dFF_snips_trial(end,:) = [];    
                        end
                     else %if there are no trials to exclude add snips to list
                     dFF_snips{ii,1} = data_dFF(pre:post);
                     raw_snips{ii,1} = data_raw(pre:post);
                     dFF_snips_ts{ii,1} = time(pre:post);
                     dFF_snips_indx{ii,1} = (pre:post);
                     dFF_snips_trial(ii,1) = trials(i);
                     ii = ii+1;
                    end
                else
                    dFF_snips(end,:) = [];
                    raw_snips(end,:) = [];
                    dFF_snips_ts(end,:) = [];
                    dFF_snips_indx(end,:) = [];
                    dFF_snips_trial(end,:) = [];  
                end
            else
            end
        end
      if length(dFF_snips_trial(:,1)) < 2%if there are less than 2 of an eventtype remove from subsequent analysis (can't mean)
            removecond = true;  
      else
            removecond= false;
      end
end
        