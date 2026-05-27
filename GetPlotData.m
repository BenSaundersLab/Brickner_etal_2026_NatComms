 function [outdata] = GetPlotData(f, outdata,sniplabel,condition,datatype)
 %A Wolff 15/2/21
%% Function to calculate mean and error for perievent photometry data - used for plotting 
% Inputs:
% f - current file number used for referencing outdata
% outdata - output array for saving
% sniplabel - string: event or control snip 
% condition - string: cond1 trial type or cond2 trial type
% datatype - string: which datatypes to get mean of, dFF or raw? Z-scored?

    tempsz = size(outdata.perievent.(sniplabel).(condition).(datatype).trials{f,1});
    arraywidth = length(outdata.timearray.(sniplabel).FP.perievent{f,1});
    if tempsz(1) > 1
    outdata.perievent.(sniplabel).(condition).(datatype).mean(f,:) = mean(outdata.perievent.(sniplabel).(condition).(datatype).trials{f,1});
    outdata.perievent.(sniplabel).(condition).(datatype).std(f,:) = std (outdata.perievent.(sniplabel).(condition).(datatype).trials{f,1});
    outdata.perievent.(sniplabel).(condition).(datatype).n (f,:) = length(outdata.perievent.(sniplabel).(condition).(datatype).trials{f,1}(:,1));
    outdata.perievent.(sniplabel).(condition).(datatype).sem(f,:) = outdata.perievent.(sniplabel).(condition).(datatype).std(f,:)/sqrt(outdata.perievent.(sniplabel).(condition).(datatype).n(f,:));
    else
    outdata.perievent.(sniplabel).(condition).(datatype).mean(f,:) = NaN(1,arraywidth);
    outdata.perievent.(sniplabel).(condition).(datatype).std(f,:) = NaN(1,arraywidth);
    outdata.perievent.(sniplabel).(condition).(datatype).n (f,:) = NaN;
    outdata.perievent.(sniplabel).(condition).(datatype).sem(f,:) = NaN(1,arraywidth);
    end
end