function Bt = get_B_troidal(PCB,grid2D,data2D,pathname,time)

% [grid2D,data2D] = process_PCBdata_280ch(PCB,pathname);
directory_rogo = strcat(pathname.fourier,'/rogowski/');

shot = convert_shot_number(PCB);
date = PCB.date;
aquisition_rate = 10;
offset = 0;
% rogowski(date,aquisition_rate,offset,shot,directory_rogo);

t_start = 1; % us
t_end = 1000; % us

t_start=t_start-offset;t_end=t_end-offset; % set offset
time_step = 1;%0.2; % us; time step of plot; must be an integer times of time step of raw data; larger time step gives faster plotting.
%calibration = [1, -1516.4, 1, 1, 1533.2, 80, 140, 480, 1, 1,]; % calibration for each channel. I'm not sure about the exact calibration coefficient.
% calibration = [1, -1, 1, 1, 1, 1, 1, 1, 1, 1,]; % calibration for each channel. I'm not sure about the exact calibration coefficient.
% calibration = [116.6647, -1, 1, 1, 1, 1, 63.9568, 1, 1, 1,]; % calibration for each channel. I'm not sure about the exact calibration coefficient.
calibration = 116.6647; % calibration factor for TF coil

date_str = num2str(date);
rgwpath = strcat('/Users/shohgookazaki/Library/CloudStorage/GoogleDrive-shohgo-okazaki@g.ecc.u-tokyo.ac.jp/My Drive/OnoLab/data/rgw/',date_str);
if ~exist(rgwpath, 'dir')
    mkdir(rgwpath); % なければ作成
end
[shot_str,path] = directory_generation_Rogowski(date_str,shot,rgwpath);

% transfer all rgw file to txt file; do nothing if there is no rgw file in the folder
% rgw2txt(date_str,'mag_probe');
% rgw2txt(date_str);

rgw2txt_shot(date_str,shot_str,directory_rogo,rgwpath);

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
    
data = readmatrix(path);
step = aquisition_rate * time_step;
x = t_start * aquisition_rate : step : t_end * aquisition_rate;
I_TF = data(x,1+2)*calibration;


timing = x/aquisition_rate==time;
m0 = 4*pi*10^(-7);
[~,xpoint] = get_axis_x(grid2D,data2D,time);
r = xpoint.r;
Bt = m0*I_TF(timing)*1e3*12/(2*pi()*r);

end

function [shot_str,data_dir] = directory_generation_Rogowski(date_str,shot,rgwpath)
    
    if shot < 10
        data_dir = [rgwpath,'/',date_str,'00',num2str(shot),'.txt'];
        shot_str = ['00',num2str(shot)];
    elseif shot < 100
        data_dir = [rgwpath,'/',date_str,'0',num2str(shot),'.txt'];
        shot_str = ['0',num2str(shot)];
    elseif shot < 1000
        data_dir = [rgwpath,'/',date_str,num2str(shot),'.txt'];
        shot_str = num2str(shot);
    else
        disp('More than 999 shots! You need some rest!!!');
        return
    end
end


function [rename] = rgw2txt_shot(date_str,shot_str,directory_rogo,rgwpath)

% current_folder = strcat('/Users/shinjirotakeda/mountpoint/',date,'/');
current_folder = strcat(directory_rogo,date_str,'/');
filename = strcat(current_folder,date_str,shot_str,'.rgw');
% rename = strcat(current_folder,date_str,shot_str,'.txt');
rename = strcat(rgwpath,'/',date_str,shot_str,'.txt');

if isfile(rename)
    return
end
copyfile(filename,rename);


end