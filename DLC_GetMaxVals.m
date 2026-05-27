function [outdata] = DLC_GetMaxVals(f,outdata,sniplabel,condition,wins,maxresponselabs)

for m = 1:length(maxresponselabs)
currentmeasure = maxresponselabs{m};
numsubfields = length(outdata.UserVals.DLCsetup.Subfields.(currentmeasure));
switch numsubfields
    case  1
    flds = outdata.UserVals.DLCsetup.Subfields.(currentmeasure){1};
    for x = 1:length(flds)
    for w = 1:length(wins)
            for t = 1:length(outdata.DLC.(sniplabel).(condition).(currentmeasure).(flds{x}).Peak.(wins{w}).trials{f,1}(:,1))
            [outdata.DLC.(sniplabel).(condition).(currentmeasure).(flds{x}).Peak.(wins{w}).MaxVal.trials{f,1}(t,1),I] = max(outdata.DLC.(sniplabel).(condition).(currentmeasure).(flds{x}).Peak.(wins{w}).trials{f,1}(t,:));
            outdata.DLC.(sniplabel).(condition).(currentmeasure).(flds{x}).Peak.(wins{w}).Average.trials{f,1}(t,1) = mean(outdata.DLC.(sniplabel).(condition).(currentmeasure).(flds{x}).Peak.(wins{w}).trials{f,1}(t,:),'omitnan');
            if ~isnan(outdata.DLC.(sniplabel).(condition).(currentmeasure).(flds{x}).Peak.(wins{w}).MaxVal.trials{f,1}(t,1))
            outdata.DLC.(sniplabel).(condition).(currentmeasure).(flds{x}).Peak.(wins{w}).MaxTs.trials{f,1}(t,1) = outdata.timearray.(sniplabel).DLC.Peak.(wins{w}){f,1}(I);
            else
            outdata.DLC.(sniplabel).(condition).(currentmeasure).(flds{x}).Peak.(wins{w}).MaxTs.trials{f,1}(t,1)= NaN;
            end
            end 
            %get mean data
            outdata.DLC.(sniplabel).(condition).(currentmeasure).(flds{x}).Peak.(wins{w}).MaxVal.mean(f,1) = mean(outdata.DLC.(sniplabel).(condition).(currentmeasure).(flds{x}).Peak.(wins{w}).MaxVal.trials{f,1},'omitnan');
            outdata.DLC.(sniplabel).(condition).(currentmeasure).(flds{x}).Peak.(wins{w}).MaxVal.n(f,1) = sum(~isnan((outdata.DLC.(sniplabel).(condition).(currentmeasure).(flds{x}).Peak.(wins{w}).MaxVal.trials{f,1})));
            outdata.DLC.(sniplabel).(condition).(currentmeasure).(flds{x}).Peak.(wins{w}).MaxVal.stdev(f,1) = std(outdata.DLC.(sniplabel).(condition).(currentmeasure).(flds{x}).Peak.(wins{w}).MaxVal.trials{f,1},'omitnan');
            outdata.DLC.(sniplabel).(condition).(currentmeasure).(flds{x}).Peak.(wins{w}).MaxVal.sem(f,1)= outdata.DLC.(sniplabel).(condition).(currentmeasure).(flds{x}).Peak.(wins{w}).MaxVal.stdev(f,1)/sqrt(outdata.DLC.(sniplabel).(condition).(currentmeasure).(flds{x}).Peak.(wins{w}).MaxVal.n(f,1));
           
            outdata.DLC.(sniplabel).(condition).(currentmeasure).(flds{x}).Peak.(wins{w}).MaxTs.mean(f,1) = mean(outdata.DLC.(sniplabel).(condition).(currentmeasure).(flds{x}).Peak.(wins{w}).MaxTs.trials{f,1},'omitnan');
            outdata.DLC.(sniplabel).(condition).(currentmeasure).(flds{x}).Peak.(wins{w}).MaxTs.n(f,1) = sum(~isnan((outdata.DLC.(sniplabel).(condition).(currentmeasure).(flds{x}).Peak.(wins{w}).MaxTs.trials{f,1})));
            outdata.DLC.(sniplabel).(condition).(currentmeasure).(flds{x}).Peak.(wins{w}).MaxTs.stdev(f,1) = std(outdata.DLC.(sniplabel).(condition).(currentmeasure).(flds{x}).Peak.(wins{w}).MaxTs.trials{f,1},'omitnan');
            outdata.DLC.(sniplabel).(condition).(currentmeasure).(flds{x}).Peak.(wins{w}).MaxTs.sem(f,1)= outdata.DLC.(sniplabel).(condition).(currentmeasure).(flds{x}).Peak.(wins{w}).MaxTs.stdev(f,1)/sqrt(outdata.DLC.(sniplabel).(condition).(currentmeasure).(flds{x}).Peak.(wins{w}).MaxTs.n(f,1));
            
            outdata.DLC.(sniplabel).(condition).(currentmeasure).(flds{x}).Peak.(wins{w}).Average.mean(f,1) =mean(outdata.DLC.(sniplabel).(condition).(currentmeasure).(flds{x}).Peak.(wins{w}).Average.trials{f,1},'omitnan');
            outdata.DLC.(sniplabel).(condition).(currentmeasure).(flds{x}).Peak.(wins{w}).Average.n(f,1) = sum(~isnan((outdata.DLC.(sniplabel).(condition).(currentmeasure).(flds{x}).Peak.(wins{w}).Average.trials{f,1})));
            outdata.DLC.(sniplabel).(condition).(currentmeasure).(flds{x}).Peak.(wins{w}).Average.stdev(f,1) = std(outdata.DLC.(sniplabel).(condition).(currentmeasure).(flds{x}).Peak.(wins{w}).Average.trials{f,1},'omitnan');
            outdata.DLC.(sniplabel).(condition).(currentmeasure).(flds{x}).Peak.(wins{w}).Average.sem(f,1)= outdata.DLC.(sniplabel).(condition).(currentmeasure).(flds{x}).Peak.(wins{w}).Average.stdev(f,1)/sqrt(outdata.DLC.(sniplabel).(condition).(currentmeasure).(flds{x}).Peak.(wins{w}).Average.n(f,1));
    end
    end
    
    case 2
    flds = outdata.UserVals.DLCsetup.Subfields.(currentmeasure){1};
    for x = 1:length(flds)
    refr = outdata.UserVals.DLCsetup.Subfields.(currentmeasure){2}{x};
    for r = 1:length(refr)
    for w = 1:length(wins)
            for t = 1:length(outdata.DLC.(sniplabel).(condition).(currentmeasure).(flds{x}).(refr{r}).Peak.(wins{w}).trials{f,1}(:,1))
            [outdata.DLC.(sniplabel).(condition).(currentmeasure).(flds{x}).(refr{r}).Peak.(wins{w}).MaxVal.trials{f,1}(t,1),I] = max(outdata.DLC.(sniplabel).(condition).(currentmeasure).(flds{x}).(refr{r}).Peak.(wins{w}).trials{f,1}(t,:));
            outdata.DLC.(sniplabel).(condition).(currentmeasure).(flds{x}).(refr{r}).Peak.(wins{w}).Average.trials{f,1}(t,1) = mean(outdata.DLC.(sniplabel).(condition).(currentmeasure).(flds{x}).(refr{r}).Peak.(wins{w}).trials{f,1}(t,:),'omitnan');
            if ~isnan(outdata.DLC.(sniplabel).(condition).(currentmeasure).(flds{x}).(refr{r}).Peak.(wins{w}).MaxVal.trials{f,1}(t,1))
            outdata.DLC.(sniplabel).(condition).(currentmeasure).(flds{x}).(refr{r}).Peak.(wins{w}).MaxTs.trials{f,1}(t,1) = outdata.timearray.(sniplabel).DLC.Peak.(wins{w}){f,1}(I);
            else
            outdata.DLC.(sniplabel).(condition).(currentmeasure).(flds{x}).(refr{r}).Peak.(wins{w}).MaxTs.trials{f,1}(t,1)= NaN;
            end
            end 
            %get mean data
            outdata.DLC.(sniplabel).(condition).(currentmeasure).(flds{x}).(refr{r}).Peak.(wins{w}).MaxVal.mean(f,1) = mean(outdata.DLC.(sniplabel).(condition).(currentmeasure).(flds{x}).(refr{r}).Peak.(wins{w}).MaxVal.trials{f,1},'omitnan');
            outdata.DLC.(sniplabel).(condition).(currentmeasure).(flds{x}).(refr{r}).Peak.(wins{w}).MaxVal.n(f,1) = sum(~isnan((outdata.DLC.(sniplabel).(condition).(currentmeasure).(flds{x}).(refr{r}).Peak.(wins{w}).MaxVal.trials{f,1})));
            outdata.DLC.(sniplabel).(condition).(currentmeasure).(flds{x}).(refr{r}).Peak.(wins{w}).MaxVal.stdev(f,1) = std(outdata.DLC.(sniplabel).(condition).(currentmeasure).(flds{x}).(refr{r}).Peak.(wins{w}).MaxVal.trials{f,1},'omitnan');
            outdata.DLC.(sniplabel).(condition).(currentmeasure).(flds{x}).(refr{r}).Peak.(wins{w}).MaxVal.sem(f,1)= outdata.DLC.(sniplabel).(condition).(currentmeasure).(flds{x}).(refr{r}).Peak.(wins{w}).MaxVal.stdev(f,1)/sqrt(outdata.DLC.(sniplabel).(condition).(currentmeasure).(flds{x}).(refr{r}).Peak.(wins{w}).MaxVal.n(f,1));
           
            outdata.DLC.(sniplabel).(condition).(currentmeasure).(flds{x}).(refr{r}).Peak.(wins{w}).MaxTs.mean(f,1) = mean(outdata.DLC.(sniplabel).(condition).(currentmeasure).(flds{x}).(refr{r}).Peak.(wins{w}).MaxTs.trials{f,1},'omitnan');
            outdata.DLC.(sniplabel).(condition).(currentmeasure).(flds{x}).(refr{r}).Peak.(wins{w}).MaxTs.n(f,1) = sum(~isnan((outdata.DLC.(sniplabel).(condition).(currentmeasure).(flds{x}).(refr{r}).Peak.(wins{w}).MaxTs.trials{f,1})));
            outdata.DLC.(sniplabel).(condition).(currentmeasure).(flds{x}).(refr{r}).Peak.(wins{w}).MaxTs.stdev(f,1) = std(outdata.DLC.(sniplabel).(condition).(currentmeasure).(flds{x}).(refr{r}).Peak.(wins{w}).MaxTs.trials{f,1},'omitnan');
            outdata.DLC.(sniplabel).(condition).(currentmeasure).(flds{x}).(refr{r}).Peak.(wins{w}).MaxTs.sem(f,1)= outdata.DLC.(sniplabel).(condition).(currentmeasure).(flds{x}).(refr{r}).Peak.(wins{w}).MaxTs.stdev(f,1)/sqrt(outdata.DLC.(sniplabel).(condition).(currentmeasure).(flds{x}).(refr{r}).Peak.(wins{w}).MaxTs.n(f,1));
            
            outdata.DLC.(sniplabel).(condition).(currentmeasure).(flds{x}).(refr{r}).Peak.(wins{w}).Average.mean(f,1) =mean(outdata.DLC.(sniplabel).(condition).(currentmeasure).(flds{x}).(refr{r}).Peak.(wins{w}).Average.trials{f,1},'omitnan');
            outdata.DLC.(sniplabel).(condition).(currentmeasure).(flds{x}).(refr{r}).Peak.(wins{w}).Average.n(f,1) = sum(~isnan((outdata.DLC.(sniplabel).(condition).(currentmeasure).(flds{x}).(refr{r}).Peak.(wins{w}).Average.trials{f,1})));
            outdata.DLC.(sniplabel).(condition).(currentmeasure).(flds{x}).(refr{r}).Peak.(wins{w}).Average.stdev(f,1) = std(outdata.DLC.(sniplabel).(condition).(currentmeasure).(flds{x}).(refr{r}).Peak.(wins{w}).Average.trials{f,1},'omitnan');
            outdata.DLC.(sniplabel).(condition).(currentmeasure).(flds{x}).(refr{r}).Peak.(wins{w}).Average.sem(f,1)= outdata.DLC.(sniplabel).(condition).(currentmeasure).(flds{x}).(refr{r}).Peak.(wins{w}).Average.stdev(f,1)/sqrt(outdata.DLC.(sniplabel).(condition).(currentmeasure).(flds{x}).(refr{r}).Peak.(wins{w}).Average.n(f,1));
    end
end
end
end
end
end

