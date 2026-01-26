function [] = plot_ESP_on_PCB(ESP,ESPdata2D,pathname)
addpath(fullfile(pathname.github,'test-open','Soft X-ray','Four-View'));
% PCB = get_PCB_data(240111,29,450,2);
% PCB = get_PCB_data(240827,13,460,2);
% PCB = get_PCB_data(240828,16,460,2);
% PCB = get_PCB_data(240828,32,468,1);
PCB = get_PCB_data(230830,32,468,1);

% [grid2D,data2D] = process_PCBdata_280ch(PCB,pathname);
[grid2D,data2D] = process_PCBdata_200ch(PCB,pathname);
% [magAxisList,xPointList] = get_axis_x_multi(grid2D,data2D); %時間ごとの磁気軸、X点を検索
% プロット部分
figure('Position', [0 0 1500 1500],'visible','on');
dt = PCB.dt;
start = PCB.start;
% Et_t = zeros(1,16);
% times = start+dt:dt:start+dt*16;
start_t = PCB.trange(1) + PCB.start - 1;
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

function PCB = get_PCB_data(date,shotIDX,start,dt)
    PCB.type = 1;
    PCB.doOverwrite = false;
    PCB.trange = 400:800;
    PCB.n = 40;
    PCB.start = start-399;
    PCB.dt = dt;

    % date = 230828;shotIDX=41;
    % date = 230830;shotIDX=37;
    % date = 240111;shotIDX=29;
    % date = 240828;shotIDX=5;
    % date = 250314;shotIDX=55;
    DOCID='1wG5fBaiQ7-jOzOI-2pkPAeV6SDiHc_LrOdcbWlvhHBw';%スプレッドシートのID
    T=getTS6log(DOCID);
    node='date';
    % date=230714;
    T=searchlog(T,node,date);
    IDXlist = find(T.shot==shotIDX);
    % IDXlist= 1; %[5:50 52:55 58:59];%[4:6 8:11 13 15:19 21:23 24:30 33:37 39:40 42:51 53:59 61:63 65:69 71:74];
    % n_data=numel(IDXlist);%計測データ数
    shotlist_a039 =T.a039(IDXlist);
    shotlist_a040 = T.a040(IDXlist);
    shotlist = [shotlist_a039, shotlist_a040];
    tfshotlist_a039 =T.a039_TF(IDXlist);
    tfshotlist_a040 =T.a040_TF(IDXlist);
    tfshotlist = [tfshotlist_a039, tfshotlist_a040];
    EFlist=T.EF_A_(IDXlist);
    TFlist=T.TF_kV_(IDXlist);
    % dtacqlist=39.*ones(n_data,1);
    PCB.idx = shotIDX;
    PCB.shot=shotlist;
    PCB.tfshot=tfshotlist;
    if PCB.shot == PCB.tfshot
        PCB.tfshot = [0,0];
    end
    PCB.i_EF=EFlist;
    PCB.TF=TFlist;
    PCB.date = date;
end