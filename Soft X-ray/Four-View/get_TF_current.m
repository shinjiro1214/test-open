function [I_TF,x,aquisition_rate] = get_TF_current(PCB,pathname)

directory_rogo = strcat(pathname.fourier,'rogowski/');

% shot = convert_shot_number(PCB);
shot = PCB.idx;
date = PCB.date;
aquisition_rate = 10;
offset = 0;
% rogowski(date,aquisition_rate,offset,shot,directory_rogo);

if date == 230920
    date = 230929;
    shot = 8;
end

t_start = 1; % us
t_end = 1000; % us

t_start=t_start-offset;t_end=t_end-offset; % set offset
time_step = 1;%0.2; % us; time step of plot; must be an integer times of time step of raw data; larger time step gives faster plotting.
%calibration = [1, -1516.4, 1, 1, 1533.2, 80, 140, 480, 1, 1,]; % calibration for each channel. I'm not sure about the exact calibration coefficient.
% calibration = [1, -1, 1, 1, 1, 1, 1, 1, 1, 1,]; % calibration for each channel. I'm not sure about the exact calibration coefficient.
% calibration = [116.6647, -1, 1, 1, 1, 1, 63.9568, 1, 1, 1,]; % calibration for each channel. I'm not sure about the exact calibration coefficient.
calibration = 116.6647; % calibration factor for TF coil

[date_str,shot_str,path] = directory_generation_Rogowski(date,shot,directory_rogo);

% transfer all rgw file to txt file; do nothing if there is no rgw file in the folder
% rgw2txt(date_str,'mag_probe');
% rgw2txt(date_str);

% rgw2txt_shot(date_str,shot_str,directory_rogo);

current_folder = strcat(directory_rogo,date_str,'/');
path = strcat(current_folder,date_str,shot_str,'.rgw');

if ~isfile(path)
    disp(strcat('No such file: ',path));
    return
elseif (t_start<0)
    disp('offset should be smaller than t_start!');
    return
elseif aquisition_rate * time_step < 1
    disp('time resolution should be < aquisition rate!');
    return
end
    
% data = readmatrix(path);
data = readmatrix(path,"FileType","text");
step = aquisition_rate * time_step;
x = t_start * aquisition_rate : step : t_end * aquisition_rate;
I_TF = data(x,2+2)*calibration;
% figure;plot(x,I_TF);

end

function [date_str,shot_str,data_dir] = directory_generation_Rogowski(date,shot,directory_rogo)
    date_str = num2str(date);
    if shot < 10
        data_dir = [directory_rogo,date_str,'/',date_str,'00',num2str(shot),'.txt'];
        shot_str = ['00',num2str(shot)];
    elseif shot < 100
        data_dir = [directory_rogo,date_str,'/',date_str,'0',num2str(shot),'.txt'];
        shot_str = ['0',num2str(shot)];
    elseif shot < 1000
        data_dir = [directory_rogo,date_str,'/',date_str,num2str(shot),'.txt'];
        shot_str = num2str(shot);
    else
        disp('More than 999 shots! You need some rest!!!');
        return
    end
end


function [] = rgw2txt_shot(date_str,shot_str,directory_rogo)

% current_folder = strcat('/Users/shinjirotakeda/mountpoint/',date,'/');
current_folder = strcat(directory_rogo,date_str,'/');
filename = strcat(current_folder,date_str,shot_str,'.rgw');
rename = strcat(current_folder,date_str,shot_str,'.txt');
if isfile(rename)
    return
end
copyfile(filename,rename);

end