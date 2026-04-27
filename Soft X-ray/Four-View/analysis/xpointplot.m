function all_means = xpointplot(grid2D, data2D, PCB)
    times = PCB.trange;
    [~,xPointList] = get_axis_x_multi(grid2D,data2D,PCB); 

    dEt_dt_grid = [];
    if PCB.xpointdata == 4
        dt_step = (data2D.trange(2) - data2D.trange(1)) * 1e-6; 
        dEt_dt_grid = zeros(size(data2D.Et));
        for i_r = 1:size(data2D.Et, 1)
            for i_z = 1:size(data2D.Et, 2)
                dEt_dt_grid(i_r, i_z, :) = gradient(squeeze(data2D.Et(i_r, i_z, :)), dt_step);
            end
        end
    end

    curvature_grid = [];
    if PCB.xpointdata == 6
        if isfield(data2D, 'Br') && isfield(data2D, 'Bz')
            dr = grid2D.rq(2,1) - grid2D.rq(1,1);
            dz = grid2D.zq(1,2) - grid2D.zq(1,1);
            curvature_grid = zeros(size(data2D.Br));
            for t_idx = 1:size(data2D.Br, 3)
                Br = data2D.Br(:,:,t_idx);
                Bz = data2D.Bz(:,:,t_idx);
                Bmag = sqrt(Br.^2 + Bz.^2);
                br_unit = Br ./ (Bmag + eps);
                bz_unit = Bz ./ (Bmag + eps);
                [dbr_dr, dbr_dz] = gradient(br_unit, dr, dz);
                [dbz_dr, dbz_dz] = gradient(bz_unit, dr, dz);
                K_r = br_unit .* dbr_dr + bz_unit .* dbr_dz;
                K_z = br_unit .* dbz_dr + bz_unit .* dbz_dz;
                curvature_grid(:,:,t_idx) = sqrt(K_r.^2 + K_z.^2);
            end
        end
    end

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

        zvals = grid2D.zq(1,:);
        rvals = grid2D.rq(:,1);

        zidx_range = find((zvals >= z - 0.05) & (zvals <= z + 0.05));
        ridx_range = find(rvals >= r-0.1 & rvals <= r+0.1);

        if isempty(zidx_range) || isempty(ridx_range)
            all_means(1,pcb_tidx) = NaN;
            continue;
        end
        
        idx = (grid2D.zq == z) & (grid2D.rq == r);
        [row, col] = find(idx == 1);
        if isempty(row) 
             row = ridx_range(1); col = zidx_range(1); 
        end

        if PCB.xpointdata == 1 %Et
            data = data2D.Et(row,col,pcb_tidx);
            
        elseif PCB.xpointdata == 2 %Et/Jt
            Et_val = data2D.Et(row,col,pcb_tidx);
            
            jt_slice = data2D.Jt(ridx_range, zidx_range, pcb_tidx);
            Jt_val = min(jt_slice(:), [], 'omitnan');
            
            data = (Et_val / Jt_val) * 1e3;
            
        elseif PCB.xpointdata == 3 %B_pressure
            data =data2D.B_pressure(row,col,pcb_tidx);
        elseif PCB.xpointdata == 4 %dEt/dt
            data = dEt_dt_grid(row, col, pcb_tidx);
        elseif PCB.xpointdata == 5 %Jt (周辺0.05の最小値)
            % 【修正点】*1e6 を削除 (元の単位のまま)
            jt_slice = data2D.Jt(ridx_range, zidx_range, pcb_tidx);
            data = min(jt_slice(:), [], 'omitnan');
            
        elseif PCB.xpointdata == 6 %Curvature (周辺0.02の最大値)
            if ~isempty(curvature_grid)
                zidx_curv = find((zvals >= z - 0.02) & (zvals <= z + 0.02));
                ridx_curv = find((rvals >= r - 0.02) & (rvals <= r + 0.02));
                if ~isempty(zidx_curv) && ~isempty(ridx_curv)
                    curv_slice = curvature_grid(ridx_curv, zidx_curv, pcb_tidx);
                    data = max(curv_slice(:), [], 'omitnan');
                else
                    data = NaN;
                end
            else
                data = NaN;
            end
        elseif PCB.xpointdata == 7
            data = NaN;
        end
        all_means(1,pcb_tidx) = data;
    end
end