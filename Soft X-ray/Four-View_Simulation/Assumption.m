function [EE_cell,Iwgn_cell,I_cell,II_cell,IIwgn_cell] = Assumption(N_projection,gm2d,plot_flag)

[~, N_g] = size(gm2d);
% N_projection = sqrt(N_p);
N_grid = sqrt(N_g);
m=N_grid;
n=N_grid;
z_0=0;
r_0=-0.3;
z=linspace(-1,1,m);
r=linspace(-1,1,n);

% z_grid = linspace(200,-200,m);
z_grid = linspace(-200,200,m);
r_grid = linspace(330,70,n);

[r_space,z_space] = meshgrid(r,z); %rが横、zが縦の座標系（左上最小）

% 従来のAssumption a0
%{
r0_space = sqrt((z_space-z_0).^2+(r_space-r_0).^2);
r1_space = abs(0.5*(z_space-z_0)+(r_space-r_0))/sqrt(1.25);
EE = exp(-0.5*r0_space.^2).*exp(-5*r1_space)+1.5*exp(-r0_space.^2);
%}
% EE = zeros(m,n);
% for i=1:m
%     for j=1:n
%         r0 = sqrt((z(i)-z_0)^2+(r(j)-r_0)^2);
%         r1 = abs(0.5*(z(i)-z_0)+(r(j)-r_0))/sqrt(1.25);
%         EE(i,j) = 1*exp(-0.5*r0^2)*exp(-5*r1)+1.5*exp(-r0^2);
%     end
% end
% size(E)


%光る領域の中心と広がり、強度を定義


centers_cell = {
    % [%a1 中央に光源2つと大きな弱い光源2つ
    % 0.3, -0.1, 0.1, 0.05, 1.0;  % [z_center, r_center, semi_major_axis, semi_minor_axis, intensity]
    % -0.5, 0.4, 1, 1, 0.8;
    % 0.0, 0.0, 0.1, 0.05, 1.2;
    % -0.7, -0.3, 2, 0.5, 0.5
    % ];
    % [%a2 4隅
    % 1, -1, 0.1, 0.05, 1.0;  % [z_center, r_center, semi_major_axis, semi_minor_axis, intensity]
    % -1, 1, 0.1, 0.1, 1;
    % 1, 1, 0.1, 0.05, 1;
    % -1, -1, 0.1, 0.05, 1
    % ];
    % [%a3 中央より少し外側に4つ均等
    % 0.5, -0.5, 0.1, 0.05, 1.0;  % [z_center, r_center, semi_major_axis, semi_minor_axis, intensity]
    % -0.5, 0.5, 0.1, 0.05, 1;
    % 0.5, 0.5, 0.1, 0.05, 1;
    % -0.5, -0.5, 0.1, 0.05, 1
    % ];
    % [%a4 a3みたいだけど一つは中央に弱く配置
    % 0.05, -0.05, 0.4, 0.4, 0.6;  % [z_center, r_center, semi_major_axis, semi_minor_axis, intensity]
    % -0.5, 0.5, 0.1, 0.05, 1;
    % 0.5, 0.5, 0.1, 0.05, 1;
    % -0.5, -0.5, 0.1, 0.05, 1
    % ];
    % [%a5 全体に同じ光源をたくさん配置
    % 0.5, -0.5, 0.05, 0.05, 1;  % [z_center, r_center, semi_major_axis, semi_minor_axis, intensity]
    % -0.5, 0.5, 0.05, 0.05, 1;
    % 0.5, 0.5, 0.05, 0.05, 1;
    % -0.5, -0.5, 0.05, 0.05, 1;
    % 0, 0, 0.05, 0.05, 1;
    % 0, 0.7, 0.05, 0.05, 1;
    % 0.7, 0, 0.1, 0.05, 1;
    % -0.7, 0, 0.1, 0.05, 1;
    % 0, -0.7, 0.1, 0.05, 1
    % ];
    % [%a6 中央に同じ光源をたくさん配置
    % 0.15, -0.15, 0.05, 0.05, 1;  % [z_center, r_center, semi_major_axis, semi_minor_axis, intensity]
    % -0.15, 0.15, 0.05, 0.05, 1;
    % 0.15, 0.15, 0.05, 0.05, 1;
    % -0.15, -0.15, 0.05, 0.05, 1;
    % 0, 0, 0.05, 0.05, 1;
    % 0, 0.17, 0.05, 0.05, 1;
    % 0.17, 0, 0.05, 0.05, 1;
    % -0.17, 0, 0.05, 0.05, 1;
    % 0, -0.17, 0.05, 0.05, 1
    % ];
    % [%a7 大きな光源と小さな光源
    % 0.5, -0.5, 0.6, 0.6, 1;  % [z_center, r_center, semi_major_axis, semi_minor_axis, intensity]
    % -0.15, 0.15, 0.07, 0.07, 1;
    % ];
    % [%a8 全体を多き隠す大きな光源
    % 0, 0, 1, 1, 1;  % [z_center, r_center, semi_major_axis, semi_minor_axis, intensity]
    % ];
    % [%a9 左上に一つだけ
    % 1, 1, 0.2, 0.2, 1;  % [z_center, r_center, semi_major_axis, semi_minor_axis, intensity]
    % ];
    % [%a10全体に大きく弱く発光
    % 0,0,1,1,0.8;
    % ];
    % [%a11全体に大きく弱く発光と強い発光一つ
    % 0.3,0.3,0.1,0.1,1.2
    % 0,0,1,1,0.4;
    % ];
    % [%a12a11と同じだけど弱い奴が少し強い
    % 0.3,0.3,0.1,0.1,1.2
    % 0,0,1,1,0.8;
    % ];
    % [%a13 複雑
    % % 中央付近に強い光源
    % 0.0, 0.0, 0.2, 0.1, 1.5;   % 強い光源1
    % 0.2, -0.2, 0.1, 0.05, 1.3; % 強い光源2
    
    % % 外周に大きな弱い光源
    % 1.2, 0.8, 0.5, 0.3, 0.6;   % 弱い光源1
    % -1.0, -1.2, 0.7, 0.4, 0.5; % 弱い光源2
    
    % % 左側に小さく強い光源
    % -0.7, 0.7, 0.1, 0.1, 1.4;  % 強い光源3
    % -0.8, -0.8, 0.05, 0.05, 1.2; % 強い光源4
    
    % % 右下に広がりを持つ中程度の光源
    % 0.8, -0.9, 0.4, 0.2, 0.9;  % 中程度光源1
    
    % % 全体にかかる非常に大きな弱い光源
    % 0.0, 0.0, 2, 2, 0.3;       % 全体に広がる弱い光源
    
    % % 右側に追加の弱い光源
    % 0.5, 0.8, 0.2, 0.1, 0.7;   % 弱い光源3
    % 0.9, 0.4, 0.1, 0.05, 0.8;  % 弱い光源4
    
    % % 左下に複数の微弱な光源
    % -0.6, -0.7, 0.05, 0.05, 0.5; % 微弱光源1
    % -0.4, -0.6, 0.03, 0.03, 0.4; % 微弱光源2
    % -0.8, -0.5, 0.04, 0.04, 0.4; % 微弱光源3
    
    % % 追加の強い光源
    % -0.3, 0.2, 0.1, 0.05, 1.6;  % 強い光源5
    % 0.3, -0.4, 0.15, 0.08, 1.7; % 強い光源6
    % ];
    % [%a14何もない画像
    % ];
    % [%a15小さく暗い点一つのみ。
    % 1,0,0.05,0.05,0.05;
    % ];
    % [%a16周辺だけ明るい
    % 1,0,0.05,0.05,0.05;
    % 1,1,0.05,0.05,0.05;
    % 0,1,0.05,0.05,0.05;
    % -1,1,0.05,0.05,0.05;
    % -1,0,0.05,0.05,0.05;
    % -1,-1,0.05,0.05,0.05;
    % 0,-1,0.05,0.05,0.05;
    % 1,-1,0.05,0.05,0.05;
    % ];
    % [%a17片側の周辺だけ明るい
    % 1,0,0.05,0.05,0.05;
    % 1,1,0.05,0.05,0.05;
    % 0,1,0.05,0.05,0.05;
    % -1,1,0.05,0.05,0.05;
    % ]
    [
        0, 0, 0.1, 0.1, 1.5;
    ]
};

% セル配列のサイズを事前に確保
n_centers = size(centers_cell, 1);
EE_cell = cell(n_centers, 1);
I_cell = cell(n_centers, 1);
Iwgn_cell = cell(n_centers, 1);
II_cell = cell(n_centers,1);
IIwgn_cell = cell(n_centers,1);

for c = 1:size(centers_cell,1)
    centers = centers_cell{c};

    % 初期化
    EE = zeros(size(r_space));
    
    % 複数の光る領域を追加（楕円形）
    for i = 1:size(centers, 1)
        z_center = centers(i, 1);
        r_center = centers(i, 2);
        a = centers(i, 3); % 長軸の半径
        b = centers(i, 4); % 短軸の半径
        intensity = centers(i, 5);
        
        % 楕円形の光る領域を定義
        EE = EE + intensity * exp(-((z_space - z_center).^2 / (2 * a^2) + (r_space - r_center).^2 / (2 * b^2)));
    end
    
    % 背景の光を低くする
    background_intensity = 0.001;
    EE = EE + background_intensity;
    %}
    
    
    %正規化
    EE = EE./max(max(EE));
    EE = fliplr(rot90(EE)); %rが縦、zが横、右下最小
    
    %2D matrix is transformed to 1D transversal vector
    E = reshape(EE,1,[]);
    % whos gm2d
    % whos E
    I=gm2d*(E)';
    n = 10;%　n％のノイズを加える
    Iwgn=awgn(I,10*log10(100/n),'measured');
    %Iwgn = I; % 0%
    Iwgn(Iwgn<0)=0;
    
    
    % 1D column vector is transformed to 2D matrix
    n_p = N_projection;
    II = zeros(n_p);
    IIwgn = zeros(n_p);
    k=FindCircle(n_p/2);
    II(k) = I;
    IIwgn(k) = Iwgn;
    Iwgn = Iwgn.';


    % 結果をセル配列に保存
    EE_cell{c} = EE;        % EEを保存
    I_cell{c} = I;        % Iを保存
    Iwgn_cell{c} = Iwgn;    % Iwgnを保存
    II_cell{c} = II;
    IIwgn_cell{c} = IIwgn;
end

%非線形フィルター
%[IIwgn,~] = imnlmfilt(IIwgn,'SearchWindowSize',25,'ComparisonWindowSize',15);

% I_check = II(75,:);
% j = 1:numel(I_check);
% figure;plot(j,I_check);
% 
% if plot_flag
%     [mesh_z,mesh_r] = meshgrid(z_grid,r_grid);
%     [~,h] = contourf(mesh_z,mesh_r,EE,20);
%     h.LineStyle = 'none';
%     c=colorbar;c.Label.String='Intensity [a.u.]';c.FontSize=18;
%     % figure;imagesc(z_grid,r_grid,EE);c=colorbar('Ticks',[0.1,0.5,1]);
%     % c.Label.String='Assumed Intensity [a.u.]';xlabel('Z [mm]');ylabel('R [mm]');
%     % axis xy
%     % ax = gca;
%     % ax.XDir = 'reverse';
%     figure;imagesc(II);c=colorbar('Ticks',[0,20,40]);
%     c.Label.String='Assumed Intensity [a.u.]';xlabel('Z Pixels');ylabel('R Pixels');
%     figure;imagesc(IIwgn);c=colorbar('Ticks',[0,20,40]);
%     c.Label.String='Assumed Intensity [a.u.]';xlabel('Z Pixels');ylabel('R Pixels');
% end

end

function k = FindCircle(L)
    R = zeros(2*L);
    for i = 1:2*L
        for j = 1:2*L
            R(i,j) = sqrt((L-i+0.5)^2+(j-L-0.5)^2);
        end
    end
    % figure;imagesc(R)
    k = find(R<L);
end