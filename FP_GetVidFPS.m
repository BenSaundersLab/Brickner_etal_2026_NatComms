function [FPS] =  FP_GetVidFPS (data,vidstream)

camts = data.epocs.(vidstream).onset(1:50);
frametime(1:49) = NaN;
for i = 2:length(camts)
    frametime(i-1) = camts(i)-camts(i-1);
end
    frametime = round(frametime,2);
    meanval = mean(frametime,'omitnan');
    stdev = std(frametime,'omitnan')*3;
    for i = 1:length(frametime)
        if frametime(i) > meanval+stdev
            frametime(i) = NaN;
        end
    end
    frametime = mean(frametime,'omitnan');
    frametime = round(frametime,2);
    FPS = 1/frametime; 
end
    
    