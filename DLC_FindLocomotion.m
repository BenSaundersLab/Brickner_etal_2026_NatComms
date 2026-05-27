function [bout,locobout,bpsarray,totalbouts,boutduration,bodymulti,scalefactor,limspeed,bodydetect] = DLC_Locomotion(indata,minlength,FPS,bps,endtime,bodybps,headbps,animalsize)
frameduration = 1/FPS;
minframes = FPS*minlength;
numframesthresh = round(FPS*endtime); %number of consecutive frames above threshold to consider bout end/start
hindx = zeros(1,length(bps));
bindx = zeros(1,length(bps));
%  fastmovedur = [];%FPS*0.2;
%  fastmovethres = [];%5;
%detectspeed = targetspeed;
%limspeed = boutlimit;
scalefactor = 0.008;
freezebodythresh = (animalsize*scalefactor)*2;
%limspeed = (animalsize*scalefactor)*1.5;
limspeed = (animalsize*scalefactor)*6;
bodymulti = 6;
bodydetect = freezebodythresh*bodymulti;
numparts = 2;



for b=1:length(bps) 
    if isfield(indata,(bps{b})) %if this bodypart exists in csv extract speed data to boutarray
        if ~exist('bpsarray','var') %for the first avail bodypart set up empty arrays for data output  
        numframes = length(indata.(bps{b}).raw);
        timearray = (frameduration:frameduration:frameduration*numframes);
        bpsarray = zeros(numframes,length(bps));
        bout.array = zeros(numframes,length(bps));
        bout.count = zeros(numframes,length(bps));
        locobout = zeros(numframes,1);
        peakdetect = ones(numframes,length(bps));
        limdetect = zeros(numframes,length(bps));
        bout.data = NaN(numframes,1);
        limdetectbinary = zeros(numframes,1);
        end
      
        if sum(strcmp((bps{b}),headbps)) > 0 %if string is found in head list then add to head
        hindx(1,b) = 1;
        else
        bindx(1,b) = 1;
        end
        bpsarray(:,b) = indata.(bps{b}).raw;
        temp = isnan(indata.(bps{b}).raw);       
        bout.array(temp,b) = NaN;
        bout.count(temp,b) = NaN;
        peakdetect(temp,b) = NaN;
        limdetect(temp,b) = NaN;       
    else %if bodypart doesnt exist then fill with NaN
         bpsarray(:,b) = NaN;
         bout.count(:,b) = NaN;
         bout.array (:,b) = NaN;
         peakdetect(:,b) = NaN;
         limdetect(:,b) = NaN;
    end
end

% if sum(hindx) <= 1 %set a higher movement threshold for movement based only on body
% bodymulti = 7;
% bodydetect = limspeed*bodymulti;
% %numparts =2;
% end

%detect peak across all bodyparts for all frames
for b=1:size(bpsarray,2)
    if bindx(1,b) 
    boutlimit = bodydetect;
    else
    boutlimit = limspeed;
    end
    
indxdata = find(bpsarray(:,b) > boutlimit);
peakdetect(indxdata,b) = 0; %find where bodypart is moving above detection threshold (set to zero so sum can be used to find number of parts NOT meeting threshold)
indxdata = find(bpsarray(:,b) > (boutlimit*0.5));
limdetect(indxdata,b) = 1; %find where bodypart is moving more than 50% of detection threshold and set to 1
end

startindx = 1;
outindx = 1;
peakdetectsum = sum(peakdetect,2,'omitnan'); %find sum (Number of parts not meeting movement threshold)
limdetectsum = sum(limdetect,2,'omitnan');%
nparts = isnan(peakdetect); %get array indexing missing (not visible bodyparts) for each frame/bodypart
temp = sum(nparts,2); %total number of not visible bodyparts for each frame
nparts = length(bindx)-temp; %number of visible parts for each frame (total bodyparts - not visible bodyparts)
nanindx = find(nparts < 2 ); %find frames where less than 2 parts are visible
peakdetectsum(nanindx) = NaN; %mark frames with too few parts as NaN
limindx = find(limdetectsum > 1);
limdetectbinary(limindx) = 1;
limdetectbinary(nanindx) = NaN;
clear limindx nanindx


%getpeaks = find(peakdetectsum == 0) ;
getpeaks = find(peakdetectsum < 1); % 1 indicates bodyparts  not meeting threshold so get peaks are when sum == 0
findpeaks = find(getpeaks > startindx,1,'first'); %find indx for first peak after the start of the current portion of the trace (after end of last bout)

    while ~isempty(findpeaks)
        peak = (getpeaks(findpeaks));
        snipindx = (startindx:peak); %take data from start of window to peak
        dataindx = ~isnan(peakdetectsum(snipindx)); %find non-nan values
        dataindx = snipindx(dataindx); %get indx for portion of data that has enough visible bodyparts
        %peakdetectsum(snipindx);
        datasnip = limdetectbinary(dataindx); %get data for non-nan frames
         if length(datasnip)-1 >= numframesthresh % are there enough frames
         for i = length(datasnip)-1:-1:numframesthresh %search backwards for bout start
            winarray = datasnip(i-(numframesthresh-1):i);
            if sum(winarray,'omitnan') == 0 %when not enough bodyparts have been above threshold for frame limit then end bout
            boutstart = dataindx(i)+1;
            break
            end
            
            if i == numframesthresh % if the last frame has been reached (*should only happen for the first bout?)
               winarray = datasnip;
               indx = find(winarray == 1 ,1,'first'); %find the first value that should be part of the bout
               boutstart = dataindx(indx);
            end
        end
        else
                    winarray = datasnip;
                    indx = find(winarray == 1 ,1,'first'); %find the first value that should be part of the bout
                    boutstart = dataindx(indx);
         end
           
            if ~exist('boutstart','var') || isempty(boutstart)%this should never happen?
            boutstart = peak;
            end
            
            
                if boutstart < peak
                %check for any nan values at the start of the bout and trim
                tempbout = limdetectbinary(boutstart:peak-1);             
                if isnan(tempbout(1))  %if the first point in bout is nan
                temp = ~isnan(tempbout);
                x = find(temp == 1,1,'first'); %find first non-nan 
                tempindx = boutstart:1:peak-1; 
                boutstart = (tempindx(x)); %set boutstart to first non-nan value
                    if isempty (boutstart)
                    boutstart = peak;
                    end
                    clear findnans x tempindx tempbout
                end
                end
                
    
    %find bout end
    	snipindx = (peak:length(peakdetectsum));
        dataindx = ~isnan(peakdetectsum(snipindx)); %find non-nan values
        dataindx = snipindx(dataindx);
        datasnip = limdetectbinary(dataindx);
        if length(datasnip)-1 >= numframesthresh %if there are enough frames, search forwards using moving window to find criteria for end bout
            for i = 2:length(datasnip)-(numframesthresh-1) %search forwards for bout end
            winarray = datasnip(i:i+(numframesthresh-1));
            if sum(winarray,'omitnan') == 0
            boutend= dataindx(i)-1;
            break
            end
            if i == length(datasnip)-(numframesthresh-1) %if the last frame has been reached and criteria is not met %this should only happen for last bout
                boutend = length(peakdetectsum);%set bout end to end of recording
            end
            end
        else
        winarray = datasnip; %this should only happen for last bout
        if sum(winarray,'omitnan') == 0
            boutend = peak;
        else
        indx = find(winarray == 1,1,'last'); %find the last value that should be part of the bout
        boutend = dataindx(indx);
        end
        end

    if ~exist('boutend','var')%this should never happen?
        winarray = limdetectbinary(dataindx);
        indx = find(winarray == 1,1,'last'); %find the last value that should be part of the bout
        boutend = dataindx(indx);
        if ~isempty(indx)
           boutend = peak; %this should never happen as peak is included in array
        end       
    end
    
               
            %check that end of bout isn't all NaN
            if boutend > peak
            tempbout = peakdetectsum(peak+1:boutend);
            if isnan(tempbout(end))  %if the first point in bout is nan
                temp = ~isnan(tempbout);
                x = find(temp == 1,1,'last'); %find last non-nan 
                tempindx = peak+1:1:boutend; 
                boutend = (tempindx(x)); %set boutstart to last non-nan value
                    if isempty (boutend)
                    boutend = peak;
                    end
                    clear findnans x tempindx tempbout
            end  
            end
    
    %save bout data
    bout.array(boutstart:boutend,:) = bpsarray(boutstart:boutend,:); 
    bout.data (boutstart:boutend,1) = limdetectsum(boutstart:boutend);
    locobout (boutstart:boutend,1) = 1;
    %boutindx{outindx,b} = (boutstart:1:boutend); %#ok<AGROW>
    bout.peakindx(outindx,1) = peak; %#ok<AGROW>
    bout.count(boutstart:boutend,1) = outindx;
    outindx = outindx+1;
    startindx = boutend+1;
    findpeaks = find(getpeaks > startindx,1,'first');   
    clear boutstart boutend
    end


%filter out events that are too short
totalbouts = 0; %count of total events 
outindx = 1; %indx for saving bout duration
sbout = find(locobout == 1);
ebout = find(locobout == 0);%array to search for boutends 
if ~isempty(sbout)
findstart = 1;
else
findstart =[];
end
while ~isempty(findstart)
    startbout = sbout(findstart);
    findend = find(ebout > startbout,1,'first'); %find indx end of bout
    if isempty(findend) %if there is no bout end
        boutend = length(locobout); %set end of bout to end of recording
    else
        boutend = ebout(findend)-1; %set boutend
    end
    tempbout = (startbout:boutend); %indx for current bout
    if length(tempbout) <= minframes       
        locobout(startbout:boutend) = 0; %remove bout from array
    else
    totalbouts = totalbouts + 1;
    boutduration.raw(outindx,1) = length(tempbout) * frameduration;
    bout.times(outindx,1) = timearray(startbout);
    outindx = outindx + 1;
    end
    findstart = find(sbout > boutend, 1,'first');%find the first bout event after the end of the current bout and set as boutstart
end  

if exist('boutduration','var')
boutduration.mean = mean(boutduration.raw);
boutduration.stdev = std(boutduration.raw);
boutduration.sem = boutduration.stdev/sqrt(totalbouts);
else
display 'no locomotion bouts were detected for this session'
boutduration.mean = NaN;
boutduration.stdev = NaN;
boutduration.sem = NaN;
end
end
    