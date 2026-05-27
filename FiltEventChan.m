function [data]= FiltEventChan(endtime,data,chantofilt,filtchaninfo)

if isfield(data.epocs,(chantofilt))
%preallocate 
eventdur = NaN(length(data.epocs.(chantofilt).onset),1);
for i = 1:length(data.epocs.(chantofilt).onset)%for each event calculate duration
    if i > length(data.epocs.(chantofilt).offset)%if there is not an offset for current event 
        data.epocs.(chantofilt).offset = endtime; %set the offset as the end of recording
    end
    eventdur(i,1) = data.epocs.(chantofilt).offset(i)-data.epocs.(chantofilt).onset(i);
end

switch filtchaninfo{1}
    case '>'
    removeindx = find(eventdur > filtchaninfo{2}); 
    case '<'
    removeindx = find(eventdur < filtchaninfo{2});   
    case '<='
    removeindx = find(eventdur <= filtchaninfo{2});  
    case '>='
    removeindx = find(eventdur >= filtchaninfo{2});
end

data.epocs.(chantofilt).onset(removeindx) = [];
data.epocs.(chantofilt).offset(removeindx) = [];
data.epocs.(chantofilt).data(removeindx) = [];
eventdur(removeindx) = []; %#ok<NASGU>
end
end