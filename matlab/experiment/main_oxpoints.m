
clear all
% close all
addpath '/Users/rsomeya/Documents/lab/matlab/common'
run define_path.m

plot_psi = true;%磁気面をプロット
plot_ratio = true;%合体率をプロット

num_data = 1;%【input】比較条件数
filename_PCB = strings(num_data,1);%比較したいmain_pcb_statistics.mで作ったmatファイルリスト
% filename_STA = strings(num_data,1);%比較したいmain_pcb_statistics.mで作ったmatファイルリスト
filename_PCB(1) = [pathname.processeddata,'/a039_2437.mat'];%【input】磁気プローブ統計data1
labellist = ["data"];
labellist2 = ["data"];

%TFスキャン
% filename_PCB(1) = [pathname.processeddata,'/a039_4851.mat'];%【input】磁気プローブ統計data1
% filename_PCB(2) = [pathname.processeddata,'/a039_4912.mat'];%【input】磁気プローブ統計data1
% filename_PCB(3) = [pathname.processeddata,'/a039_4893.mat'];%【input】磁気プローブ統計data1
% filename_STA(1) = [pathname.mat,'/PCB_STA/240827_shot11-20_22-45_47-51_450-500.mat'];%【input】磁気プローブ統計data1
% filename_STA(2) = [pathname.mat,'/PCB_STA/240828_shot30-41_43-46_48-54_450-500.mat'];%【input】磁気プローブ統計data2
% filename_STA(3) = [pathname.mat,'/PCB_STA/240828_shot3-12_14-22_25-29_450-500.mat'];%【input】磁気プローブ統計data3
% labellist = ["B_t = 0.20 T","B_t = 0.25 T","B_t = 0.30 T"];
% labellist2 = ["B_t = 0.20 T","B_t = 0.25 T　(+3us)","B_t = 0.30 T (+5us)"];

%データ読み込み
for i_data = 1:num_data
    load(filename_PCB(i_data));
    multi_PCBgrid2D(i_data) = PCBgrid2D;
    multi_PCBdata2D(i_data) = PCBdata2D;

    % load(filename_STA(i_data));
    % multi_PCBgrid2D(i_data) = PCB_STAgrid2D;
    % multi_PCBdata2D(i_data) = PCB_STAdata2D;
end

FIG.tate = 2;
FIG.yoko = 4;
FIG.dt = 4;
FIG.start = 462;
mergin = 5;

for i_data = 1:num_data
    trange = multi_PCBdata2D(i_data).trange;
    zq = multi_PCBgrid2D(i_data).zq(2:end-3,4+mergin:end-1-mergin);
    rq = multi_PCBgrid2D(i_data).rq(2:end-3,4+mergin:end-1-mergin);
    psi = multi_PCBdata2D(i_data).psi(2:end-3,4+mergin:end-1-mergin,:);
    if not(isfield(multi_PCBdata2D(i_data),'o1_psi'))
        multi_PCBdata2D(i_data).o1_psi = zeros(numel(trange),1);%磁気軸1のpsi
        multi_PCBdata2D(i_data).o2_psi = zeros(numel(trange),1);%磁気軸2のpsi
        multi_PCBdata2D(i_data).x_pos = zeros(numel(trange),1);%X点のpsi
        multi_PCBdata2D(i_data).m_ratio = zeros(numel(trange),1);%合体率
        multi_PCBdata2D(i_data).o1_pos = zeros(numel(trange),1);%磁気軸1(z,r)
        multi_PCBdata2D(i_data).o2_pos = zeros(numel(trange),1);%磁気軸2(z,r)
        multi_PCBdata2D(i_data).x_pos = zeros(numel(trange),1);%X点(z,r)

        idx_x_r = zeros(numel(trange),1);
        idx_x_z = zeros(numel(trange),1);
        idx_o1_r = zeros(numel(trange),1);
        idx_o1_z = zeros(numel(trange),1);
        idx_o2_r = zeros(numel(trange),1);
        idx_o2_z = zeros(numel(trange),1);
        x_psi = zeros(numel(trange),1);%X点のpsi
        o1_psi = zeros(numel(trange),1);%磁気軸1のpsi
        o2_psi = zeros(numel(trange),1);%磁気軸2のpsi

        %O点探索
        for i_t =1:numel(trange)
            idx_t = knnsearch(multi_PCBdata2D(i_data).trange',trange(i_t));
            idx_z0 = knnsearch(zq(1,:)',0.02);
            psi_t = squeeze(psi(:,:,idx_t));
            left_psi = psi_t(:,1:idx_z0);
            [o1_psi(i_t,1), I1] = max(left_psi(:));
            [idx_o1_r(i_t,1), idx_o1_z(i_t,1)] = ind2sub(size(left_psi), I1);
            right_psi = psi_t(:,idx_z0:end);
            [o2_psi(i_t,1), I2] = max(right_psi(:));
            [idx_o2_r(i_t,1), idx_o2_z(i_t,1)] = ind2sub(size(right_psi), I2);
            idx_o2_z(i_t,1) = idx_o2_z(i_t,1) + idx_z0 - 1;
        end
        multi_PCBdata2D(i_data).o1_psi = o1_psi;
        multi_PCBdata2D(i_data).o1_pos(:,1) = zq(1,idx_o1_z);
        multi_PCBdata2D(i_data).o1_pos(:,2) = rq(idx_o1_r,1);
        multi_PCBdata2D(i_data).o2_psi = o2_psi;
        multi_PCBdata2D(i_data).o2_pos(:,1) = zq(1,idx_o2_z);
        multi_PCBdata2D(i_data).o2_pos(:,2) = rq(idx_o2_r,1);

        %X点探索
        for i_t =1:numel(trange)
            idx_t = knnsearch(multi_PCBdata2D(i_data).trange',trange(i_t));
            psi_t = squeeze(psi(:,:,idx_t));
            for i_z = idx_o1_z(i_t,1):idx_o2_z(i_t,1)
                if i_z == idx_o1_z(i_t,1)
                    [x_psi(i_t,1),idx_x_r(i_t,1)] = max(psi_t(:,i_z));
                    idx_x_z(i_t,1) = i_z;
                else
                    if max(psi_t(:,i_z)) < x_psi(i_t,1)
                        [x_psi(i_t,1),idx_x_r(i_t,1)] = max(psi_t(:,i_z));
                        idx_x_z(i_t,1) = i_z;
                    end
                end
            end
        end
        multi_PCBdata2D(i_data).x_psi = x_psi;
        multi_PCBdata2D(i_data).x_pos(:,1) = zq(1,idx_x_z);
        multi_PCBdata2D(i_data).x_pos(:,2) = rq(idx_x_r,1);
        multi_PCBdata2D(i_data).m_ratio = 2*multi_PCBdata2D(i_data).x_psi./(multi_PCBdata2D(i_data).o1_psi + multi_PCBdata2D(i_data).o1_psi);

        % PCBgrid2D = multi_PCBgrid2D(i_data);
        % PCBdata2D = multi_PCBdata2D(i_data);
        % save(filename_PCB(i_data),"PCBgrid2D","PCBdata2D")
        % PCB_STAgrid2D = multi_PCBgrid2D(i_data);
        % PCB_STAdata2D = multi_PCBdata2D(i_data);
        % save(filename_STA(i_data),"PCB_STAgrid2D","PCB_STAdata2D")
    end

    if plot_psi
        figure('Position', [0 0 1500 1500],'visible','on')
        for i_plot = 1:FIG.tate*FIG.yoko
            plot_time = FIG.start + FIG.dt*(i_plot-1);
            if plot_time > trange(1) && plot_time < trange(end)
                idx_contour_t = knnsearch(multi_PCBdata2D(i_data).trange',plot_time);
                idx_OX_t = knnsearch(multi_PCBdata2D(i_data).trange',plot_time);
                subplot(FIG.tate,FIG.yoko,i_plot)
                % contourf(multi_PCBgrid2D(i_data).zq(1,:),multi_PCBgrid2D(i_data).rq(:,1),squeeze(multi_PCBdata2D(i_data).psi(:,:,idx_contour_t)),[-20e-3:0.2e-3:40e-3],'black','LineWidth',1)
                contourf(zq(1,:),rq(:,1),squeeze(psi(:,:,idx_contour_t)),[-20e-3:0.2e-3:40e-3],'black','LineWidth',1)
                % contourf(zq(1,1:idx_x_z(i_t,1)),rq(:,1),left_psi,[-20e-3:0.2e-3:40e-3],'black','LineWidth',1)
                % figure
                % contourf(zq(1,idx_x_z(i_t,1):end),rq(:,1),right_psi,[-20e-3:0.2e-3:40e-3],'black','LineWidth',1)
                hold on
                plot(multi_PCBdata2D(i_data).x_pos(idx_OX_t,1),multi_PCBdata2D(i_data).x_pos(idx_OX_t,2),'kx','LineWidth',3)
                hold on
                plot(multi_PCBdata2D(i_data).o1_pos(idx_OX_t,1),multi_PCBdata2D(i_data).o1_pos(idx_OX_t,2),'bo','LineWidth',3)
                hold on
                plot(multi_PCBdata2D(i_data).o2_pos(idx_OX_t,1),multi_PCBdata2D(i_data).o2_pos(idx_OX_t,2),'ro','LineWidth',3)
                title([num2str(plot_time),'us'])
                xlabel('z [m]')
                ylabel('z [m]')
                daspect([1 1 1])
                colorbar
                clim([0 12E-3])
            end
        end
        sgtitle(labellist(i_data))
    end
end

% if plot_ratio
%     figure('Position', [0 0 1400 700],'visible','on')
%     labeltitle = [];
%     for i_plot = 1:4
%         labeltitle = [];
%         subplot(2,3,i_plot)
%         for i_data = 1:num_data
%             switch i_plot
%                 case 1
%                     plot(multi_PCBdata2D(i_data).trange, movmean(multi_PCBdata2D(i_data).x_psi,3),'LineWidth',3)
%                 case 2
%                     plot(multi_PCBdata2D(i_data).trange, movmean(multi_PCBdata2D(i_data).o1_psi,3),'LineWidth',3)
%                 case 3
%                     plot(multi_PCBdata2D(i_data).trange, movmean(multi_PCBdata2D(i_data).o2_psi,3),'LineWidth',3)
%                 case 4
%                     plot(multi_PCBdata2D(i_data).trange, movmean(multi_PCBdata2D(i_data).m_ratio,3),'LineWidth',3)
%             end
%             hold on
%             labeltitle = [labeltitle, labellist(i_data)];
%         end
%         legend(labeltitle)
%         xlim([455 490])
%         xticks(455:2:490)
%         xlabel('Time [us]')
%         fontsize(16,"points")
% 
%         switch i_plot
%             case 1
%                 ylim([1E-7 2E-3])
%                 ylabel('Psi in X-point')
%             case 2
%                 ylim([2E-3 6.5E-3])
%                 ylabel('Psi in O-point (-z)')
%             case 3
%                 ylim([2E-3 6.5E-3])
%                 ylabel('Psi in O-point (+z)')
%             case 4
%                 ylim([-0.05 0.6])
%                 % yticks(0:0.05:0.6)
%                 ylabel('Merging Ratio')
%         end
%         grid on
%     end
% end

%合体率
figure('Position', [0 0 700 700],'visible','on')
labeltitle = [];
for i_data = 1:num_data
    plot(multi_PCBdata2D(i_data).trange, movmean(multi_PCBdata2D(i_data).m_ratio,5),'LineWidth',3)
    hold on
    % labeltitle = [labeltitle, labellist(i_data)];
end
% legend(labeltitle,'Location','northwest')
xlim([440 480])
% xticks(460:2:480)
ylim([0 1])
% xticks(470:5:490)
xlabel('Time [us]')
fontsize(28,"points")
% ylim([-0.05 0.6])
ylabel('Reconnection Ratio')
grid on

% %合体率の増加速度
% figure('Position', [0 0 700 700],'visible','on')
% labeltitle = [];
% for i_data = 1:num_data
%     plot(multi_PCBdata2D(i_data).trange(2:end), movmean(diff(movmean(multi_PCBdata2D(i_data).m_ratio,3)),3),'LineWidth',3)
%     hold on
%     labeltitle = [labeltitle, labellist(i_data)];
% end
% legend(labeltitle,'Location','northwest')
% xlim([470 490])
% xticks(470:5:490)
% xlabel('Time [us]')
% fontsize(28,"points")
% ylim([-0.001 0.05])
% ylabel('Reconnection Ratio Velocity [/us]')
% grid on

% delaylist = [0 3 5];%【input】data1を基準0として、比較するデータ時間ずれ[us]
% %補正後合体率
% figure('Position', [0 0 700 700],'visible','on')
% labeltitle = [];
% for i_data = 1:num_data
%     plot(multi_PCBdata2D(i_data).trange-delaylist(i_data), movmean(multi_PCBdata2D(i_data).m_ratio,3),'LineWidth',3)
%     hold on
%     labeltitle = [labeltitle, labellist2(i_data)];
% end
% legend(labeltitle,'Location','northwest')
% xlim([470 490])
% xticks(470:5:490)
% xlabel('Time [us]')
% fontsize(28,"points")
% ylim([-0.05 0.6])
% ylabel('Reconnection Ratio')
% grid on

% %補正後合体率の増加速度
% figure('Position', [0 0 700 700],'visible','on')
% labeltitle = [];
% for i_data = 1:num_data
%     plot(multi_PCBdata2D(i_data).trange(2:end)-delaylist(i_data), movmean(diff(movmean(multi_PCBdata2D(i_data).m_ratio,3)),3),'LineWidth',3)
%     hold on
%     labeltitle = [labeltitle, labellist2(i_data)];
% end
% legend(labeltitle,'Location','northwest')
% xlim([470 490])
% xticks(470:5:490)
% xlabel('Time [us]')
% fontsize(28,"points")
% ylim([-0.001 0.05])
% ylabel('Reconnection Ratio Velocity [/us]')
% grid on


% start_t = 460;
% dt = 1;
% num_t = 30;
% time = zeros(num_t,num_data);
% Et_xp = zeros(num_t,num_data);
% labeltitle = [];
% figure('Position', [0 0 700 700],'visible','on')
% for i_data = 1:num_data
%     for i_t = 1:num_t
%         plot_time = start_t + (i_t-1)*dt;
%         time(i_t,i_data) = plot_time;
%         idx_t = knnsearch(multi_PCBdata2D(i_data).trange',plot_time);
%         idx_xp_z = knnsearch(multi_PCBgrid2D(i_data).zq(1,:)',multi_PCBdata2D(i_data).x_pos(idx_t,1));
%         idx_xp_r = knnsearch(multi_PCBgrid2D(i_data).rq(:,1),multi_PCBdata2D(i_data).x_pos(idx_t,2));
%         Et_xp(i_t,i_data) = multi_PCBdata2D(i_data).Et(idx_xp_r,idx_xp_z,idx_t);
%     end
%     labeltitle = [labeltitle, labellist(i_data)];
%     Et_xp(:,i_data) = movmean(Et_xp(:,i_data),3);
%     plot(time(:,i_data),Et_xp(:,i_data),'LineWidth',3)
%     hold on
% end
% legend(labeltitle)
% xlim([466 486])
% xticks(466:2:486)
% xlabel('Time [us]')
% fontsize(16,"points")
% ylim([-120 0])
% ylabel('E_t in X-point [V/m]')
