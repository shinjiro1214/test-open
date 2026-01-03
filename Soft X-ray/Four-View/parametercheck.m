function [gm2d1, gm2d2, gm2d3, gm2d4, U1, U2, U3, U4, ...
          s1, s2, s3, s4, v1, v2, v3, v4, M, K, range, N_projection, N_grid, gm3d,U3d,s3d, v3d, M3d, K3d] = parametercheck(newProjectionNumber, newGridNumber)
% 再構成計算に必要なパラメータを計算するなら読み込む、しない場合も範囲に関しては読み込む
parameterFile = sprintf('/Users/shohgookazaki/Documents/GitHub/test-open/Soft X-ray/Four-view/parameters%d%d.mat', newProjectionNumber, newGridNumber);

if isfile(parameterFile)
        disp(strcat('Loading parameter from ',which(parameterFile)))
        load(parameterFile,'gm2d1','gm2d2','gm2d3','gm2d4', ...
                'U1','U2','U3','U4','s1','s2','s3','s4', ...
                'v1','v2','v3','v4','M','K','range','N_projection','N_grid');
        disp('Parameter loaded')
        if newProjectionNumber ~= N_projection || newGridNumber ~= N_grid
            disp('Different parameters - Start calculation!');
            get_parameters(newProjectionNumber,newGridNumber,parameterFile);
            load(parameterFile,'gm2d1','gm2d2','gm2d3','gm2d4', ...
                    'U1','U2','U3','U4','s1','s2','s3','s4', ...
                    'v1','v2','v3','v4','M','K','range', 'N_projection','N_grid');
        end
else
    disp('No parameters - Start calculation!');
    get_parameters(newProjectionNumber,newGridNumber,parameterFile);
    load(parameterFile,'gm2d1','gm2d2','gm2d3','gm2d4', ...
            'U1','U2','U3','U4','s1','s2','s3','s4', ...
            'v1','v2','v3','v4','M','K','range','N_projection','N_grid');
end

end