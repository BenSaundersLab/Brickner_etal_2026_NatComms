function [bout,freezebout,bpsarray,totalbouts,boutduration,bodymulti,scalefactor,limspeed,bodydetect] = DLC_FindFreezing(indata,minlength,FPS,bps,endtime,bodybps,headbps,animalsize)
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
limspeed = animalsize*scalefactor;
bodymulti = 2;
bodydetect = limspeed*bodymulti;

for b=1:length(bps) 
    if isfield(indata,(bps{b})) %if this bodypart exists in csv extract speed data to boutarray
        if ~exist('bpsarray','var') %for the first avail bodypart set up empty arrays for data output  
        numframes = length(indata.(bps{b}).raw);
        timearray = (frameduration:frameduration:frameduration*numframes);
        bpsarray = zeros(numframes,length(bps));
        bout.array = zeros(numframes,length(bps));
        bout.count = zeros(numframes,length(bps));
        freezebout = zeros(numframes,1);
        peakdetect = ones(numframes,length(bps));
        bout.data = NaN(numframes,1);
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
    else %if bodypart doesnt exist then fill with NaN
         bpsarray(:,b) = NaN;
         bout.count(:,b) = NaN;
         bout.array (:,b) = NaN;
    end
end

%detect peak across all bodyparts for all frames
for b=1:size(bpsarray,2)
    if bindx(1,b) 
    boutlimit = bodydetect;
    else
    boutlimit = limspeed;
    end
    
indxdata = find(bpsarray(:,b) <= boutlimit);
peakdetect(indxdata,b) = 0;
end

startindx = 1;
outindx = 1;
peakdetectsum = sum(peakdetect,2,'omitnan'); %find sum (#parts not freezing)
nparts = isnan(peakdetect); 
temp = sum(nparts,2);
nparts = length(bindx)-temp; %number of visible parts for each frame
nanindx = find(nparts < 2 ); %find frames where less than 2 parts are visible
peakdetectsum(nanindx) = NaN; %mark frames with too few parts as NaN



getpeaks = find(peakdetectsum == 0) ;
findpeaks = find(getpeaks > startindx,1,'first');

    while ~isempty(findpeaks)
        peak = (getpeaks(findpeaks));
        snipindx = (startindx:peak);
        dataindx = ~isnan(peakdetectsum(snipindx)); %find non-nan values
        dataindx = snipindx(dataindx);
        %peakdetectsum(snipindx);
        datasnip = peakdetectsum(dataindx);
         if length(datasnip)-1 >= numframesthresh
         for i = length(datasnip)-1:-1:numframesthresh %search backwards for bout start
            winarray = datasnip(i-(numframesthresh-1):i);
            winarrayindx = winarray   >= 2;
            if sum(winarrayindx) == numframesthresh
            boutstart = dataindx(i)+1;
            break
            end
            
            if i == numframesthresh % if the last frame has been reached (*should only happen for the first bout?)
               winarray = datasnip;
               winarrayvals = winarray   >= 2;
               winarrayindx = dataindx;
               indx = find(winarrayvals ==0 ,1,'first'); %find the first value that should be part of the bout
               boutstart = winarrayindx(indx);
            end
        end
        else
                    winarray = datasnip;
                    winarrayvals = winarray   >= 2;
                    winarrayindx = dataindx;
                    indx = find(winarrayvals ==0 ,1,'first'); %find the first value that should be part of the bout
                    boutstart = winarrayindx(indx);
         end
           
            if ~exist('boutstart','var') || isempty(boutstart)%this should never happen?
            boutstart = peak;
            end
            
%             %% search for large movements of a single bodypart
%             if ~isempty(fastmovedur) && ~isempty(fastmovthres)
%                 if boutstart < peak 
%                 valindx = ~isnan(bpsarray(boutstart:peak,b));
%                 indxarray = boutstart:peak;
%                 tempindx = indxarray(valindx);
%                 tempbout = bpsarray(tempindx,b);%array excluding nan
%                
%                 if ~isempty(find(tempbout>fastmovethres)) %if there are fast movements in the snip see if these occur for enough frames to exclude from bout
%                 if length (tempbout) >= fastmovedur
%                     for i = length(tempbout)-1:-1:fastmovedur
%                     win = tempbout(i-(fastmovedur-1):i);
%                     x = find (win > fastmovethres);
%                     if length(x) == fastmovedur %if threshold of fast movement met, reset boutstart to after fast movement
%                         boutstart = tempindx(i)+1;
%                         break
%                         
%                     end
%                     end
%                 end
%                 end
%                 end
%             end
%                 
                
                if boutstart < peak
                %check for any nan values at the start of the bout and trim
                tempbout = peakdetectsum(boutstart:peak-1);             
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
        datasnip = peakdetectsum(dataindx);
        if length(datasnip)-1 >= numframesthresh %if there are enough frames, search forwards using moving window to find criteria for end bout
            for i = 2:length(datasnip)-(numframesthresh-1) %search forwards for bout end
            winarray = datasnip(i:i+(numframesthresh-1));
            winarrayindx = winarray   >= 2;
            if sum(winarrayindx) == numframesthresh
            boutend= dataindx(i)-1;
            break
            end
            if i == length(datasnip)-(numframesthresh-1) %if the last frame has been reached and criteria is not met %this should only happen for last bout
                boutend = length(peakdetectsum);%set bout end to end of recording
            end
            end
        else
        winarray = datasnip; %this should only happen for last bout
        winarrayvals = winarray   >= 2;
        if sum(winarrayvals) == length(winarray)
            boutend = peak;
        else
        winarrayindx = dataindx; 
        indx = find(winarrayvals == 0,1,'last'); %find the last value that should be part of the bout
        boutend = winarrayindx(indx);
        end
        end

    if ~exist('boutend','var')%this should never happen?
        winarray = peakdetectsum(dataindx);
        winarrayvals = winarray   >= 2;
        winarrayindx = dataindx; 
        indx = find(winarrayvals == 0,1,'last'); %find the last value that should be part of the bout
        boutend = winarrayindx(indx);
        if ~isempty(indx)
           boutend = peak; %this should never happen as peak is included in array
        end       
    end
    
%                 %search for fastmovements
%                 if ~isempty(fastmovedur) && ~isempty(fastmovthres)
%                 if boutend > peak 
%                 valindx = ~isnan(boutdata(peak:boutend));
%                 indxarray = peak:1:boutend;
%                 tempindx = indxarray(valindx);
%                 tempbout = boutdata(tempindx,b);%array excluding nan
%                
%                 if ~isempty(find(tempbout>fastmovethres)) %if there are fast movements in the snip see if these occur for enough frames to exclude from bout
%                 if length (tempbout) >= fastmovedur
%                     for i = 2:1:length(tempbout)-(fastmovedur-1)
%                     win = tempbout(i:i+(fastmovedur-1));
%                     x = find (win > fastmovethres);
%                     if length(x) == fastmovedur %if threshold of fast movement met, reset boutstart to after fast movement
%                         boutend = tempindx(i)-1;
%                         break
%                         
%                     end
%                     end
%                 end
%                 end
%                 end
%                 end
                
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
    bout.data (boutstart:boutend,1) = peakdetectsum(boutstart:boutend);
    freezebout (boutstart:boutend,1) = 1;
    %boutindx{outindx,b} = (boutstart:1:boutend); %#ok<AGROW>
    bout.peakindx(outindx,1) = peak; %#ok<AGROW>
    bout.count(boutstart:boutend,1) = outindx;
    outindx = outindx+1;
    startindx = boutend+1;
    findpeaks = find(getpeaks > startindx,1,'first');   
    clear boutstart boutend
    end


% for b = 1:length(bout.array)
%     boutvals = ~isnan(bout.count(b,:));
%     boutvals = bout.count(b,boutvals); %exclude bodyparts that are not visible   
%     if ~isempty (boutvals)
%         if sum(boutvals == 0)== 0 %check if all visible bodyparts are in a bout
%         if length(boutvals) >= 2 %only include as bout if more than 2 bodyparts are visible
%         freezebout(b,1) = 1;
%         else
%         freezebout(b,1) = 0;
%         end
%         else
%         freezebout(b,1) = 0;
%         end
%     else %if there are no visible bodyparts 
%        freezebout(b,1) = NaN; 
%     end
% end

%filter out events that are too short
totalbouts = 0;
outindx = 1; %indx for saving bout duration
sbout = find(freezebout == 1);
ebout = find(freezebout == 0);%array to search for boutends 
if ~isempty(sbout)
findstart = 1;
else
findstart =[];
end
while ~isempty(findstart)
    startbout = sbout(findstart);
    findend = find(ebout > startbout,1,'first'); %find indx end of bout
    if isempty(findend) %if there is no bout end
        boutend = length(freezebout); %set end of bout to end of recording
    else
        boutend = ebout(findend)-1; %set boutend
    end
    tempbout = (startbout:boutend); %indx for current bout
    if length(tempbout) <= minframes       
        freezebout(startbout:boutend) = 0; %remove bout from array
    else
        totalbouts = totalbouts+1;
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
display 'no freezing bouts were detected for this session'
boutduration.mean = NaN;
boutduration.stdev = NaN;
boutduration.sem = NaN;
end
end
    