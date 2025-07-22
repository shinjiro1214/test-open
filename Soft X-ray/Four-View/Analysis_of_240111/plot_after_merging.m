close all
% figPath = '/Users/shinjirotakeda/Library/CloudStorage/GoogleDrive-takeda-shinjiro234@g.ecc.u-tokyo.ac.jp/マイドライブ/SXR_DATA/ReconstructionResults_fig/LF_LR/240828/shot15/shot15_492us.fig';
% figPath = '/Users/shinjirotakeda/Library/CloudStorage/GoogleDrive-takeda-shinjiro234@g.ecc.u-tokyo.ac.jp/マイドライブ/SXR_DATA/ReconstructionResults_fig/LF_LR/240828/shot3/shot3_488us.fig';
figPath = '/Users/shinjirotakeda/Library/CloudStorage/GoogleDrive-takeda-shinjiro234@g.ecc.u-tokyo.ac.jp/マイドライブ/SXR_DATA/ReconstructionResults_fig/LF_LR/240828/shot7/shot7_498us.fig';

hfig = openfig(figPath,'invisible');
ax = findobj(hfig, 'Type', 'axes');
hContour = findobj(ax, 'Type', 'contour');

contour1 = hContour(2);
EE = get(contour1,'ZData');
mesh_z = get(contour1,'XData');
mesh_r = get(contour1,'YData');

contour2 = hContour(1);
psi = get(contour2,'ZData');
mesh_z_mag = get(contour2,'XData');
mesh_r_mag = get(contour2,'YData');

figure;contourf(mesh_z,mesh_r,EE,'LineStyle','none');hold on;
contourf(mesh_z_mag,mesh_r_mag,psi,'white','Fill','off');

% idx_mag = 25;
idx_mag = 24;
path_mag = getenv('pre_processed_directory_path');%計算結果の保存先（どこでもいい）
PCBfile = strcat(path_mag,'/',num2str(240111),sprintf('%03d',idx_mag),'_200ch.mat');
load(PCBfile,'data2D','grid2D');PCBdata.data2D=data2D;PCBdata.grid2D=grid2D;

rmin_psi = min(grid2D.rq,[],'all');
rmax_psi = max(grid2D.rq,[],'all');
zmin_psi = min(grid2D.zq,[],'all');
zmax_psi = max(grid2D.zq,[],'all');
psi_mesh_z = grid2D.zq;
psi_mesh_r = grid2D.rq;

t = 480;
t_idx = find(data2D.trange==t);
psi = data2D.psi(:,:,t_idx);
psi_min = min(min(psi));
psi_max = max(max(psi));
contour_layer = linspace(psi_min,psi_max,20);

figure;contourf(mesh_z,mesh_r,EE,'LineStyle','none');hold on;
contourf(interp_matrix(psi_mesh_z,3)+0.05,interp_matrix(psi_mesh_r,3)-0.03,interp_matrix(psi,3),contour_layer,'black','LineWidth',1,'Fill','off');
ylim([0.05 0.35]);xlim([-0.1 0.2]);