function ESPdata2D = cal_ESP_Uebosan(pathname, ESP)
n_ch = 8; % 静電プローブCH数
res_ratio = 51; % 静電プローブ分圧比

% 信号処理パラメータ
Fs = 1e7; % サンプリング周波数 (1 MHzと仮定)
Fc = 1e4; % カットオフ周波数 (10 kHzと仮定)
windowSize = 10; % スムージング窓のサイズ (移動平均用)

savename = [pathname.ESPmat,'/',num2str(ESP.date),'_shot'];
for i_shot = 1:numel(ESP.shotlist)
    if i_shot == 1
        savename =[savename,num2str(ESP.shotlist(i_shot))];
    else
        if ESP.shotlist(i_shot) == ESP.shotlist(i_shot-1)+1%連番の場合間の番号をファイル名に含まない
            if i_shot < numel(ESP.shotlist)
                if ESP.shotlist(i_shot+1) > ESP.shotlist(i_shot)+1
                    savename =[savename,'-',num2str(ESP.shotlist(i_shot))];
                end
            else
                savename =[savename,'-',num2str(ESP.shotlist(i_shot))];
            end
        else%連番でない場合ファイル名に含む
            savename =[savename,'_',num2str(ESP.shotlist(i_shot))];
        end
    end
end
savename = [savename,'_mesh',num2str(ESP.mesh),'.mat'];

if exist(savename, "file") && ESP.restart == 0
    load(savename, 'ESPdata2D')
else
    disp('calculation starting...')
    z = linspace(-0.056, 0.08, ESP.mesh); % プロットメッシュZ座標[m]
    % z_probe = [-0.056, -0.032, -0.016, 0, 0.016, 0.032, 0.056, 0.08]; % 静電プローブ計測点Z座標[m]
    z_probe = [0.08, 0.056, 0.032, 0.016, 0, -0.016, -0.032, -0.056];

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % case-I
    ng_ch = [1,2,5,6]; % 死んだCH
    % case-O
    % ng_ch = [1, 2, 5, 6];
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    z_probe(ng_ch) = [];
    % ESPdata2D.zprobe = z_probe;
    ESPdata2D.zprobe = fliplr(z_probe);
    r = linspace(min(ESP.rlist), max(ESP.rlist), ESP.mesh) * 1E-3; % プロットメッシュR座標[m]
    r_probe = unique(ESP.rlist) * 1E-3; % 静電プローブ計測点R座標[m]
    ESPdata2D.rprobe = r_probe;

    cnt_r = zeros(numel(r_probe), 1);
    phi_all = cell(numel(r_probe), 1);

    % 各ショットのデータを収集
    for i = 1:numel(ESP.shotlist)
        idx_r = find(r_probe == ESP.rlist(i) * 1E-3);
        cnt_r(idx_r) = cnt_r(idx_r) + 1;
        shotnum = ESP.shotlist(i);
        if shotnum < 10
            shotnum = ['00', num2str(shotnum)];
        else
            shotnum = ['0', num2str(shotnum)];
        end
        filename = sprintf("%s%03d%s",[pathname.ESPrawdata '/' num2str(ESP.date) '/ES_' num2str(ESP.date)], ESP.shotlist(i), '.csv');
        ESPdata = readmatrix(filename,'Range',sprintf('B%d:V%d',ESP.trange(1)*10+2,ESP.trange(end)*10+2));

        % ローパスフィルタ処理
        for ch = 1:size(ESPdata, 2)
            ESPdata(:, ch) = lowpass(ESPdata(:, ch), Fc, Fs);
        end
        
        % スムージング処理
        for ch = 1:size(ESPdata, 2)
            ESPdata(:, ch) = movmean(ESPdata(:, ch), windowSize);
        end

        % データを保存
        if isempty(phi_all{idx_r})
            phi_all{idx_r} = ESPdata;
        else
            phi_all{idx_r} = cat(3, phi_all{idx_r}, ESPdata);
        end
    end

    % 平均と標準誤差の計算
    phi_mean = zeros(size(phi_all{1}, 1), n_ch, numel(r_probe));
    phi_error = zeros(size(phi_all{1}, 1), n_ch, numel(r_probe));
    for id_R = 1:numel(r_probe)
        data = phi_all{id_R};
        if isempty(data)
            continue;
        end
        phi_mean(:, :, id_R) = mean(data, 3);
        phi_error(:, :, id_R) = std(data, 0, 3) ./ sqrt(size(data, 3));
    end

    % 結果の保存
    phi_mean(:, ng_ch, :) = []; % 死んだCHを除去
    % phi_mean = fliplr(phi_mean); % CHの並びを逆転
    phi_mean = phi_mean .* res_ratio; % 分圧比を掛ける
    phi_error(:, ng_ch, :) = [];
    % phi_error = fliplr(phi_error);
    phi_error = phi_error .* res_ratio;

    ESPdata2D.phi_mean = phi_mean;
    ESPdata2D.phi_error = phi_error;

    [ESPdata2D.zq, ESPdata2D.rq] = meshgrid(z, r);
    ESPdata2D.trange = ESP.trange;

    % メッシュデータ生成
    ESPdata2D.phi = zeros(numel(ESP.trange), ESP.mesh, ESP.mesh);
    ESPdata2D.phi_err = zeros(numel(ESP.trange), ESP.mesh, ESP.mesh);

    ESPdata2D.Ez = zeros(numel(ESP.trange), ESP.mesh, ESP.mesh);
    ESPdata2D.Er = zeros(numel(ESP.trange), ESP.mesh, ESP.mesh);
    for i = 1:numel(ESP.trange)
        ESPdata2D.phi(i, :, :) = griddata(z_probe, r_probe, squeeze(phi_mean(i, :, :))', ESPdata2D.zq, ESPdata2D.rq);
        ESPdata2D.phi(i,:,:) = movmean(ESPdata2D.phi(i,:,:),round(ESP.mesh/7),1);%移動平均
        ESPdata2D.phi(i,:,:) = movmean(ESPdata2D.phi(i,:,:),round(ESP.mesh/7),2);%移動平均
        ESPdata2D.phi_err(i, :, :) = griddata(z_probe, r_probe, squeeze(phi_error(i, :, :))', ESPdata2D.zq, ESPdata2D.rq);

        ESPdata2D.Ez(i, :, 2:end) = -diff(squeeze(ESPdata2D.phi(i, :, :)), 1, 2) / (z(2) - z(1));
        ESPdata2D.Er(i, 2:end, :) = -diff(squeeze(ESPdata2D.phi(i, :, :)), 1, 1) / (r(2) - r(1));
    end
    save(savename, 'ESPdata2D')
end
