function [] = plot_ESP_on_PCB(ESP,ESPdata2D,pathname)
addpath(fullfile(pathname.github,'test-open','Soft X-ray','Four-View'));
PCB.type = 1;
PCB.doOverwrite = false;
PCB.trange = 400:800;
PCB.n = 40;
PCB.start = 61;
PCB.dt = 1;
PCB.idx = 29;
PCB.shot = [3597 2071];
PCB.tfshot = [3569 2043];
PCB.i_EF = 200;
PCB.TF = 4;
PCB.date = 240111;
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
     xlim([-0.1 0.1])
     ylim([0.12 0.32])
     pbaspect([1 1 1])
     hold on
     contour(grid2D.zq(1,:),grid2D.rq(:,1),squeeze(data2D.psi(:,:,i)),20,'black')
     t=PCB.trange(i);
     title(string(t)+' us')
 end

end