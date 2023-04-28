%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%�V���b�g�ԍ��A�B�e�p�����[�^�Ȃǂ��������O���玩���擾����
%�h�b�v���[�v���[�u�ɂ��C�I�����x�A�t���[�Ƃ��̏u�Ԃ̎��C�ʂ��v���b�g
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%�ePC�̃p�X���`
run define_path.m

%------�yinput�z-------
date = 230314;%�yinput�z������
begin_cal = 57;%�yinput�z���C��&�t���[�v�Z�n��shot�ԍ�(�������OD��)
end_cal = 57;%�yinput�z���C��&�t���[�v�Z�I���shot�ԍ�(�������OD��)(0�ɂ����begin_cal�ȍ~�̓����̑Sshot�v�Z)
min_r = 12.5;%�yinput�z�h�b�v���[�v���[�u�v���_�ŏ�r���W[mm]
int_r = 2.5;%�yinput�z�h�b�v���[�v���[�u�v���_r�����Ԋu[mm]
min_z = -2.1;%�yinput�z�h�b�v���[�v���[�u�v���_�ŏ�z���W[mm](-2.1,2.1)
int_z = 4.2;%�yinput�z�h�b�v���[�v���[�u�v���_z�����Ԋu[mm](4.2)
ICCD.line = 'Ar';%�yinput�z�h�b�v���[�������C��('Ar')
n_CH = 28;%�yinput�z�h�b�v���[�v���[�u�t�@�C�o�[CH��(28)
n_z = 1;%�yinput�z�h�b�v���[�v���[�uz�����f�[�^��(���l)(1)
%------�ڍאݒ�yinput�z-------
cal_flow = false;%�yinput�z�������v�Z(true,false)

plot_fit = false;%�yinput�z�K�E�X�t�B�b�e�B���O��\��(true,false)
plot_flow = true;%�yinput�z�������v���b�g(true,false)
plot_psi = true;%�yinput�z���C�ʂ��v���b�g(true,false)
overlay_plot = true;%�yinput�z�����Ǝ��C�ʂ��d�˂�(true,false)

save_fit = false;%�yinput�z�K�E�X�t�B�b�e�B���Opng��ۑ�(true,false)
save_fig = false;%�yinput�z����png��ۑ�(true,false)

save_flow = false;%�yinput�z�����f�[�^��ۑ�(true,false)
load_flow = true;%�yinput�z�����f�[�^��ǂݍ���(true,false)

show_offset = false;%�yinput�z����offset��\��(true,false)
factor = 0.1;%�yinput�z�C�I���t���[���T�C�Y(���l:0.1�Ȃ�)
dtacq.num = 39;%�yinput�z���C�v���[�udtacq�ԍ�(39)
mesh_rz = 100;%�yinput�z���C�v���[�urz�����̃��b�V����(50)
trange = 430:590;%�yinput�z���C�v���[�u�v�Z���Ԕ͈�(430:590)

%�h�b�v���[�v���[�u�v���_�z��𐶐�
mpoints = make_mpoints(n_CH,min_r,int_r,n_z,min_z,int_z);

%�������O�ǂݎ��
[exp_log,begin_row,end_row] = load_log(date);
if isempty(begin_row)
    return
end

%--------���C��&�t���[���v�Z------
start_i = begin_row + begin_cal - 1;
if start_i <= end_row
    if end_cal == 0
        end_i = end_row;%begin_cal�ȍ~�S���v�Z
    elseif end_cal < begin_cal
        error('end_cal must <= begin_cal.')
    elseif begin_row + end_cal - 1 <= end_row
        end_i = begin_row + end_cal - 1;%begin_cal����end_cal�܂Ōv�Z
    else
        error('end_cal must <= %d.', exp_log(end_row,4))
    end
    for i = start_i:end_i
        ICCD.shot = exp_log(i,4);%�V���b�g�ԍ�
        a039shot = exp_log(i,8);%a039�V���b�g�ԍ�
        a039tfshot = exp_log(i,9);%a039TF�V���b�g�ԍ�
        expval.PF1 = exp_log(i,11);%PF1�d��(kv)
        expval.PF2 = exp_log(i,14);%PF2�d��(kv)
        expval.TF = exp_log(i,18);%PF2�d��(kv)
        expval.EF = exp_log(i,23);%EF�d��
        ICCD.trg = exp_log(i,42);%ICCD�g���K����
        ICCD.exp_w = exp_log(i,43);%ICCD�I������
        ICCD.gain = exp_log(i,44);%Andor gain
        time = round(ICCD.trg+ICCD.exp_w/2);%���C�ʃv���b�g����
        if dtacq.num == 39
            dtacq.shot = a039shot;
            dtacq.tfshot = a039tfshot;
        end
        if cal_flow
            %�C�I�����x�A�t���[���v�Z
            [V_i,absV,T_i] = cal_ionflow(date,ICCD,mpoints,pathname,show_offset,plot_fit,save_fit,save_flow);
        elseif load_flow
            %�ۑ��ς݃C�I�����x�A�t���[��ǂݎ��
            [V_i,absV,T_i] = load_ionflow(date,ICCD,pathname);
        end
        %���C�ʂ��v���b�g
        if plot_psi
            [grid2D,data2D,ok_z,ok_r] = cal_pcb200ch(date,dtacq,pathname,mesh_rz,expval,trange);
            plot_psi200ch_at_t(time,trange,grid2D,data2D,ok_z,ok_r);
        end
        %�C�I�����x�A�t���[���v���b�g
        if plot_flow
            if not(isempty(V_i))
                if plot_psi
                    plot_ionflow(V_i,absV,T_i,date,expval,ICCD,pathname,factor,mpoints,overlay_plot,save_fig,'ionflow')
                else
                    plot_ionflow(V_i,absV,T_i,date,expval,ICCD,pathname,factor,mpoints,false,save_fig,'ionflow')
                end
            end
        end
    end
else
    error('begin_cal must <= %d.', exp_log(end_row,4))
end