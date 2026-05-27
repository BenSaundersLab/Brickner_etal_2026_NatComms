function  [outdata] = FP_ConditionalBinTrials(f,outdata,time,eventtypes,ProcessData,setcond,p)
%A Wolff 15/2/21
%% Function to bin events into two trial types depending on conditional events 
%Inputs:
    %f - indx to current filenumber (used for indexing)   
    %outdata - to save
    %time - timearray - of whole recording\
    %eventtypes - array of event epoch labels
    %ProcessData - list of labels for types of data to process
    %setcond - contains info needed for sorting trials depending on rules(listed below)
    
    %all rules require first cell of setcond to be the indx to eventtype for primary (t0) and conditional events.
    %second cell of input is labels for saving conditions, followed by rule and rule arguments in cell 3 and 4

    % 'RuleName',[RuleArgs]
    %       'none',[]
    %       'trial',[indxtoeventthatdefinestrial]
    %       'during' [*binthisevent] optional - default is to bin primary event
    %       'window',[startwintime,endwintime] -times (in s) relative to t0 (event 1, i.e. -100, 20)
    %       'first', [nevents after conditionalevent*, windowstart*,windowend*] - all inputs optional, default is 1 event, from current to next conditional event window time is s from  conditional event onset
    %       'control', [onset of perievent in s relative to primary event]
    %       cond1indx = 1;%indx for non-probe trial ts
    %       cond1array.ts = (NaN); %preallocate
    %       cond1array.trial = (NaN);
    %       cond2indx = 1;%indx for probe trial ts
    %       cond2array.ts = (NaN); %preallocate
    %       cond2array.trial = (NaN);
ruletype = setcond.(ProcessData{p}){3};

%determine how many conditions can be binned
numconds = length(setcond.(ProcessData{p}){2});
for nc = 1:numconds
    cond.(setcond.(ProcessData{p}){2}{nc}).indx = 1;
    cond.(setcond.(ProcessData{p}){2}{nc}).ts = (NaN); %preallocate
    cond.(setcond.(ProcessData{p}){2}{nc}).off = (NaN); %preallocate
    cond.(setcond.(ProcessData{p}){2}{nc}).trial =(NaN); %preallocate
end

switch ruletype
    case 'none' %requires event channel index only
            if ~isempty(outdata.eventdata.raw.(eventtypes{setcond.(ProcessData{p}){1}}).on{f,1})
                cond.(setcond.(ProcessData{p}){2}{nc}).ts = outdata.eventdata.raw.(eventtypes{setcond.(ProcessData{p}){1}(nc)}).on{f,1}; %add ts of primarty event to cond1 array (no second condition)
                cond.(setcond.(ProcessData{p}){2}{nc}).off = outdata.eventdata.raw.(eventtypes{setcond.(ProcessData{p}){1}(nc)}).off{f,1};
                cond.(setcond.(ProcessData{p}){2}{nc}).trial = (1:1:length(outdata.eventdata.raw.(eventtypes{setcond.(ProcessData{p}){1}(nc)}).on{f,1}));
                cond.(setcond.(ProcessData{p}){2}{nc}).indx = length(outdata.eventdata.raw.(eventtypes{setcond.(ProcessData{p}){1}(nc)}).on{f,1}); 
                if cond.(setcond.(ProcessData{p}){2}{nc}).indx == 2
                cond.(setcond.(ProcessData{p}){2}{nc}).indx = cond.(setcond.(ProcessData{p}){2}{nc}).indx+1;
                end
            end
        
    case 'trial' 
            if ~isempty(outdata.eventdata.raw.(eventtypes{setcond.(ProcessData{p}){4}}).on{f,1})
            for t = 1:(length(outdata.eventdata.raw.(eventtypes{setcond.(ProcessData{p}){4}}).on{f,1}(:,1))) %for each trial 
                winstart = outdata.eventdata.raw.(eventtypes{setcond.(ProcessData{p}){4}}).on{f,1}(t); %start of current trial window
                if t < length(outdata.eventdata.raw.(eventtypes{setcond.(ProcessData{p}){4}}).on{f,1}(:,1))%if its not the last trial
                winend= outdata.eventdata.raw.(eventtypes{setcond.(ProcessData{p}){4}}).on{f,1}(t+1); %set start of next trial as end of current one
                else
                winend = time(end);%otherwise set end trial as end of rec
                end
            
                temp = find(outdata.eventdata.raw.(eventtypes{setcond.(ProcessData{p}){1}(2)}).on{f,1} >= winstart,1,'first'); %find first conditional event occuring after trial start
                if ~isempty (temp)&& outdata.eventdata.raw.(eventtypes{setcond.(ProcessData{p}){1}(2)}).on{f,1}(temp) <= winend %see if this event occurs within current trial
                eventduring = true;
                else
                eventduring = false;
                end
            
                if eventduring
                cond.(setcond.(ProcessData{p}){2}{1}).ts(cond.(setcond.(ProcessData{p}){2}{1}).indx) = outdata.eventdata.raw.(eventtypes{setcond.(ProcessData{p}){1}(1)}).on{f,1}(t); %add ts of primary event to cond1 array 
                cond.(setcond.(ProcessData{p}){2}{1}).off(cond.(setcond.(ProcessData{p}){2}{1}).indx) = outdata.eventdata.raw.(eventtypes{setcond.(ProcessData{p}){1}(1)}).off{f,1}(t);
                cond.(setcond.(ProcessData{p}){2}{1}).trial(cond.(setcond.(ProcessData{p}){2}{1}).indx) = t;
                cond.(setcond.(ProcessData{p}){2}{1}).indx = cond.(setcond.(ProcessData{p}){2}{1}).indx+1;
                else
                cond.(setcond.(ProcessData{p}){2}{2}).ts(cond.(setcond.(ProcessData{p}){2}{2}).indx) = outdata.eventdata.raw.(eventtypes{setcond.(ProcessData{p}){1}(1)}).on{f,1}(t); %add ts of primary event to cond2 array 
                cond.(setcond.(ProcessData{p}){2}{2}).off(cond.(setcond.(ProcessData{p}){2}{2}).indx) = outdata.eventdata.raw.(eventtypes{setcond.(ProcessData{p}){1}(1)}).off{f,1}(t); %add ts of primary event to cond2 array 
                cond.(setcond.(ProcessData{p}){2}{2}).trial(cond.(setcond.(ProcessData{p}){2}{2}).indx) = t;
                cond.(setcond.(ProcessData{p}){2}{2}).indx = cond.(setcond.(ProcessData{p}){2}{2}).indx+1;
                end
            end
            end
        
   case 'during' 
        if ~isempty(setcond.(ProcessData{p}){4})
            if setcond.(ProcessData{p}){4}(1) ~= setcond.(ProcessData{p}){1}(1)
            binprimary = false;
            else
            binprimary = true;
            end
        else
            binprimary = true;
        end
           
            primindxarray = zeros(1,length(outdata.eventdata.raw.(eventtypes{setcond.(ProcessData{p}){1}(1)}).on{f,1})); %binary array of all primary events
            condindxarray = zeros(1,length(outdata.eventdata.raw.(eventtypes{setcond.(ProcessData{p}){1}(2)}).on{f,1}));    
            if ~isempty(outdata.eventdata.raw.(eventtypes{setcond.(ProcessData{p}){1}(2)}).on{f,1}) %only look if there are conditional events
            for e = 1:length(outdata.eventdata.raw.(eventtypes{setcond.(ProcessData{p}){1}(1)}).on{f,1})% for each primary event create window from onset to offset   
                winstart = outdata.eventdata.raw.(eventtypes{setcond.(ProcessData{p}){1}(1)}).on{f,1}(e);
                if length(outdata.eventdata.raw.(eventtypes{setcond.(ProcessData{p}){1}(1)}).on{f,1}) > length(outdata.eventdata.raw.(eventtypes{setcond.(ProcessData{p}){1}(2)}).off{f,1})
                    winend = time(end); %if there is no offset for last event use time end as window end
                else
                winend = outdata.eventdata.raw.(eventtypes{setcond.(ProcessData{p}){1}(1)}).off{f,1}(e);
                end

                temp = find (outdata.eventdata.raw.(eventtypes{setcond.(ProcessData{p}){1}(2)}).on{f,1} > winstart);%find all cond events starting after onset of current primary event
                if ~isempty(temp) %check events occur before window end
                    temp2 = find (outdata.eventdata.raw.(eventtypes{setcond.(ProcessData{p}){1}(2)}).on{f,1}(temp) < winend);
                    primindxarray(e) = 1;
                    if ~isempty(temp2)
                    condindxarray(temp(temp2)) = 1;
                    end
                end
            end 
            end

            %bin data
            if binprimary
                indxarray = primindxarray;
                eventarray = outdata.eventdata.raw.(eventtypes{setcond.(ProcessData{p}){1}(1)}).on{f,1};
                eventarray2 = outdata.eventdata.raw.(eventtypes{setcond.(ProcessData{p}){1}(1)}).on{f,1};
            else
                indxarray = condindxarray;
                eventarray = outdata.eventdata.raw.(eventtypes{setcond.(ProcessData{p}){1}(2)}).on{f,1};
                eventarray2 = outdata.eventdata.raw.(eventtypes{setcond.(ProcessData{p}){1}(2)}).off{f,1};
            end
            
            for i = 1:length(indxarray)
            if indxarray(i) %if condition 1 event
                cond.(setcond.(ProcessData{p}){2}{1}).ts(cond.(setcond.(ProcessData{p}){2}{1}).indx) = eventarray(i); %add ts of snip to cond1 array 
                cond.(setcond.(ProcessData{p}){2}{1}).off(cond.(setcond.(ProcessData{p}){2}{1}).indx) = eventarray2(i);
                cond.(setcond.(ProcessData{p}){2}{1}).trial(cond.(setcond.(ProcessData{p}){2}{1}).indx)= i;
                cond.(setcond.(ProcessData{p}){2}{1}).indx = cond.(setcond.(ProcessData{p}){2}{1}).indx+1;         
            else
                cond.(setcond.(ProcessData{p}){2}{2}).ts(cond.(setcond.(ProcessData{p}){2}{2}).indx) = eventarray(i); %add ts of snip to cond1 array 
                cond.(setcond.(ProcessData{p}){2}{2}).off(cond.(setcond.(ProcessData{p}){2}{2}).indx) = eventarray2(i);
                cond.(setcond.(ProcessData{p}){2}{2}).trial(cond.(setcond.(ProcessData{p}){2}{2}).indx)= i;
                cond.(setcond.(ProcessData{p}){2}{2}).indx = cond.(setcond.(ProcessData{p}){2}{2}).indx+1;     
            end
            end
                
    case 'window'
        if ~isempty(outdata.eventdata.raw.(eventtypes{setcond.(ProcessData{p}){1}(1)}).on{f,1})
        for t = 1:length(outdata.eventdata.raw.(eventtypes{setcond.(ProcessData{p}){1}(1)}).on{f,1}(:,1)) %for each primary event
            winstart = outdata.eventdata.raw.(eventtypes{setcond.(ProcessData{p}){1}(1)}).on{f,1}(t)+ setcond.(ProcessData{p}){4}(1); %start of user defined window
            winend= outdata.eventdata.raw.(eventtypes{setcond.(ProcessData{p}){1}(1)}).on{f,1}(t)+ setcond.(ProcessData{p}){4}(2); %end of user defined window
            temp = find(outdata.eventdata.raw.(eventtypes{setcond.(ProcessData{p}){1}(2)}).on{f,1} >= winstart,1,'first'); %find first conditional event after start of current window
            if ~isempty (temp) %if there are cond events
                if outdata.eventdata.raw.(eventtypes{setcond.(ProcessData{p}){1}(2)}).on{f,1}(temp) <= winend %check they occur within current window
                eventduring = true;
                else
                eventduring = false;
                end
            else
                eventduring = false;
            end
            if eventduring
                cond.(setcond.(ProcessData{p}){2}{1}).ts(cond.(setcond.(ProcessData{p}){2}{1}).indx) = outdata.eventdata.raw.(eventtypes{setcond.(ProcessData{p}){1}(1)}).on{f,1}(t); %add ts of primary event to cond1 array 
                cond.(setcond.(ProcessData{p}){2}{1}).off(cond.(setcond.(ProcessData{p}){2}{1}).indx) = outdata.eventdata.raw.(eventtypes{setcond.(ProcessData{p}){1}(1)}).off{f,1}(t);
                cond.(setcond.(ProcessData{p}){2}{1}).trial(cond.(setcond.(ProcessData{p}){2}{1}).indx)= t;
                cond.(setcond.(ProcessData{p}){2}{1}).indx = cond.(setcond.(ProcessData{p}){2}{1}).indx+1; 
            else
                cond.(setcond.(ProcessData{p}){2}{2}).ts(cond.(setcond.(ProcessData{p}){2}{2}).indx) = outdata.eventdata.raw.(eventtypes{setcond.(ProcessData{p}){1}(1)}).on{f,1}(t); %add ts of primary event to cond2 array 
                cond.(setcond.(ProcessData{p}){2}{2}).off(cond.(setcond.(ProcessData{p}){2}{2}).indx) = outdata.eventdata.raw.(eventtypes{setcond.(ProcessData{p}){1}(1)}).off{f,1}(t);
                cond.(setcond.(ProcessData{p}){2}{2}).trial(cond.(setcond.(ProcessData{p}){2}{2}).indx)= t;
                cond.(setcond.(ProcessData{p}){2}{2}).indx = cond.(setcond.(ProcessData{p}){2}{2}).indx+1; 
            end
        end 
        end
        
        case 'first'
        if ~isempty(outdata.eventdata.raw.(eventtypes{setcond.(ProcessData{p}){1}(1)}).on{f,1}) %only look if there are primary events
            
            if ~isempty(setcond.(ProcessData{p}){4}) && ~isempty(setcond.(ProcessData{p}){4}(1))%if user has set number of events
            nevents = setcond.(ProcessData{p}){4}(1);
            else %default 1 event
            nevents = 1;
            end
            
            primindxarray = zeros(1,length(outdata.eventdata.raw.(eventtypes{setcond.(ProcessData{p}){1}(1)}).on{f,1}));
            
            for e = 1:length(outdata.eventdata.raw.(eventtypes{setcond.(ProcessData{p}){1}(2)}).on{f,1})% for each conditional event work out the relevant window
                %find window around conditional event    
                if ~isempty(setcond.(ProcessData{p}){4}) && length(setcond.(ProcessData{p}){4}) > 1 %if the user has set a window
                    if ~isnan(setcond.(ProcessData{p}){4}(2)) %if user has set winstart use
                        winstart = outdata.eventdata.raw.(eventtypes{setcond.(ProcessData{p}){1}(2)}).on{f,1}(e)+ setcond.(ProcessData{p}){4}(2);
                    else %use next conditional event onset as winstart
                        winstart = outdata.eventdata.raw.(eventtypes{setcond.(ProcessData{p}){1}(2)}).on{f,1}(e); 
                    end
                    
                    if length(setcond.(ProcessData{p}){4}) > 2 %if there is a window end use it
                        if ~isnan(setcond.(ProcessData{p}){4}(3))
                        winend = outdata.eventdata.raw.(eventtypes{setcond.(ProcessData{p}){1}(2)}).on{f,1}(e) + setcond.(ProcessData{p}){4}(3);
                        else
                            if e < length(outdata.eventdata.raw.(eventtypes{setcond.(ProcessData{p}){1}(2)}).on{f,1}) %if not last event set to next
                            winend= outdata.eventdata.raw.(eventtypes{setcond.(ProcessData{p}){1}(2)}).on{f,1}(e+1);   
                            else %for last event don't set winend
                            winend = [];
                            end
                        end
                    else %otherwise use next event onset
                        if e < length(outdata.eventdata.raw.(eventtypes{setcond.(ProcessData{p}){1}(2)}).on{f,1}) %if not last event set to next
                        winend= outdata.eventdata.raw.(eventtypes{setcond.(ProcessData{p}){1}(2)}).on{f,1}(e+1);   
                        else %for last event don't set winend
                        winend = [];
                        end
                    end
                else %if no user input set default to next event onset
                    winstart = outdata.eventdata.raw.(eventtypes{setcond.(ProcessData{p}){1}(2)}).on{f,1}(e); 
                    if e < length(outdata.eventdata.raw.(eventtypes{setcond.(ProcessData{p}){1}(2)}).on{f,1}) %if not last event set to next
                    winend= outdata.eventdata.raw.(eventtypes{setcond.(ProcessData{p}){1}(2)}).on{f,1}(e+1);   
                    else %for last event don't set winend
                    winend = [];
                    end
                end

                
                temp = find (outdata.eventdata.raw.(eventtypes{setcond.(ProcessData{p}){1}(1)}).on{f,1} >= winstart,nevents);
                if ~isempty(temp) 
                    if isempty(winend)%if there are events and its the last trial, then add all events as cond 1
                    primindxarray(temp) = 1;
                    else %otherwise check events occur before window end
                        for t = 1:length(temp)
                            if outdata.eventdata.raw.(eventtypes{setcond.(ProcessData{p}){1}(1)}).on{f,1}(temp(t)) < winend
                            primindxarray(temp(t)) = 1;
                            end
                        end
                    end
                end 
            end

            %bin data
            for i = 1:length(primindxarray)
            if primindxarray(1,i) > 0 %if condition 1 event %if condition 1 event
                cond.(setcond.(ProcessData{p}){2}{1}).ts(cond.(setcond.(ProcessData{p}){2}{1}).indx) = outdata.eventdata.raw.(eventtypes{setcond.(ProcessData{p}){1}(1)}).on{f,1}(i); %add ts of snip to cond1 array 
                cond.(setcond.(ProcessData{p}){2}{1}).off(cond.(setcond.(ProcessData{p}){2}{1}).indx) = outdata.eventdata.raw.(eventtypes{setcond.(ProcessData{p}){1}(1)}).off{f,1}(i);
                cond.(setcond.(ProcessData{p}){2}{1}).trial(cond.(setcond.(ProcessData{p}){2}{1}).indx)= i;
                cond.(setcond.(ProcessData{p}){2}{1}).indx = cond.(setcond.(ProcessData{p}){2}{1}).indx+1;         
            else
                cond.(setcond.(ProcessData{p}){2}{2}).ts(cond.(setcond.(ProcessData{p}){2}{2}).indx) = outdata.eventdata.raw.(eventtypes{setcond.(ProcessData{p}){1}(1)}).on{f,1}(i); %add ts of snip to cond1 array 
                cond.(setcond.(ProcessData{p}){2}{2}).ts(cond.(setcond.(ProcessData{p}){2}{2}).indx) = outdata.eventdata.raw.(eventtypes{setcond.(ProcessData{p}){1}(1)}).off{f,1}(i);
                cond.(setcond.(ProcessData{p}){2}{2}).trial(cond.(setcond.(ProcessData{p}){2}{2}).indx)= i;
                cond.(setcond.(ProcessData{p}){2}{2}).indx = cond.(setcond.(ProcessData{p}){2}{2}).indx+1;     
            end
            end
        end
        
        case 'control' 
            if ~isempty(outdata.eventdata.raw.(eventtypes{setcond.(ProcessData{p}){1}(1)}).on{f,1})
            for t = 1:length(outdata.eventdata.raw.(eventtypes{setcond.(ProcessData{p}){1}(1)}).on{f,1}(:,1))   %for each primary event   
                cond.(setcond.(ProcessData{p}){2}{1}).ts(t)= outdata.eventdata.raw.(eventtypes{setcond.(ProcessData{p}){1}(1)}).on{f,1}(t)+ setcond.(ProcessData{p}){4}; %add ts of control snip to cond1 array 
                if t <=length(outdata.eventdata.raw.(eventtypes{setcond.(ProcessData{p}){1}(1)}).off{f,1})
                    cond.(setcond.(ProcessData{p}){2}{1}).off(t)= outdata.eventdata.raw.(eventtypes{setcond.(ProcessData{p}){1}(1)}).off{f,1}(t)+ setcond.(ProcessData{p}){4};              
                end
                cond.(setcond.(ProcessData{p}){2}{1}).trial(t)= t;
                cond.(setcond.(ProcessData{p}){2}{1}).indx = cond.(setcond.(ProcessData{p}){2}{1}).indx+1; 
            end
            end
            
    otherwise
        disp('rule type not recognized, please choose from the following: none,trial, during,window,first or control')
end
%% save the data
outdata.metadata.availcond{f,1}{p}=[];
ci = 1;
for nc = 1:numconds   
    if  cond.(setcond.(ProcessData{p}){2}{nc}).indx > 2
        outdata.eventdata.(ProcessData{p}).(setcond.(ProcessData{p}){2}{nc}).ts{f,1} = cond.(setcond.(ProcessData{p}){2}{nc}).ts;
        outdata.eventdata.(ProcessData{p}).(setcond.(ProcessData{p}){2}{nc}).tsoff{f,1} = cond.(setcond.(ProcessData{p}){2}{nc}).off;
        outdata.eventdata.(ProcessData{p}).(setcond.(ProcessData{p}){2}{nc}).trialn{f,1} = cond.(setcond.(ProcessData{p}){2}{nc}).trial;
        outdata.metadata.availcond{f,1}{p}{ci} = setcond.(ProcessData{p}){2}{nc}; %list of conditions with enough trials for analysis
        ci = ci+1;
    else
        outdata.eventdata.(ProcessData{p}).(setcond.(ProcessData{p}){2}{nc}).ts{f,1} = [];
        outdata.eventdata.(ProcessData{p}).(setcond.(ProcessData{p}){2}{nc}).tsoff{f,1} = [];
        outdata.eventdata.(ProcessData{p}).(setcond.(ProcessData{p}){2}{nc}).trialn{f,1} = [];
    end     
end
end