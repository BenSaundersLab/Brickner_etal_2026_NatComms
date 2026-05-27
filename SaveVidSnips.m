function [outdata] = SaveVidSnips (f,outdata,fsep,saveloc,condition,vidfile,vidticks,PATH, FILE,sniplabel,vidTRANGE)
%A Wolff 15/2/21
%% function to save shorter snips of video around event onset
%Inputs:
%f - current file number used to reference correct recording
%outdata - outdatafile (.mat)
%fsep - fileseparator 
%condition - string: cond1 or cond2
%vidfile - string: name of vidfile including path
%vidticks - epoc to find timestamps for camera ticks
%PATH - string: used to generate savename
%FILE - string: ussed to generate savename
%sniplabel - string: t0 event locked or control snip
%vidTRANGE - data range for perievent window

%% Get data from outfile
vidpath =  strcat(vidfile);
if ~exist(vidpath,'file')
    disp ('Video file does not exist or cannot be found');
else
savepath = strcat(saveloc,'VideoSnips',fsep,outdata.metadata.subj{f,1},fsep,FILE,'_f',num2str(f));
%savepath = cell2mat(savepath);
if ~exist(savepath, 'dir')
       mkdir(savepath);
end

for c = 1:length(condition)
v = VideoReader(vidpath);    
nevents = length(outdata.perievent.(sniplabel).(condition{c}).trialn{f,1});
trialn = outdata.perievent.(sniplabel).(condition{c}).trialn{f,1};
outdata.videodata.filename.(sniplabel).(condition{c}){f,1} = cell (nevents,1);%preallocate
outdata.videodata.vidticks.(sniplabel).(condition{c}).ts{f,1} = cell (nevents,1);
outdata.videodata.vidticks.(sniplabel).(condition{c}).indx{f,1} = cell (nevents,1);

%% For each Event pull the video snip and save
totframes = length(vidticks);
save ('nframestemp.mat','totframes'); 
for t = 1:nevents 
indx = outdata.eventdata.(sniplabel).(condition{c}).trialn{f,1} == trialn(t);
if isfield(outdata.timearray.(sniplabel), 'FP')
winend = outdata.timearray.(sniplabel).FP.perievent{f,1}(end);
else
winend = outdata.timearray.(sniplabel).DLC.perievent{f,1}(end);
end
eventts = outdata.eventdata.(sniplabel).(condition{c}).ts{f,1}(indx);
eventindx = find(outdata.videodata.frames.onset{f,1}>= eventts,1,'first');
frameindx = (eventindx+vidTRANGE(1):eventindx+vidTRANGE(2));
actualend = find(outdata.videodata.frames.onset{f,1} >= eventts+winend,1,'first');
foundend = frameindx(end);

if ~isempty(actualend) && frameindx(1) > 0
if abs(actualend - foundend) <=1 && foundend <= length(vidticks) %only get video if frames have all been captured and not too many frames have been dropped
outdata.videodata.vidticks.(sniplabel).(condition{c}).ts{f,1}{t} = vidticks(frameindx);
outdata.videodata.vidticks.(sniplabel).(condition{c}).indx{f,1}{t} = frameindx;
savedir = strcat(savepath,'/',(sniplabel),'/',(condition{c}),'/');
clear actualend foundend

if ~exist(savedir, 'dir')
       mkdir(savedir);
end

outputfname = strcat('t',num2str(outdata.perievent.(sniplabel).(condition{c}).trialn{f,1}(t)));
outputName = strcat(savedir,outputfname);
% localoutname = outdata.UserVals.localoutname;
%     if localoutname(end) == '/' || localoutname(end) == '\'
%     localoutname(end) = [];
%     end
% if ~exist(localoutname, 'dir')
%     mkdir(localoutname,'f');
% end
% localoutname = strcat(localoutname,filesep,outputfname);
outdata.videodata.filename.(sniplabel).(condition{c}){f,1}{t} = strcat(outputName,'.mp4');
if ~exist(outdata.videodata.filename.(sniplabel).(condition{c}){f,1}{t},'file')
vidObj = VideoWriter(outputName,'MPEG-4');
vidObj.FrameRate = v.FrameRate;
open(vidObj);

outdata.videodata.fps{f,1}= v.FrameRate;
outdata.videodata.width{f,1}= v.Width;
outdata.videodata.height{f,1}= v.Height;

for img = outdata.videodata.vidticks.(sniplabel).(condition{c}).indx{f,1}{t}(1):outdata.videodata.vidticks.(sniplabel).(condition{c}).indx{f,1}{t}(end)
    save ('imgtemp.mat','img'); 
    b = read(v, img);
    writeVideo(vidObj,b);
end
close(vidObj);
clear img vidObj b winend eventts eventindx frameindx 
% copyfile(strcat(localoutname,'.mp4'),savedir,'f');
% delete (strcat(localoutname,'.mp4'))
end
end
end
end
clear v
end
end
end





