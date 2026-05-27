function y = FP_lowpassFilt(x,cutoff,Fs,n)
% Butterworth Lowpass Filter (zero-phase distortion filter)
% This creates n-th order Butterworth lowpass filter and takes input
% signal and creates output, the filtered signal. 
%
% <Usage>
%
% y = lowpass(x,cutoff,Fs,n)
% 
% where x: the unfiltered, raw signal
%       cutoff: cut-off frequency
%       Fs: sampling rate
%       n: the order of Butterworth filter
%       y: the filtered signal
%
% <Example>
%
% y = lowpass(x,100,2000,4);
%
% Coded by Ryan Cho, Oct 21 2013. From paper : 
% Ultrafast neuronal imaging of dopamine dynamics with designed genetically encoded sensors.
% Patriarchi T, Cho JR, Merten K, Howe MW, Marley A, Xiong WH, Folk RW, Broussard GJ, Liang R, Jang MJ, Zhong H, Dombeck D, von Zastrow M, Nimmerjahn A, Gradinaru V, Williams JT, Tian L
[b,a] = butter(n,cutoff/(Fs/2),'low');
x = double(x);
y = filtfilt(b,a,x);
end