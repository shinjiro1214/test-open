clearvars -except datalist_MC
addpath '/Users/rsomeya/Documents/lab/matlab/common';

%各PCのパスを定義
run define_path.m

%%ST40データ取り込み練習

%mdsplusのパスを通す
setenv('MDSPLUS_DIR','/usr/local/mdsplus');
addpath(fullfile(getenv('MDSPLUS_DIR'), 'matlab'));

read_data = true;
% shotlist = 11966;
shotlist = 12126;
errlist = [];
% shotlist = datalist_MC(:,1);%2:9 11:19 21:29 44:46 51:62 64
% errlist = [11954 11961 12150 12151 12167 12168 12169 12170 12130 12131 11966 11993];
shotlist = setdiff(shotlist, errlist);

plot_time = 0.01;%プロット時間[s]
r_max = 0.65;
FIG.tate = 1;
FIG.yoko = 1;
FIG.start = 7E-3;%プロット開始時刻[s]
FIG.dt = 4E-3;%プロット時刻間隔[s]

plot_type = 'psi';%'Ti_psi','psi'
cmap_type = 'Br';
mu0 = 4*pi*1E-7;
e = 1.6E-19;

if read_data
    cnt = 0;
    for i_shot = 1:numel(shotlist)
        shot_num = shotlist(i_shot);
        IDS_folder_name = [pathname.mat,'/ST40_IDS'];
        if not(exist(IDS_folder_name,'dir'))
            mkdir(IDS_folder_name)
        end
        IDS_savename = [IDS_folder_name,'/ST40_shot',num2str(shot_num),'.mat'];
        if exist(IDS_savename,"file")
            load(IDS_savename,'ST40IDSdata')
            MDS_folder_name = [pathname.mat,'/ST40_MDS'];
            if not(exist(MDS_folder_name,'dir'))
                mkdir(MDS_folder_name)
            end
            MDS_savename = [MDS_folder_name,'/ST40_shot',num2str(shot_num),'.mat'];
            if exist(MDS_savename,"file")
                load(MDS_savename,'ST40MDSdata')
                cnt = cnt +1;
                switch plot_type
                    case 'scatter'
                        if cnt == 1
                            figure('Position',[0 0 800 800])
                        end
                        idx_t_psi_7ms = knnsearch(ST40MDSdata.t_PSI,0.007);
                        Br_max = max(ST40MDSdata.Br(8:37,20:46,idx_t_psi_7ms),[],'all');
                        Ti_max = max(ST40IDSdata.Ti_Local(1:10,:),[],'all');
                        n_i_ST40 = 5*1E19;
                        h = plot(Br_max,3/2*Ti_max*n_i_ST40*e,'ro','MarkerSize',10,'LineWidth',3);
                        % drawnow
                        hold on
                        data = [shot_num Br_max Ti_max];
                        if cnt == 1
                            datalist = data;
                            hs = h;
                        else
                            datalist = [datalist;data];
                        end
                    case 'Ti_psi'
                        figure('Position',[0 0 800 800])
                        idx_r_max = knnsearch(ST40IDSdata.r,r_max);
                        contourf(ST40IDSdata.z,ST40IDSdata.r(1:idx_r_max),ST40IDSdata.Ti_Local(1:idx_r_max,:,1),100,'LineStyle','none');
                        colormap("jet")
                        c = colorbar;
                        c.Label.String = 'T_i [eV]';
                        clim([100 350])
                        hold on
                        idx_t_psi = knnsearch(ST40MDSdata.t_PSI,ST40IDSdata.t*1E-3);
                        contour(ST40MDSdata.zq,ST40MDSdata.rq,ST40MDSdata.psi(:,:,idx_t_psi),[-0.4:2E-2:0.09],'k')
                        xlabel('Z [m]')
                        ylabel('R [m]')
                        view([90 -90])%RZ反転
                        fontsize(30,"points")
                        xlim([-0.5 0.5])
                        xticks(-0.5:0.25:0.5)
                        ylim([-inf 0.8])
                        daspect([1 1 1])
                        title(['shot',num2str(shot_num),' - ',num2str(ST40IDSdata.t),'ms'])
                end
            end
        else
            % %ST40に接続
            % mdsconnect('87.224.94.202:8000');
            % % shotにアクセス
            % mdsopen('ST40',shot_num);
            % %データ取得
            % d_MC=mdsvalue("_d_MC="+'.PSU.MC:I');
            % d_Ip=mdsvalue("_d_Ip="+'.PFIT.POST_BEST.RESULTS.GLOBAL:IP');
            % d_TF=mdsvalue("_d_TF="+'.PSU.TF:I_REF');
            % d_PSI=mdsvalue("_d_PSI="+'.EFIT.BEST.PSI2D:PSI');
            % psi = d_PSI*(2*pi);%単位の補正
            % %データに対応する時刻を取得
            % t_MC = mdsvalue("dim_of(_d_MC)");
            % t_Ip = mdsvalue("dim_of(_d_Ip)");
            % t_TF = mdsvalue("dim_of(_d_TF)");
            % rq = mdsvalue("dim_of(_d_PSI,0)");
            % zq = mdsvalue("dim_of(_d_PSI,1)");
            % t_PSI = mdsvalue("dim_of(_d_PSI,2)");
            %
            % Br = zeros(size(psi));
            % Bz = zeros(size(psi));
            % Bt = zeros(size(psi));
            % for i_t = 1:size(psi,3)
            %     idx_t_TF = knnsearch(t_TF,t_PSI(i_t));
            %     [Br(:,:,i_t),Bz(:,:,i_t)]=gradient(psi(:,:,i_t),zq,rq);
            %     for i_r = 1:size(psi,1)
            %         Br(i_r,:,i_t)=-Br(i_r,:,i_t)/(2*pi*rq(i_r));
            %         Bz(i_r,:,i_t)=Bz(i_r,:,i_t)/(2*pi*rq(i_r));
            %         Bt(i_r,:,i_t)=24*mu0*d_TF(idx_t_TF)/(2*pi*rq(i_r));%TF24ターン
            %     end
            % end
            % absBp = sqrt(Br.^2+Bz.^2);
            % absB = sqrt(absBp.^2+Bt.^2);
            %
            % ST40MDSdata =struct(...
            %     'psi',psi,...
            %     'Br',Br,...
            %     'Bz',Bz,...
            %     'Bt',Bt,...
            %     'absBp',absBp,...
            %     'absB',absB,...
            %     'zq',zq,...
            %     'rq',rq,...
            %     't_PSI',t_PSI,...
            %     'I_MC',d_MC,...
            %     'I_TF',d_TF,...
            %     'Ip',d_Ip,...
            %     't_MC',t_MC,...
            %     't_TF',t_TF,...
            %     't_Ip',t_Ip);
            % save(MDS_savename,'ST40MDSdata')
            % mdsclose;
            % mdsdisconnect;
        end
    end
end
switch plot_type
    case 'scatter'
        n_i_TS6 = 2*1E19;
        n_i_TS6_min = 1.5*1E19;
        n_i_TS6_max = 3*1E19;
        h = errorbar(0.04,3/2*40*n_i_TS6*e,3/2*(40*(n_i_TS6-n_i_TS6_min)+n_i_TS6*10)*e,3/2*(40*(n_i_TS6-n_i_TS6_min)+n_i_TS6*10)*e,0.005,0.005,'b+','MarkerSize',10,'LineWidth',3);
        hs = [hs h];
        hold on
        xx = linspace(0.001,1,1000);
        xx = xx';
        yy = 1E5*xx.^2;
        %平均値表示
        % plot(xx,yy,'k','LineWidth',3)
        % hold on
        %標準偏差表示
        errarea_y_neg = 5E4*xx.^2;
        errarea_y_pos = 2E4*xx.^2;
        ar_curve=area(xx,[yy-errarea_y_neg yy+errarea_y_pos]);
        set(ar_curve(1),'FaceColor','None','LineStyle',':','EdgeColor','k')
        set(ar_curve(2),'FaceColor','k','FaceAlpha',0.2,'LineStyle',':','EdgeColor','k')
        set(gca, 'XScale','log', 'YScale','log')
        xlim([1E-2 1])
        xlabel('B_{rec} [T]')
        ylabel('3/2・n_iT_{i} [J/m^3]')
        legendStrings = ["ST-40","TS-6"];
        lgd = legend(hs,legendStrings,'FontSize',20);
        fontsize(30,'points')
end
switch plot_type
    % case 'Ti_psi'
    %     figure('Position',[0 0 800 800])
    %     idx_r_max = knnsearch(ST40IDSdata.r,r_max);
    %     contourf(ST40IDSdata.z,ST40IDSdata.r(1:idx_r_max),ST40IDSdata.Ti_Local(1:idx_r_max,:,1),100,'LineStyle','none');
    %     colormap("jet")
    %     c = colorbar;
    %     c.Label.String = 'T_i [eV]';
    %     clim([100 350])
    %     hold on
    %     idx_t_psi = knnsearch(ST40MDSdata.t_PSI,plot_time);
    %     contour(ST40MDSdata.zq,ST40MDSdata.rq,ST40MDSdata.psi(:,:,idx_t_psi),[-0.4:2E-2:0.4],'k')
    %     xlabel('Z [m]')
    %     ylabel('R [m]')
    %     view([90 -90])%RZ反転
    %     fontsize(30,"points")
    %     xlim([-0.5 0.5])
    %     xticks(-0.5:0.25:0.5)
    %     ylim([-inf 0.8])
    %     daspect([1 1 1])
    case 'psi'
        figure('Position',[0 0 1500 1500])
        for i_plot=1:FIG.yoko*FIG.tate
            subplot_time = FIG.start+FIG.dt*(i_plot-1);
            subplot(FIG.tate,FIG.yoko,i_plot)
            idx_t_psi = knnsearch(ST40MDSdata.t_PSI,subplot_time);
            switch cmap_type
                case 'psi'
                    contourf(ST40MDSdata.zq,ST40MDSdata.rq,ST40MDSdata.psi(:,:,idx_t_psi),[-0.4:2E-2:0.09],'LineStyle','none')
                    colormap("jet")
                    c = colorbar;
                    c.Label.String = 'Psi [Wb]';
                    clim([-0.4 0.4])
                case 'Br'
                    contourf(ST40MDSdata.zq,ST40MDSdata.rq,ST40MDSdata.Br(:,:,idx_t_psi),[-0.6:1E-3:0.6],'LineStyle','none')
                    colormap("jet")
                    c = colorbar;
                    c.Label.String = 'B_r [T]';
                    clim([-0.25 0.25])
                case 'Bz'
                    contourf(ST40MDSdata.zq,ST40MDSdata.rq(5:end),ST40MDSdata.Bz(5:end,:,idx_t_psi),[-0.6:1E-3:0.6],'LineStyle','none')
                    colormap("jet")
                    c = colorbar;
                    c.Label.String = 'B_z [T]';
                    clim([-0.6 0.6])
                case 'Bp'
                    contourf(ST40MDSdata.zq,ST40MDSdata.rq(5:end),ST40MDSdata.absBp(5:end,:,idx_t_psi),[0:1E-3:0.6],'LineStyle','none')
                    colormap("jet")
                    c = colorbar;
                    c.Label.String = 'B_p [T]';
                    clim([0 0.6])
                case 'Bt'
                    contourf(ST40MDSdata.zq,ST40MDSdata.rq,ST40MDSdata.Bt(:,:,idx_t_psi),[0:1E-2:5],'LineStyle','none')
                    colormap("jet")
                    c = colorbar;
                    c.Label.String = 'B_t [T]';
                    clim([0 5])
            end
            hold on
            contour(ST40MDSdata.zq,ST40MDSdata.rq,ST40MDSdata.psi(:,:,idx_t_psi),[-0.4:2E-2:0.1],'k')
            title([num2str(ST40MDSdata.t_PSI(idx_t_psi)*1E3),' ms'])
            xlabel('Z [m]')
            ylabel('R [m]')
            view([90 -90])%RZ反転
            % fontsize(20,"points")
            xlim([-0.5 0.5])
            xticks(-0.5:0.25:0.5)
            ylim([-inf 0.8])
            daspect([1 1 1])
        end
end

% figure('Position',[0 0 800 600])
% tiledlayout(1,3)
% if isnumeric(ST40MDSdata.t_MC)
%     idx_t_MC_0 = knnsearch(ST40MDSdata.t_MC,0);
%     I_MC_0 = ST40MDSdata.I_MC(idx_t_MC_0);
%     nexttile
%     plot(ST40MDSdata.t_MC,ST40MDSdata.I_MC)
%     xlim([-0.01 0.02])
%     title(['MC current - shot',num2str(shot_num)])
%     xlabel('Time [s]')
%     ylabel('MC current [A]')
% end
% if isnumeric(ST40MDSdata.t_Ip)
%     idx_t_Ip_4ms = knnsearch(ST40MDSdata.t_Ip,0.004);
%     idx_t_Ip_6ms = knnsearch(ST40MDSdata.t_Ip,0.006);
%     Ip_max = max(ST40MDSdata.I_Ip(idx_t_Ip_4ms:idx_t_Ip_6ms),[],'all');
%     nexttile
%     plot(ST40MDSdata.t_Ip,ST40MDSdata.I_Ip)
%     xlim([-0.01 0.02])
%     title(['I_p - shot',num2str(shot_num)])
%     xlabel('Time [s]')
%     ylabel('I_p [A]')
% end
% if isnumeric(ST40MDSdata.t_PSI)
%     idx_t_TF_0 = knnsearch(ST40MDSdata.t_PSI,0);
%     I_TF_0 = ST40MDSdata.I_TF(idx_t_TF_0);
%     nexttile
%     plot(ST40MDSdata.t_PSI,ST40MDSdata.I_TF)
%     xlim([-0.01 0.02])
%     title(['I_p - shot',num2str(shot_num)])
%     xlabel('Time [s]')
%     ylabel('TF curent [A]')
% end
%
