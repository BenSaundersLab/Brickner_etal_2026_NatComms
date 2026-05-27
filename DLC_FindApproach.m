function [ApprEvents,totalapproaches,apprduration] = DLC_FindApproach(Appr,FPS,minlength,endtime)
    frameduration = 1/FPS;
    timearray = (frameduration:frameduration:frameduration*length(Appr));
    minframes = FPS*minlength;
    numframesthresh = round(FPS*endtime); %number of consecutive non approach frames to consider bout end/start
    outindx = 1;
    totalapproaches = 0;
    apprduration.raw = [];
    apprduration.mean = NaN;
    apprduration.stdev = NaN;
    apprduration.sem = NaN; 
    startindx = 1;
    apprst = 1;
    apprend = 1;
    apprindx = find(Appr(:,2) == 1); %detect approach events
    ApprEvents = zeros(length(Appr),1);
    apprdetect = find(apprindx >= apprend,1,'first'); %find the first approach after the current frame
    apprdetect = apprindx(apprdetect);
    indxdata = find(~isnan(Appr(:,1)));
    
    while ~isempty(apprdetect)  
    %search backward for start of approach
        snipstartindx = find(indxdata >= startindx, 1, 'first'); %find the first realdata point that is greater than the startindx (ignoring nan)
        datapeak = find(indxdata == apprdetect); %find the indx for the approach in the array excluding nan
        snipindx = indxdata(snipstartindx:datapeak);
        datasnip = Appr(snipindx,1);
        if length(datasnip)-1 >= numframesthresh
        for i = length(datasnip)-1:-1:numframesthresh %search backwards for bout start
            winarray = datasnip(i-(numframesthresh-1):i);
            if sum(winarray) == 0 %if there are no approaches in this window
            apprst = snipindx(i)+1;
            break
            end
            if i == numframesthresh %if we are at the start of the snip and no consec datapoints have been found
                    winarray = Appr(startindx:apprdetect,1);
                    winarrayindx = startindx:apprdetect;
                    indx = find(winarray == 1,1,'first'); %find the first non-nan value that should be part of the bout
                    apprst = winarrayindx(indx);
            end
        end
        else
                    winarray = Appr(startindx:apprdetect,1);
                    winarrayindx = startindx:apprdetect;
                    indx = find(winarray == 1,1,'first'); %find the first non-nan value that should be part of the bout
                    apprst = winarrayindx(indx);
        end
         
        if ~exist('apprstart','var')%if no start found set start to peak
        apprst = apprdetect;
        end
        
                %if boutstart < peak
                %check for leading nan values )
                tempbout = Appr(apprst:apprdetect,1);
                tempindx = apprst:1:apprdetect; 
                findnans= isnan(tempbout); %indx of NaN in bout
                if findnans(1)  %if the first point in bout is nan
                x = find(tempbout ==1,1,'first'); %find first bout value 
                apprst = (tempindx(x)); %set boutstart to first non-nan value
                    if isempty (apprst)
                    apprst = apprdetect;
                    end
                    clear findnans x tempindx tempbout
                end
    
    %find bout end
        snipindx = indxdata(datapeak:end);
        datasnip = Appr(snipindx,1);
        if length(datasnip)-1 >= numframesthresh %if there are enough frames, search forwards using moving window to find criteria for end bout
            for i = 2:length(datasnip)-(numframesthresh-1) %search forwards for bout end
            winarray = datasnip(i:i+(numframesthresh-1));
            if sum(winarray) == 0
            apprend= snipindx(i)-1;
            break
            end
            if i == length(datasnip)-(numframesthresh-1) %if we are at the end of the snip and no 3 consec datapoints have been found
                    winarray = Appr(apprdetect:end,1);
                    winarrayindx = apprdetect:length(Appr);
                    indx = find(winarray == 1,1,'last'); %find the last non-nan value that should be part of the bout
                    apprend = winarrayindx(indx);
            end
            end
        else
            winarray = Appr(apprdetect:end,1);
            indx = find(winarray == 1,1,'last');
            winarrayindx = apprdetect:length(Appr);
            apprend= winarrayindx(indx);
        end
        
        
        
%     for i = apprdetect+1:length(Appr)-1
%         if Appr(i) == 0  && Appr(i+1) == 0 
%             apprend = i-1;
%             %check that end of bout isn't all NaN
%             if apprend > apprdetect
%             tempbout = Appr(apprdetect+1:apprend);
%             tempindx = apprdetect+1:1:apprend; 
%             findnans= isnan(tempbout); %indx of NaN in bout
%              if findnans(end) %if the last point in bout is nan
%              x = find(~isnan(tempbout),1,'last'); %find first non-nan value 
%              apprend = (tempindx(x)); %set boutstart to first non-nan value
%             if isempty (apprend)
%                 apprend = apprdetect;
%             end
%             clear findnans x tempindx tempbout
%             end
%             end
%         break
%         end
%     end
    if ~exist('apprend','var') %if no end found set to end of rec
        winarray = Appr(apprdetect+1:end,1);
        windarrayindx = apprdetect+1:length(Appr);
        indxvals = find(winarray == 1,1,'last');
        if ~isempty(indxvals)
           apprend = winarrayindx(indxvals);
        else
           apprend = apprdetect;
        end
    end
    
    %check that end of bout isn't all NaN
            if apprend > apprdetect
            tempbout = Appr(apprdetect+1:apprend,1);
            tempindx = apprdetect+1:1:apprend; 
            findnans= isnan(tempbout); %indx of NaN in bout
                if findnans(end)  %if the last point in bout is nan
                x = find(tempbout == 1,1,'last'); %find last non-nan value 
                apprend = (tempindx(x)); %set boutstart to first non-nan value
                    if isempty (apprend)
                    apprend = apprdetect;
                    end
                    clear findnans x tempindx tempbout
                end
            end
    
            
        if length(apprst:apprend)> numframesthresh %if approach is long enough
        ApprEvents(apprst:apprend,1) = 1;
        totalapproaches = totalapproaches + 1;
        apprduration.raw(outindx,1) = (length(apprst:apprend)) * frameduration;
        approachtimes(outindx,1) = timearray(apprst);
        outindx = outindx + 1;
        end
        %find start  of next event
        apprdetect = find(apprindx > apprend,1,'first');
        apprdetect = apprindx(apprdetect);
        startindx =apprend;
    end

    if exist('apprduration','var')
    apprduration.mean = mean(apprduration.raw);
    apprduration.stdev = std(apprduration.raw);
    apprduration.sem = apprduration.stdev/sqrt(totalapproaches); 
    else
    display 'no locomotion bouts were detected for this session'
    apprduration.mean = NaN;
    apprduration.stdev =  NaN;
    apprduration.sem =  NaN; 
    end
end