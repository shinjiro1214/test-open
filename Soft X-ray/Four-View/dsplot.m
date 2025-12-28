function all_means = dsplot(grid2D, data2D,PCB)
%downstream plot 特に内側を計算している

times = PCB.trange;

[~,xPointList] = get_axis_x_multi(grid2D,data2D,PCB); %時間ごとの磁気軸、X点を検索

all_means = zeros(size(times));
for t= times
    pcb_tidx = data2D.trange == t;
    z = xPointList.z(pcb_tidx);
    r = xPointList.r(pcb_tidx);
    if isnan(z) || isnan(r)
        if t == times(1)
            z = grid2D.zq(1,21);
            r = grid2D.rq(1,1);
        else
            z = prevz;
            r = prevr;
        end
    end
    prevz = z;
    prevr = r;

    % z方向 ±0.1範囲のインデックスを取得
    zvals = grid2D.zq(1,:);
    zidx_range = find((zvals >= z - 0.1) & (zvals <= z + 0.1));

    % r方向：x点より「内側（小さいr）」を対象
    rvals = grid2D.rq(:,1);
    ridx_range = find(rvals < r);

    % if isempty(zidx_range) || isempty(ridx_range)
    %     warning('範囲外データあり (t=%.3f)', t);
    %     continue;
    % end

    % データ抽出と平均
    if PCB.xpointdata == 1 % Et
        slice = squeeze(data2D.Et(ridx_range, zidx_range, pcb_tidx));
    elseif PCB.xpointdata == 2 % Et/Jt
        Et_slice = squeeze(data2D.Et(ridx_range, zidx_range, pcb_tidx));
        Jt_slice = squeeze(data2D.Jt(ridx_range, zidx_range, pcb_tidx));
        slice = Et_slice ./ Jt_slice * 1e3;
    elseif PCB.xpointdata == 3 % dB/dt
        slice = squeeze(data2D.dBdt_magnitude(ridx_range, zidx_range, pcb_tidx));
    elseif PCB.xpointdata == 4 % Bt
        slice = squeeze(data2D.Bt(ridx_range, zidx_range, pcb_tidx));
    elseif PCB.xpointdata == 5 % Br
        slice = squeeze(data2D.Br(ridx_range, zidx_range, pcb_tidx));
    elseif PCB.xpointdata == 6 % Bz
        slice = squeeze(data2D.Bz(ridx_range, zidx_range, pcb_tidx));
    else
        error('不明なデータタイプ: PCB.xpointdata=%d', PCB.xpointdata);
    end

    all_means(1,pcb_tidx) = mean(slice(:), 'omitnan');
end

% figure;
% plot(times,all_means);
% %errorbar(times, stderr_means, 'vertical');
% xlim([times(1) times(end)]);


end