function [] = plot_ionflow(IDSPdata,EXP,IDSP,pathname,factor,overlay_plot,save_fig,cal_type)
%IDSPdata/実験条件/IDSP変数/pathname/矢印サイズ(数値:0.05など)/磁気面に重ねる/figを保存/流速計算方法
r_start = 1;
r_end = 7;

time = round(IDSP.delay+IDSP.width/2);%計測時刻
if overlay_plot%磁気面と重ねる
    unit = 1;%単位変換しない
else
    unit = 1e2;%単位をmからcmに変換
    if save_fig
        figure('Position',[300 150 600 600],'visible','on')
    else
        figure('Position',[300 150 600 600],'visible','on')
    end
end
IDSP.z = IDSP.z * unit;
IDSP.r = IDSP.r * unit;
factor = factor * unit;

%温度カラーマップ
T_icon = repmat(IDSPdata.T_i(:,1),1,5);%等高線図用平均イオン温度
zcon = IDSP.z(1,1);
s = pcolor([zcon-0.02*unit zcon-0.01*unit zcon zcon+0.01*unit zcon+0.02*unit],IDSP.r,T_icon);
s.FaceColor = 'interp';
s.EdgeAlpha = 0;
colormap('jet')
colorbar
% clim([0 150])
hold on

% plot(IDSP.z,IDSP.r,'xr');%ドップラープローブ計測点を表示
plot(IDSP.z(r_start:r_end,1),IDSP.r(r_start:r_end,1),'xk');%ドップラープローブ計測点を表示
hold on
if IDSP.n_z == 1
    q = quiver(IDSP.z(r_start:r_end,1),IDSP.r(r_start:r_end,1),IDSPdata.V_i(r_start:r_end,1)*factor,IDSPdata.V_i(r_start:r_end,2)*factor);
end
if IDSP.n_z == 2
    q = quiver(IDSP.z(r_start:r_end,1),IDSP.r(r_start:r_end,1),[IDSPdata.V_i(r_start:r_end,1),IDSPdata.V_i(r_start:r_end,3)]*factor,[IDSPdata.V_i(r_start:r_end,2),IDSPdata.V_i(r_start:r_end,4)]*factor);
end
q.LineWidth = 2;
q.MaxHeadSize = 10;
q.AutoScale = 'off';
q.Color = 'r';
IDSPdata.absV = round(IDSPdata.absV,1);
for j = 1:IDSP.n_z
    for i = r_start:r_end
        % txtstr = num2str(IDSPdata.absV(i,j));
        switch cal_type
            case 'ionflow'
                txtstr_Vi = sprintf('V_z = %.1f±%.1f\nV_r = %.1f±%.1f',IDSPdata.V_i(i,(j-1)*2+1),IDSPdata.err_V_i(i,(j-1)*2+1),IDSPdata.V_i(i,(j-1)*2+2),IDSPdata.err_V_i(i,(j-1)*2+2));
                txtstr_Ti = sprintf('T_i = %.1f±%.1f',IDSPdata.T_i(i,j),IDSPdata.err_T_i(i,j));
                txt_Ti = text(IDSP.z(i,j)-0.1*unit,IDSP.r(i,j)+0.005*unit,txtstr_Ti);
                txt_Ti.FontSize = 18;
                txt_Ti.Color = 'b';
                txt_Ti.FontWeight = 'bold';
            case 'ionvdist'
                txtstr_Vi = sprintf('V_z = %.1f\nV_r = %.1f',IDSPdata.V_i(i,(j-1)*2+1),IDSPdata.V_i(i,(j-1)*2+2));
        end
        txt_Vi = text(IDSP.z(i,j)+0.05*unit,IDSP.r(i,j)+0.005*unit,txtstr_Vi);
        txt_Vi.FontSize = 18;
        txt_Vi.Color = 'r';
        txt_Vi.FontWeight = 'bold';
    end
end
if overlay_plot
    s.FaceAlpha = 0.3;%透明度(0で完全に透明)
    xlim([-0.17 0.17])
    ylim([0.06 0.33])
    % xlim([-0.04 0.02])
    % ylim([0.125 0.275])
    % xticks([-0.04 -0.01 0.02])
    % yticks(0.15:0.05:0.25)
    daspect([1 1 1])
    ax = gca;
    ax.FontSize = 16;
    title([num2str(time),' [us]'])
    % ax.FontSize = 18;
    % title(['shot', num2str(ICCD.shot),'-',num2str(time),' [us] Ion Flow [km/s]',newline,'PF1 = ',num2str(EXP.PF1), ...
    %     ' [kV], PF2 = ',num2str(EXP.PF2),' [kV], TF = ',num2str(EXP.TF),' [kV], EF = ',num2str(EXP.EF),' [A]'] ...
    %     ,'Color','black','FontWeight','bold')
    if save_fig
        if IDSP.shot > 0
            saveas(gcf,[pathname.fig,'/',cal_type,'_psi/',num2str(IDSP.date),'_shot', num2str(IDSP.shot),'_',num2str(time),'us_PF1_',num2str(EXP.PF1), ...
                'kV_PF2_',num2str(EXP.PF2),'kV_TF_',num2str(EXP.TF),'kV_EF_',num2str(EXP.EF),'A.png'])
        elseif IDSP.shot == 0
            saveas(gcf,[pathname.fig,'/',cal_type,'_psi/',num2str(IDSP.date),'_shot', num2str(IDSP.shotlist(1)),'-',num2str(IDSP.shotlist(end)),'_',num2str(time),'us_PF1_',num2str(EXP.PF1), ...
                'kV_PF2_',num2str(EXP.PF2),'kV_TF_',num2str(EXP.TF),'kV_EF_',num2str(EXP.EF),'A.png'])
        end
        hold off
        close
    else
        hold off
    end
else
    xlim([min(IDSP.z,[],'all')-2.5 max(IDSP.z,[],'all')+2.5])
    ylim([min(IDSP.r,[],'all')-2.5 max(IDSP.r,[],'all')+2.5])
    % title(['shot', num2str(ICCD.shot),'-',num2str(time),' [us]', newline, 'Ion Flow [km/s]'],'Color','black','FontWeight','bold')
    if IDSP.shot > 0
        title(['shot', num2str(IDSP.shot),'-',num2str(time),' [us] Ion Flow [km/s]',newline,'PF1 = ',num2str(EXP.PF1), ...
            ' [kV], PF2 = ',num2str(EXP.PF2),' [kV]',newline,'TF = ',num2str(EXP.TF),' [kV], EF = ',num2str(EXP.EF),' [A]'] ...
            ,'Color','black','FontWeight','bold')
    elseif IDSP.shot == 0
        title(['shot', num2str(IDSP.shotlist(1)),'-',num2str(IDSP.shotlist(end)),'-',num2str(time),' [us] Ion Flow [km/s]',newline,'PF1 = ',num2str(EXP.PF1), ...
            ' [kV], PF2 = ',num2str(EXP.PF2),' [kV]',newline,'TF = ',num2str(EXP.TF),' [kV], EF = ',num2str(EXP.EF),' [A]'] ...
            ,'Color','black','FontWeight','bold')
    end
    xlabel('Z [cm]')
    ylabel('R [cm]')
    ax = gca;
    ax.FontSize = 10;
    grid on
    daspect([1 1 1])
    if save_fig
        if IDSP.shot > 0
            saveas(gcf,[pathname.fig,'/',cal_type,'/cal25_',num2str(IDSP.date),'_shot', num2str(IDSP.shot),'_',num2str(time),'us_PF1_',num2str(EXP.PF1), ...
                'kV_PF2_',num2str(EXP.PF2),'kV_TF_',num2str(EXP.TF),'kV_EF_',num2str(EXP.EF),'A.png'])
        elseif IDSP.shot == 0
            saveas(gcf,[pathname.fig,'/',cal_type,'/cal25_',num2str(IDSP.date),'_shot', num2str(IDSP.shotlist(1)),'-',num2str(IDSP.shotlist(end)),'_',num2str(time),'us_PF1_',num2str(EXP.PF1), ...
                'kV_PF2_',num2str(EXP.PF2),'kV_TF_',num2str(EXP.TF),'kV_EF_',num2str(EXP.EF),'A.png'])
        end
        hold off
        close
    else
        hold off
    end
end
end