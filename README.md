# FP_analysis

User should edit and run FP_UserSetup to execute.
Requires excel loadfile list of files to load - see example list in example data
Can also provide a list of loafilelists for running many recordings overnight.

Based on user inputs, selects data for windows around TTL events and generates peri-event plots.
Options to:
	trim the start and end of recording to remove artifacts (intitial LED on artifact already removed by default).
	Create video snippets around events
	Analyze perievent behaviour data analysed in DLC


script requires following functions:
	TDTbin2mat.m (to load synapse files)
	FP_Analysis 
  	FP_ConditionalBinTrials
	FP_GetSnips
  	FP_MaxRespons
 	FP_PlotPerievent	
  	FP_PlotTrial	
  	FP_Zscoresnips	
  	GenPulseEpoch
  	GetdFF	
  	GetLists
  	GetPlotData

optional analyses require:
  	SaveVidSnips
  	TrimRecording
  
DLC analysis requires:
 	Distance
  	DLC_Analyze
  	DLC_GetSnips
  	DLC_PlotPerievent
  	DLC_PlotSummaryFigure
  	DLC_PlotTrials
  
  Outputs:
  	Figures
  	.mat file for each animal (all recordings in a single file)
  	videosnips (optional)


