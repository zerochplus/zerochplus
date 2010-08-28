#============================================================================================================
#
#	�g���@�\ - ���ꋭ���\���@�\
#	0ch_stress.pl
#	---------------------------------------------------------------------------
#	2005.02.19 start
#
#============================================================================================================
package ZPL_stress;

#------------------------------------------------------------------------------------------------------------
#
#	�R���X�g���N�^
#	-------------------------------------------------------------------------------------
#	@param	�Ȃ�
#	@return	�I�u�W�F�N�g
#
#------------------------------------------------------------------------------------------------------------
sub new
{
	my		$this = shift;
	my		$obj={};
	bless($obj,$this);
	return $obj;
}

#------------------------------------------------------------------------------------------------------------
#
#	�g���@�\���̎擾
#	-------------------------------------------------------------------------------------
#	@param	�Ȃ�
#	@return	���̕�����
#
#------------------------------------------------------------------------------------------------------------
sub getName
{
	my	$this = shift;
	return '���ꋭ���\���@�\\';
}

#------------------------------------------------------------------------------------------------------------
#
#	�g���@�\�����擾
#	-------------------------------------------------------------------------------------
#	@param	�Ȃ�
#	@return	����������
#
#------------------------------------------------------------------------------------------------------------
sub getExplanation
{
	my	$this = shift;
	return '�擪�� ��,��,# �̕t�����s�������\�����܂��B';
}

#------------------------------------------------------------------------------------------------------------
#
#	�g���@�\�^�C�v�擾
#	-------------------------------------------------------------------------------------
#	@param	�Ȃ�
#	@return	�g���@�\�^�C�v(�X������:1,���X:2,read:4,index:8)
#
#------------------------------------------------------------------------------------------------------------
sub getType
{
	my	$this = shift;
	return (1 | 2);
}

#------------------------------------------------------------------------------------------------------------
#
#	�g���@�\���s�C���^�t�F�C�X
#	-------------------------------------------------------------------------------------
#	@param	$sys	MELKOR
#	@param	$form	SAMWISE
#	@return	����I���̏ꍇ��0
#
#------------------------------------------------------------------------------------------------------------
sub execute
{
	my	$this = shift;
	my	($sys,$form) = @_;
	
	my $content = $form->Get('MESSAGE');
	STRESS(\$content);
	$form->Set('MESSAGE',$content);
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	���ꋭ���\��
#	-------------------------------------------------------------------------------------
#	@param	$text	�Ώە�����
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub STRESS
{
	my	($text) = @_;
	
	$$text = '<br>' . $$text . '<br>';
	
	# �����p�ϊ�
	while($$text =~ /<br>��(.*?)<br>/){
		$$text =~ s/<br>��(.*?)<br>/<br><font color=gray>��$1<\/font><br>/;
	}
	# �����p�ϊ�
	while($$text =~ /<br>��(.*?)<br>/){
		$$text =~ s/<br>��(.*?)<br>/<br><font color=green>��$1<\/font><br>/;
	}
	# #���p�ϊ�
	while($$text =~ /<br>#(.*?)<br>/){
		$$text =~ s/<br>#(.*?)<br>/<br><font color=green>#$1<\/font><br>/;
	}
	
	# �ŏ��ɂ���<br>�����O��
	$$text = substr($$text,4,length($$text) - 8);
}

#============================================================================================================
#	Module END
#============================================================================================================
1;