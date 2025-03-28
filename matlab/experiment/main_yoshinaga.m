% clear all
addpath '/Users/rsomeya/Documents/lab/matlab/common';
run define_path.m

shot = 20;%【Input】shot番号(15~26)

filename = ['/Users/rsomeya/Library/CloudStorage/OneDrive-TheUniversityofTokyo(2)/lab/mat/yoshinaga/shot',num2str(shot),'_variables.mat'];
load(filename,"z","r","Ti_local_smooth");

figure
contourf(z,r,Ti_local_smooth,[-10:0.1:50],'LineStyle','none')
colorbar
colormap("jet")
xlim([-0.02 0.02])
ylim([-inf 0.26])
clim([0 40])
