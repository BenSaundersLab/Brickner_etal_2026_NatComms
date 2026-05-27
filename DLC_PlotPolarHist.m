function[] = DLC_PlotPolarHist(outdata,figdir)
figure('visible','off')
for r = 1:length(outdata.rawdata.DLC)
subplot(1,length(outdata.rawdata.DLC),r)
data = outdata.DLC.Trial.StimTrial.Angle.BottomLight.ItoNT.degrees_360.Peak.cuedur.trials{r,1};
if outdata.rawdata.DLC{r,1}.paddata
indx = 1:2:length(data(1,:));
data = outdata.DLC.Trial.StimTrial.Angle.BottomLight.ItoNT.degrees_360.Peak.cuedur.trials{r,1}(:,indx);
end   
getindx = ~isnan(data);
polarhistogram(data(getindx),12,'Normalization','probability','BinEdges',[0:pi/6:2*pi])
pax = gca;
pax.RLim = [0 0.1];
%polarhistogram(data,12,'BinEdges',[0:pi/6:2*pi])
end

savename = strcat(figdir,'CueDur_prob.pdf');
gcf.Renderer='Painters'; %makes sure figure can be manipulated in illustrator
print(savename,'-dpdf','-bestfit');
clear r
close all

figure('visible','off')
for r = 1:length(outdata.rawdata.DLC)
subplot(1,length(outdata.rawdata.DLC),r)
data = outdata.DLC.Trial.StimTrial.Angle.BottomLight.ItoNT.degrees_360.Peak.cue2s.trials{r,1};
if outdata.rawdata.DLC{r,1}.paddata
indx = 1:2:length(data(1,:));
data = outdata.DLC.Trial.StimTrial.Angle.BottomLight.ItoNT.degrees_360.Peak.cue2s.trials{r,1}(:,indx);
end   
getindx = ~isnan(data);
polarhistogram(data(getindx),12,'Normalization','probability','BinEdges',[0:pi/6:2*pi])
pax = gca;
pax.RLim = [0 0.1];
%polarhistogram(data,12,'BinEdges',[0:pi/6:2*pi])
end

savename = strcat(figdir,'Cue2s_prob.pdf');
gcf.Renderer='Painters'; %makes sure figure can be manipulated in illustrator
print(savename,'-dpdf','-bestfit');
close all
end
