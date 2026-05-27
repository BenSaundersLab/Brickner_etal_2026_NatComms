function [Orient,totalorients,orientduration] = DLC_FindOrienting (FPS,endtime,mintime,orientangle,data)
frameduration = 1/FPS; 
timearray = (frameduration:frameduration:frameduration*length(data));
numframesthresh = round(FPS*endtime);
minframes = round(FPS*mintime);
num_frames = length(data);
 
    realdatavals = ~isnan(data);%find non-nan vals
    indx = 1:num_frames;
    anglevals = data(realdatavals); %get only non-nan vals
    threshvals = anglevals < orientangle; %array indexing all real datapoints within orient threshold
    threshindx = indx(realdatavals); %indx of realdata points
    NanVals = isnan(data);
    Orient = zeros(num_frames,1);
    Orient(NanVals) = NaN;
    clear nanvals %realdatavals anglevals
    startindx = find (threshvals == 1,1,'first'); %find first point below threshold
    
    while ~isempty(startindx) %look for end to current orient
        threshvals = threshvals(startindx:end);
        threshindx = threshindx(startindx:end);
        if length(threshvals)-1 >= numframesthresh
        for w = 1:length(threshvals)-(numframesthresh-1)
            framesnip = threshvals(w:w+(numframesthresh-1));
            frameindx = threshindx(w:w+(numframesthresh-1));
            if sum(framesnip) == 0
            orientend = (frameindx(1))-1; %set end of orient to last frame before this window (may be a nan value)
            %check snip for nan ends
            orientsnip = data(threshindx(1):orientend);
            if isnan(orientsnip(end))
               orientindx = threshindx(1):orientend;
               findend = find(~isnan(orientsnip),1,'last');
               orientend = orientindx(findend);
            end
            Orient(threshindx(1):orientend) = 1; %mark orient in binary array
            threshvals = threshvals(w+numframesthresh:end); %check this - trims array to remove already checked sections
            threshindx = threshindx(w+numframesthresh:end);
            startindx = find(threshvals == 1,1,'first'); %find next orient
            break
            end
            
            if w == length(threshvals)-(numframesthresh-1)%if the last frame has been reached and criteria is not met %this should only happen for last bou
                %check snip for nan ends
                orientend= threshindx(end);
                orientsnip = data(threshindx(1):orientend);
                if isnan(orientsnip(end))
                orientindx = threshindx(1):orientend;
                findend = find(~isnan(orientsnip),1,'last');
                orientend = orientindx(findend);
                end
                Orient(threshindx(1):1:orientend) = 1; %mark orient in binary array
                startindx = [];
            end
        end
        else % if there are not enough frames
                orientend= threshindx(end);%set bout end to end of recording
                %check snip for nan ends
                orientsnip = data(threshindx(1):orientend);
                if isnan(orientsnip(end))
                orientindx = data(threshindx(1):orientend);
                findend = find(~isnan(orientsnip),1,'last');
                orientend = orientindx(findend);
                end
                Orient(threshindx(1):orientend) = 1; %mark orient in binary array
                startindx = [];      
        end
    end
    %remove events that are too short
    %filter out events that are too short
totalorients = 0; %count of total events 
orientduration.mean = NaN;
orientduration.stdev = NaN;
orientduration.sem = NaN;
outindx = 1; %indx for saving bout duration
sbout = find(Orient == 1);
ebout = find(Orient == 0);%array to search for boutends 
if ~isempty(sbout)
findstart = 1;
else
findstart =[];
end
while ~isempty(findstart)
    startbout = sbout(findstart);
    findend = find(ebout > startbout,1,'first'); %find indx end of bout
    if isempty(findend) %if there is no bout end
        boutend = length(Orient); %set end of bout to end of recording
    else
        boutend = ebout(findend)-1; %set boutend
    end
    tempbout = (startbout:boutend); %indx for current bout
    if length(tempbout) <= minframes       
        Orient(startbout:boutend) = 0; %remove bout from array
    else
        totalorients = totalorients+1;
        orientduration.raw(outindx,1) = (length(tempbout)) * frameduration;
        orienttimes(outindx,1) = timearray(startbout);
        outindx = outindx + 1;
    end
    findstart = find(sbout > boutend, 1,'first');%find the first bout event after the end of the current bout and set as boutstart
end

if exist('orientduration','var')
orientduration.mean = mean(orientduration.raw);
orientduration.stdev = std(orientduration.raw);
orientduration.sem = orientduration.stdev/sqrt(totalorients);
else
display 'no orient bouts were detected for this session'
orientduration.mean = NaN;
orientduration.stdev = NaN;
orientduration.sem = NaN;
end
end