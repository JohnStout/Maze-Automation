%% AutoMaze ver 1.2
% This script uses the arduino and adafruit shield v2 set-up for T-maze
% task automation. Currently it interfaces with the user at the Command
% Window to support Delayed Alternation and Continuous Alternation tasks.
% This script also incorporates a function that tests the equipment.
%
% Future versions will interface with the user to determine CA,DA, or DNMP
% tasks
%
% written by John Stout

%% Configuring steps
%
% 1) connect the arduino board to your computer via cable
% 2) plug in the 12V battery and connect it to arduino
% 3) make sure you have the EquipmentTest function in your directory or
%    path (check the Current Folder)
% 4) hit the 'Run' button on the editor
%
% if you experience errors with defining the arduino, go to device manager
% under your search menu, then make sure the arduino is connected. If
% connected, make sure the port and arduino type matches what is defined
% below.

%% test equipment
clear; clc

% interface with user to explain the code
X_disp = [' This code is used for T-maze automation. First, it will interface with the user \n'...
    ' to test for equipment functionality. Then, it will require the user to \n' ...
    ' enter which task to automate (currently only capable of CA, DA, and DNMP). \n' ...
    ' Finally, it will require you to enter some task parameters (i.e. length of delay and \n'...
    ' number of trials)... \n \n Note that<strong> user inputs are case sensitive</strong>. If you are ready' ...
    ' to continue press [\bspacebar]\b. \n'];

fprintf(X_disp)
pause;

% test equipment?
prompt   = 'Do you want to test equipment prior to maze usage? [Y/N] ';
test_equipment = input(prompt,'s');

% test equipment if 'Y'
if test_equipment == 'Y'
    EquipmentTest();
end

%% interface with user 
% clear out the workspace again in case anything was left in memory
clear; clc

% future iterations will have options for CA, DA, and DNMP

% input number of trials
prompt     = 'How many trials will you run? Enter an integer: ';
num_trials = input(prompt);

% input delay between trials
prompt       = 'Delay length? Enter an integer (i.e. 20 = 20 seconds) ';
delay_length = input(prompt);


%% set up maze
% define arduino - you may need to specify that you want the adafruit
% motorshield v2 library. Note that you also need to know your port (COM_)
% and arduino type
a = arduino('COM3','Mega2560','Libraries','Adafruit\MotorShieldV2');

% define the top and bottom shields using separate I2C addresses - see ___
% for steps to configure this on the hardware end of things  
shield_top = addon(a,'Adafruit\MotorshieldV2','I2CAddress','0x60');
shield_bot = addon(a,'Adafruit\MotorshieldV2','I2CAddress','0x61'); 

% steppers
StepperMotor.Left = stepper(shield_bot,1,200,'RPM',50,'StepType','Double');
StepperMotor.Right = stepper(shield_bot,2,200,'RPM',50,'StepType','Double');

% IR beams
IR.Central = 'D22';
IR.Left    = 'D26';
IR.Right   = 'D24';

% servos
Door.Central = servo(a,'D53');
Door.Left    = servo(shield_top,2);
Door.Right   = servo(shield_top,1);

%% orient doors
% define closed and open position
door_close  = 0.44;
door_open   = 1;
% do stuff
writePosition(Door.Central,door_close);
writePosition(Door.Left,door_close);
writePosition(Door.Right,door_close);

%% set up maze
% open central door
% writePosition(Door.Central,0.44); % up
% writePosition(Door.Central,1);    % down

% define a stepper distance
StepperDistance.RewardL = -150;
StepperDistance.RewardR = -150;

% provide reward
move(StepperMotor.Left, StepperDistance.RewardL);
move(StepperMotor.Right,StepperDistance.RewardR);

% open left and right doors
writePosition(Door.Left,1);
writePosition(Door.Right,1);

% 2 second pause
pause(2);

% open central door
writePosition(Door.Central,door_open);

%% first trial
for triali = 1:num_trials  
    
    % if not on the first trial, open up the central door to restart the
    % traversal
    if triali ~= 1
        writePosition(Door.Central,door_open)
    end    
    
    % track animals traversal into arms
    next = 0; % hardcode next as 0 - this value gets updated when criteria is met
    while next == 0 
        % if rat goes right
        if readDigitalPin(a,IR.Right) == 0
           writePosition(Door.Left,door_close)
           trajectory{triali} = 'R'; % make this binary like Int file?
           % tell the loop to move on
           next = 1;
        elseif readDigitalPin(a,IR.Left) == 0
           writePosition(Door.Right,door_close)
           trajectory{triali} = 'L';
           % tell the loop to move on
           next = 1;
        end
    end

    % track animals traversal to central stem
    next = 0; % hardcode next as 0 - this will be updated when criteria met
    while next == 0
        % if he goes back to Central and came from right arm
        if readDigitalPin(a,IR.Central) == 0 && trajectory{triali} == 'R'
            writePosition(Door.Central,door_close);
            writePosition(Door.Left,door_open);
            % provide reward to opposite arm if not first trial
            if triali ~= 1
               % prevents overfilling the cup
               if trajectory{triali} ~= trajectory{triali-1}
                  move(StepperMotor.Left,StepperDistance.RewardL);
               end
            end
            next = 1;
            pause(delay_length); % test that this whole thing will actually be 20 seconds. It may be more
        % if he goes back to central and came from left arm
        elseif readDigitalPin(a,IR.Central) == 0 && trajectory{triali} == 'L'
            writePosition(Door.Central,door_close);
            writePosition(Door.Right,door_open);
            % provide reward to opposite arm if not first trial
            if triali ~= 1
                % make sure not to overfill
                if trajectory{triali} ~= trajectory{triali-1}
                    move(StepperMotor.Right,StepperDistance.RewardR); 
                end
            end   
            next = 1;
            pause(delay_length); % again test that the delay will actually be 20. I should account for motor times than create an estimate that I can convert to and from                
        end
    end

    % trial log for visualizing progress
    trial_log{triali} = num2str(triali);
    X = ['Trial number ', trial_log{triali}];
    disp(X);
end

%% reset maze
% at the end of the script, reward wells will reset
