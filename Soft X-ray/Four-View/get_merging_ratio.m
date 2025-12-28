function merging_ratio = get_merging_ratio(data2D,grid2D,times)
    merging_ratio = zeros(numel(times),1);
    i = 1;
    
    for time = times
        psi_timeseries = data2D.psi;
        psi = psi_timeseries(:,:,data2D.trange==time);
        merging_ratio(i) = clc_merging_ratio(psi,grid2D,time);
        i = i+1;
    end
    idx_nan=find(isnan(merging_ratio));
    for j = 1:numel(idx_nan)
        i = idx_nan(j);
        if times(i)<470
            merging_ratio(i) = 0;
        elseif times(i)>480
            merging_ratio(i) = 1;
        end
    end
    merging_ratio(merging_ratio<0)=0;
    merging_ratio=merging_ratio*100;
    % figure('Position',[100 100 600 200]);
    % if plot_flag
    %     figure;
    %     plot(times,merging_ratio,'k-','LineWidth',2);
    %     xlabel('time [us]');ylabel('Merging ratio [%]');
    %     title('Merging ratio');
    %     ax=gca;ax.FontSize=18;
    % end
    
    % merging_speed = diff(merging_ratio);
    % figure;
    % plot(times(2:end),merging_speed,'k-','LineWidth',2);
    % xlabel('time [us]');ylabel('Merging speed [a.u.]');
    % title('Merging speed');
    % ax=gca;ax.FontSize=18;
    
    end
    
    function merging_ratio = clc_merging_ratio(psi,grid2D,time)
    
    [pos_oz,pos_or,pos_xz,~,psi_o,psi_x] = search_xo(psi,grid2D,time);
    
    % if sum(pos_oz<pos_xz)==1 && sum(isnan(pos_oz))==0 % pos_xzがpos_ozの最大値と最小値の間にあることを判別＆O点が2つあることを判別
    % 必要な条件：O点が少なくとも一つある＋X点が（あれば）その二つの間
    if max(sum(pos_oz<pos_xz),sum(pos_oz>pos_xz))==1 % pos_xzがpos_ozの最大値と最小値の間にあることを判別（NaNが入ってもいいように）
        common_flux = psi_x;
        % private_flux = mean(psi_o, 'omitnan');
        private_flux = min(psi_o,[],'omitnan');
    elseif sum(isnan(pos_oz))==0 && sum(pos_oz>0)==1 && isnan(pos_xz)% O点二つ（値が違う）あるけどX点なし
        pos_xz = mean(pos_oz);
        pos_xr = mean(pos_or);
        r_space = grid2D.rq(:,1);
        z_space = grid2D.zq(1,:);
        z_idx = knnsearch(z_space',pos_xz);
        r_idx = knnsearch(r_space,pos_xr);
        common_flux = psi(r_idx,z_idx);
        private_flux = min(psi_o);
    else
        common_flux = NaN;
        private_flux = NaN;
    end
    
    merging_ratio = common_flux/private_flux;
    
    end
    
    function [pos_oz,pos_or,pos_xz,pos_xr,psi_o,psi_x] = search_xo(psi,grid2D,time)
    % z座標の制限範囲
    z_min = -0.275;
    z_max = 0.275;
    
    r_space = grid2D.rq(:,1);
    z_space = grid2D.zq(1,:);
    mesh_r = numel(r_space);
    
    if time >480
        % zの範囲外のインデックスを取得
        invalid_z_idx = find(z_space < z_min | z_space > z_max);
        % 範囲外のpsiをNaNにする これはx点が変なところに出るのを阻止するため
        psi(:, invalid_z_idx) = NaN;
    end
    % psi_or=zeros(2,length(time));
    pos_or=zeros(2,1);
    pos_oz=pos_or;
    psi_o = zeros(2,1);
    % psi_xr=zeros(1,length(time));
    % psi_xz=psi_xr;
    % [max_psi,max_psi_r]=max(psi_store,[],1); %各時間、各列(z)ごとのpsiの最大値
    [max_psi,max_psi_r]=max(psi,[],1); %各列(z)ごとのpsiの最大値
    max_psi=squeeze(max_psi);
    
    % for i = time
    %     ind=i-time(1)+1;
    %     max_psi_ind=find(islocalmax(smooth(max_psi(:,i)),'MaxNumExtrema', 2));
        % max_psi_ind=find(islocalmax(smooth(max_psi),'MaxNumExtrema', 2));
        smoothed_data = smooth(max_psi); 
    % あるいは平滑化なしで行くなら： smoothed_data = max_psi;
    
    % 1. 通常のピーク探索
    tf_peaks = islocalmax(smoothed_data);
    
    % 2. 【重要】境界（端点）のチェックを追加
    % 左端：隣（2番目）より大きければピークとみなす
    if smoothed_data(1) > smoothed_data(2)
        tf_peaks(1) = true;
    end
    % 右端：隣（end-1番目）より大きければピークとみなす
    if smoothed_data(end) > smoothed_data(end-1)
        tf_peaks(end) = true;
    end
    
    % 3. ピークのインデックスを抽出
    candidate_ind = find(tf_peaks);
    
    % 4. ピークが3つ以上ある場合、値が大きい順に2つ選ぶ
    if numel(candidate_ind) > 2
        [~, sort_idx] = sort(smoothed_data(candidate_ind), 'descend');
        % 上位2つのインデックスを取り出す
        max_psi_ind = candidate_ind(sort_idx(1:2));
    else
        max_psi_ind = candidate_ind;
    end
    
    % 5. インデックスを位置順（左→右）にソートし直す（O1, O2の順序を保つため）
    max_psi_ind = sort(max_psi_ind);
    %     r_ind=max_psi_r(:,:,i);
        r_ind=max_psi_r;
    %     if numel(max_psi(min(max_psi_ind),i))==0
        if numel(max_psi(min(max_psi_ind)))==0
    %         psi_or(1,ind)=NaN;
    %         psi_oz(1,ind)=NaN;
            pos_or(1)=NaN;
            pos_oz(1)=NaN;
            psi_o(1) = NaN;
        else
            o1r=r_ind(min(max_psi_ind));
    %         psi_or(1,ind)=r_space(o1r);
    %         psi_oz(1,ind)=z_space(min(max_psi_ind));
            pos_or(1)=r_space(o1r);
            pos_oz(1)=z_space(min(max_psi_ind));
    %         psi_o(1) = psi_store(min(max_psi_ind),o1r);
            psi_o(1) = psi(o1r,min(max_psi_ind));
        end
    %     if numel(max_psi(max(max_psi_ind),i))==0
        if numel(max_psi(max(max_psi_ind)))==0
    %         psi_or(2,ind)=NaN;
    %         psi_oz(2,ind)=NaN;
            pos_or(2)=NaN;
            pos_oz(2)=NaN;
            psi_o(2) = NaN;
        else
            o2r=r_ind(max(max_psi_ind));
    %         psi_or(2,ind)=r_space(o2r);
    %         psi_oz(2,ind)=z_space(max(max_psi_ind));
            pos_or(2)=r_space(o2r);
            pos_oz(2)=z_space(max(max_psi_ind));
    %         psi_o(2) = psi_store(min(max_psi_ind),o2r);
            psi_o(2) = psi(o2r,max(max_psi_ind));
        end
    %     if numel(find(islocalmin(smooth(max_psi(:,i)),'MaxNumExtrema', 1)))==0
        if numel(find(islocalmin(smooth(max_psi),'MaxNumExtrema', 1)))==0
    %         psi_xr(1,ind)=NaN;
    %         psi_xz(1,ind)=NaN;
            pos_xr=NaN;
            pos_xz=NaN;
            psi_x = NaN;
        else
    %         min_psi_ind=islocalmin(smooth(max_psi(:,i)),'MaxNumExtrema', 1);
            min_psi_ind=islocalmin(smooth(max_psi),'MaxNumExtrema', 1);
            xr=r_ind(min_psi_ind);  
            if xr==1 || xr==mesh_r %r両端の場合は検知しない
    %             psi_xr(1,ind)=NaN;
    %             psi_xz(1,ind)=NaN;
                pos_xr=NaN;
                pos_xz=NaN;
                psi_x = NaN;
            else
    %             psi_xr(1,ind)=r_space(xr);
    %             psi_xz(1,ind)=z_space(min_psi_ind);
                pos_xr=r_space(xr);
                pos_xz=z_space(min_psi_ind);
    %             psi_x = psi_store(min_psi_ind,xr);
                psi_x = psi(xr,min_psi_ind);
            end
        end
    %     if max_psi(1,i)==max(max_psi(1:end/2,i)) %z両端の場合はpsi中心が画面外として検知しない
        mid_idx = round(numel(max_psi)/2);
        if max_psi(1)==max(max_psi(1:mid_idx)) %z両端の場合はpsi中心が画面外として検知しない
    %         psi_or(1,ind)=NaN; %r_space(r_ind(1));
    %         psi_oz(1,ind)=NaN; %z_space(1);
            pos_or(1)=NaN; %r_space(r_ind(1));
            pos_oz(1)=NaN; %z_space(1);
            psi_o(1) = NaN;
        end
    %     if max_psi(end,i)==max(max_psi(end/2:end,i))
        if max_psi(end)==max(max_psi(mid_idx:end))
    %         psi_or(2,ind)=NaN; %r_space(r_ind(1));
    %         psi_oz(2,ind)=NaN; %z_space(end);
            pos_or(2)=NaN; %r_space(r_ind(1));
            pos_oz(2)=NaN; %z_space(end);
            psi_o(2) = NaN;
        end
    end