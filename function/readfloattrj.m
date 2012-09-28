function [trj,box] = readfloattrj(natom,filename,index,isbox)
%% readfloattrj
% read float trajectory file
%
% function [trj,box,ititle] = readambertrj(natom,filename,index,isbox)
%
% input: natom ���ҿ�
%        filename �ե�����̾
%        index �ɤ߹��ึ���ֹ�Υꥹ��(��ά�ġ���ά���줿���ˤ������Ҥ��ɤ�)
%        isbox �ܥå����դ���trj�ե����뤫�ݤ����֡��ꥢ��(false or true)��(��ά�ġ���ά���줿���ϥܥå����ʤ�=false)
%
% output: trj (nstep x natom*3) �ȥ饸�����ȥ� each row containing coordinates in the order [x1 y1 z1 x2 y2 z2 ...]
%         box (nstep x 3) box
% 
% example:
% �ܥå���̵���ξ��
% natom = 3343;
% trj = readfloattrj(natom,'md.trj');
% �ܥå���ͭ��ξ��
% natom = 62475;
% [trj,box] = readfloattrj(natom,'md_with_box.trj',1:natom,true);
% 

natom3 = natom*3;

if nargin < 3
  index = 1:natom;
end

if nargin < 4
  isbox = false;
end

if isbox
  nlimit = natom3 + 3;
else
  nlimit = natom3;
end

index3 = to3(index);

fid = fopen(filename, 'r');
trj = fread(fid, '*float');
fclose(fid);

nstep = length(trj) / nlimit;
trj = reshape(trj,nlimit,nstep)';

if isbox
  box = trj(:, end-2:end);
  trj(:, end-2:end) = [];
end

trj = trj(:, index3);

