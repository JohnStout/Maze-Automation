%% EquipmentTest
%
% This function tests servo doors, IR beams, and stepper motors for reward
% for the prototype automatic maze
%
% written by John Stout

%% Configuring steps
% 1) connect the arduino board to your computer via cable
% 2) plug in the 12V battery and connect it to arduino
% 3) go to your search menu and find 'device manager' to find the port and
%    arduino name

function [] = EquipmentTest()
% clear and clc
clear; clc

% define arduino - you may need to specify that you want the adafruit
% motorshield v2 library. Note that you also need to know your port (COM_)
% and arduino type
a = arduino('COM4','Mega2560','Libraries','Adafruit\MotorShieldV2');

% define the top and bottom shields using separate I2C addresses - see ___
% for steps to configure this on the hardware end of things  
shield_top = addon(a,'Adafruit\MotorshieldV2','I2CAddress','0x60');
shield_bot = addon(a,'Adafruit\MotorshieldV2','I2CAddress','0x61'); 

%% stepper motor control
% functional 9/5/2019

% define the stepper motor variables - note that this is like a structure
% array where if you want to change RPM, you would do 'StepperMotor.Left.RPM = 20'; same
% for step type. Double step type seems to make less noise. You could also
% predefine a variable, like 'stepper_rpm = 50' then fill it in below after
% the 'RPM'. Same for step type
StepperMotor.Left = stepper(shield_bot,1,200,'RPM',50,'StepType','Double');
StepperMotor.Right = stepper(shield_bot,2,200,'RPM',50,'StepType','Double');

% are the reward plungers pushed all the way up?
prompt  = 'Do you want to lower the left reward plunger? [Y/N] ';
answer1 = input(prompt,'s');
if answer1 == 'Y'
    next = 0;
    while next == 0
        prompt   = 'How much would you like to lower the plunger? \n Enter an integer between 100 and 1000 ';
        answer1a = input(prompt);
        move(StepperMotor.Left,answer1a);
        prompt   = 'Enter 1 if you would like to continue lowering the plunger. Enter 0 to move on ';
        answer1b = input(prompt);
        if answer1b == 0
            % if the user is ready to move onto the next part of code,
            % define next as 1 to break the while loop
            next = 1;
        end
    end
end

prompt  = 'Do you want to lower the right reward plunger? [Y/N] ';
answer2 = input(prompt,'s');
if answer2 == 'Y'
    next = 0;
    while next == 0
        prompt   = 'How much would you like to lower the plunger? \n Enter an integer between 100 and 1000 ';
        answer2a = input(prompt);
        move(StepperMotor.Left,answer2a);
        prompt   = 'Enter 1 if you would like to continue lowering the plunger. Enter 0 to move on ';
        answer1b = input(prompt);
        if answer2b == 0
            % if the user is ready to move onto the next part of code,
            % define next as 1 to break the while loop
            next = 1;
        end
    end
end
  
% interface with user to test stepper motors
prompt  = 'Testing stepper motor - enter a value between 100 and 500 ';
answer3 = input(prompt);

% give user a count down to allow them to visualize maze
countdown_start = 15;
count_var = linspace(countdown_start*-1,-1,countdown_start);
for i = 1:length(count_var)
    if i ~= length(count_var)
        X2 = [num2str(abs(count_var(i))), ' seconds'];
        pause(1);
        disp(X2)
    else
        X2 = [num2str(abs(count_var(i))), ' second'];
        pause(1);
        disp(X2)
    end
end

% test - note that based on our orientation of the stepper motor, negative
% steps move upwards
disp('Moving left stepper upwards')
move(StepperMotor.Left,answer3*-1);
pause(1);
disp('Moving right stepper upwards')
move(StepperMotor.Right,answer3*-1);

% did the steppers work?
prompt  = 'Did stepper motors move upwards? [Y/N] ';
answer4 = input(prompt,'s');

if answer4 == 'N'
    disp('Check that wires are plugged in and re-run')
    return
else
    disp('reward steppers ready')
end

%% IR beam control
% IR beams will be used to recognize the rat and either drive stepper
% motors or linear actuators

IR.Central = 'D22';
IR.Left    = 'D26';
IR.Right   = 'D24';

% beams aligned? run 1000 times which is slightly over 1 minute
disp('Testing IR beams')

% create a while loop that resets if beams are not aligned
aligned = readDigitalPin(a,IR.Central);
start  = 0;   % start variable for for loop (made for resetting)
finish = 500; % end variable for for loop
for i = start+1:finish
    while aligned(end) == 0
        % store aligned data
        aligned(i) = readDigitalPin(a,IR.Central);
        % if it's not aligned, tell the user to fix
        if aligned(i) == 0
            disp('Central IR beams are not aligned')
        elseif aligned(i) == 1
            disp('Central IR beams are aligned')
            % reset the for loop
            disp('Resetting testing loop for IR beam')
            start = 0;
        end
    end
    % store aligned data as a 1 if connected
    aligned(i) = readDigitalPin(a,IR.Central);
end
disp('Central IR beams are aligned')

% left beam test
aligned = readDigitalPin(a,IR.Left);
start  = 0;   % start variable for for loop (made for resetting)
finish = 500; % end variable for for loop
for i = start+1:finish
    while aligned(end) == 0
        % store aligned data
        aligned(i) = readDigitalPin(a,IR.Left);
        % if it's not aligned, tell the user to fix
        if aligned(i) == 0
            disp('Left IR beams are not aligned')
        elseif aligned(i) == 1
            disp('Left IR beams are aligned')
            disp('Resetting testing loop for IR beam')            
            % reset the for loop
            start = 0;
        end
    end
    % store aligned data as a 1 if connected
    aligned(i) = readDigitalPin(a,IR.Left);
end
disp('Left IR beams are aligned')

% right beam test
aligned = readDigitalPin(a,IR.Right);
start  = 0;   % start variable for for loop (made for resetting)
finish = 500; % end variable for for loop
for i = start+1:finish
    while aligned(end) == 0
        % store aligned data
        aligned(i) = readDigitalPin(a,IR.Right);
        % if it's not aligned, tell the user to fix
        if aligned(i) == 0
            disp('Right IR beams are not aligned')
        elseif aligned(i) == 1
            disp('Right IR beams are aligned')
            disp('Resetting testing loop for IR beam')            
            % reset the for loop
            start = 0;
        end
    end
    % store aligned data as a 1 if connected
    aligned(i) = readDigitalPin(a,IR.Right);
end
disp('Right IR beams are aligned')
pause(1);

% let user know that IR beams are good
disp('IR beams ready')

% variable to tell script to move to the next phase

%% servo control
% define servos
Door.Central = servo(a,'D53');
Door.Left    = servo(shield_top,2);
Door.Right   = servo(shield_top,1);

% interface with the user to test servos
answer5 = 'N';
% hardcode the starting countdown to 15 seconds - this allows the user to
% approach the maze and watch it
countdown_start = 15;

while answer5 == 'N'
    % tell user to visually observe the servos working
    X1 = ['Watch doors for proper movement ', num2str(countdown_start),' second count-down starts now'];
    disp(X1)
    
    % Count down
    count_var = linspace(countdown_start*-1,-1,countdown_start);
    for i = 1:length(count_var)
        if i ~= length(count_var)
            X2 = [num2str(abs(count_var(i))), ' seconds'];
            pause(1);
            disp(X2)
        else
            X2 = [num2str(abs(count_var(i))), ' second'];
            pause(1);
            disp(X2)
        end
    end

    % test
    writePosition(Door.Central,0.44);
    writePosition(Door.Left,0.44);
    writePosition(Door.Right,0.44);
    pause(2)
    writePosition(Door.Central,1);
    writePosition(Door.Left,1);
    writePosition(Door.Right,1);

    % have matlab interface with the user
    prompt = 'Did all doors work properly? [Y/N] ';
    str = input(prompt,'s');
    
    % redefine answer variable
    answer5 = str;
    
    if answer5 == 'N'
        % give user option for timing it would take to fix the set up or if
        % they want to cancel and re-run
        prompt = 'Enter "T" for time to fix or "C" if you want to cancel and re-run [T/C] ';
        str = input(prompt,'s');
        answer6 = str;
        % interface with user
        if answer6 == 'T'
            prompt = 'Enter time in seconds (i.e. 60 seconds for 1 minute) ';
            countdown_start = input(prompt);
        elseif answer6 == 'C'
            disp('re-run this script')
            break
        end
    else
        disp('servo motors for doors work properly')
    end
end

end
