function[binneddata,bintimearray]=DLC_bindata(inputdata,binsize,FPS,timearray)

numframestobin = binsize*FPS;
binneddata = NaN(1,length(inputdata)/numframestobin);
bintimearray = NaN(1,length(inputdata)/numframestobin);
indxs = 1;
indxe = numframestobin;

for i = 1:length(binneddata)
    binneddata(i) = mean(inputdata(indxs:indxe,1),'omitnan'); 
    bintimearray(i) = timearray(indxs);
    indxs = indxs+numframestobin;
    indxe = indxe+numframestobin; 
end 
end
