//----------------------------------------------------------------------------------------
//	submit����
//----------------------------------------------------------------------------------------
function DoSubmit(modName, mode, subMode)
{
	// �t�����ݒ�
	document.ADMIN.MODULE.value		= modName;				// ���W���[����
	document.ADMIN.MODE.value		= mode;					// ���C�����[�h
	document.ADMIN.MODE_SUB.value	= subMode;				// �T�u���[�h
	
	// POST���M
	document.ADMIN.submit();
}

//----------------------------------------------------------------------------------------
//	�I�v�V�����ݒ�
//----------------------------------------------------------------------------------------
function SetOption(key, val)
{
	document.ADMIN.elements[key].value = val;
}
