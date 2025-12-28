function [I_FCPF2, I_FCTF2,x,aquisition_rate] = get_TF_current(PCB,pathname)

directory_rogo = strcat(pathname.fourier,'/rogowski/');

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

t_start=t_start-offset;
t_end=t_end-offset; % set offset
time_step = 1;%0.2; % us; time step of plot; must be an integer times of time step of raw data; larger time step gives faster plotting.
%calibration = [1, -1516.4, 1, 1, 1533.2, 80, 140, 480, 1, 1,]; % calibration for each channel. I'm not sure about the exact calibration coefficient.
% calibration = [1, -1, 1, 1, 1, 1, 1, 1, 1, 1,]; % calibration for each channel. I'm not sure about the exact calibration coefficient.
% calibration = [116.6647, -1, 1, 1, 1, 1, 63.9568, 1, 1, 1,]; % calibration for each channel. I'm not sure about the exact calibration coefficient.
calibration_TF = 116.6647; % calibration factor for TF coil
calibration_FCPF1 = 82.0*1e3; % calibration factor for FCPF1 coil
calibration_FCPF2 = 81.1*1e3; % calibration factor for FCPF2 coil
calibration_FCTF2 = 217*1e3; % calibration factor for FCPT2 coil

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

if PCB.date >= 240400
    I_TF = data(x,2+2)*calibration_TF;
    I_FCPF1 = data(x,2+9)*calibration_FCPF1;
    I_FCPF2 = data(x,2+10)*-1*calibration_FCPF2;
    I_FCTF2 = data(x,2+12)*calibration_FCTF2;
else
    I_TF = data(x,1+2)*calibration_TF; 
end

%%%%%%%%%%%プラズマ応用工学の課題で使ったゾーン%%%%%%%%%%%
%240828 shot40 FCTF2, FCPF2使用
t = 405;%400;
limit = 600;
figure;hold on;
plot(x./10,I_FCPF1);
hold on;
plot(x./10,I_FCPF2);
xlabel('time [us]');ylabel('current [A]');
% ylim([-5e4 8e4]);
xlim([300 600]);

% 理論値計算
% An1 = 0.15134;%0.3966;%0.7169;%0.8786;
% An2 = 0.09345;%0.2552;%0.2049;%-0.5372;
% An3 = 0.2626;
% C = 18.75*1e-6;
% T = 87e-6;%77e-6;%86*1e-6;
% L = T^2/(4*C*((log(abs(An1)/abs(An2)))^2+pi^2));
% R = 4*L*log(abs(An1)/abs(An2))/T;
% V = 36e3;%28e3;%39e3;
% w = (1/(L*C)-(R/(2*L))^2)^0.5;

% cal = V/(w*L)*exp(-R/(2*L).*x./10.*1e-6).*sin(w.*x./10.*1e-6);
% plot(x(1:limit-t)./10+t,cal(1:limit-t),'r');
% legend('Signal','Theoretical');

% plot peak
% [peaks_max, locs_max] = findpeaks(I_FCPF2);
% [peaks_min, locs_min] = findpeaks(-I_FCPF2);
% hold on;
% plot(x(locs_max)./10,peaks_max,'r*');
% hold on;
% plot(x(locs_min)./10,-peaks_min,'r*');
% legend('Signal','Peaks');
hold off;

ax=gca;ax.FontSize=18;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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