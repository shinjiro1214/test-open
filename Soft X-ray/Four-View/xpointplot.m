function all_means = xpointplot(grid2D, data2D,PCB)

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
            r = grid2D.rq(21,1);
        else
            z = prevz;
            r = prevr;
        end
    end
    prevz = z;
    prevr = r;

    zidx = grid2D.zq ==z;
    ridx = grid2D.rq ==r;
    idx = zidx & ridx;
    [row, col] = find(idx == 1);
    
    if PCB.xpointdata == 1 %Et
        data = data2D.Et(row,col,pcb_tidx);
    elseif PCB.xpointdata == 2 %Et/Jt
        data = data2D.Et(row,col,pcb_tidx)/data2D.Jt(row,col,pcb_tidx)*1e3;
    elseif PCB.xpointdata == 3 %dB/dt
        data =data2D.dBdt_magnitude(row,col,pcb_tidx);
    end
    all_means(1,pcb_tidx) = data;
end

% figure;
% plot(times,all_means);
% %errorbar(times, stderr_means, 'vertical');
% xlim([times(1) times(end)]);



end