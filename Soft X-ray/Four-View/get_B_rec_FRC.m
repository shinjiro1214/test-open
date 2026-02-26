function [B_reconnection] = get_B_rec_FRC(PCB,pathname)
    %磁気軸のBrtをとる
    trange = PCB.trange;
    newTimeRange = 1:numel(trange);
    [grid2D,data2D] = process_PCBdata_280ch(PCB,pathname);
    trange = trange(newTimeRange);
    B_reconnection = zeros(1,numel(trange));

    mergingRatio = zeros(1,numel(trange));

    [magAxisList,xPointList] = get_axis_x_multi(grid2D,data2D,PCB);

    for i = 1:numel(trange)
        mergingRatio(1,i) = xPointList.psi(i)/mean(magAxisList.psi(:,i));

        if mergingRatio(1,i) < 0.4 && mergingRatio(1,i) > 0.2
            B_reconnection (1,i) = max(magAxisList.Brt(1,i),magAxisList.Brt(2,i));
        else
            
        end
    end

    B_reconnection(B_reconnection == 0) = NaN;
    B_reconnection = mean(B_reconnection, 'omitnan');


    