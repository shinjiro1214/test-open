function [] = plot_ESP_on_PCB(ESP,ESPdata2D,pathname)
addpath(fullfile(pathname.github,'test-open','Soft X-ray','Four-View'));
PCB.type = 1;
PCB.doOverwrite = false;
PCB.trange = 400:800;
PCB.n = 40;
PCB.start = 50;
PCB.dt = 3;
PCB.idx = 29;
PCB.shot = [3597 2071];
PCB.tfshot = [3569 2043];
PCB.i_EF = 200;
PCB.TF = 4;
PCB.date = 240111;

% PCB.idx = 55;
% PCB.shot = [6136 4727];
% PCB.tfshot = [6093 4684];
% PCB.i_EF = 200;
% PCB.TF = 4;
% PCB.date = 250314;

% PCB.start = 71;
% PCB.dt = 1;
% PCB.idx = 41;
% PCB.shot = [2325 803];
% PCB.tfshot = [2287 765];
% PCB.i_EF = 150;
% PCB.TF = 4;
% PCB.date = 230828;

% PCB.idx = 37;
% PCB.date = 230830;
% PCB.shot = [2452 931];
% PCB.tfshot = [2417,896];
PCB.date = 230830;
PCB.tfshot = [2417,896];
% PCB.idx = 37;PCB.shot = [2452 931];
PCB.idx = 24;
if PCB.idx >= 17
    PCB.shot = PCB.tfshot+PCB.idx-2;
else
    PCB.shot = PCB.tfshot+PCB.idx-3;
end
PCB.i_EF = 200;
PCB.TF = 4;

% [grid2D,data2D] = process_PCBdata_280ch(PCB,pathname);
[grid2D,data2D] = process_PCBdata_200ch(PCB,pathname);
% [magAxisList,xPointList] = get_axis_x_multi(grid2D,data2D); %時間ごとの磁気軸、X点を検索
% プロット部分
figure('Position', [0 0 1500 1500],'visible','on');
dt = PCB.dt;
start = PCB.start;
% Et_t = zeros(1,16);
% times = start+dt:dt:start+dt*16;
start_t = PCB.trange(1) + PCB.start;
 for m=1:16 %図示する時間
     i=start+(m-1).*dt; %end
    %  t=trange(i);
    %  offset_t = knnsearch(ESP.trange',ESP.start_t);
     offset_t = knnsearch(ESP.trange',start_t);
     idx_t = offset_t+(m-1)*dt*10;
     subplot(4,4,m);
     contourf(ESPdata2D.phi_mesh_z,ESPdata2D.phi_mesh_r,squeeze(ESPdata2D.phi_grid(idx_t,:,:)),linspace(-240,240,100),'edgecolor','none');clim([-240 240]);
    % contourf(ESPdata2D.phi_mesh_z,ESPdata2D.phi_mesh_r,squeeze(ESPdata2D.Ez_grid(idx_t,:,:)),100,'edgecolor','none');
     colormap(redblue(3000));
    %  xlim([-0.1 0.1])
    %  ylim([0.12 0.32])
     pbaspect([1 1 1])
     hold on
    %  contour(grid2D.zq(1,:),grid2D.rq(:,1),smoothdata2(squeeze(data2D.psi(:,:,i)),"movmean",2),20,'black')
    contour(grid2D.zq(1,:),grid2D.rq(:,1),squeeze(data2D.psi(:,:,i)),20,'black')
     t=PCB.trange(i);
     title(string(t)+' us')
 end
%   for m=1:4 %図示する時間
%      i=start+(m-1).*dt; %end
%     %  t=trange(i);
%     %  offset_t = knnsearch(ESP.trange',ESP.start_t);
%      offset_t = knnsearch(ESP.trange',start_t);
%      idx_t = offset_t+(m-1)*dt*10;
%      subplot(2,2,m);
%      contourf(ESPdata2D.phi_mesh_z,ESPdata2D.phi_mesh_r,squeeze(ESPdata2D.phi_grid(idx_t,:,:)),linspace(-240,240,100),'edgecolor','none');clim([-240 240]);
%     % contourf(ESPdata2D.phi_mesh_z,ESPdata2D.phi_mesh_r,smoothdata(squeeze(ESPdata2D.Ez_grid(idx_t,:,:)),2),100,'edgecolor','none');
%     % contourf(ESPdata2D.phi_mesh_z,ESPdata2D.phi_mesh_r,smoothdata(squeeze(ESPdata2D.Er_grid(idx_t,:,:))),100,'edgecolor','none');
%      colormap(redblue(3000));
%     %  xlim([-0.1 0.1])
%     %  ylim([0.12 0.32])
%      pbaspect([1 1 1])
%      hold on
%      contour(grid2D.zq(1,:),grid2D.rq(:,1),squeeze(data2D.psi(:,:,i)),20,'black')
%      t=PCB.trange(i);
%      title(string(t)+' us')
%      ax = gca; ax.FontSize = 18;
%  end


end