%%% cal & plot ExB drift velocity %%%
function ESPdata2D = cal_ESP(pathname,ESP)
dirPath_ESP = [pathname.ESP '/' num2str(ESP.date)];
ESPdataFile = fullfile(dirPath_ESP,'ESPdata.mat');
if exist(ESPdataFile,'file')
    disp('Loading ESPdata from:');
    disp(ESPdataFile);
    load(ESPdataFile,"ESPdata2D");
    doCalculation = false;
else
    disp('Start the calculation of ESPdata');
    doCalculation = true;
end

if doCalculation
    n_ch = 21;%静電プローブCH数
    res_ratio = 50;%静電プローブ分圧比

    z = linspace(-0.15,0.15,ESP.mesh);%プロットメッシュZ座標[m]
    z_probe = linspace(-0.15,0.15,21);%静電プローブ計測点Z座標[m]
    % ng_ch = [4 6 16];%死んだCH 230830
    % ng_ch = [4 6 16 20];%死んだCH 230828
    % ng_ch = [4,11,12,14:21];%死んだCH 240827
    ng_ch = [14:21];%死んだCH 240828
    z_probe(ng_ch) = [];
    r = linspace(min(ESP.rlist),max(ESP.rlist),ESP.mesh)*1E-3;%プロットメッシュR座標[m]
    r_probe = unique(ESP.rlist)*1E-3;%静電プローブ計測点R座標[m]

    phi = zeros(numel(ESP.trange),n_ch,numel(r_probe));
    cnt_r = zeros(numel(r_probe),1);
    for i = 1:numel(ESP.shotlist)
        idx_r = find(r_probe==ESP.rlist(i)*1E-3);
        cnt_r(idx_r) = cnt_r(idx_r) + 1;
        filename = sprintf("%s%03d%s",[pathname.ESP '/' num2str(ESP.date) '/ES_' num2str(ESP.date)], ESP.shotlist(i), '.csv');
        ESPdata_full = readmatrix(filename);
        ESPdata = ESPdata_full(ismember(round(ESPdata_full(:,1),1),ESP.trange),2:end);
        % ESPdata = readmatrix(filename,'Range',sprintf('B%d:V%d',ESP.trange(1)*10+2,ESP.trange(end)*10+2));
        phi(:,:,idx_r) = (phi(:,:,idx_r)*(cnt_r(idx_r)-1) + ESPdata)/cnt_r(idx_r);
        % if ESP.rlist(i)*1E-3 == 0.1150
        %     figure;hold on;grid on;
        %     for j = 1:n_ch
        %         plot(ESP.trange, ESPdata(:,j));
        %     end
        % end
    end
    phi(:,ng_ch,:) = [];%死んだCHを除去
    phi = fliplr(phi);%(CH1のZ座標)>(CH2のZ座標)>...のため、列を反転
    phi = phi.*res_ratio;%分圧比を掛ける

    [ESPdata2D.phi_mesh_z,ESPdata2D.phi_mesh_r] = meshgrid(z,r);
    ESPdata2D.phi_grid = zeros(numel(ESP.trange),ESP.mesh,ESP.mesh);
    ESPdata2D.Ez_grid = zeros(numel(ESP.trange),ESP.mesh,ESP.mesh);
    ESPdata2D.Er_grid = zeros(numel(ESP.trange),ESP.mesh,ESP.mesh);
    for i = 1:numel(ESP.trange)
        phi_fine = griddata(z_probe,r_probe,squeeze(phi(i,:,:))',ESPdata2D.phi_mesh_z,ESPdata2D.phi_mesh_r);
        ESPdata2D.phi_grid(i,:,:) = phi_fine;
        % ESPdata2D.phi_grid(i,:,:) = smoothdata(smoothdata(phi_fine),2);
        % ESPdata2D.phi_grid(i,:,:) = griddata(z_probe,r_probe,squeeze(phi(i,:,:))',ESPdata2D.phi_mesh_z,ESPdata2D.phi_mesh_r);
        % ESPdata2D.Ez_grid(i,:,2:end) =-diff(squeeze(ESPdata2D.phi_grid(i,:,:)),1,2)/(z(2)-z(1));
        % ESPdata2D.Er_grid(i,2:end,:) = -diff(squeeze(ESPdata2D.phi_grid(i,:,:)),1,1)/(r(2)-r(1));
        ESPdata2D.Ez_grid(i,:,2:end) = smoothdata2(-diff(squeeze(ESPdata2D.phi_grid(i,:,:)),1,2)/(z(2)-z(1)));
        ESPdata2D.Er_grid(i,2:end,:) = smoothdata2(-diff(squeeze(ESPdata2D.phi_grid(i,:,:)),1,1)/(r(2)-r(1)));
    end
    save(ESPdataFile,"ESPdata2D");
end

