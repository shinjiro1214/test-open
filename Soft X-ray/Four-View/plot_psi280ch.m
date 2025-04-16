function plot_psi280ch(PCB,pathname)
shot = PCB.shot;
trange = PCB.trange;
start = PCB.start;

[grid2D,data2D] = process_PCBdata_280ch(PCB,pathname);
% [grid2D,data2D] = process_PCBdata_200ch(PCB,pathname);

% ***********************************************

if isstruct(grid2D)==0 %もしdtacqデータがない場合次のloopへ(データがない場合NaNを返しているため)
    return
end

[magAxisList,xPointList] = get_axis_x_multi(grid2D,data2D); %時間ごとの磁気軸、X点を検索

% プロット部分
figure('Position', [0 0 1500 1500],'visible','on');

% figure('Position', [0 0 1500 1500],'visible','on');
% start=30;
dt = PCB.dt;
%  t_start=470+start;
Et_t = zeros(1,16);
E_eff = zeros(1,16);
mergingRatio = zeros(1,16);
% PCB.type = 0;
times = trange(1)+start:dt:trange(1)+start+dt*15;
 for m=1:16 %図示する時間
     i=start+(m-1)*dt; %start+400μsからdtごとに取得
     t=trange(i+1); %startが60なら460μsのデータを取る
     subplot(4,4,m);

     switch(PCB.type)
        case 0
            contour(grid2D.zq(1,:),grid2D.rq(:,1),squeeze(data2D.psi(:,:,i)),10,'black','LineWidth',2);
        case 1
            contourf(grid2D.zq(1,:),grid2D.rq(:,1),data2D.psi(:,:,i),40,'LineStyle','none');clim([-5e-3,5e-3])%psi
        case 2
            contourf(grid2D.zq(1,:),grid2D.rq(:,1),data2D.Bz(:,:,i),30,'LineStyle','none');clim([-0.1,0.1])%Bz
        case 3
            % contourf(grid2D.zq(1,:),grid2D.rq(:,1),data2D.Bt(:,:,i),40,'LineStyle','none');clim([0,0.3])%Bt
            % contourf(grid2D.zq(1,:),grid2D.rq(:,1),data2D.Bt(:,:,i),-100e-3:0.5e-3:100e-3,'LineStyle','none')
            contourf(grid2D.zq(1,:),grid2D.rq(:,1),data2D.Bt_th(:,:,i),-100e-3:0.5e-3:100e-3,'LineStyle','none')
        case 4
            contourf(grid2D.zq(1,:),grid2D.rq(:,1),data2D.Br(:,:,i),30,'LineStyle','none');clim([-0.1,0.1])%Br
        case 5
            contourf(grid2D.zq(1,:),grid2D.rq(:,1),-1.*data2D.Et(:,:,i),20,'LineStyle','none');clim([-500,400])%Et
            % 時刻iにおけるx点の[r,z]座標（インデックス）を取得
            idxR = knnsearch(grid2D.rq(:,1),xPointList.r(i));
            idxZ = knnsearch(grid2D.zq(1,:).',xPointList.z(i));
            % ±3程度の範囲でEtの平均を計算
            Et_t(m) = mean(data2D.Et(max(1,idxR-1):min(idxR+1,numel(grid2D.rq(:,1))),max(1,idxZ-1):min(numel(grid2D.zq(1,:)),idxZ+1),i),'all');
        case 6
            contourf(grid2D.zq(1,:),grid2D.rq(:,1),-1.*data2D.Jt(:,:,i),30,'LineStyle','none');clim([-0.8*1e+6,0.8*1e+6]);%clim([-0.8*1e+6,0]) %jt%カラーバーの軸の範囲
        case 7
            Bp = sqrt(data2D.Bz(:,:,i).^2+data2D.Br(:,:,i).^2);
            % GFR = data2D.Bt_th(:,:,i)./Bp;
            % contourf(grid2D.zq(1,:),grid2D.rq(:,1),GFR,30,'LineStyle','none');clim([0,20]);%GFR
            % % 時刻iにおけるx点の[r,z]座標（インデックス）を取得
            % idxR = knnsearch(grid2D.rq(:,1),xPointList.r(i));
            % idxZ = knnsearch(grid2D.zq(1,:).',xPointList.z(i));
            % % ±3程度の範囲でGFRの平均（最大？）を計算
            % maxGFR = max(GFR(max(1,idxR-3):min(idxR+3,numel(grid2D.rq(:,1))),max(1,idxZ-3):min(numel(grid2D.zq(1,:)),idxZ+3)),[],'all');
            % disp(maxGFR);
            [zq,rq] = meshgrid(linspace(-0.1,0.1,200),linspace(0.2,0.32,200));
            Bp_q = griddata(grid2D.zq(1,:),grid2D.rq(:,1),Bp,zq,rq);
            Bt_th_q = griddata(grid2D.zq(1,:),grid2D.rq(:,1),data2D.Bt_th(:,:,i),zq,rq);
            Et_q = griddata(grid2D.zq(1,:),grid2D.rq(:,1),data2D.Et(:,:,i),zq,rq);
            GFR_q = abs(Bt_th_q./Bp_q);
            % contourf(zq(1,:),rq(:,1),GFR_q,50,'LineStyle','none');clim([0,50]);%GFR
            % disp(max(GFR_q,[],"all"))
            idxRq = knnsearch(rq(:,1),xPointList.r(i));
            idxZq = knnsearch(zq(1,:).',xPointList.z(i));
            E_eff_tmp = Et_q.*GFR_q;
            E_eff(m) = min(E_eff_tmp(max(1,idxRq-10):min(200,idxRq+10),max(1,idxZq-10):min(200,idxZq+10)),[],"all");
            contourf(zq(1,:),rq(:,1),-1*E_eff_tmp,50,'LineStyle','none');clim([1e3,Inf]);%GFR
            % Jt_q = griddata(grid2D.zq(1,:),grid2D.rq(:,1),data2D.Jt(:,:,i),zq,rq);
            % eta_q = Et_q./Jt_q;
            % contourf(zq(1,:),rq(:,1),eta_q,linspace(-1e-2,1e-2,50),'LineStyle','none');clim([-1e-2,1e-2]);%resistivity
            % maxGFRq = max(GFR_q(max(1,idxRq-3):min(idxRq+3,numel(rq(:,1))),max(1,idxZq-3):min(numel(zq(1,:)),idxZq+3)),[],'all');
            % disp(maxGFRq);
        case 8
            Bp = sqrt(data2D.Bz(:,:,i).^2+data2D.Br(:,:,i).^2);
            % contourf(grid2D.zq(1,:),grid2D.rq(:,1),Bp,30,'LineStyle','none');clim([0 0.1]);%Bp
            [zq,rq] = meshgrid(linspace(-0.1,0.1,200),linspace(0.2,0.32,200));
            Bp_q = griddata(grid2D.zq(1,:),grid2D.rq(:,1),Bp,zq,rq);
            contourf(zq(1,:),rq(:,1),Bp_q,50,'LineStyle','none');clim([0,0.01]);%GFR
            disp(min(Bp_q,[],"all"));
        case 9
            B = sqrt(data2D.Bz(:,:,i).^2+data2D.Br(:,:,i).^2+data2D.Bt_th(:,:,i).^2);
            contourf(grid2D.zq(1,:),grid2D.rq(:,1),B,30,'LineStyle','none');clim([0 1]);%Bp  
     end
     mergingRatio(m) = xPointList.psi(i)/min(magAxisList.psi(:,i));

     % ポロイダル磁場ベースでのプロット
     % Bp = sqrt((data2D.Br(:,:,i)).^2+(data2D.Bz(:,:,i)).^2);
     % contourf(grid2D.zq(1,:),grid2D.rq(:,1),Bp,30,'LineStyle','none');clim([0,0.02]);
     % contourf(grid2D.zq(1,:),grid2D.rq(:,1),abs(data2D.Bt(:,:,i)./data2D.Bz(:,:,i)),30,'LineStyle','none');clim([-1,1]);
     % sepa = zeros(size(data2D.psi(:,:,i)));
     % x_psi = xPointList.psi(i);
     % sepa(((data2D.psi(:,:,i)<=x_psi+5e-4&data2D.psi(:,:,i)>=x_psi-5e-5)|(data2D.psi(:,:,i)<=x_psi*1.1&data2D.psi(:,:,i)>=x_psi*0.9)))=1;
     % contourf(grid2D.zq(1,:),grid2D.rq(:,1),sepa,'LineStyle','none');
    % contourf(grid2D.zq(1,:),grid2D.rq(:,1),data2D.psi(:,:,i),40,'LineStyle','none');clim([-5e-3,5e-3])%psi
    % contourf(grid2D.zq(1,:),grid2D.rq(:,1),data2D.Bz(:,:,i),30,'LineStyle','none');clim([-0.1,0.1])%Bz
    % contourf(grid2D.zq(1,:),grid2D.rq(:,1),data2D.Br(:,:,i),30,'LineStyle','none');clim([-0.1,0.1])%Br
    % contourf(grid2D.zq(1,:),grid2D.rq(:,1),data2D.Bt(:,:,i),40,'LineStyle','none');clim([0,0.3])%Bt
    % contourf(grid2D.zq(1,:),grid2D.rq(:,1),data2D.Bt(:,:,i),-100e-3:0.5e-3:100e-3,'LineStyle','none')
    % contourf(grid2D.zq(1,:),grid2D.rq(:,1),-1.*data2D.Jt(:,:,i),30,'LineStyle','none');clim([-0.8*1e+6,0]);%clim([-0.8*1e+6,0.8*1e+6]) %jt%カラーバーの軸の範囲
    % contourf(grid2D.zq(1,:),grid2D.rq(:,1),-1.*data2D.Et(:,:,i),20,'LineStyle','none');clim([-500,400])%Et
    % contourf(grid2D.zq(1,:),grid2D.rq(:,1),-1.*data2D.Bt_th(:,:,i),20,'LineStyle','none');clim([0,0.3])%Bt
    colormap(jet)
    axis image
    axis tight manual
%     caxis([-0.8*1e+6,0.8*1e+6]) %jt%カラーバーの軸の範囲
    % clim([-0.1,0.1])%Bz
     % clim([0,0.3])%Bt
    % clim([-5e-3,5e-3])%psi
    % clim([-500,400])%Et
%     colorbar('Location','eastoutside')
    %カラーバーのラベル付け
%     c = colorbar;
%     c.Label.String = 'Jt [A/m^{2}]';
    hold on
%     plot(grid2D.zq(1,squeeze(mid(:,:,i))),grid2D.rq(:,1))
%     contour(grid2D.zq(1,:),grid2D.rq(:,1),squeeze(data2D.psi(:,:,i)),20,'black')

    contour(grid2D.zq(1,:),grid2D.rq(:,1),squeeze(data2D.psi(:,:,i)),20,'black')

    % contour(grid2D.zq(1,:),grid2D.rq(:,1),squeeze(data2D.psi(:,:,i)),[-20e-3:0.2e-3:40e-3],'black','LineWidth',1)
%     plot(grid2D.zq(1,squeeze(mid(opoint(:,:,i),:,i))),grid2D.rq(opoint(:,:,i),1),"bo")
%     plot(grid2D.zq(1,squeeze(mid(xpoint(:,:,i),:,i))),grid2D.rq(xpoint(:,:,i),1),"bx")
     % plot(ok_z,ok_r,"k.",'MarkerSize', 6)%測定位置

    % timeIndex = find(trange==t);
    % [magaxis,xpoint] = get_axis_x(grid2D,data2D,t);
    % plot(magaxis.z,magaxis.r,'ro');
    % plot(xpoint.z,xpoint.r,'rx');

    plot(magAxisList.z(:,i),magAxisList.r(:,i),'ko');
    plot(xPointList.z(i),xPointList.r(i),'kx');

    if PCB.type == 7 || PCB.type == 8
        xlim([-0.1,0.1]);ylim([0.2,0.32]);
    end
    hold off
    title(string(t)+' us')
%     xlabel('z [m]')
%     ylabel('r [m]')
 end

 sgtitle(strcat('shot',num2str(shot)));

 if PCB.type==5
     figure;plot(times,Et_t,'LineWidth',3);
     ax = gca;
     ax.FontSize = 18;
     xlabel('time [us]');ylabel('Reconnection electric field [V/m]');
 elseif PCB.type == 7
     figure;plot(times,E_eff,'LineWidth',3);
    xlabel('time [us]');
    %  figure;plot(mergingRatio,E_eff,'LineWidth',3);
    %  ax = gca;
    %  ax.FontSize = 18;
    % %  xlim([460 468]);
    %  xlabel('Merging ratio');
 end
 % drawnow

end