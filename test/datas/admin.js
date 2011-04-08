//----------------------------------------------------------------------------------------
//	submit処理
//----------------------------------------------------------------------------------------
function DoSubmit(modName, mode, subMode)
{
	// 付加情報設定
	document.ADMIN.MODULE.value		= modName;				// モジュール名
	document.ADMIN.MODE.value		= mode;					// メインモード
	document.ADMIN.MODE_SUB.value	= subMode;				// サブモード
	
	// POST送信
	document.ADMIN.submit();
}

//----------------------------------------------------------------------------------------
//	オプション設定
//----------------------------------------------------------------------------------------
function SetOption(key, val)
{
	document.ADMIN.elements[key].value = val;
}
