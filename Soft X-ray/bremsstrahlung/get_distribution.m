function [I,conv] = get_distribution(M,K,U,s,v,Ep, transmission_matrix, ReconMethod)
Z=U'*Ep;

gmin=-250;gmax=10;
% gmin=-30;gmax=0;
lg_gamma=gmin:0.1:gmax;
l_g = numel(lg_gamma);
gamma=10.^(lg_gamma);

V1 = zeros(1,l_g);
V2 = zeros(1,l_g);
Vgamma = zeros(1,21);

for n=1:l_g
    rho = M*gamma(n)./(s.^2+M*gamma(n));

    V11 = rho.*(Z.');
    V1(n)=M*sum(V11.^2);
    V2(n)=(sum(rho))^2;
    Vgamma(n)=V1(n)/V2(n);
end

[~,gamma_index]=min(Vgamma);
I = zeros(1,K);

if ReconMethod == 2
    Tgamma = 10^(lg_gamma(gamma_index));%GCVも考え直さないと→計算時間やばくなりそう
    L = transmission_matrix; %Lf=g
    Lt = L.';
    g = Ep;
    df = zeros(K, 1);%Newton法の解の修正
    eps = 1e-30; % Newton法やめる時ようのε
    iter = 0;
    iterc = 0;
    conv = 1;
    
    %初期値を決める
    %Tikhonov
    for i=1:K
        % v_1 = v(i,:);
        if M>K
            v_1 = [v(i,:) zeros(1,M-K)];
        else
            v_1 = v(i,:);
        end
        I1 = (s./(s.^2+M*Tgamma)).*v_1.*(Z.');
        I(i)=sum(I1);
    end
    I(I<1e-10) = 1e-10;
    f = log(I.');
    % if ~isempty(find(I<1e-9, 1))
    %     fmean = mean(f);
    %     f = fmean*ones(K,1);
    % end
    
    
    %f = log(I.');
    %fmean = mean(f);
    %f = fmean*ones(K,1);
    
    % モデル関数　熱的オンリー
    %I = exp(-(means*10^(-3)));
    % 
    
    
    %モデル関数　非熱的オンリー
    % I = (means-6).^(-2)+0.004;
    % f = log(I.');
    
    
    
    % c = 3*10^(10);
    % m = 9.1*10^(-28);
    % h = 6.63*10^(-27);
    % E = 4.8*10^(-10);
    % k = 1.38*10^(-16);
    % H = 4.14*10^(-15);
    % Z = 1;
    % s = 3.6;
    % v = 10^6;
    % n = 10^(20);
    % TA = 3000;
    % I= zeros(size(means));
    % % I(means * 1e-4 <= 0.003) = (2^5 * pi * E^6 / (3 * c^3 * m)) * sqrt(2 * pi / (3 * m * k)) * ...
    % %      n^2 * Z^2 * T^(-0.5) .* exp(-h *1e-4*means(means* 1e-4<=0.003) ./ (H * k * T));
    % 
    % % Calculate I_assumption2 where x > 0
    % I = (2^5 * pi * E^6 / (3 * c^3 * m)) * sqrt(2 * pi / (3 * m * k)) * ...
    %      n^2 * Z^2 * TA^(-0.5) .* exp(-h*means ./ (H * k * TA));
    % I(I<0) = 1e-10;
    % f = log(I.');
    
    while df.'*df > eps*(f.'*f) || iter == 0 ||iterc==10
        %-----------GCVの処理をまず行う-----------
        V1 = zeros(1,l_g);
        V2 = zeros(1,l_g);
        Vgamma = zeros(1,21);
    
        for n=1:l_g
            diagEf = exp(f).^(-1); %対角成分のままでいることで計算時間が減る
            diagDf = M*gamma(n)/2*diagEf;
            diaginvDf = diagDf.^(-1);%逆行列計算を楽にする
    
            Q = L*(Lt.*diaginvDf);
            [U,D] = eig(Q);
            l = diag(D);
            %V1(n)=sum(L*exp(f)-g)/M;
            V1(n)=sum(U.'*g)/M;
            V2(n)=(sum(1./(1+l.'))/M)^2;
            Vgamma(n)=V1(n)/V2(n);
        end
        [~,gamma_index]=min(Vgamma);
        MEMgamma = 10^(lg_gamma(gamma_index));
        %---------------------------------------
        %disp(iter);
        diagEx = exp(f); %対角成分のままでいることで計算時間が減る
        diaginvEx = diagEx.^(-1);%逆行列計算を楽にする
        diagDx = M*MEMgamma/2*diagEx;
        diaginvDx = diagDx.^(-1);%逆行列計算を楽にする
    
        Phif = M*MEMgamma/2*(f+1)+ Lt*(L*exp(f)-g);
        A = eye(M) + L*(Lt.*diaginvDx); %A = eye(M)+L*invDx*Lt; %正定値対称行列になっているはずなんだよね
        b = L*(Phif.*diaginvDx); %b = L*invDx*Phif;
        xi = cholesky(A,b);
    
        % R = cholesky(A);
        % xi = R\(R'\b);
    
        %diagproduct = diaginvEx.*diaginvDx;
    
        %L2正則化する場合
    
        lambda = 100;%良くわかんないけど適当に決めた
        L2 = lambda/2*(f.'*f);
        b2 = L2*(Lt.*diaginvDx).'; % b2 = L*invDx*L2;
        xi2 = cholesky(A,b2); % 時間かかるね
        diaginvs = ((L2-Lt*xi2).*diaginvDx+diagEx).^(-1);
        diagproduct = diaginvs.*diaginvDx;
    
    
        df = -(Phif-Lt*xi).*diagproduct; %df = -inv?*invDx*(Phif-L.'*xi);
    
        % dfが大きく/小さくなりすぎるのを阻止。エラーの原因になる。
        m = 0.5;
        df(df > m) = 1+m - m ./ df(df > m);
        df(df < -m) = -(1+m) - m ./df(df<-m);
    
        f = f+ df; %Newton法
    
        iter = iter+1;
        %
        %disp((df.'*df)/(f.'*f)/eps);
        % disp(df.'*df);
        % disp(f.'*f);
        % disp(log(df.'*df));
        % disp((log(f.'*f)));
        if (df.'*df)/(f.'*f)>0.8 % 収束しないで振動しそうになった時は初期値を変えよう
            iterc = iterc+1;
            % if iterc  == 1000
            %     disp(iterc)
            %     f = -0.01*ones(K,1);
            %     df = zeros(K,1);
            %     disp('収束しそうにないから初期値変えた');
            if iterc >1000
                disp('収束しなさそうだよ');
                f = -0.01*ones(K,1);
                conv = 0;
                break;
            end
        end
    end
    I = exp(f);
elseif ReconMethod == 1 % 最小フィッシャー
    tic
    gamma = 10^(lg_gamma(gamma_index));
    C = Laplacian(sqrt(K)-1);
    H = transmission_matrix;
    G = Ep.';
    W = eye(size(C, 1));
    diag_idx = find(W);
    for i=1:K
        % v_1 = v(i,:);
        if M>K
            v_1 = [v(i,:) zeros(1,M-K)];
        else
            v_1 = v(i,:);
        end
        E1 = (s./(s.^2+M*10^(lg_gamma(gamma_index)))).*v_1.*(Z.');
        E(i)=sum(E1);
    end
    EE = E;
    EE(EE<1e-20) = -1;
    % ここで10^-5未満を0に設定？
    W(diag_idx) = 1./EE;
    % W(W==Inf) = -1;
    W(W<0) = max(W, [], 'all');
    % if plot_flag
    %     figure;histogram(W(diag_idx));
    % end
    I = (H' * H + (M * gamma) .* (C'* W * C))^(-1) * H' * G'; 
    % I(I<1e-20) = 1e-20;
elseif ReconMethod == 0
    for i=1:K
        % v_1 = v(i,:);
        if M>K
            v_1 = [v(i,:) zeros(1,M-K)];
        else
            v_1 = v(i,:);
        end
        E1 = (s./(s.^2+M*10^(lg_gamma(gamma_index)))).*v_1.*(Z.');
        I(i)=sum(E1);
        % I(I<1e-20) = 1e-20;
    end

end
end




function C = Laplacian(N_grid)
k=N_grid+1;
K=k*k;
C=zeros(K);
for i=1:1:k
    for j=1:1:k
           C((i-1)*k+j,(i-1)*k+j)=-4;
        if j+1<=k
            C((i-1)*k+j,(i-1)*k+j+1)=1;
        end
        
        if j-1>=1
            C((i-1)*k+j,(i-1)*k+j-1)=1;
        end
        
        if i-1-1>=0
            C((i-1)*k+j,(i-1-1)*k+j)=1;
        end
        
        if i-1+1<=k-1
            C((i-1)*k+j,(i-1+1)*k+j)=1;
        end
    end
end
end