clear all
addpath '/Users/rsomeya/Documents/lab/matlab/common';
run define_path.m

date = 240829;%230830,230903,230523;
shot = 4;%22,6,8;
ch = [2];% 4 3 7 8];
calib(ch) = [116.6647*12];%-174.19*3/30*35.7,225.71*3,63.9568,223.2319];
FIG.start = 40;%0以上0.1の倍数(us)
FIG.end = 60;%FIG.start以上0.1の倍数(us)
FIG.smooth = 0;%移動平均長さ(1以下なら移動平均とらない)

rgw2txt(date,shot)
plot_rogowski(pathname,date,shot,ch,calib,FIG)
ylabel("I [kA・Turn]")
xlabel("Time [us]")
% legend("PF1","PF2","TF")
% legend("PF1","PF2")
% fontsize(60,"points")
% xlim([400 480])
% ylim([-40 110])
