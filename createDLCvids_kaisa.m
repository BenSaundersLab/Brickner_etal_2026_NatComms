function []=createDLCvids_kaisa(f,outdata,datatype,conditions,DLC, maxwinlabels,maxwintimepoints,savepath,googledrive,personalpath)

vidpath =  outdata.videodata.videofile{f};
if nargin > 8
if googledrive
    vidpath = googleconvert_fname(vidpath,personalpath)
end
end
fsep = filesep;
plotmeasures = false;
plotbps = false;
plotenviron = false;
plotvectors = false;
plotLEDs = false;

paddata = outdata.rawdata.DLC{f,1}.paddata;
if paddata
padfq =  outdata.rawdata.DLC{f,1}.FPS/outdata.videodata.vidFPS{f,1};
end

%Plot colors
 environcolor = [0.6350 0.0780 0.1840];
 bpscolor = [0.9290 0.6940 0.1250];
 vectorcolor(1,:) = [0 0.4470 0.7410];
 vectorcolor(2,:) = [0.3010 0.7450 0.9330];

if ~isempty(DLC.measures)
    plotmeasures = true;
    textspacer = (10:630/length(DLC.measures):630);
end

if ~isempty(DLC.bps)
    plotbps = true;
end

if ~isempty(DLC.LEDs)
    plotLEDs = true;
end

if ~isempty(DLC.environfeats)
    plotenviron = true;
end

if ~isempty(DLC.vectorcoords)
    plotvectors = true;
end

if ~exist(vidpath,'file')
    disp ('Video file does not exist or cannot be found');
end

%% Get data snips and frame indx for each condition, window and measure
for c = 1:length(conditions)
if isfield(outdata.DLC.(datatype),(conditions{c}))
    if isfield(outdata.DLC.(datatype).(conditions{c}),'frameindx')  %if there are trials for this condition create vids and plot
    if ~isempty(outdata.DLC.(datatype).(conditions{c}).frameindx{f,1})
        viddata.(conditions{c}).frameindx{f,1} = outdata.DLC.(datatype).(conditions{c}).frameindx{f,1};
        viddata.(conditions{c}).timearray{f,1} = outdata.DLC.(datatype).time{f,1};   
    for w = 1:length(maxwinlabels)
        wintimes = maxwintimepoints{w};
        winstart = 1; %default winstart is beginning
        winend = length(viddata.(conditions{c}).frameindx{f,1}); %default winend is end
            if ~isnan(wintimes(1)) %replace start if user specified
            winstart = find(viddata.(conditions{c}).timearray{f,1} == wintimes(1));
            end
            if ~isnan(wintimes(2))
            winend = find(viddata.(conditions{c}).timearray{f,1} == wintimes(2));
            end
        viddata.(conditions{c}).(maxwinlabels{w}).timearray = viddata.(conditions{c}).timearray{f,1}(winstart:winend);
        viddata.(conditions{c}).(maxwinlabels{w}).framestograb = outdata.DLC.(datatype).(conditions{c}).frameindx{f,1}(:,winstart:winend);
        %get xy coordinates for environfeats
        if plotenviron
            for e = 1:length(DLC.environfeats)
                if f <= length(outdata.DLC.(datatype).(conditions{c}).fixedpoints.(DLC.environfeats{e}))
                if ~isempty(outdata.DLC.(datatype).(conditions{c}).fixedpoints.(DLC.environfeats{e}){f,1})     
                    viddata.(conditions{c}).(maxwinlabels{w}).environ.(DLC.environfeats{e}) = outdata.DLC.(datatype).(conditions{c}).fixedpoints.(DLC.environfeats{e}){f,1}{1};
                end 
                end
            end
        else
            if plotvectors %if plot vectors is selected then extract cue location for plotting ** need to fix this at some point so you can choose reference but default is to cue for the moment
            DLC.environfeats = {'LeftMag'};
                for e = 1:length(DLC.environfeats)
                viddata.(conditions{c}).(maxwinlabels{w}).environ.(DLC.environfeats{e}) = outdata.DLC.(datatype).(conditions{c}).fixedpoints.(DLC.environfeats{e}){f,1}{1};
                end 
            end               
        end
        %get xy coordinates for bodparts
        if plotbps
            for b = 1: length(DLC.bps)
                for i = 1:size(outdata.DLC.(datatype).(conditions{c}).bodyparts.(DLC.bps{b}){1},1)
                    if ~isempty(outdata.DLC.(datatype).(conditions{c}).bodyparts.(DLC.bps{b}){f,1}{i})
                    viddata.(conditions{c}).(maxwinlabels{w}).bps.(DLC.bps{b}){i} = outdata.DLC.(datatype).(conditions{c}).bodyparts.(DLC.bps{b}){f,1}{i}(winstart:winend,:);
                    else
                    viddata.(conditions{c}).(maxwinlabels{w}).bps.(DLC.bps{b}){i} = [];
                    end
                end
            end 
        end
        
        %get xy coordinates for LEDs
        if plotLEDs
            for b = 1: length(DLC.LEDs)
                for i = 1:size(outdata.DLC.(datatype).(conditions{c}).LED.(DLC.LEDs{b}){1},1)
                if ~isempty(outdata.DLC.(datatype).(conditions{c}).LED.(DLC.LEDs{b}){f,1}{i})
                viddata.(conditions{c}).(maxwinlabels{w}).LEDs.(DLC.LEDs{b}){i} =outdata.DLC.(datatype).(conditions{c}).LED.(DLC.LEDs{b}){f,1}{i}(winstart:winend,:);
                else
                viddata.(conditions{c}).(maxwinlabels{w}).LEDs.(DLC.LEDs{b}){i}= [];
                end
                end
            end 
        end
        
        %get vector coordinates
        
        if plotvectors
            for b = 1: length(DLC.vectorcoords)
                for i = 1:size(outdata.DLC.(datatype).(conditions{c}).VectorCoord.trials.(DLC.vectorcoords{b}).headxy{f},1)
                if ~isempty(outdata.DLC.(datatype).(conditions{c}).VectorCoord.trials.(DLC.vectorcoords{b}).headxy{f,1}{i}) 
                viddata.(conditions{c}).(maxwinlabels{w}).VectorCoord.(DLC.vectorcoords{b}).head{i} =outdata.DLC.(datatype).(conditions{c}).VectorCoord.trials.(DLC.vectorcoords{b}).headxy{f,1}{i}(winstart:winend,:);
                viddata.(conditions{c}).(maxwinlabels{w}).VectorCoord.(DLC.vectorcoords{b}).tail{i} =outdata.DLC.(datatype).(conditions{c}).VectorCoord.trials.(DLC.vectorcoords{b}).tailxy{f,1}{i}(winstart:winend,:);
                viddata.(conditions{c}).(maxwinlabels{w}).AngleVectorCoord.LeftMag.(DLC.vectorcoords{b}).head{i} =outdata.DLC.(datatype).(conditions{c}).AngleVectorCoord.LeftMag.(DLC.vectorcoords{b}).trials{f,1}.headxy{i}(winstart:winend,:);
                viddata.(conditions{c}).(maxwinlabels{w}).AngleVectorCoord.LeftMag.(DLC.vectorcoords{b}).tail{i} =outdata.DLC.(datatype).(conditions{c}).AngleVectorCoord.LeftMag.(DLC.vectorcoords{b}).trials{f,1}.headxy{i}(winstart:winend,:);
                    
                else
                viddata.(conditions{c}).(maxwinlabels{w}).VectorCoord.(DLC.vectorcoords{b}).head{i} = [];
                viddata.(conditions{c}).(maxwinlabels{w}).VectorCoord.(DLC.vectorcoords{b}).tail{i} = [];
                viddata.(conditions{c}).(maxwinlabels{w}).AngleVectorCoord.LeftMag.(DLC.vectorcoords{b}).head{i} = [];
                viddata.(conditions{c}).(maxwinlabels{w}).AngleVectorCoord.LeftMag.(DLC.vectorcoords{b}).tail{i} = [];
                end
                end 
            end
        end

        
        %get measures
        if plotmeasures
            for m = 1: length(DLC.measures) %need to add in subfields here
            flds = DLC.subfields.(DLC.measures{m}){1};
            numsubfields = length(DLC.subfields.(DLC.measures{m}));
            for x = 1:length(flds)
            switch numsubfields
                case 1      
                viddata.(conditions{c}).(maxwinlabels{w}).measures.(DLC.measures{m}).(flds{x}) = outdata.DLC.(datatype).(conditions{c}).(DLC.measures{m}).(flds{x}).trials{f,1}(:,winstart:winend);
                case 2
                    refr = DLC.subfields.(DLC.measures{m}){2};
                    for r = 1:length(refr)
                    viddata.(conditions{c}).(maxwinlabels{w}).measures.(DLC.measures{m}).(flds{x}).(refr{r}{1}) = outdata.DLC.(datatype).(conditions{c}).(DLC.measures{m}).(flds{x}).(refr{r}{1}).trials{f,1}(:,winstart:winend);
                    end
                case 3
                    refr = DLC.subfields.(DLC.measures{m}){1,2};
                    for r = 1:length(refr)
                    degs = DLC.subfields.(DLC.measures{m}){1,3}{1,r}{1,1};
                    for d = 1:length(degs)
                    viddata.(conditions{c}).(maxwinlabels{w}).measures.(DLC.measures{m}).(flds{x}).(refr{1,1}{r}).(degs{d}) = outdata.DLC.(datatype).(conditions{c}).(DLC.measures{m}).(flds{x}).(refr{1,1}{r}).(degs{d}).trials{f,1}(:,winstart:winend);
                    end
                    end  
            end
            end
            end %measures loop
        end
        
        %get orientation to cue
        if isfield(DLC,'orient')
        if DLC.orient      
        viddata.(conditions{c}).(maxwinlabels{w}).Orient = outdata.DLC.(datatype).(conditions{c}).Orient.(DLC.orientenvironfeat).(DLC.orientbodypart).trials{f,1}(:,winstart:winend);    
        end
        end

        if isfield(DLC,'locobouts')
        if DLC.locobouts
        viddata.(conditions{c}).(maxwinlabels{w}).locobouts = outdata.DLC.(datatype).(conditions{c}).Locomotion{f,1}(:,winstart:winend);    
        
        end
        end
        
        if isfield(DLC,'approach')
        if DLC.approach
        viddata.(conditions{c}).(maxwinlabels{w}).approach = outdata.DLC.(datatype).(conditions{c}).Approach.(DLC.approachenvironfeat).(DLC.approachbodypart){f,1}(:,winstart:winend);    
        end
        end
        
        if isfield(DLC,'freezebouts')
        if DLC.freezebouts
        viddata.(conditions{c}).(maxwinlabels{w}).freezebouts = outdata.DLC.(datatype).(conditions{c}).Freeze{f,1}(:,winstart:winend);    
        end
        end
    end %end window loop
    end
    end
end
end %end condition loop

%% initialize video frames
v = VideoReader(vidpath); 
s = struct('cdata',zeros(v.Height,v.Width,3,'uint8'),...
    'colormap',[]);
hFig = figure('MenuBar','none',...
    'Units','pixels',...
    'Position',[100 100 v.Width v.Height]);
hAx = axes('Parent',hFig,...
    'Units','pixels',...
    'Position',[0 0 v.Width v.Height],...
    'NextPlot','add',...
    'Visible','off',...
    'XTick',[],...
    'YTick',[],...
    'YDir','reverse');
hIm = image(uint8(zeros(v.Height,v.Width,3)),...
    'Parent',hAx);

%% create vids
for c = 1:length(conditions)
if isfield(viddata,(conditions{c}))%if there are trials for this condition create vids and plot  
    nevents = length(outdata.perievent.(datatype).(conditions{c}).trialn{f,1});
for w = 1:length(maxwinlabels)
for t = 1:nevents
    %for t = 1

    if sum(~isnan(viddata.(conditions{c}).frameindx{f,1}(t,:))) > 1
    trialnum = outdata.perievent.(datatype).(conditions{c}).trialn{f,1}(t);
    savedir = strcat(savepath,fsep,(conditions{c}),fsep,(maxwinlabels{w}),fsep,outdata.metadata.subjID{1,f},'_',num2str(f),fsep);
    if ~exist(savedir, 'dir')
       mkdir(savedir);
    end
outputName = strcat(savedir,'t',num2str(trialnum),'.mp4');
vidObj = VideoWriter(outputName,'MPEG-4');
vidObj.FrameRate = v.FrameRate;
open(vidObj);

framecount = 1;
if ~paddata
for img = viddata.(conditions{c}).(maxwinlabels{w}).framestograb(t,1):viddata.(conditions{c}).(maxwinlabels{w}).framestograb(t,end)
    b = read(v, img);
    hIm.CData = b;
    image(b);
    hold on
    %plot environ features
    if plotenviron
        for e = 1:length(DLC.environfeats)
            if isfield(viddata.(conditions{c}).(maxwinlabels{w}).environ,(DLC.environfeats{e}))
         xval = viddata.(conditions{c}).(maxwinlabels{w}).environ.(DLC.environfeats{e})(1);
         yval = viddata.(conditions{c}).(maxwinlabels{w}).environ.(DLC.environfeats{e})(2);
         plot(xval,yval,'Marker','o','MarkerSize',4,'MarkerFaceColor',environcolor,'MarkerEdgeColor',environcolor);
         clear xval yval
            end    
        end
    end
    
    %plot bodyparts
    if plotbps
        for x = 1:length(DLC.bps)
            xval = viddata.(conditions{c}).(maxwinlabels{w}).bps.(DLC.bps{x}){t}(framecount,1);
            yval = viddata.(conditions{c}).(maxwinlabels{w}).bps.(DLC.bps{x}){t}(framecount,2);
            plot(xval,yval,'Marker','o','MarkerSize',4,'MarkerFaceColor',bpscolor,'MarkerEdgeColor',bpscolor);   
            clear xval yval
        end
    end
    
    %plot LEDs
    if plotLEDs
        for x = 1:length(DLC.LEDs)
            xval = viddata.(conditions{c}).(maxwinlabels{w}).LEDs.(DLC.LEDs{x}){t}(framecount,1);
            yval = viddata.(conditions{c}).(maxwinlabels{w}).LEDs.(DLC.LEDs{x}){t}(framecount,2);
            plot(xval,yval,'Marker','o','MarkerSize',4,'MarkerFaceColor',bpscolor,'MarkerEdgeColor',bpscolor);   
            clear xval yval
        end
    end
    
    %plot vectors
    if plotvectors
        for x = 1:length(DLC.vectorcoords) %need to fix the reference point to plot dynamically but here is fixed to LeftMag
            xval = [viddata.(conditions{c}).(maxwinlabels{w}).VectorCoord.(DLC.vectorcoords{x}).head{t}(framecount,1),viddata.(conditions{c}).(maxwinlabels{w}).VectorCoord.(DLC.vectorcoords{x}).tail{t}(framecount,1)];
            yval = [viddata.(conditions{c}).(maxwinlabels{w}).VectorCoord.(DLC.vectorcoords{x}).head{t}(framecount,2),viddata.(conditions{c}).(maxwinlabels{w}).VectorCoord.(DLC.vectorcoords{x}).tail{t}(framecount,2)];
            xval2 = [viddata.(conditions{c}).(maxwinlabels{w}).environ.LeftMag(1),viddata.(conditions{c}).(maxwinlabels{w}).VectorCoord.(DLC.vectorcoords{x}).tail{t}(framecount,1)];
            yval2 = [viddata.(conditions{c}).(maxwinlabels{w}).environ.LeftMag(2),viddata.(conditions{c}).(maxwinlabels{w}).VectorCoord.(DLC.vectorcoords{x}).tail{t}(framecount,2)];
            plot(xval,yval,'Linewidth',2,'Color',vectorcolor(x,:) );
            plot(xval2,yval2,'Linewidth',2,'Color',vectorcolor(x,:) );
            
            xval = [viddata.(conditions{c}).(maxwinlabels{w}).AngleVectorCoord.LeftMag.(DLC.vectorcoords{x}).head{t}(framecount,1),viddata.(conditions{c}).(maxwinlabels{w}).AngleVectorCoord.LeftMag.(DLC.vectorcoords{x}).tail{t}(framecount,1)];
            yval = [viddata.(conditions{c}).(maxwinlabels{w}).AngleVectorCoord.LeftMag.(DLC.vectorcoords{x}).head{t}(framecount,2),viddata.(conditions{c}).(maxwinlabels{w}).AngleVectorCoord.LeftMag.(DLC.vectorcoords{x}).tail{t}(framecount,2)];
            xval2 = [viddata.(conditions{c}).(maxwinlabels{w}).environ.LeftMag(1),viddata.(conditions{c}).(maxwinlabels{w}).AngleVectorCoord.LeftMag.(DLC.vectorcoords{x}).tail{t}(framecount,1)];
            yval2 = [viddata.(conditions{c}).(maxwinlabels{w}).environ.LeftMag(2),viddata.(conditions{c}).(maxwinlabels{w}).AngleVectorCoord.LeftMag.(DLC.vectorcoords{x}).tail{t}(framecount,2)];
            plot(xval,yval,'Linewidth',2,'Color',vectorcolor(x,:) );
            plot(xval2,yval2,'Linewidth',2,'Color',vectorcolor(x,:) );
            
            
        end
    end
    
    %plot measures
    if plotmeasures
    for m = 1: length(DLC.measures)
        %figure out how many measures should be plotted total to arrange
        %spacing for plots
            flds = DLC.subfields.(DLC.measures{m}){1};
            numsubfields = length(DLC.subfields.(DLC.measures{m}));
            numlabels = length(DLC.subfields.(DLC.measures{m}){1});
            if numsubfields > 1
            temp = size(DLC.subfields.(DLC.measures{m}){numsubfields});
            temp2= temp(1)*temp(2);
            numlabels = numlabels*temp2;
            end
            if numlabels > 1
            maxycoord = 10+20*(numlabels-1);
            stepsize = (maxycoord-10)/(numlabels-1);
            verttxtspacer = (10:stepsize:maxycoord);
            else
            verttxtspacer = 10;
            end
            clear stepsiz maxycoord temp temp2 numlabels
     
     vertindx = 1;
     for x = 1:length(flds)        
     switch numsubfields
         case 1
         DLCdata = round(viddata.(conditions{c}).(maxwinlabels{w}).measures.(DLC.measures{m}).(flds{x})(t,framecount),2);
         txt = num2str(DLCdata, '%.2f');
         if length(flds) >1
            txt = strcat(txt,{' '},(DLC.labels{m}),'-',(flds{x})); 
         else
             txt = strcat(txt,{' '},(DLC.labels{m}));
         end
         txt = txt{1};
         text((textspacer(m)),verttxtspacer(vertindx),txt,'Fontsize',10,'FontWeight','bold','Color',bpscolor); %change txt location to be evenly across bottom with subcategories stacked on top of each other
         vertindx = vertindx+1;
         case 2
         refr = DLC.subfields.(DLC.measures{m}){2}{x};
         for r = 1:length(refr)
         DLCdata = round(viddata.(conditions{c}).(maxwinlabels{w}).measures.(DLC.measures{m}).(flds{x}).(refr{r})(t,framecount),2);
         txt = num2str(DLCdata, '%.2f');
         if length(flds) >1
         txt = strcat(txt,{' '},(DLC.labels{m}),{' '},(flds{x}),'-',(refr{r})); 
         else
         txt = strcat(txt,{' '},(DLC.labels{m}),{' '},(refr{r})); 
         end
         txt = txt{1};
         text((textspacer(m)),verttxtspacer(vertindx),txt,'Fontsize',10,'FontWeight','bold','Color',bpscolor); %change txt location to be evenly across bottom with subcategories stacked on top of each other
         vertindx = vertindx+1;
         end
         case 3
            refr = DLC.subfields.(DLC.measures{m}){2}(x,:);
            for r = 1:length(refr)
            degs = DLC.subfields.(DLC.measures{m}){3}{r};
            for d = 1:length(degs)
            DLCdata = round(viddata.(conditions{c}).(maxwinlabels{w}).measures.(DLC.measures{m}).(flds{x}).(refr{1}{r}).(degs{r}{d})(t,framecount),2);
            txt = num2str(DLCdata, '%.2f');
            if length(flds) >1
            txt = strcat(txt,{' '},(DLC.labels{m}),{' '},(flds{x}),'-',(refr{r})); 
            else
            txt = strcat(txt,{' '},(DLC.labels{m}),{' '},(refr{r})); 
            end
         txt = txt{1};
         text((textspacer(m)),verttxtspacer(vertindx),txt,'Fontsize',10,'FontWeight','bold','Color',bpscolor); %change txt location to be evenly across bottom with subcategories stacked on top of each other
         vertindx = vertindx+1;
            end
            end

     end
     end
     end %measures loop   
    end
     
    %orientation
     if isfield(DLC,'orient')
     if DLC.orient
    DLCdata = viddata.(conditions{c}).(maxwinlabels{w}).Orient(t,framecount);
    if ~isnan(DLCdata)
        if DLCdata 
        txt = 'Orient';
        text(10,380,txt,'Fontsize',14,'FontWeight','bold','Color',[[0.149019607843137,0.850980392156863,1]]); 
        end
    end
     end
     end
    
    if isfield(DLC,'approach')
     if DLC.approach
     DLCdata = viddata.(conditions{c}).(maxwinlabels{w}).approach(t,framecount);
     if ~isnan(DLCdata)
        if DLCdata 
        txt = 'approach';
        text(10,400,txt,'Fontsize',14,'FontWeight','bold','Color',[[0.149019607843137,0.850980392156863,1]]); 
        end
     end
     end
     end
    
    
     if isfield(DLC,'locobouts')
     if DLC.locobouts
     DLCdata = viddata.(conditions{c}).(maxwinlabels{w}).locobouts(t,framecount);
     if ~isnan(DLCdata)
        if DLCdata 
        txt = 'move';
        text(10,420,txt,'Fontsize',14,'FontWeight','bold','Color',[[0.149019607843137,0.850980392156863,1]]); 
        end
     end
     end
     end
     
     if isfield(DLC,'freezebouts')
     if DLC.freezebouts
     DLCdata = viddata.(conditions{c}).(maxwinlabels{w}).freezebouts(t,framecount); 
     if ~isnan(DLCdata)
        if DLCdata 
        txt = 'freeze';
        text(10,440,txt,'Fontsize',14,'FontWeight','bold','Color',[0.7725    0.2275    1.0000]); 
        end
     end
     end
     end
    s(framecount) = getframe(hAx);
    framecount = framecount+1;
end
% vOut = VideoWriter(savevidas,'MPEG-4');
% vOut.FrameRate = v.FrameRate;
% open(vOut)
for k = 1:numel(s)
    writeVideo(vidObj,s(k))
end
close(vidObj)

else
    dlcindx = 1;
    for img = viddata.(conditions{c}).(maxwinlabels{w}).framestograb(t,1):1:viddata.(conditions{c}).(maxwinlabels{w}).framestograb(t,end)
    b = read(v, img);
    hIm.CData = b;
    image(b);
    hold on
    %plot environ features
    if plotenviron
        for e = 1:length(DLC.environfeats)
         xval = viddata.(conditions{c}).(maxwinlabels{w}).environ.(DLC.environfeats{e})(dlcindx,1);
         yval = viddata.(conditions{c}).(maxwinlabels{w}).environ.(DLC.environfeats{e})(dlcindx,2);
         plot(xval,yval,'Marker','o','MarkerSize',4,'MarkerFaceColor',environcolor,'MarkerEdgeColor',environcolor);
        end     
    end
    
    %plot bodyparts
    if plotbps
        for x = 1:length(DLC.bps)
            xval = viddata.(conditions{c}).(maxwinlabels{w}).bps.(DLC.bps{x}){t}(dlcindx,1);
            yval = viddata.(conditions{c}).(maxwinlabels{w}).bps.(DLC.bps{x}){t}(dlcindx,2);
            plot(xval,yval,'Marker','o','MarkerSize',4,'MarkerFaceColor',bpscolor,'MarkerEdgeColor',bpscolor);   
            clear xval yval
        end
    end
    
    %plot LEDs
    if plotLEDs
        for x = 1:length(DLC.LEDs)
            xval = viddata.(conditions{c}).(maxwinlabels{w}).LEDs.(DLC.LEDs{x}){t}(dlcindx,1);
            yval = viddata.(conditions{c}).(maxwinlabels{w}).LEDs.(DLC.LEDs{x}){t}(dlcindx,2);
            plot(xval,yval,'Marker','o','MarkerSize',4,'MarkerFaceColor',bpscolor,'MarkerEdgeColor',bpscolor);   
            clear xval yval
        end
    end
    
    %plot vectors
    if plotvectors
        for x = 1:length(DLC.vectorcoords) %need to fix the reference point to plot dynamically but here is fixed to LeftMag
            xval = [viddata.(conditions{c}).(maxwinlabels{w}).VectorCoord.(DLC.vectorcoords{x}).head{t}(dlcindx,1),viddata.(conditions{c}).(maxwinlabels{w}).VectorCoord.(DLC.vectorcoords{x}).tail{t}(dlcindx,1)];
            yval = [viddata.(conditions{c}).(maxwinlabels{w}).VectorCoord.(DLC.vectorcoords{x}).head{t}(dlcindx,2),viddata.(conditions{c}).(maxwinlabels{w}).VectorCoord.(DLC.vectorcoords{x}).tail{t}(dlcindx,2)];
            xval2 = [viddata.(conditions{c}).(maxwinlabels{w}).environ.LeftMag(1),viddata.(conditions{c}).(maxwinlabels{w}).VectorCoord.(DLC.vectorcoords{x}).tail{t}(dlcindx,1)];
            yval2 = [viddata.(conditions{c}).(maxwinlabels{w}).environ.LeftMag(2),viddata.(conditions{c}).(maxwinlabels{w}).VectorCoord.(DLC.vectorcoords{x}).tail{t}(dlcindx,2)];
            plot(xval,yval,'Linewidth',2,'Color',vectorcolor(x,:) );
            plot(xval2,yval2,'Linewidth',2,'Color',vectorcolor(x,:) );
            
            xval = [viddata.(conditions{c}).(maxwinlabels{w}).AngleVectorCoord.LeftMag.(DLC.vectorcoords{x}).head{t}(framecount,1),viddata.(conditions{c}).(maxwinlabels{w}).AngleVectorCoord.LeftMag.(DLC.vectorcoords{x}).tail{t}(framecount,1)];
            yval = [viddata.(conditions{c}).(maxwinlabels{w}).AngleVectorCoord.LeftMag.(DLC.vectorcoords{x}).head{t}(framecount,2),viddata.(conditions{c}).(maxwinlabels{w}).AngleVectorCoord.LeftMag.(DLC.vectorcoords{x}).tail{t}(framecount,2)];
            xval2 = [viddata.(conditions{c}).(maxwinlabels{w}).environ.LeftMag(1),viddata.(conditions{c}).(maxwinlabels{w}).AngleVectorCoord.LeftMag.(DLC.vectorcoords{x}).tail{t}(framecount,1)];
            yval2 = [viddata.(conditions{c}).(maxwinlabels{w}).environ.LeftMag(2),viddata.(conditions{c}).(maxwinlabels{w}).AngleVectorCoord.LeftMag.(DLC.vectorcoords{x}).tail{t}(framecount,2)];
            plot(xval,yval,'Linewidth',2,'Color',vectorcolor(x,:) );
            plot(xval2,yval2,'Linewidth',2,'Color',vectorcolor(x,:) );
            
        end
    end
    
    %plot measures
    if plotmeasures
    for m = 1: length(DLC.measures)
        %figure out how many measures should be plotted total to arrange
        %spacing for plots
            flds = DLC.subfields.(DLC.measures{m}){1};
            numsubfields = length(DLC.subfields.(DLC.measures{m}));
            numlabels = length(DLC.subfields.(DLC.measures{m}){1});
            if numsubfields > 1
            temp = size(DLC.subfields.(DLC.measures{m}){numsubfields});
            temp2= temp(1)*temp(2);
            numlabels = numlabels*temp2;
            end
            if numlabels > 1
            maxycoord = 10+20*(numlabels-1);
            stepsize = (maxycoord-10)/(numlabels-1);
            verttxtspacer = (10:stepsize:maxycoord);
            else
            verttxtspacer = 10;
            end
            clear stepsiz maxycoord temp temp2 numlabels
     
     vertindx = 1;
     for x = 1:length(flds)        
     switch numsubfields
         case 1
         DLCdata = round(viddata.(conditions{c}).(maxwinlabels{w}).measures.(DLC.measures{m}).(flds{x})(t,dlcindx),2);
         txt = num2str(DLCdata, '%.2f');
         if length(flds) >1
            txt = strcat(txt,{' '},(DLC.labels{m}),'-',(flds{x})); 
         else
             txt = strcat(txt,{' '},(DLC.labels{m}));
         end
         txt = txt{1};
         text((textspacer(m)),verttxtspacer(vertindx),txt,'Fontsize',10,'FontWeight','bold','Color',bpscolor); %change txt location to be evenly across bottom with subcategories stacked on top of each other
         vertindx = vertindx+1;
         case 2
         refr = DLC.subfields.(DLC.measures{m}){2}{x};
         for r = 1:length(refr)
         DLCdata = round(viddata.(conditions{c}).(maxwinlabels{w}).measures.(DLC.measures{m}).(flds{x}).(refr{r})(t,dlcindx),2);
         txt = num2str(DLCdata, '%.2f');
         if length(flds) >1
         txt = strcat(txt,{' '},(DLC.labels{m}),{' '},(flds{x}),'-',(refr{r})); 
         else
         txt = strcat(txt,{' '},(DLC.labels{m}),{' '},(refr{r})); 
         end
         txt = txt{1};
         text((textspacer(m)),verttxtspacer(vertindx),txt,'Fontsize',10,'FontWeight','bold','Color',bpscolor); %change txt location to be evenly across bottom with subcategories stacked on top of each other
         vertindx = vertindx+1;
         end
         case 3
            refr = DLC.subfields.(DLC.measures{m}){2}(x,:);
            for r = 1:length(refr)
            degs = DLC.subfields.(DLC.measures{m}){3}{r};
            for d = 1:length(degs)
            DLCdata = round(viddata.(conditions{c}).(maxwinlabels{w}).measures.(DLC.measures{m}).(flds{x}).(refr{1,1}{r}).(degs{1}{d})(t,dlcindx),2);
            txt = num2str(DLCdata, '%.2f');
            if length(flds) >1
            txt = strcat(txt,{' '},(DLC.labels{m}),{' '},(flds{x}),'-',(refr{r})); 
            else
            txt = strcat(txt,{' '},(DLC.labels{m}),{' '},(refr{r})); 
            end
         txt = txt{1};
         text((textspacer(m)),verttxtspacer(vertindx),txt,'Fontsize',10,'FontWeight','bold','Color',bpscolor); %change txt location to be evenly across bottom with subcategories stacked on top of each other
         vertindx = vertindx+1;
            end
            end

     end
     end
     end %measures loop   
    end
    
    %orientation
    if isfield(DLC,'orient')
    DLCdata = viddata.(conditions{c}).(maxwinlabels{w}).Orient(t,dlcindx);
    if ~isnan(DLCdata)
        if DLCdata 
        txt = 'Orient';
        text(10,380,txt,'Fontsize',14,'FontWeight','bold','Color',[[0.149019607843137,0.850980392156863,1]]); 
        end
    end
    end
    
    
    if isfield(DLC,'approach')
     if DLC.approach
     DLCdata = viddata.(conditions{c}).(maxwinlabels{w}).approach(t,dlcindx);
     if ~isnan(DLCdata)
        if DLCdata 
        txt = 'approach';
        text(10,400,txt,'Fontsize',14,'FontWeight','bold','Color',[[0.149019607843137,0.850980392156863,1]]); 
        end
     end
     end
     end
    
    
     if isfield(DLC,'locobouts')
     if DLC.locobouts
     DLCdata = viddata.(conditions{c}).(maxwinlabels{w}).locobouts(t,dlcindx);
     if ~isnan(DLCdata)
        if DLCdata 
        txt = 'move';
        text(10,420,txt,'Fontsize',14,'FontWeight','bold','Color',[[0.149019607843137,0.850980392156863,1]]); 
        end
     end
     end
     end
     
     if isfield(DLC,'freezebouts')
     if DLC.freezebouts
     DLCdata = viddata.(conditions{c}).(maxwinlabels{w}).freezebouts(t,dlcindx);    
        if DLCdata 
        txt = 'freeze';
        text(10,440,txt,'Fontsize',14,'FontWeight','bold','Color',[0.7725    0.2275    1.0000]); 
        end
     end
     end
    s(framecount) = getframe(hAx);
    framecount = framecount+1;
    dlcindx = dlcindx+padfq;
end
% vOut = VideoWriter(savevidas,'MPEG-4');
% vOut.FrameRate = v.FrameRate;
% open(vOut)

for k = 1:numel(s)
    writeVideo(vidObj,s(k))
end
close(vidObj)
    end
    end
end %end trial loop
end %end window loop
end
end %end condition loop
close all
end