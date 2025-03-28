clear all
close all
addpath '/Users/rsomeya/Documents/lab/matlab/common';
run define_path.m
%
% %--【Input】----
% date = 240313;%校正実験日
% calib_CHlist = [49];%校正CH番号リスト
plot_cont = false;%等高線図を描画
% cal_CH1 = true;%1st用CH位置特定
% cal_1st = true;%1stピーク特定
% cal_CH2 = true;%2nd用CH位置特定
% cal_2nd = true;%2ndピーク特定
% cal_CH3 = true;%2nd用CH位置特定
% cal_3rd = true;%2ndピーク特定
% save_fit = false;%フィッティングをpngで保存
% save_cal = false;%校正結果をmatで保存
% N_CH = 1;%校正CH総数(基本的には1)
% width = 6;%チャンネル切り取り幅
% th_ratio = 0.8;
% l_mov = 15;

% filename = '/Users/rsomeya/Desktop/TE/240326/Ne_center_top.asc';
% bg_name = '/Users/rsomeya/Desktop/TE/240328/bg_gain=2000_for_240326.asc';

filename = '/Users/rsomeya/Desktop/TE/240325/slit2.asc';
bg_name = '/Users/rsomeya/Desktop/TE/240325/slit2_bg.asc';


%-----ファイル読み込み----
rawdata = importdata(filename);
bg = importdata(bg_name);
data = rawdata - bg;
data = data(:,2:1025);%データ1列目は通し番号なので切り捨てる

%----配列定義----
ax_pixel = transpose(linspace(1,1024,1024));%1~1024の整数軸

%-----ICCD生データをプロット-----
if plot_cont
    figure
    contour(ax_pixel,ax_pixel,data)
    xlabel('Pixel number in CH direction')
    ylabel('Pixel number in Lambda direction')
    hold off
end

spectrum = transpose(sum(data(:,406:412),2));
figure
plot(ax_pixel,spectrum,'b','LineWidth',2)
xlim([300 700])
ax = gca;
ax.FontSize = 20;

