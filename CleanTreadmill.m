%% Treadmill manipulation
%
% This script linearly manipulates the treadmill speed
% last edit 1/29/20 - JS
clearvars -except maze a

addpath('X:\03. Lab Procedures and Protocols\MazeEngineers')

if exist("maze") == 0
    % connect to the serial port making an object
    maze = serialport("COM9",19200);
end

% load in door functions
doorFuns = DoorActions;

% test reward wells
rewFuns = RewardActions;

% load treadmill functions and settings
[treadFuns,treadSpeeds] = TreadMillFuns;

% get IR information
irBreakNames = irBreakLabels;

pause(0.25)
writeline(maze,[doorFuns.centralClose doorFuns.sbLeftClose ...
    doorFuns.sbRightClose doorFuns.tLeftClose doorFuns.tRightClose]);

pause(0.25)
writeline(maze,[doorFuns.gzLeftClose doorFuns.gzRightClose])

% load treadmill functions and settings
[treadFuns,treadSpeeds] = TreadMillFuns;

% make an empty array
speed_cell = cell(size(fieldnames(treadSpeeds),1)+1,1);

% fill the first cell with nan because there is no 1mpm rate
speed_cell{1} = NaN;

% make an array where its row index is the speed
speed_cell(2:end) = struct2cell(treadSpeeds);

% linearly increase speed
linearIncrease = [2:1:11];
linearDecrease = fliplr(linearIncrease);
speedVector    = round([linearIncrease linearDecrease]);

% test medium speed
write(maze,treadFuns.start,'uint8');

write(maze,uint8(speed_cell{3}'),'uint8'); % add a second command in case the machine missed the first one


% stop treadmill          
write(maze,treadFuns.stop,'uint8');

