% clear all
% filenames = cell(1, 10);
% for i = 1:10
%     filenames{i} = sprintf('/Users/shohgookazaki/Documents/GitHub/test-open/TA/BZ--%04d.CSV', 900 + i);
% end
for i = 13:14
file = sprintf('/Users/shohgookazaki/Documents/UTokyo/OnoTanabeLab/TA/WAVE/BZ-C%04d.CSV', i);


M = readmatrix( file );

scaling = 100; % scaling of data
Fs = 1.00E09; % sampling frequency
t = 0:1/Fs:1/Fs*(size(M,1)-1);%5.00E-04; % time series
v_coil_raw = M(:,3);
v_i_raw = M(:,2);
v_coil_raw = v_coil_raw(1:scaling:end);
v_i_raw = v_i_raw(1:scaling:end);
t = t(1:scaling:end);
Fs = Fs/scaling;
len_freq = length(t);

% smoothing and filtering
perc = 0.02; % span used in smoothing
windowSize = 5; % window size in filtering
b = (1/windowSize)*ones(1,windowSize);
a = 1;
smoothed = smooth(v_coil_raw,perc,'rloess');
filtered_and_smoothed = filter(b,a,smoothed);

% fft
y_fft = fft(v_coil_raw);
P2 = abs(y_fft/len_freq);
P1 = P2(1:(len_freq-1)/2+1);
P1(2:end-1) = 2*P1(2:end-1);

y_fft_Ri = fft(v_i_raw);
P2_Ri = abs(y_fft_Ri/len_freq);
P1_Ri = P2_Ri(1:(len_freq-1)/2+1);
P1_Ri(2:end-1) = 2*P1_Ri(2:end-1);

f = Fs*(0:floor(len_freq/2))/len_freq;

% plotting
% figure
% subplot(2,2,1)
% hold on
% plot(t,filtered_and_smoothed,'LineWidth',1);
% scatter(t,v_coil_raw,1);
% xlabel("Time (t)")
% ylabel("Coil signal (V)")
% hold off
% subplot(2,2,2)
% scatter(t,v_i_raw,1);
% xlabel("Time (t)")
% ylabel("R_i signal (V)")
% subplot(2,2,3)
% plot(f(1:min(100,length(f))),P1(1:min(100,length(P1))))
% xlabel("f (Hz)")
% ylabel("Amplitude (V)")
% subplot(2,2,4)
% plot(f(1:min(100,length(f))),P1_Ri(1:min(100,length(P1_Ri))))
% xlabel("f (Hz)")
% ylabel("Amplitude (V)")

% calculate rms and peak
rms_raw = rms(v_coil_raw);
rms_smoothed = rms(filtered_and_smoothed);
[max_vcoil, i_of_max_vcoil] = max(P1);
[max_vri, i_of_max_vri] = max(P1_Ri);
a = 0.04; % コイル間、コイル半径
n = 50; % コイル巻き数
r = 0.1; % 標準抵抗
u_0 = 4*pi*10^-7;
helmholtz_const = (4/5)^(3/2)*u_0/a; % 2.08001E-05;
B_rms = max_vri*n/r/sqrt(2)*helmholtz_const;
NS = (max_vcoil/sqrt(2))/(2*pi*f(i_of_max_vri)*B_rms);

disp(i);
disp(strcat('rms_Vcoil_raw = ', num2str(rms_raw)));
disp(strcat('rms_Vcoil_smoothed = ', num2str(rms_smoothed)));
disp(strcat('rms_fft_Vcoil_peak = ', num2str(max_vcoil/sqrt(2))));
disp(strcat('rms_fft_Ri_peak = ', num2str(max_vri/sqrt(2))));
disp(strcat('frequency = ', num2str(f(i_of_max_vri))));
disp(strcat('NS = ', num2str(NS),' m^2'));
disp(string(file));
disp('-------------------------');
end 