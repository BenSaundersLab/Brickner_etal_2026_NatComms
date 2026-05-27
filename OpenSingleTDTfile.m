%% load single TDT file_ARW
%loads a single TDT file from the filelist so you can view the stream names
%last edit ARW 01-22-2020
clearvars %clears all variables
close all %closes all figures
%filename = ['/Users/amywolff/Library/CloudStorage/GoogleDrive-awolff@umn.edu/Shared drives/SL_Data/Megan/bLight Cohort 4/03.5_FearConditioning/BLA-dLight13_14-220613-143058'];
filename = ['G:/Shared drives/SL_Data/Megan/bLight Cohort 4/03.5_FearConditioning/BLA-dLight13_14-220613-143058'];
data = TDTbin2mat(filename);

    
