function[Z_data]= FP_Zscoresnips(inputdata,time,t0)
%A Wolff 15/2/21
%% Input arguments
%inputdata - data to Zscore 
%time array of snips (pre:post)
%t0 in time array to use as mean/sdev for z score (if empty uses whole
%trial)

%% index to calc mean and std for z score calc (currently just uses everything before event onset)
if ~isempty(t0)
zind = find (time < t0);% finds the index for points before event onset to start of plot window 
    if isempty(zind)
        zind = 1:length(inputdata(1,:));
    end   
else %if no pre- event window given Zscore based on mean and sdev of whole trial
zind = 1:length(inputdata(1,:));
end
%% Calculate Z scored Traces
    Z_data = zeros(length(inputdata(:,1)),length(inputdata(1,:)));
        for i = 1: length(inputdata(:,1)) % for each trials signal, calculate mean and stdev of pre event        
        u = mean (inputdata(i,zind)); %calc pre-event mean
        sdev = std(inputdata(i,zind)); %calc pre-event stdev
            for ii = 1: length(inputdata(i,:)) %for each datapoint in the trace use calc u and sdev to convert to z score
                Z_data(i,ii) = (inputdata(i,ii)-u)/sdev; 
            end   
        clear u sdev
        end       
end
