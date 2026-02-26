function [] = get_parameters(N_projection,N_grid,filepath)

% filepath = '/Users/shinjirotakeda/Documents/GitHub/test-open/Soft X-ray/Four-View_Simulation/parameters.mat';
% filepath = '/Users/shohgookazaki/Documents/GitHub/test-open/Soft X-ray/Four-view/parameters3050.mat';
% N_projection = 30;
% N_grid = 50;
% get_parameters(30,50, '/Users/shohgookazaki/Documents/GitHub/test-open/Soft X-ray/Four-view/parameters3050.mat')

% 視線の分布、重み行列の作成
zhole1=40;zhole2=-40;                                  
zmin1=-240;zmax1=320;zmin2=-320;zmax2=240;             
rmin=55;rmax=375;

R_coil = 310; % Major Radius
r_coil_min = 40; % Minor Radius
z_coil_pos = 213.5; % コイルのZ位置 (+/-)


range = [zmin1,zmax1,zmin2,zmax2,rmin,rmax];            
l1 = MCPLine_up(N_projection,zhole2,true);
gm2d1 = LineProjection(l1,N_grid,zmin2,zmax2,rmin,rmax,true,true); 
l2 = MCPLine_down(N_projection,zhole2,false);
gm2d2 = LineProjection(l2,N_grid,zmin2,zmax2,rmin,rmax,false,false);
l3 = MCPLine_up(N_projection,zhole1,false);
gm2d3 = LineProjection(l3,N_grid,zmin1,zmax1,rmin,rmax,false,true);
l4 = MCPLine_down(N_projection,zhole1,false);
gm2d4 = LineProjection(l4,N_grid,zmin1,zmax1,rmin,rmax,false,false);


disp('Calculation for TP starting...')
% ラプラシアン行列の計算と特異値分解
C = Laplacian(N_grid);
[U1,S1,V1]=svd(gm2d1*(C^(-1)),'econ');
[U2,S2,V2]=svd(gm2d2*(C^(-1)),'econ');
[U3,S3,V3]=svd(gm2d3*(C^(-1)),'econ');
[U4,S4,V4]=svd(gm2d4*(C^(-1)),'econ');


% [U1,S1,V1]=svd(gm2d1*(C^(-1)));
% [U2,S2,V2]=svd(gm2d2*(C^(-1)));
% [U3,S3,V3]=svd(gm2d3*(C^(-1)));
% [U4,S4,V4]=svd(gm2d4*(C^(-1)));
v1=(C^(-1)*V1);
v2=(C^(-1)*V2);
v3=(C^(-1)*V3);
v4=(C^(-1)*V4);


[M,K] = size(gm2d1);

if K>M
    v1 = v1(:,1:M);
    v2 = v2(:,1:M);
    v3 = v3(:,1:M);
    v4 = v4(:,1:M);
end
s1 = (diag(S1)).';
s2 = (diag(S2)).';
s3 = (diag(S3)).';
s4 = (diag(S4)).';
if M>K
    s1 = [s1 zeros(1,M-K)];
    s2 = [s2 zeros(1,M-K)];
    s3 = [s3 zeros(1,M-K)];
    s4 = [s4 zeros(1,M-K)];
end

save(filepath,'gm2d1','gm2d2','gm2d3','gm2d4', ...
    'U1','U2','U3','U4','s1','s2','s3','s4', ...
    'v1','v2','v3','v4','M','K','range','N_projection','N_grid');

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

% function l = MCPLine_up(N_projection,Z_hole,plot_flag)
% d_hole = 24.4; % distance between the hole and the MCP
% r_mcp=8.5;%10;  % radius of the MCP plate

% % Y_hole = 427.85+12; 
% Y_hole = 413.24+12; %?

% % X_hole = 209.62;
% X_hole = 208.13; %?

% Y_initial=Y_hole+d_hole;  X_initial=X_hole-r_mcp;  Z_initial=Z_hole+r_mcp;    %CCD position
% X_end=X_hole+r_mcp;      Z_end=Z_hole-r_mcp;

% Nh=N_projection-1; 
% Dhx=(X_end-X_initial)/Nh;
% Dhz=(Z_end-Z_initial)/Nh;

% X=X_initial:Dhx:X_end;
% Z=Z_initial:Dhz:Z_end;
% Y=repelem(Y_initial,N_projection);

% r_center = 55;
% r_device = 375;
% ll(N_projection,N_projection) = struct('x',[],'y',[],'z',[]);
% if plot_flag
%     f1=figure;
%     f1.Name = "Upper MCP Line - Lightlines";
%     f2=figure;
%     f2.Name = "Upper MCP Line - 視線の行列";
% end
% for i=1:N_projection
%     for j=1:N_projection
%         ll(i,j).y=Y(j):-10:-400;
%         length = numel(ll(i,j).y);
%         ll(i,j).x=(ll(i,j).y-Y_hole)*(X(i)-X_hole)/(Y(j)-Y_hole)+X_hole;
%         ll(i,j).z=(ll(i,j).y-Y_hole)*(Z(j)-Z_hole)/(Y(j)-Y_hole)+Z_hole;
%         %中心軸で視線が遮られることを考慮
%         r = sqrt(ll(i,j).y.^2+ll(i,j).x.^2);
%         A = find(r<=r_center);
%         if isempty(A) == 0
%             obs1 = A(1)-1;
%             ll(i,j).x = [repelem(ll(i,j).x(1),length-obs1) ll(i,j).x(1:obs1)];
%             ll(i,j).y = [repelem(ll(i,j).y(1),length-obs1) ll(i,j).y(1:obs1)];
%             ll(i,j).z = [repelem(ll(i,j).z(1),length-obs1) ll(i,j).z(1:obs1)];
%         end
%         B = find(r>=r_device & ll(i,j).y<=0);
%         if isempty(B) == 0
%             obs2 = B(1)-1;
%             ll(i,j).x = [repelem(ll(i,j).x(1),length-obs2) ll(i,j).x(1:obs2)];
%             ll(i,j).y = [repelem(ll(i,j).y(1),length-obs2) ll(i,j).y(1:obs2)];
%             ll(i,j).z = [repelem(ll(i,j).z(1),length-obs2) ll(i,j).z(1:obs2)];
%         end
%         %plot the lightline
%         if plot_flag
%             figure(f1);plot3(X(i),Y(j),Z(j),'*',ll(i,j).x,ll(i,j).y,ll(i,j).z);  
%             hold on;grid on; 
%         end
%     end
% end

% %視線の行列のうち円の内部に含まれるものだけをベクトル化
% L = N_projection/2;
% k = FindCircle(L);
% l = ll(k);
% if plot_flag
%     for i = 1:numel(l)
%         figure(f2);plot3(l(i).x,l(i).y,l(i).z);
%         hold on;grid on;
%     end
% end
% end

% function l = MCPLine_down(N_projection,Z_hole,plot_flag)
% d_hole =24.4; % distance between the hole and the MCP
% r_mcp=8.5;  %radius of the MCP plate
% % Y_hole=425.24;  X_hole=195.13;          % position of the hole

% % Y_hole = 427.85+12; %
% Y_hole = 413.24+12; %?

% % X_hole = 145.62; 
% X_hole = 144.13; %?

% Y_initial=Y_hole+d_hole;  X_initial=X_hole-r_mcp;  Z_initial=Z_hole+r_mcp;    %CCD position
% X_end=X_hole+r_mcp;      Z_end=Z_hole-r_mcp;

% Nh=N_projection-1; 
% Dhx=(X_end-X_initial)/Nh;
% Dhz=(Z_end-Z_initial)/Nh;

% X=X_initial:Dhx:X_end;
% Z=Z_initial:Dhz:Z_end;
% Y=repelem(Y_initial,N_projection);

% r_center = 55;
% r_device = 375;
% ll(N_projection,N_projection) = struct('x',[],'y',[],'z',[]);
% if plot_flag
%     f1=figure;
%     f1.Name = "Lower MCP Line - Lightlines";
%     f2=figure;
%     f2.Name = "Lower MCP Line - 視線の行列";
% end
% for i=1:N_projection
%     for j=1:N_projection
%         ll(i,j).y=Y(j):-10:-400; %大から小
%         length = numel(ll(i,j).y);
%         ll(i,j).x=(ll(i,j).y-Y_hole)*(X(i)-X_hole)/(Y(j)-Y_hole)+X_hole;
%         ll(i,j).z=(ll(i,j).y-Y_hole)*(Z(j)-Z_hole)/(Y(j)-Y_hole)+Z_hole;
%         %中心軸で視線が遮られることを考慮
%         r = sqrt(ll(i,j).y.^2+ll(i,j).x.^2);
%         A = find(r<=r_center);
%         if isempty(A) == 0
%             obs1 = A(1)-1;
%             ll(i,j).x = [repelem(ll(i,j).x(1),length-obs1) ll(i,j).x(1:obs1)];
%             ll(i,j).y = [repelem(ll(i,j).y(1),length-obs1) ll(i,j).y(1:obs1)];
%             ll(i,j).z = [repelem(ll(i,j).z(1),length-obs1) ll(i,j).z(1:obs1)];
%         end
%         B = find(r>=r_device & ll(i,j).y<=0);
%         if isempty(B) == 0
%             obs2 = B(1)-1;
%             ll(i,j).x = [repelem(ll(i,j).x(1),length-obs2) ll(i,j).x(1:obs2)];
%             ll(i,j).y = [repelem(ll(i,j).y(1),length-obs2) ll(i,j).y(1:obs2)];
%             ll(i,j).z = [repelem(ll(i,j).z(1),length-obs2) ll(i,j).z(1:obs2)];
%         end
%         %plot the lightline
%         if plot_flag
%             figure(f1);plot3(X(i),Y(j),Z(j),'*',ll(i,j).x,ll(i,j).y,ll(i,j).z);  
%             hold on;grid on; 
%         end
%     end
% end

% %視線の行列のうち円の内部に含まれるものだけをベクトル化
% L = N_projection/2;
% k = FindCircle(L);
% l = ll(k);
% if plot_flag
%     for i = 1:numel(l)
%         figure(f2);plot3(l(i).x,l(i).y,l(i).z);
%         hold on;grid on;
%     end
% end
% end


function l = MCPLine_up(N_projection,Z_hole,plot_flag)
% === パラメータ定義 ===
d_hole = 24.4; 
r_mcp = 8.5;
Y_hole = 413.24+12; 
X_hole = 208.13;


coil_R =310; % Major Radius
coil_r = 40; % Minor Radius
coil_z = 213.5; % Z position (+/-)

Y_initial=Y_hole+d_hole;  X_initial=X_hole-r_mcp;  Z_initial=Z_hole+r_mcp;
X_end=X_hole+r_mcp;      Z_end=Z_hole-r_mcp;

Nh=N_projection-1; 
Dhx=(X_end-X_initial)/Nh;
Dhz=(Z_end-Z_initial)/Nh;

X=X_initial:Dhx:X_end;
Z=Z_initial:Dhz:Z_end;
Y=repelem(Y_initial,N_projection);

r_center = 55;
r_device = 375;
ll(N_projection,N_projection) = struct('x',[],'y',[],'z',[]);

if plot_flag
    f1=figure; f1.Name = "Upper MCP Line - Lightlines";
    f2=figure; f2.Name = "Upper MCP Line - Matrix";
end

for i=1:N_projection
    for j=1:N_projection
        % 1. 視線方向ベクトルの計算
        P_start = [X(i), Y(j), Z(j)];
        % 仮の終点(y=-400)を使って方向を算出
        y_temp = -400;
        x_temp = (y_temp-Y_hole)*(X(i)-X_hole)/(Y(j)-Y_hole)+X_hole;
        z_temp = (y_temp-Y_hole)*(Z(j)-Z_hole)/(Y(j)-Y_hole)+Z_hole;
        vec = [x_temp, y_temp, z_temp] - P_start;
        dir = vec / norm(vec);

        % 2. コイルとの交差判定 (上下2つのコイル)
        t_hits_up   = intersect_torus(P_start, dir, coil_R, coil_r, coil_z);
        t_hits_down = intersect_torus(P_start, dir, coil_R, coil_r, -coil_z);
        
        valid_hits = [t_hits_up; t_hits_down];
        y_limit = -9999; % デフォルトは制限なし
        
        if ~isempty(valid_hits)
            % 最も手前の衝突点を取得
            t_hit = min(valid_hits);
            % 衝突点のY座標
            y_limit = P_start(2) + t_hit * dir(2); 
        end

        % 3. 座標列の生成 (コイルによる遮蔽を適用)
        % y_limit より手前(大きい値)の範囲のみを採用
        y_range = Y(j):-10:-400;
        ll(i,j).y = y_range(y_range > y_limit); 
        
        % 対応するx, zを計算
        ll(i,j).x = (ll(i,j).y-Y_hole)*(X(i)-X_hole)/(Y(j)-Y_hole)+X_hole;
        ll(i,j).z = (ll(i,j).y-Y_hole)*(Z(j)-Z_hole)/(Y(j)-Y_hole)+Z_hole;

        % 4. 既存の遮蔽処理 (Center Stack & Outer Wall)
        length = numel(ll(i,j).y);
        if length > 0
            r = sqrt(ll(i,j).y.^2+ll(i,j).x.^2);
            
            % Center Stack (r <= 55)
            A = find(r<=r_center);
            if ~isempty(A)
                obs1 = A(1)-1; 
                % 遮蔽後は視線カット (データをパディングで埋める既存ロジックを維持する場合)
                % もしくはここで cut するなら: ll(i,j).x = ll(i,j).x(1:obs1); 等
                ll(i,j).x = [repelem(ll(i,j).x(1),length-obs1) ll(i,j).x(1:obs1)];
                ll(i,j).y = [repelem(ll(i,j).y(1),length-obs1) ll(i,j).y(1:obs1)];
                ll(i,j).z = [repelem(ll(i,j).z(1),length-obs1) ll(i,j).z(1:obs1)];
            end
            
            % Outer Wall (r >= 375 & y<=0)
            B = find(r>=r_device & ll(i,j).y<=0);
            if ~isempty(B)
                obs2 = B(1)-1;
                ll(i,j).x = [repelem(ll(i,j).x(1),length-obs2) ll(i,j).x(1:obs2)];
                ll(i,j).y = [repelem(ll(i,j).y(1),length-obs2) ll(i,j).y(1:obs2)];
                ll(i,j).z = [repelem(ll(i,j).z(1),length-obs2) ll(i,j).z(1:obs2)];
            end
        end

        if plot_flag
            figure(f1);plot3(X(i),Y(j),Z(j),'*',ll(i,j).x,ll(i,j).y,ll(i,j).z);  
            hold on;grid on; 
        end
    end
end

L = N_projection/2;
k = FindCircle(L);
l = ll(k);
if plot_flag
    for i = 1:numel(l)
        figure(f2);plot3(l(i).x,l(i).y,l(i).z); hold on;grid on;
    end
end
end

function l = MCPLine_down(N_projection,Z_hole,plot_flag)
% === パラメータ定義 ===
d_hole = 24.4; 
r_mcp = 8.5;
Y_hole = 413.24+12; 
X_hole = 144.13;

coil_R =310; % Major Radius
coil_r = 40; % Minor Radius
coil_z = 213.5; % Z position (+/-)

Y_initial=Y_hole+d_hole;  X_initial=X_hole-r_mcp;  Z_initial=Z_hole+r_mcp;
X_end=X_hole+r_mcp;      Z_end=Z_hole-r_mcp;

Nh=N_projection-1; 
Dhx=(X_end-X_initial)/Nh;
Dhz=(Z_end-Z_initial)/Nh;

X=X_initial:Dhx:X_end;
Z=Z_initial:Dhz:Z_end;
Y=repelem(Y_initial,N_projection);

r_center = 55;
r_device = 375;
ll(N_projection,N_projection) = struct('x',[],'y',[],'z',[]);

if plot_flag
    f1=figure; f1.Name = "Lower MCP Line - Lightlines";
    f2=figure; f2.Name = "Lower MCP Line - Matrix";
end

for i=1:N_projection
    for j=1:N_projection
        % 1. 視線方向ベクトルの計算
        P_start = [X(i), Y(j), Z(j)];
        y_temp = -400;
        x_temp = (y_temp-Y_hole)*(X(i)-X_hole)/(Y(j)-Y_hole)+X_hole;
        z_temp = (y_temp-Y_hole)*(Z(j)-Z_hole)/(Y(j)-Y_hole)+Z_hole;
        vec = [x_temp, y_temp, z_temp] - P_start;
        dir = vec / norm(vec);

        % 2. コイルとの交差判定
        t_hits_up   = intersect_torus(P_start, dir, coil_R, coil_r, coil_z);
        t_hits_down = intersect_torus(P_start, dir, coil_R, coil_r, -coil_z);
        
        valid_hits = [t_hits_up; t_hits_down];
        y_limit = -9999;
        
        if ~isempty(valid_hits)
            t_hit = min(valid_hits);
            y_limit = P_start(2) + t_hit * dir(2);
        end

        % 3. コイル遮蔽を適用したY配列
        y_range = Y(j):-10:-400;
        ll(i,j).y = y_range(y_range > y_limit); 

        ll(i,j).x = (ll(i,j).y-Y_hole)*(X(i)-X_hole)/(Y(j)-Y_hole)+X_hole;
        ll(i,j).z = (ll(i,j).y-Y_hole)*(Z(j)-Z_hole)/(Y(j)-Y_hole)+Z_hole;

        % 4. 既存遮蔽処理
        length = numel(ll(i,j).y);
        if length > 0
            r = sqrt(ll(i,j).y.^2+ll(i,j).x.^2);
            A = find(r<=r_center);
            if ~isempty(A)
                obs1 = A(1)-1;
                ll(i,j).x = [repelem(ll(i,j).x(1),length-obs1) ll(i,j).x(1:obs1)];
                ll(i,j).y = [repelem(ll(i,j).y(1),length-obs1) ll(i,j).y(1:obs1)];
                ll(i,j).z = [repelem(ll(i,j).z(1),length-obs1) ll(i,j).z(1:obs1)];
            end
            B = find(r>=r_device & ll(i,j).y<=0);
            if ~isempty(B)
                obs2 = B(1)-1;
                ll(i,j).x = [repelem(ll(i,j).x(1),length-obs2) ll(i,j).x(1:obs2)];
                ll(i,j).y = [repelem(ll(i,j).y(1),length-obs2) ll(i,j).y(1:obs2)];
                ll(i,j).z = [repelem(ll(i,j).z(1),length-obs2) ll(i,j).z(1:obs2)];
            end
        end

        if plot_flag
            figure(f1);plot3(X(i),Y(j),Z(j),'*',ll(i,j).x,ll(i,j).y,ll(i,j).z);  
            hold on;grid on; 
        end
    end
end

L = N_projection/2;
k = FindCircle(L);
l = ll(k);
if plot_flag
    for i = 1:numel(l)
        figure(f2);plot3(l(i).x,l(i).y,l(i).z); hold on;grid on;
    end
end
end

function l = MCPLine(N_projection,Z_hole,plot_flag)
d_hole =24.4; % distance between the hole and the MCP
r_mcp=10;  %radius of the MCP plate
Y_hole=425.24;  X_hole=195.13;          % position of the hole
% Y_hole_new = 427.85+12; 
% X_hole_new_up = 209.62; X_hole_new_down = X_hole_new_up - 64;
Y_initial=Y_hole+d_hole;  X_initial=X_hole-r_mcp;  Z_initial=Z_hole+r_mcp;    %CCD position
X_end=X_hole+r_mcp;      Z_end=Z_hole-r_mcp;

Nh=N_projection-1; 
Dhx=(X_end-X_initial)/Nh;
Dhz=(Z_end-Z_initial)/Nh;

X=X_initial:Dhx:X_end;
Z=Z_initial:Dhz:Z_end;
Y=repelem(Y_initial,N_projection);

r_center = 55;
r_device = 375;
ll(N_projection,N_projection) = struct('x',[],'y',[],'z',[]);
if plot_flag
    f1=figure;
    f2=figure;
end
for i=1:N_projection
    for j=1:N_projection
        ll(i,j).y=Y(j):-10:-400;
        length = numel(ll(i,j).y);
        ll(i,j).x=(ll(i,j).y-Y_hole)*(X(i)-X_hole)/(Y(j)-Y_hole)+X_hole;
        ll(i,j).z=(ll(i,j).y-Y_hole)*(Z(j)-Z_hole)/(Y(j)-Y_hole)+Z_hole;
        %中心軸で視線が遮られることを考慮
        r = sqrt(ll(i,j).y.^2+ll(i,j).x.^2);
        A = find(r<=r_center);
        if isempty(A) == 0
            obs1 = A(1)-1;
            ll(i,j).x = [repelem(ll(i,j).x(1),length-obs1) ll(i,j).x(1:obs1)];
            ll(i,j).y = [repelem(ll(i,j).y(1),length-obs1) ll(i,j).y(1:obs1)];
            ll(i,j).z = [repelem(ll(i,j).z(1),length-obs1) ll(i,j).z(1:obs1)];
        end
        B = find(r>=r_device & ll(i,j).y<=0);
        if isempty(B) == 0
            obs2 = B(1)-1;
            ll(i,j).x = [repelem(ll(i,j).x(1),length-obs2) ll(i,j).x(1:obs2)];
            ll(i,j).y = [repelem(ll(i,j).y(1),length-obs2) ll(i,j).y(1:obs2)];
            ll(i,j).z = [repelem(ll(i,j).z(1),length-obs2) ll(i,j).z(1:obs2)];
        end
        %plot the lightline
        if plot_flag
            figure(f1);plot3(X(i),Y(j),Z(j),'*',ll(i,j).x,ll(i,j).y,ll(i,j).z);  
            hold on;grid on; 
        end
    end
end

%視線の行列のうち円の内部に含まれるものだけをベクトル化
L = N_projection/2;
k = FindCircle(L);
l = ll(k);
if plot_flag
    for i = 1:numel(l)
        figure(f2);plot3(l(i).x,l(i).y,l(i).z);
        hold on;grid on;
    end
end
end

function gm2d = LineProjection(l,N_grid,zmin,zmax,rmin,rmax,plot_flag,up_flag)
    % rmin=70;rmax=330;
    % rmin=55;rmax=375;
    % rmin=70;rmax=280;
    
    N_p = numel(l);
    N_g = N_grid+1;
    DR=(rmax-rmin)/N_grid;
    DZ=(zmax-zmin)/N_grid;
    gm2d = zeros(N_p,N_g^2);
    
    if plot_flag
        f1=figure;
        f2=figure;
        if up_flag
            f1.Name = "Upper Line Projection";
            f2.Name = "Upper Line Projection";
        else
            f1.Name = "Lower Line Projection";
            f2.Name = "Lower Line Projection";
        end
    end
    
    for i = 1:N_p
        %各視線の座標からrz座標を計算、プロット
        x=l(i).x;
        y=l(i).y;
        z=l(i).z;
        r=sqrt(x.^2+y.^2);
        if plot_flag
            figure(f1);plot(z,r);
            hold on;grid on;
            xlabel('Z [mm]');ylabel('R [mm]');
        end
        
        %再構成対象の領域内の視線を抽出
        k=find(r>=rmin&r<=rmax&z>=zmin&z<=zmax);
        pl_r=r(k);
        pl_z=z(k);
        if plot_flag
            figure(f2);plot(pl_z,pl_r,'.');
            hold on;grid on;
            xlabel('Z [mm]');ylabel('R [mm]');
        end
        
        %各点のグリッド座標を求め、各グリッド毎に含まれる点の数を数え上げる
        r_grid = fix((pl_r-rmin)./DR)+1;%グリッド座標
        z_grid = fix((pl_z-zmin)./DZ)+1;
        num_p = numel(r_grid);
        gm_temp = zeros(N_g);
        for ct = 1:num_p
            gm_temp(r_grid(ct),z_grid(ct)) = gm_temp(r_grid(ct),z_grid(ct))+1;
        end
        gm2d(i,:) = reshape(flipud(gm_temp),1,[]);
    end
end

function C = Laplacian(N_grid)
    k = N_grid+1;
    K = k*k;
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

% === 直線とトーラスの交差判定関数 ===
function t_hits = intersect_torus(P, D, R, r, z_center)
    % P: Origin [x,y,z], D: Direction [x,y,z] (normalized)
    % R: Major Radius, r: Minor Radius, z_center: Z offset
    
    Ox = P(1); Oy = P(2); Oz = P(3) - z_center;
    Dx = D(1); Dy = D(2); Dz = D(3);
    
    sum_sq_O = Ox^2 + Oy^2 + Oz^2;
    O_dot_D  = Ox*Dx + Oy*Dy + Oz*Dz;
    K = sum_sq_O + R^2 - r^2;
    
    m = Ox^2 + Oy^2;
    n = Ox*Dx + Oy*Dy;
    p = Dx^2 + Dy^2;
    term2_fac = 4 * R^2;
    
    % 4次方程式の係数
    c4 = 1; 
    c3 = 4 * O_dot_D;
    c2 = 2 * K + 4 * (O_dot_D^2) - term2_fac * p;
    c1 = 4 * K * O_dot_D - term2_fac * 2 * n;
    c0 = K^2 - term2_fac * m;
    
    roots_all = roots([c4, c3, c2, c1, c0]);
    t_hits = sort(roots_all(imag(roots_all)==0 & roots_all > 0));
end