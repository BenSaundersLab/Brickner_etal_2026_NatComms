function [dFF, fittedcontrol,std_dFF, sem_dFF] = GetdFF(controldata,signaldata);
%A Wolff 15/2/21 code taken from LickingBouts.m on TDT website
%% Detrending and dFF
bls = polyfit(controldata,signaldata,1);
Y_fit_all = bls(1) .* controldata + bls(2);
Y_dF_all = signaldata - Y_fit_all; %dF (units mV) is not dFF

% Full dFF according to Lerner et al. 2015
% http://dx.doi.org/10.1016/j.cell.2015.07.014
% dFF using 405 fit as baseline
dFF = 100*(Y_dF_all)./Y_fit_all;
std_dFF = std(double(dFF));
sem_dFF = std_dFF/(sqrt(length(dFF)));
fittedcontrol = Y_fit_all;
end