

���낿���˂�v���X Ver.{=0ch+ver=} - Readme.txt

����WEB : http://zerochplus.sourceforge.jp/


���͂��߂�
�@���̃t�@�C���́A�{�Ƃ��낿���˂�(http://0ch.mine.nu/)�̃X�N���v�g���Q�����˂�d�l
�ɉ�������Ƃ����ړI�ł͂��܂����v���W�F�N�g�u���낿���˂�v���X�v�̎�舵���������ł��B
�@�Ȃ�ׂ��ǂ̂悤�Ȑl�ł��킩��悤�ɉ�����Ă��������ł����ȂɂԂ񐻍�҂��ʓ|��������
�Ȃ̂Ŏ���Ȃ��_�����邩������܂��񂪂��������������B
�@�Ȃ����̃t�@�C���͖{�Ƃ��낿���˂��/readme/readme.txt�����ɕҏW����Ă��܂��̂ňꕔ
�����܂܂̕���������܂��B���������������B


�����낿���˂�v���X�Ƃ�
�@�X���b�h�t���[�g�^�f���𓮍삳����Perl�X�N���v�g�Ƃ��Đ��삳�ꂽ���낿���˂�̋@�\
���P�łł��B
�@���Ƃ��Ƃ͂��낿���˂�X�N���v�g���g���č��ꂽ�f���Q�̉������K���������̂ō���
�������Ƃ��ړI�ł������u�ǂ����Ȃ�ق��̐l�ɂ��g���Ă��炨���v�Ƃ������Ƃō���̌��J�Ɏ�
��܂����B
�@���낿���˂�Ɠ������Q�����˂��p�u���E�U�ł��������݂Ɖ{�����\�ł��B


�������
  ���K�{��
    �ECGI�̓��삪�\��HTTPD�������Ă���CPerl 5.8�ȏ�(Perl 6�͊܂܂Ȃ�)�������͂��̃f�B
      �X�g���r���[�V�����n�\�t�g�E�F�A�����삷��OS
    �E5MB�ȏ�̃f�B�X�N�X�y�[�X 
  ��������
    �EsuEXEC��CGI���삪�\��Apache HTTP Server�������Ă���CPerl 5.8�ȏ�(Perl 6�͊܂܂�
      ��)�����삷��UNIX�n��������Linux�n��OS
    �E10MB�ȏ�̃f�B�X�N�X�y�[�X

���z�z�t�@�C���\��
zerochplus_x.x.x/
 + Readme/                    - �ŏ��ɓǂނׂ��t�@�C��
 |  + ArtisticLicense.txt
 |  + Readme.txt              - ���낿���˂�v���X��Readme�t�@�C��(����ł�)
 |  + Readme0ch.txt           - ���낿���˂�(�{��)��Readme�t�@�C��
 |
 + test/                      - ���낿���˂�v���X����f�B���N�g��
    + *.cgi                   - ��{����pCGI
    + datas/                  - �����f�[�^�E�Œ�f�[�^�i�[�p
    |  + 1000.txt
    |  + 2000000000.dat
    |  :
    + info/
    |  + category.cgi         - �f���J�e�S���̏�����`�t�@�C��
    |  + errmes.cgi           - �G���[���b�Z�[�W��`�t�@�C��
    |  + users.cgi            - �������[�U(Administrator)��`�t�@�C��
    + module/
    |  + *.pl                 - ���낿���˂郂�W���[��
    + mordor/
    |  + *.pl                 - �Ǘ�CGI�p���W���[��
    + plugin/
    |  + 0ch_*.pl             - �v���O�C���X�N���v�g
    + perllib/
       + *                    - ���낿���˂�v���X�ɕK�v�ȃp�b�P�[�W

���ݒu���@�T��
�@Wiki�ɂĉ摜���̐ݒu���@�̉�������J���Ă��܂��B
  �EInstall - ���낿���˂�v���X Wiki
    http://sourceforge.jp/projects/zerochplus/wiki/Install

1.�X�N���v�g�ύX

	�E�\���t�@�C��test������.cgi�t�@�C�����J���A1�s�ڂɏ����Ă���perl�p�X
	  �����ɍ��킹�ĕύX���܂��B
	
	���ȉ��̂悤�ɂȂ��Ă���ꏊ��ύX���܂��B
	
		#!/usr/bin/perl

2.�X�N���v�g�A�b�v���[�h

	�E�\���t�@�C����test�ȉ����ׂĂ�ݒu�T�[�o�ɃA�b�v���[�h���܂��B
	�E�A�b�v���[�h��p�[�~�b�V������K�؂Ȓl�ɐݒ肵�܂��B
	
	���p�[�~�b�V�����̒l�ɂ��Ă͈ȉ��̃y�[�W���Q��
	�EPermission - ���낿���˂�v���X
	  http://sourceforge.jp/projects/zerochplus/wiki/Permission

3.�ݒ�

	�E[�ݒu�T�[�o]/test/admin.cgi�ɃA�N�Z�X���܂��B
	�E���[�U��"Administrator",�p�X"zeroch"�Ń��O�C�����܂��B
	�E��ʏ㕔��"�V�X�e���ݒ�"���j���[��I�����܂��B
	�E��ʍ�����"��{�ݒ�"���j���[��I�����܂��B
	�E����[�ғ��T�[�o]��K�؂Ȓl�ɐݒ肵�A[�ݒ�]�{�^���������܂��B
	�E�ēx��ʍ�����"��{�ݒ�"���j���[��I�����āA�ғ��T�[�o���X�V����Ă��邱�Ƃ��m�F��
	  �Ă��������B
	  �i��������Ă��Ȃ��ꍇ�̓p�[�~�b�V�����̐ݒ�ɖ�肪���邩������܂���j
	�E��ʏ㕔��"���[�U�["���j���[��I�����܂��B
	�E��ʒ�����[User Name]���"Administrator"��I�����܂��B
	�E���[�U���A�p�X���[�h��ύX����[�ݒ�]�{�^���������܂��B
	�E��ʏ㕔��"���O�I�t"��I�����܂��B

4.�f���쐬

	�E��قǐݒ肵���Ǘ��҃��[�U�Ń��O�C�����܂��B
	�E��ʏ㕔��"�f����"���j���[��I�����܂��B
	�E��ʍ�����"�f���쐬"���j���[��I�����܂��B
	�E�K�v���ڂ��L������[�쐬]�{�^���������܂��B

5.�f���ݒ�

	�E��ʏ㕔��"�f����"���j���[��I�����܂��B
	�E�f���ꗗ���A�ݒ肷��f����I�����܂��B
	�E��ʏ㕔��"�f���ݒ�"��I�����܂��B
	�E�e���ڂ�ݒ肵�܂��B

-----------------------------------------------------------------------
�����ӁF
	�E�ݒu���Administrator���[�U�͕K���ύX���s���Ă��������B�ݒu�����
	  ���[�U���ƃp�X���[�h���Œ�Ȃ̂ŁA���u���Ă����ƊǗ��҈ȊO�ɊǗ�
	  �����Ń��O�C������Ă��܂��댯������܂��B
-----------------------------------------------------------------------


�����C�Z���X
�@�{�X�N���v�g�̃��C�Z���X�͖{�Ƃ��낿���˂�Ɠ��������Ƃ��܂��B�ȉ��͖{�Ƃ��낿����
�� /readme/readme.txt ����̈��p�ł��B

> �{�X�N���v�g�͎��R�ɉ����E�Ĕz�z���Ă�����Ă��܂��܂���B�܂��A�{�X�N���v�g�ɂ���ďo
�͂����N���W�b�g�\��(�o�[�W�����\��)�Ȃǂ̕\���������Ďg�p���Ă�����Ă��\���܂���B
> �������A��҂͖{�X�N���v�g�ƕt���t�@�C���Ɋւ��钘�쌠��������܂���B�܂��A��҂͖{�X
�N���v�g�g�p�Ɋւ��Ĕ������������Ȃ�g���u���ɂ��ӔC�𕉂����˂܂��̂ł��������������B

�@�܂�remake.cgi�̒��쌠����C�Z���X�͕ʂ̕��ɂ���Aremake.cgi�̍�҂ɒ��쌠����C�Z���X��
�A�����܂��B

�@perllib�Ɋ܂߂Ă���p�b�P�[�W�ɂ��Ă͌�q�B

���o�[�W�����A�b�v�ɂ���
�@0.7.0����o�[�W�����A�b�v�̍ۂɂ͊Ǘ���ʂɂĒʒm����悤�ɂȂ�܂����B
�@�Z�L�����e�B�C�����܂ރA�b�v�f�[�g�����X����܂��̂ł��萔���Ǝv���܂����A���܂߂ȃA�b
�v�f�[�g����낵�����˂������܂��B


���w���v�E�T�|�[�g
�@����ɏڂ������e�������߂̕��͈ȉ��̃y�[�W���Q�Ƃ��Ă��������B
  �E�w���v - ���낿���˂�v���X
    http://zerochplus.sourceforge.jp/help/
  �E���낿���˂�v���XWiki
    http://sourceforge.jp/projects/zerochplus/wiki/

�@�ȏ�̃y�[�W�ɋ��߂Ă����񂪂Ȃ��ꍇ��s��񍐂Ȃǂ��Ă���������ꍇ�͈ȉ����炨��
�����킹���������B
  �E�T�|�[�g - ���낿���˂�v���X
    http://zerochplus.sourceforge.jp/support/

���ӎ�
�@���낿���˂�v���X���쐬����ɂ������Ďx�����Ă������������ׂĂ̊F�l�Ɋ��ӂ��܂��B
�@�����ĉ���茳�ł���X�N���v�g�̂��낿���˂������ꂽ���_���コ��ɂ͐S���犴�ӂ�
�܂��B

������WEB
�@http://zerochplus.sourceforge.jp/

��perllib�ɂ���p�b�P�[�W
�@�����͂��낿���˂�v���X�̎��s�ɕK�v�ȃp�b�P�[�W�ł��B���łɃC���X�g�[������Ă���
�T�[�o�[�����邩������܂��񂪁A�ꉞ�܂߂Ă����܂��B
�@�ȉ��̓p�b�P�[�W�̏ڍׂł��B

Digest-SHA-PurePerl
Perl implementation of SHA-1/224/256/384/512
    Version:    5.72
    Released:   2012-09-24
    Author:     Mark Shelor <mshelor@cpan.org>
    License:    Artistic License
    CPAN:       http://search.cpan.org/dist/Digest-SHA-PurePerl-5.72/

Net-DNS-Lite
a pure-perl DNS resolver with support for timeout
    Version:    0.09
    Released:   2012-06-20
    Author:     Kazuho Oku <kazuhooku@gmail.com>
    License:    Artistic License
    CPAN:       http://search.cpan.org/dist/Net-DNS-Lite-0.09/

List-MoreUtils
Provide the stuff missing in List::Util
    Version:    0.33
    Released:   2011-08-04
    Author:     Adam Kennedy <adamk@cpan.org>
    License:    Artistic License
    CPAN:       http://search.cpan.org/dist/List-MoreUtils-0.33/

