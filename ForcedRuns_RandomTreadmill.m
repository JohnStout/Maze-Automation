%
% theres a .25-.5 second lag between when a maze action occurs and when
% cheetah receives it

% shuffle the seed
rng('shuffle')

cd 'X:\01.Experiments\R21\Experiment 1 - Treadmill Manipulation'

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

% for arduino
if exist("a") == 0
    % connect arduino
    a = arduino('COM10','Uno','Libraries','Adafruit\MotorShieldV2');
end

irArduino.Treadmill = 'D9';

%% initialize treadmill variables
% load treadmill speeds
speeds.medium = load('mediumSpeed30.mat');
speeds.fast   = load('fastSpeed30.mat');

mediumSpeed = speeds.medium.mediumSpeed;
fastSpeed   = speeds.fast.fastSpeed;

% make an empty array
speed_cell = cell(size(fieldnames(treadSpeeds),1)+1,1);

% fill the first cell with nan because there is no 1mpm rate
speed_cell{1} = NaN;

% make an array where its row index is the speed
speed_cell(2:end) = struct2cell(treadSpeeds);

%% some parameters set by the user
numTrials    = 24; % do not include first trial, so if you want 13, write 12
pellet_count = 1;
timeout_len  = 60*10;
treadmill    = 1; % set this to 1 if you want to use
cheetah      = 1;
delay        = 1;
delay_length = 30;
vary_tread_speed = 1; % set to 0 for speed of 2mpm

%% clean the stored data just in case IR beams were broken
maze.Timeout = 1; % 1 second timeout
next = 0; % set while loop variable
while next == 0
   irTemp = read(maze,4,"uint8"); % look for stored data
   if isempty(irTemp) == 1     % if there are no stored ir beam breaks
       next = 1;               % break out of the while loop
       disp('IR record empty - ignore the warning')
   else
       disp('IR record not empty')
       disp(irTemp)
   end
end

%% Interface stuff
    next = 0;
    while next == 0
        prompt = 'Is the rat in the bowl? [Y/N] ';
        cheetah_resp = input(prompt,'s');

        if cheetah_resp == 'Y'
            next = 1;
        elseif cheetah_resp == 'N'
            next = 0; 
        end
    end

if cheetah == 1
    next = 0;
    while next == 0
        prompt = 'Is the Digital Lynx box on and cheetah opened? [Y/N] ';
        cheetah_resp = input(prompt,'s');

        if cheetah_resp ~= 'Y'
            disp('Please turn the Digital Lynx box on, wait until light stops blinking, then open Cheetah');
            pause(2);
            next = 0;
        elseif cheetah_resp == 'Y'
            next = 1; 
        end
    end

    % addpath to the netcom functions
    addpath('X:\03. Lab Procedures and Protocols\MATLABToolbox\NetCom\Matlab_M-files')

    % define the computers server name
    serverName = '192.168.0.200'; % from C. Sanger's sticker on the console

    % connected via netcom to cheetah
    disp('Connecting with NetCom. This may take a few minutes...')
    if NlxAreWeConnected() ~= 1
        succeeded = NlxConnectToServer(serverName);
        if succeeded ~= 1
            error('FAILED to connect');
            return
        else
            display('Connected to NetCom Server - Ready to run session.');
        end
    end

    % start acquisition
    prompt  = 'If you are ready to begin acquisition, type "Begin" ';
    acquire = input(prompt,'s');

    if acquire == 'Begin'
        % end acquisition if its already occuring as a safety precaution
        [succeeded, cheetahReply] = NlxSendCommand('-StopAcquisition');    
        [succeeded, cheetahReply] = NlxSendCommand('-StartAcquisition');
    else
        disp('Please manually start data acquisition')
    end

    %{
    % open a stream to interface with events
    [succeeded, cheetahObjects, cheetahTypes] = NlxGetDASObjectsAndTypes; % gets cheetah objects and types
    succeeded = 0;
    while succeeded == 0
        try 
            succeeded = NlxOpenStream(cheetahObjects(33));
            disp('Successfully opened a stream with Events')
        catch
            disp('Failed to open stream with Events')
        end
    end
%}
    % make user enter information for the task
    next = 0;
    while next == 0
        prompt = 'How many trials? Type a number in numerical format: ' ;
        numTrials = str2num(input(prompt,'s'));

        if numTrials > 0
            next = 1;
        end
    end
end

    prompt = 'Will you use the treadmill manipulation? [1 for Yes, 0 for no) ' ;
    treadmill  = str2num(input(prompt,'s'));

if cheetah == 1    
    % ask user if he/she is ready to begin recording
    prompt = 'Would you like to begin recording? You can start manually at a later time otherwise. [Y/N] ';
    rec_start = input(prompt,'s');

    if rec_start == 'Y'
        prompt = 'Will this be a pre-recording? [Y/N] ';
        pre_rec = input(prompt,'s');

        if pre_rec == 'Y'
            prompt = 'Please enter an integer time in minutes (i.e. 1 = 1 minute) for the pre-recording: ';
            pre_time = input(prompt,'s');
            pre_time = str2num(pre_time);

            % begin recording
            [succeeded, cheetahReply] = NlxSendCommand('-StartRecording');
            [succeeded, cheetahReply] = NlxSendCommand('-PostEvent "PreRecordingStart" 10 1'); % prerecording is TTL 00000000001010

            disp('Recording started - check the Cheetah screen');

            % set a timer for diplay
            counter = linspace(pre_time*-1,-1,pre_time);
            for i = 1:length(counter)
                X_disp = [num2str(counter(i)*-1), ' minutes of pre-recording remaining'];
                disp(X_disp)
                pause(60);       % 60 seconds  
                if i == length(counter)
                    [succeeded, cheetahReply] = NlxSendCommand('-PostEvent "PreRecordingEnd" 11 1'); % prerecording end is TTL 00000000001011
                end
            end
        else
            [succeeded, cheetahReply] = NlxSendCommand('-StartRecording');
        end    
    end
end

%% create a random organization of forced run trajectories

% create a unique ID - LN = A, LM = B, LF = C, RN = D, RM = E, RF = F
condsL = repmat(['A';'B';'C'],[numTrials/6 1]);
condsR = repmat(['D';'E';'F'],[numTrials/6 1]);
conds = [condsL; condsR];
conds_temp = conds;

% randomize
for i = 1:1000
    % notice how it rewrites the both_shuffled variable
    conds_shuffled = conds_temp(randperm(numTrials));
end

condsNew = cellstr(conds_shuffled);

% variables (LN = A, LM = B, LF = C, RN = D, RM = E, RF = F) - this
% counterbalances everything randomly
for i = 1:length(condsNew)
    if condsNew{i} == 'A'
        trajectoryTemp{i} = 'L';
        treadRandTemp{i}  = 'N';
    elseif condsNew{i} == 'B'
        trajectoryTemp{i} = 'L';
        treadRandTemp{i}  = 'M'; 
    elseif condsNew{i} == 'C'
        trajectoryTemp{i} = 'L';
        treadRandTemp{i}  = 'F';  
    elseif condsNew{i} == 'D'
        trajectoryTemp{i} = 'R';
        treadRandTemp{i}  = 'N'; 
    elseif condsNew{i} == 'E'
        trajectoryTemp{i} = 'R';
        treadRandTemp{i}  = 'M';  
    elseif condsNew{i} == 'F'
        trajectoryTemp{i} = 'R';
        treadRandTemp{i}  = 'F'; 
    end
end

% double check
for i = 1:length(trajectoryTemp)
    % check trajectory
    if trajectoryTemp{i} == 'L'
        lefts(i)  = 1;
        rights(i) = 0;
    elseif trajectoryTemp{i} == 'R'
        lefts(i)  = 0;
        rights(i) = 1;
    end
    % check treadmill
    if treadRandTemp{i} == 'N'
        nones(i) = 1;
        mediums(i) = 0;
        fasts(i) = 0;
    elseif treadRandTemp{i} == 'M'
        nones(i) = 0;
        mediums(i) = 1;
        fasts(i) = 0;        
    elseif treadRandTemp{i} == 'F'
        nones(i) = 0;
        mediums(i) = 0;
        fasts(i) = 1; 
    end
end

% check that things are properly counterbalanced
if length(find(lefts == 1)) ~= numTrials/2 || length(find(rights==1)) ~= numTrials/2 ...
        || length(find(nones==1)) ~= numTrials/3 || length(find(mediums==1)) ~= numTrials/3 ...
        || length(find(fasts==1)) ~= numTrials/3
    disp('Trajectories and treadmill speeds are not properly counterbalanced')
    return
end

% now designate the first trial
trajTemp2 = repmat(['L';'R'],[numTrials/2 1]);
for i = 1:1000
    trajectoryTemp3 = trajTemp2(randperm(numTrials));
end

% final trajectory variable
trajectory(1) = cellstr(trajectoryTemp3(1));

% designate the rest
trajectory(2:numTrials+1) = cellstr(trajectoryTemp);  

% add nan to the end - this is for the purpose of the reward release. Its a
% place holder
trajectory(end+1)=cellstr('NaN');

% define treadRand
treadRand = cellstr(treadRandTemp);

% add place holder
treadRand(end+1) = cellstr('NaN');

%% maze prep

% close all maze doors - this gives problems with solenoid box
pause(0.25)
writeline(maze,[doorFuns.centralClose doorFuns.sbLeftClose ...
    doorFuns.sbRightClose doorFuns.tLeftClose doorFuns.tRightClose]);

pause(0.25)
writeline(maze,[doorFuns.gzLeftClose doorFuns.gzRightClose])

pause(0.5)
% reward dispensers need about 3 seconds to release pellets
for rewardi = 1:pellet_count
    disp('Prepping reward wells, this may take a few seconds...')
    if trajectory {1} == 'R'
        writeline(maze,rewFuns.right)
        pause(3)
    elseif trajectory{1} == 'L'
        writeline(maze,rewFuns.left)
        pause(3)
    end
end    

%% trials
open_t  = [doorFuns.tLeftOpen doorFuns.tRightOpen];
close_t = [doorFuns.tLeftClose doorFuns.tRightClose];
maze_prep = [doorFuns.gzLeftOpen doorFuns.gzRightOpen];

for triali = 1:numTrials+1
    
    % set central door timeout value
    maze.Timeout = timeout_len; % 5 minutes before matlab stops looking for an IR break    
        
    % first trial - set up the maze doors appropriately
    writeline(maze,maze_prep)
    
    if trajectory{triali} == 'L'
        writeline(maze,doorFuns.tLeftOpen)   
    elseif trajectory{triali} == 'R'
        writeline(maze,doorFuns.tRightOpen)
    end

    if triali == 1
        next_start = 0; % hardcode next as 0 - this value gets updated when criteria is met
        while next_start == 0 
            % for the start of the task, this will only begin the task when hes in
            % the center arm
            if readDigitalPin(a,irArduino.Treadmill) == 0
                if cheetah == 1
                    % neuralynx
                    [succeeded, cheetahReply] = NlxSendCommand('-PostEvent "trialStart" 600 2');
                end
                % open central door to let rat off of treadmill
                writeline(maze,doorFuns.centralOpen)
                
                if cheetah == 1
                    % send a neuralynx command to track the trial
                    [succeeded, cheetahReply] = NlxSendCommand('-PostEvent "centralOpen" 100 2');                
                end
                % tell the loop to move on
                next_start = 1;
            end
        end
    else
        % open central door to let rat off of treadmill
        writeline(maze,doorFuns.centralOpen)        
    end 
    
    % central beam
    % while loop so that we continuously read the IR beam breaks
    maze.Timeout = timeout_len;
    next = 0;
    while next == 0
        irTemp = read(maze,4,"uint8");            % look for IR beam breaks
        if irTemp == irBreakNames.central      % if central beam is broken
                if cheetah == 1
                    % neuralynx timestamp command
                    [succeeded, cheetahReply] = NlxSendCommand('-PostEvent "centralBeam" 102 2');    
                end
                % close door
                pause(0.5) % short delay
                writeline(maze,doorFuns.centralClose) % close the door behind the rat
                if cheetah == 1
                    [succeeded, cheetahReply] = NlxSendCommand('-PostEvent "centralClose" 101 2');            
                end                
            next = 1;                          % break out of the loop
        end
    end

    % t-beam
    % check which direction the rat turns at the T-junction
    next = 0;
    while next == 0
        maze.Timeout = timeout_len;
        irTemp = read(maze,4,"uint8");         
        if irTemp == irBreakNames.tRight 
            if cheetah == 1
                % broke tjunction right beam
                [succeeded, cheetahReply] = NlxSendCommand('-PostEvent "tRightBeam" 222 2');                        
            end
            % close opposite door
            writeline(maze,doorFuns.tRightClose) 
            if cheetah == 1
                [succeeded, cheetahReply] = NlxSendCommand('-PostEvent "tRightClose" 221 2'); % left will be 200s; close door because 201            
            end
            % open sb door
            pause(0.25)            
            writeline(maze,doorFuns.sbRightOpen)
            if cheetah == 1
                [succeeded, cheetahReply] = NlxSendCommand('-PostEvent "sbRightOpen" 510 2'); % left will be 200s; close door because 201                                  
            end
            next = 1;
        elseif irTemp == irBreakNames.tLeft
            if cheetah == 1            
                [succeeded, cheetahReply] = NlxSendCommand('-PostEvent "tLeftBeam" 212 2');          
            end            
            % close door
            writeline(maze,doorFuns.tLeftClose)
            if cheetah == 1            
                 [succeeded, cheetahReply] = NlxSendCommand('-PostEvent "tLeftClose" 211 2'); % right will be 300s            
            end            
            % open sb door
            pause(0.25)            
            writeline(maze,doorFuns.sbLeftOpen)
            if cheetah == 1                        
                [succeeded, cheetahReply] = NlxSendCommand('-PostEvent "sbLeftOpen" 510 2'); % left will be 200s; close door because 201                               
            end
            % break out of while loop
            next = 1;
        end
    end    
    
    %{
    %%%% ~~~~ Reward zone and eating ~~~~ %%%%
    % send to netcom   
    if cheetah == 1
        maze.Timeout=timeout_len;
        irTemp = read(maze,4,"uint8");         
        if irTemp == irBreakNames.rewRight     
            [succeeded, cheetahReply] = NlxSendCommand('-PostEvent "rewardRight" 322 2'); 
        elseif irTemp == irBreakNames.rewLeft
            [succeeded, cheetahReply] = NlxSendCommand('-PostEvent "rewardLeft" 312 2');
        end
        irTemp = [];
    end
    %}
    
    % return arm
    maze.Timeout = timeout_len;
    next = 0;
    while next == 0
        irTemp = read(maze,4,"uint8");         
        if irTemp == irBreakNames.gzRight 
            if cheetah == 1                        
                % send neuralynx command for timestamp
                [succeeded, cheetahReply] = NlxSendCommand('-PostEvent "gzRightBeam" 422 2');             
            end
            % close both for audio symmetry
            writeline(maze,doorFuns.gzLeftClose)
            pause(0.25)
            writeline(maze,doorFuns.gzRightClose)
            pause(0.25)
            writeline(maze,doorFuns.tRightClose)
            pause(0.25)
            
            % release pellet
            if trajectory{triali+1} == 'R' 
                % reward dispensers need about 3 seconds to release pellets
                for rewardi = 1:pellet_count
                    pause(0.25)
                    writeline(maze,rewFuns.right)
                    pause(0.5)
                end
            elseif trajectory{triali+1} == 'L' 
                % reward dispensers need about 3 seconds to release pellets
                for rewardi = 1:pellet_count
                    pause(0.25)
                    writeline(maze,rewFuns.left)
                    pause(0.5)
                end 
            end          
            
            if cheetah == 1                        
                % only code as gzRightClose
                [succeeded, cheetahReply] = NlxSendCommand('-PostEvent "gzRightClose - gzLeft and tLeft close too" 421 2');             
            end
            next = 1;                          
        elseif irTemp == irBreakNames.gzLeft
            if cheetah == 1                        
                % send neuralynx command for timestamp
                [succeeded, cheetahReply] = NlxSendCommand('-PostEvent "gzLeftBeam" 412 2');
            end
            % close both for audio symmetry
            writeline(maze,doorFuns.gzLeftClose)
            pause(0.25)
            writeline(maze,doorFuns.gzRightClose)
            pause(0.25)
            writeline(maze,doorFuns.tLeftClose)  
            pause(0.25)
            
            % release pellet
            if trajectory{triali+1} == 'R' 
                % reward dispensers need about 3 seconds to release pellets
                for rewardi = 1:pellet_count
                    pause(0.25)
                    writeline(maze,rewFuns.right)
                    pause(0.5)
                end
            elseif trajectory{triali+1} == 'L' 
                % reward dispensers need about 3 seconds to release pellets
                for rewardi = 1:pellet_count
                    pause(0.25)
                    writeline(maze,rewFuns.left)
                    pause(0.5)
                end                 
            end                
            
            if cheetah == 1                        
                % only code as gzLeftClose
                [succeeded, cheetahReply] = NlxSendCommand('-PostEvent "gzLeftClose - gzRight and tLeft close too" 411 2');                        
            end
            next = 1;
        end
    end    
    
    % startbox
    next = 0;
    while next == 0
        maze.Timeout = timeout_len;
        irTemp = read(maze,4,"uint8");         
        if irTemp == irBreakNames.sbRight
            if cheetah == 1                        
                 % neuralynx ttl
                [succeeded, cheetahReply] = NlxSendCommand('-PostEvent "sbRightBeam" 522 2');             
            end
            % track animals traversal onto the treadmill
            next_tread = 0; % hardcode next as 0 - this value gets updated when criteria is met
            while next_tread == 0 
                % try to see if the rat goes and checks out the other doors
                % IR beam
                maze.Timeout = 0.1;
                irTemp = read(maze,4,"uint8");
                % if rat enters the startbox, only close the door behind
                % him if he has either checked out the opposing door or
                % entered the center of the startbox zone. This ensures
                % that the rat is in fact in the startbox
                if readDigitalPin(a,irArduino.Treadmill) == 0
                    if cheetah == 1            
                        % neuralynx ttl
                        [succeeded, cheetahReply] = NlxSendCommand('-PostEvent "TreadmillBeam" 602 2');
                    end
                    % close startbox door
                    pause(.25);                    
                    writeline(maze,doorFuns.sbRightClose)
                    
                     if cheetah == 1                
                        % neuralynx ttl
                        [succeeded, cheetahReply] = NlxSendCommand('-PostEvent "sbRightClose" 521 2');                    
                     end
                    % tell the loop to move on
                    next_tread = 1;
                elseif isempty(irTemp) == 0
                    if irTemp == irBreakNames.sbLeft
                        if cheetah == 1            
                            % neuralynx ttl
                            [succeeded, cheetahReply] = NlxSendCommand('-PostEvent "sbLeftBeam - after Right" 512 3'); 
                        end
                        % close startbox door
                        pause(0.25)
                        writeline(maze,doorFuns.sbRightClose)
                        
                        if cheetah == 1               
                            % neuralynx ttl
                            [succeeded, cheetahReply] = NlxSendCommand('-PostEvent "sbRightClose" 521 2');                        
                        end
                        % tell the loop to move on
                        next_tread = 1;
                    end
                elseif isempty(irTemp)==1 && readDigitalPin(a,irArduino.Treadmill) == 1
                    next_tread = 0;
                end
            end
            
            next = 1;
        elseif irTemp == irBreakNames.sbLeft 
            if cheetah == 1            
                % neuralynx ttl
                [succeeded, cheetahReply] = NlxSendCommand('-PostEvent "sbLeftBeam" 512 2');                         
            end
            % track animals traversal onto the treadmill
            next_tread = 0; % hardcode next as 0 - this value gets updated when criteria is met
            while next_tread == 0 
                % try to see if the rat goes and checks out the other doors
                % IR beam
                maze.Timeout = 0.1;
                irTemp = read(maze,4,"uint8");
                % if rat enters the startbox, only close the door behind
                % him if he has either checked out the opposing door or
                % entered the center of the startbox zone. This ensures
                % that the rat is in fact in the startbox
                if readDigitalPin(a,irArduino.Treadmill) == 0
                    % close startbox door
                    pause(.25);                    
                    writeline(maze,doorFuns.sbLeftClose)
                    
                    if cheetah == 1            
                        % neuralynx ttl
                        [succeeded, cheetahReply] = NlxSendCommand('-PostEvent "sbLeftClose" 511 2');                    
                    end
                    % tell the loop to move on
                    next_tread = 1;
                elseif isempty(irTemp) == 0
                    if irTemp == irBreakNames.sbRight
                        if cheetah == 1            
                            % neuralynx ttl
                            [succeeded, cheetahReply] = NlxSendCommand('-PostEvent "sbRightBeam - after Right" 522 3');                         
                        end
                        % close startbox door
                        pause(0.25)
                        writeline(maze,doorFuns.sbLeftClose)
                        
                        if cheetah == 1              
                            % neuralynx ttl
                            [succeeded, cheetahReply] = NlxSendCommand('-PostEvent "sbLeftClose" 511 2'); 
                        end
                        % tell the loop to move on
                        next_tread = 1;
                    end
                elseif isempty(irTemp)==1 && readDigitalPin(a,irArduino.Treadmill) == 1
                    next_tread = 0;
                end
            end
            
            next = 1;
        end 
    end
    
    % reset timeout
    maze.Timeout = timeout_len;
    
    if delay == 1
        if treadmill == 1 && triali ~= numTrials+1

            % start treadmill
            pause(0.25)
            
            write(maze,treadFuns.start,'uint8');
            
            if cheetah == 1                        
                % neuralynx command
                [succeeded, cheetahReply] = NlxSendCommand('-PostEvent "treadmillStart" 600 2');    
            end
            % short pause before sending the machine the speed data
            pause(0.25)

            if vary_tread_speed == 1
                if treadRand{triali} == 'M' % if medium treadmill speed                    
                    for i = mediumSpeed
                        % set treadmill speed
                        write(maze,uint8(speed_cell{i}'),'uint8'); % add a second command in case the machine missed the first one

                        % define a flexible variable that tells cheetah what speed
                        % the rat is on
                        if i < 10
                            X2 = ['0' num2str(i)];
                        else
                            X2 = num2str(i);
                        end

                        % make variable to reflect on cheeta
                        X3 = [num2str(i), 'mpm'];


                        % make a flexible 
                        X1 = ['-PostEvent ', '"', X3, '"', ' 8', X2 ' 2'];

                        if cheetah == 1
                            % neuralynx command
                            [succeeded, cheetahReply] = NlxSendCommand(X1);  
                        end
                        pause(1)
                    end
                elseif treadRand{triali} == 'F' % if fast treadmill speed
                    for i = fastSpeed
                        % set treadmill speed
                        write(maze,uint8(speed_cell{i}'),'uint8'); % add a second command in case the machine missed the first one

                        % define a flexible variable that tells cheetah what speed
                        % the rat is on
                        if i < 10
                            X2 = ['0' num2str(i)];
                        else
                            X2 = num2str(i);
                        end

                        % make variable to reflect on cheeta
                        X3 = [num2str(i), 'mpm'];


                        % make a flexible 
                        X1 = ['-PostEvent ', '"', X3, '"', ' 8', X2 ' 2'];

                        if cheetah == 1
                            % neuralynx command
                            [succeeded, cheetahReply] = NlxSendCommand(X1);  
                        end
                        pause(1)
                    end    
                elseif treadRand{triali} == 'N' % if no treadmill speed
                    pause(delay_length)
                end
                write(maze,treadFuns.stop,'uint8');     
            else
                speed = 2;
                % set treadmill speed
                write(maze,uint8(speed_cell{speed}'),'uint8'); % add a second command in case the machine missed the first one
                pause(delay_length);
                write(maze,treadFuns.stop,'uint8');     
            end
        else
            pause(delay_length);
        end
    end
    
    % indicate trial start
    if triali ~= 1 || triali ~= numTrials+1
        if cheetah == 1
            % neuralynx
            [succeeded, cheetahReply] = NlxSendCommand('-PostEvent "trialStart" 600 2'); 
        end 
    end   
    
    counter = triali;
    disp(['Trial', num2str(counter),' finished']);
end

% save data - this is very important! This save section stores a unique
% name for each save file. It requires the user to interface.
c = clock;
c_save = strcat(num2str(c(2)),'_',num2str(c(3)),'_',num2str(c(1)),'_','EndTime',num2str(c(4)),num2str(c(5)));

prompt   = 'Please enter the rats name ';
rat_name = input(prompt,'s');

prompt   = 'Please enter the task ';
task_name = input(prompt,'s');

prompt   = 'Enter the directory to save the data ';
dir_name = input(prompt,'s');

save_var = strcat(rat_name,'_',task_name,'_',c_save);

cd(dir_name);
save(save_var);

