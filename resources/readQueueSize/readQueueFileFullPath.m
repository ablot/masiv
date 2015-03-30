function fName = readQueueFileFullPath
% function fName = readQueueFileFullPath
%
% The name of the read queue file. On a multi-user system
% we run into problems if two people are using goggleViewer
% at the same time. Thus we append the date and time to the
% file name to create a unique file each time. 

  fName=fullfile(tempdir,...
                 sprintf('goggleViewer_readqueue_%s.txt',...
                         datestr(now,'yymmdd_HHMMSS')) );


end

