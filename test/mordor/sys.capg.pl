#============================================================================================================
#
#	システム管理 - 共通キャップグループ モジュール
#
#============================================================================================================
package	MODULE;

use strict;
use warnings;

#------------------------------------------------------------------------------------------------------------
#
#	コンストラクタ
#	-------------------------------------------------------------------------------------
#	@param	なし
#	@return	モジュールオブジェクト
#
#------------------------------------------------------------------------------------------------------------
sub new
{
	my $class = shift;
	
	my $obj = {
		'LOG'	=> [],
	};
	bless $obj, $class;
	
	return $obj;
}

#------------------------------------------------------------------------------------------------------------
#
#	表示メソッド
#	-------------------------------------------------------------------------------------
#	@param	$Sys	MELKOR
#	@param	$Form	SAMWISE
#	@param	$CGI	管理システム
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub DoPrint
{
	my $this = shift;
	my ($Sys, $Form, $CGI) = @_;
	
	# 管理マスタオブジェクトの生成
	require './mordor/sauron.pl';
	my $Base = SAURON->new;
my $Page =
	$Base->Create($Sys, $Form);
	
	my $subMode = $Form->Get('MODE_SUB');
	
	# メニューの設定
	SetMenuList($Base, $CGI);
	
	my $indata = undef;
	
	# グループ一覧画面
	if ($subMode eq 'LIST') {
		#PrintGroupList($Page, $Sys, $Form);
		$indata = PreparePageGroupList($Sys, $Form);
	}
	# グループ作成画面
	elsif ($subMode eq 'CREATE') {
		PrintGroupSetting($Page, $Sys, $Form, 0);
		#$indata = PreparePageGroupSetting($Sys, $Form, 0);
	}
	# グループ編集画面
	elsif ($subMode eq 'EDIT') {
		PrintGroupSetting($Page, $Sys, $Form, 1);
		#$indata = PreparePageGroupSetting($Sys, $Form, 0);
	}
	# グループ削除確認画面
	elsif ($subMode eq 'DELETE') {
		PrintGroupDelete($Page, $Sys, $Form);
		#$indata = PreparePageGroupDelete($Sys, $Form);
	}
	# グループ設定完了画面
	elsif ($subMode eq 'COMPLETE') {
		$indata = $Base->PreparePageComplete('キャップグループ処理', $this->{'LOG'});
	}
	# グループ設定失敗画面
	elsif ($subMode eq 'FALSE') {
		$indata = $Base->PreparePageError($this->{'LOG'});
	}
	
	$Base->Print($Sys->Get('_TITLE'), 1, $indata);
}

#------------------------------------------------------------------------------------------------------------
#
#	機能メソッド
#	-------------------------------------------------------------------------------------
#	@param	$Sys	MELKOR
#	@param	$Form	SAMWISE
#	@param	$CGI	管理システム
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub DoFunction
{
	my $this = shift;
	my ($Sys, $Form, $CGI) = @_;
	
	my $subMode = $Form->Get('MODE_SUB');
	my $err = 0;
	
	# グループ作成
	if ($subMode eq 'CREATE') {
		$err = FunctionGroupSetting($Sys, $Form, 0, $this->{'LOG'});
	}
	# グループ編集
	elsif ($subMode eq 'EDIT') {
		$err = FunctionGroupSetting($Sys, $Form, 1, $this->{'LOG'});
	}
	# グループ削除
	elsif ($subMode eq 'DELETE') {
		$err = FunctionGroupDelete($Sys, $Form, $this->{'LOG'});
	}
	
	# 処理結果表示
	if ($err) {
		$CGI->{'LOGGER'}->Put($Form->Get('UserName'), "SYSCAP_GROUP($subMode)", "ERROR:$err");
		push @{$this->{'LOG'}}, $err;
		$Form->Set('MODE_SUB', 'FALSE');
	}
	else {
		$CGI->{'LOGGER'}->Put($Form->Get('UserName'), "SYSCAP_GROUP($subMode)", 'COMPLETE');
		$Form->Set('MODE_SUB', 'COMPLETE');
	}
	
	$this->DoPrint($Sys, $Form, $CGI);
}

#------------------------------------------------------------------------------------------------------------
#
#	メニューリスト設定
#	-------------------------------------------------------------------------------------
#	@param	$Base	SAURON
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub SetMenuList
{
	my ($Base, $CGI) = @_;
	
	# 共通表示メニュー
	$Base->SetMenu('グループ一覧', "'sys.capg','DISP','LIST'");
	
	# 管理グループ設定権限のみ
	if ($CGI->{'SECINFO'}->IsAuthority($CGI->{'USER'}, $ZP::AUTH_SYSADMIN, '*')) {
		$Base->SetMenu('グループ登録', "'sys.capg','DISP','CREATE'");
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	グループ一覧の表示
#	-------------------------------------------------------------------------------------
#	@param	$Sys	システム変数
#	@param	$Form	フォーム変数
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PreparePageGroupList
{
	my ($Sys, $Form) = @_;
	
	my $CGI = $Sys->Get('ADMIN');
	my $Sec = $CGI->{'SECINFO'};
	my $cuser = $CGI->{'USER'};
	
	my $issysad = $Sec->IsAuthority($cuser, $ZP::AUTH_SYSADMIN, '*');
	
	# グループ情報の読み込み
	require './module/ungoliants.pl';
	my @groupSet;
	my $Group = SHELOB->new;
	$Group->Load($Sys, 1);
	$Group->GetKeySet(\@groupSet, 1);
	
	# キャップ一覧を出力
	my $groups = [];
	foreach my $id (@groupSet) {
		push @$groups, {
			'id'	=> $id,
			'name'	=> $Group->Get('NAME', $id),
			'expl'	=> $Group->Get('EXPL', $id),
			'color'	=> $Group->Get('COLOR', $id),
			'num'	=> scalar(@$_ = split(/,/, $Group->Get('CAPS', $id, ''))),
		};
	}
	
	my $indata = {
		'title'		=> 'Common CAP Group List',
		'intmpl'	=> 'sys.capg.grouplist',
		'groups'	=> $groups,
		'issysad'	=> $issysad,
	};
	
	return $indata;
}

#------------------------------------------------------------------------------------------------------------
#
#	グループ設定の表示
#	-------------------------------------------------------------------------------------
#	@param	$Sys	システム変数
#	@param	$Form	フォーム変数
#	@param	$mode	作成の場合:0, 編集の場合:1
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
=pod
sub PreparePageGroupSetting
{
	my ($Sys, $Form, $mode) = @_;
	
	# ユーザ情報の読み込み
	require './module/ungoliants.pl';
	my $Group = SHELOB->new;
	$Group->Load($Sys, 1);
	my @userSet;
	my $User = UNGOLIANT->new;
	$User->Load($Sys);
	$User->GetKeySet('ALL', '', \@userSet);
	
	my $group = {
		'name'	=> '',
		'expl'	=> '',
		'color'	=> '',
		'auth'	=> [],
		'user'	=> [],
	};
	foreach (0 .. $CAP_MAXNUM) {
		$group->{'auth'}->[$_] = 0;
	}
	
	my $selgroup = '';
	
	# 編集モードならユーザ情報を取得する
	if ($mode) {
		$selgroup = $Form->Get('SELECT_CAPGROUP');
		$group->{'name'} = $Group->Get('NAME', $selgroup);
		$group->{'expl'} = $Group->Get('EXPL', $selgroup);
		$group->{'color'} = $Group->Get('COLOR', $selgroup);
		my @auth = split(/,/, $Group->Get('AUTH', $selgroup, ''));
		my @user = split(/,/, $Group->Get('CAPS', $selgroup, ''));
		foreach (@auth) {
			$group->{'auth'}->[$_-0] = 1;
		}
	}
	else {
		$group->{'name'} = '';
		$group->{'expl'} = '';
		$group->{'color'} = '';
	}
	
	# 所属ユーザ一覧表示
	foreach my $id (@userSet) {
		my $groupid = $Group->GetBelong($id);
		# システム共通キャップ、他のグループに所属しているキャップは非表示
		if (!$User->Get('SYSAD', $id) &&
			($groupid eq '' || $groupid eq $selgroup)) {
			push @{$group->{'user'}}, {
				'id'		=> $id,
				'name'		=> $Group->Get('NAME', $id),
				'full'		=> $Group->Get('FULL', $id),
				'belong'	=> ($groupid ne '' && $groupid eq $selgroup ? 1 : 0),
			};
		}
	}
	
	my $indata = {
		'title'		=> 'Common CAP Group ' . ($mode ? 'Edit' : 'Create'),
		'intmpl'	=> 'sys.capg.groupedit',
		'modesub'	=> $Form->Get('MODE_SUB'),
		'selgroup'	=> $selgroup,
		'group'		=> $group,
	};
	
	return $indata;
}
=cut

sub PrintGroupSetting
{
	my ($Page, $Sys, $Form, $mode) = @_;
	my ($Group, $User, @userSet, @authNum, $i, $num, $id);
	my ($name, $expl, $color, @auth, @user, $common);
	
	$Sys->Set('_TITLE', 'Common CAP Group Edit')	if ($mode == 1);
	$Sys->Set('_TITLE', 'Common CAP Group Create')	if ($mode == 0);
	
	require './module/ungoliants.pl';
	$User = UNGOLIANT->new;
	$Group = SHELOB->new;
	
	# ユーザ情報の読み込み
	$User->Load($Sys);
	$Group->Load($Sys, 1);
	$User->GetKeySet('ALL', '', \@userSet);
	
	# 編集モードならユーザ情報を取得する
	if ($mode) {
		$name = $Group->Get('NAME', $Form->Get('SELECT_CAPGROUP'));
		$expl = $Group->Get('EXPL', $Form->Get('SELECT_CAPGROUP'));
		$color = $Group->Get('COLOR', $Form->Get('SELECT_CAPGROUP'));
		@auth = split(/\,/, (defined ($_ = $Group->Get('AUTH', $Form->Get('SELECT_CAPGROUP'))) ? $_ : ''));
		@user = split(/\,/, (defined ($_ = $Group->Get('CAPS', $Form->Get('SELECT_CAPGROUP'))) ? $_ : ''));
		
		# 権限番号マッピング配列を作成
		for ($i = 0 ; $i < $ZP::CAP_MAXNUM ; $i++) {
			$authNum[$i] = '';
		}
		foreach $num (@auth) {
			$authNum[$num - 1] = 'checked';
		}
	}
	else {
		$Form->Set('SELECT_CAPGROUP', '');
		$name = '';
		$expl = '';
		$color = '';
		for ($i = 0 ; $i < $ZP::CAP_MAXNUM ; $i++) {
			$authNum[$i] = '';
		}
	}
	
	$Page->Print("<center><br><table border=0 cellspacing=2 width=90%>");
	$Page->Print("<tr><td colspan=2>各情報を入力して[設定]ボタンを押してください。</td></tr>");
	$Page->Print("<tr><td colspan=2><hr></td></tr>");
	$Page->Print("<tr><td class=\"DetailTitle\" colspan=2>基本情報</td></tr>");
	$Page->Print("<tr><td colspan=2><table cellspcing=2>");
	$Page->Print("<tr><td class=\"DetailTitle\">グループ名称</td><td>");
	$Page->Print("<input name=GROUPNAME_CAP type=text size=50 value=\"$name\"></td></tr>");
	$Page->Print("<tr><td class=\"DetailTitle\">説明</td><td>");
	$Page->Print("<input name=GROUPSUBS_CAP type=text size=50 value=\"$expl\"></td></tr>");
	$Page->Print("<tr><td class=\"DetailTitle\">キャップの色(無記入でデフォルト)</td><td>");
	$Page->Print("<input name=GROUPCOLOR_CAP type=text size=50 value=\"$color\"></td></tr>");
	$Page->Print("</table><br></td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\" width=40%>権限情報</td>");
	$Page->Print("<td class=\"DetailTitle\">所属キャップ</td></tr><tr><td valign=top>");
	
	# 権限一覧表示
	$Page->Print("<input type=checkbox name=C_SUBJECT $authNum[0] value=on>タイトル文字数規制解除<br>");
	$Page->Print("<input type=checkbox name=C_NAME $authNum[1] value=on>名前文字数規制解除<br>");
	$Page->Print("<input type=checkbox name=C_MAIL $authNum[2] value=on>メール文字数規制解除<br>");
	$Page->Print("<input type=checkbox name=C_CONTENTS $authNum[3] value=on>本文文字数規制解除<br>");
	$Page->Print("<input type=checkbox name=C_CONTLINE $authNum[4] value=on>本文行数規制解除<br>");
	$Page->Print("<input type=checkbox name=C_LINECOUNT $authNum[5] value=on>本文1行文字数規制解除<br>");
	$Page->Print("<input type=checkbox name=C_NONAME $authNum[6] value=on>名無し規制解除<br>");
	$Page->Print("<input type=checkbox name=C_THREAD $authNum[7] value=on>スレッド作成規制解除<br>");
	$Page->Print("<input type=checkbox name=C_THREADCAP $authNum[8] value=on>スレッド作成可能\(キャップ)<br>");
	$Page->Print("<input type=checkbox name=C_CONTINUAS $authNum[9] value=on>連続投稿規制解除<br>");
	$Page->Print("<input type=checkbox name=C_DUPLICATE $authNum[10] value=on>二重書き込み規制解除<br>");
	$Page->Print("<input type=checkbox name=C_SHORTWRITE $authNum[11] value=on>短時間投稿規制解除<br>");
	$Page->Print("<input type=checkbox name=C_READONLY $authNum[12] value=on>読取専用規制解除<br>");
	$Page->Print("<input type=checkbox name=C_IDDISP $authNum[13] value=on>ID非表\示<br>");
	$Page->Print("<input type=checkbox name=C_NOSLIP $authNum[22] value=on>端末識別子非表\示<br>");
	$Page->Print("<input type=checkbox name=C_HOSTDISP $authNum[14] value=on>本文ホスト非表\示<br>");
	$Page->Print("<input type=checkbox name=C_MOBILETHREAD $authNum[15] value=on>携帯からのスレッド作成<br>");
	$Page->Print("<input type=checkbox name=C_FIXHANLDLE $authNum[16] value=on>コテハン★表\示<br>");
	$Page->Print("<input type=checkbox name=C_SAMBA $authNum[17] value=on>Samba規制解除<br>");
	$Page->Print("<input type=checkbox name=C_PROXY $authNum[18] value=on>プロキシ規制解除<br>");
	$Page->Print("<input type=checkbox name=C_JPHOST $authNum[19] value=on>海外ホスト規制解除<br>");
	$Page->Print("<input type=checkbox name=C_NGUSER $authNum[20] value=on>ユーザー規制解除<br>");
	$Page->Print("<input type=checkbox name=C_NGWORD $authNum[21] value=on>NGワード規制解除<br>");
	$Page->Print("</td>\n<td valign=top>");
	
	# 所属ユーザ一覧表示
	foreach $id (@userSet) {
		my $groupid = $Group->GetBelong($id);
		# システム共通キャップ、他のグループに所属しているキャップは非表示
		if (0 == $User->Get('SYSAD', $id) &&
			( $groupid eq '' || $groupid eq $Form->Get('SELECT_CAPGROUP') )) {
			my $userName = $User->Get('NAME', $id);
			my $fullName = $User->Get('FULL', $id);
			my $check = '';
			foreach (@user) {
				if ($_ eq $id) {
					$check = 'checked'
				}
			}
			$Page->Print("<input type=checkbox name=BELONGUSER_CAP value=$id $check>$userName($fullName)<br>");
		}
	}
	
	# submit設定
	$common = "'" . $Form->Get('MODE_SUB') . "'";
	$common = "onclick=\"DoSubmit('sys.capg', 'FUNC', $common)\"";
	
	$Page->HTMLInput('hidden', 'SELECT_CAPGROUP', $Form->Get('SELECT_CAPGROUP'));
	$Page->Print("</td></tr>");
	$Page->Print("<tr><td colspan=2><hr></td></tr>");
	$Page->Print("<tr><td colspan=2 align=left>");
	$Page->Print("<input type=submit value=\"　設定　\" $common></td></tr>");
	$Page->Print("</table><br>");
}

#------------------------------------------------------------------------------------------------------------
#
#	グループ削除確認画面の表示
#	-------------------------------------------------------------------------------------
#	@param	$Page	ページコンテキスト
#	@param	$SYS	システム変数
#	@param	$Form	フォーム変数
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintGroupDelete
{
	my ($Page, $SYS, $Form) = @_;
	my ($Group, $BBS, @groupSet, $name, $expl, $rang, $id, $common);
	
	$SYS->Set('_TITLE', 'Common CAP Group Delete Confirm');
	
	require './module/ungoliants.pl';
	$Group = SHELOB->new;
	$Group->Load($SYS, 1);
	
	# ユーザ情報を取得
	@groupSet = $Form->GetAtArray('CAP_GROUPS');
	
	$Page->Print("<br><center><table border=0 cellspacing=2 width=100%>");
	$Page->Print("<tr><td colspan=2>以下のキャップグループを削除します。</td></tr>");
	$Page->Print("<tr><td colspan=2><hr></td></tr>");
	
	$Page->Print("<tr>");
	$Page->Print("<td class=\"DetailTitle\" style=\"width:150\">Group Name</td>");
	$Page->Print("<td class=\"DetailTitle\" style=\"width:200\">Subscription</td>");
	
	# ユーザリストを出力
	foreach $id (@groupSet) {
		$name = $Group->Get('NAME', $id);
		$expl = $Group->Get('EXPL', $id);
		
		$Page->Print("<tr><td>$name</td><td>$expl</td></tr>\n");
		$Page->HTMLInput('hidden', 'CAP_GROUPS', $id);
	}
	
	$Page->Print("<tr><td colspan=2><hr></td></tr>");
	$Page->Print("<tr><td bgcolor=yellow colspan=3><b><font color=red>");
	$Page->Print("※注：削除したグループを元に戻すことはできません。</b><br>");
	$Page->Print("※注：削除するグループに所属しているキャップはすべて未所属状態になります。</td></tr>");
	$Page->Print("<tr><td colspan=2><hr></td></tr>");
	$Page->Print("<tr><td colspan=2 align=left><input type=button value=\"　削除　\" ");
	$Page->Print("onclick=\"DoSubmit('sys.capg','FUNC','DELETE')\" class=\"delete\"></td></tr>");
	$Page->Print("</table>");
}

#------------------------------------------------------------------------------------------------------------
#
#	グループ作成/編集
#	-------------------------------------------------------------------------------------
#	@param	$Sys	システム変数
#	@param	$Form	フォーム変数
#	@param	$mode	編集:1, 作成:0
#	@param	$pLog	ログ用
#	@return	エラーコード
#
#	2010.08.12 windyakin ★
#	 -> キャップ権限の追加
#
#------------------------------------------------------------------------------------------------------------
sub FunctionGroupSetting
{
	my ($Sys, $Form, $mode, $pLog) = @_;
	my ($Group, $User, @userSet, @authNum, @belongUser);
	my ($name, $expl, $color, $auth, $user, $i);
	
	# 権限チェック
	{
		my $SEC = $Sys->Get('ADMIN')->{'SECINFO'};
		my $chkID = $Sys->Get('ADMIN')->{'USER'};
		
		if (($SEC->IsAuthority($chkID, $ZP::AUTH_CAPGROUP, $Sys->Get('BBS'))) == 0) {
			return 1000;
		}
	}
	# 入力チェック
	{
		my @inList = ('GROUPNAME_CAP');
		if (! $Form->IsInput(\@inList)) {
			return 1001;
		}
	}
	require './module/ungoliants.pl';
	$User = UNGOLIANT->new;
	$Group = SHELOB->new;
	
	# ユーザ情報の読み込み
	$User->Load($Sys);
	$Group->Load($Sys, 1);
	
	# 基本情報の設定
	$name = $Form->Get('GROUPNAME_CAP');
	$expl = $Form->Get('GROUPSUBS_CAP');
	$color = $Form->Get('GROUPCOLOR_CAP');
	$color =~ s/[^\w\d\#]//ig;
	
	# 権限情報の生成
	my %field2auth = (
		'C_SUBJECT'			=> $ZP::CAP_FORM_LONGSUBJECT,
		'C_NAME'			=> $ZP::CAP_FORM_LONGNAME,
		'C_MAIL'			=> $ZP::CAP_FORM_LONGMAIL,
		'C_CONTENTS'		=> $ZP::CAP_FORM_LONGTEXT,
		'C_CONTLINE'		=> $ZP::CAP_FORM_MANYLINE,
		'C_LINECOUNT'		=> $ZP::CAP_FORM_LONGLINE,
		'C_NONAME'			=> $ZP::CAP_FORM_NONAME,
		'C_THREAD'			=> $ZP::CAP_REG_MANYTHREAD,
		'C_THREADCAP'		=> $ZP::CAP_LIMIT_THREADCAPONLY,
		'C_CONTINUAS'		=> $ZP::CAP_REG_NOBREAKPOST,
		'C_DUPLICATE'		=> $ZP::CAP_REG_DOUBLEPOST,
		'C_SHORTWRITE'		=> $ZP::CAP_REG_NOTIMEPOST,
		'C_READONLY'		=> $ZP::CAP_LIMIT_READONLY,
		'C_IDDISP'			=> $ZP::CAP_DISP_NOID,
		'C_HOSTDISP'		=> $ZP::CAP_DISP_NOHOST,
		'C_MOBILETHREAD'	=> $ZP::CAP_LIMIT_MOBILETHREAD,
		'C_FIXHANLDLE'		=> $ZP::CAP_DISP_HANLDLE,
		'C_SAMBA'			=> $ZP::CAP_REG_SAMBA,
		'C_PROXY'			=> $ZP::CAP_REG_DNSBL,
		'C_JPHOST'			=> $ZP::CAP_REG_NOTJPHOST,
		'C_NGUSER'			=> $ZP::CAP_REG_NGUSER,
		'C_NGWORD'			=> $ZP::CAP_REG_NGWORD,
	);
	my @auths = ();
	foreach (keys %field2auth) {
		if ($Form->Equal($_, 'on')) {
			push @auths, $field2auth{$_};
		}
	}
	$auth = join(',', @auths);
	
	# 所属ユーザ情報の生成
	@belongUser = $Form->GetAtArray('BELONGUSER_CAP');
	$user = join(',', @belongUser);
	
	# 設定情報の登録
	if ($mode){
		my $groupID = $Form->Get('SELECT_CAPGROUP');
		$Group->Set($groupID, 'NAME', $name);
		$Group->Set($groupID, 'EXPL', $expl);
		$Group->Set($groupID, 'COLOR', $color);
		$Group->Set($groupID, 'AUTH', $auth);
		$Group->Set($groupID, 'CAPS', $user);
		$Group->Set($groupID, 'ISCOMMON', 1);
	}
	else {
		$Group->Add($name, $expl, $color, $auth, $user, 1);
	}
	
	# 設定を保存
	$Group->Save($Sys, 1);
	
	# 処理ログ
	{
		my $id;
		push @$pLog, '■以下のキャップグループを登録しました。';
		push @$pLog, "グループ名称：$name";
		push @$pLog, "説明：$expl";
		push @$pLog, "色：$color";
		push @$pLog, "権限：$auth";
		push @$pLog, '所属キャップ：';
		foreach	$id (@belongUser){
			push @$pLog, '　　> ' . $User->Get('NAME', $id);
		}
	}
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	グループ削除
#	-------------------------------------------------------------------------------------
#	@param	$Sys	システム変数
#	@param	$Form	フォーム変数
#	@param	$pLog	ログ用
#	@return	エラーコード
#
#------------------------------------------------------------------------------------------------------------
sub FunctionGroupDelete
{
	my ($Sys, $Form, $pLog) = @_;
	my ($Group, @groupSet, $id);
	
	# 権限チェック
	{
		my $SEC = $Sys->Get('ADMIN')->{'SECINFO'};
		my $chkID = $Sys->Get('ADMIN')->{'USER'};
		
		if (($SEC->IsAuthority($chkID, $ZP::AUTH_CAPGROUP, $Sys->Get('BBS'))) == 0) {
			return 1000;
		}
	}
	require './module/ungoliants.pl';
	$Group = SHELOB->new;
	
	# ユーザ情報の読み込み
	$Group->Load($Sys, 1);
	
	push @$pLog, '■以下のグループを削除しました。';
	@groupSet = $Form->GetAtArray('CAP_GROUPS');
	
	foreach $id (@groupSet) {
		next if (! defined $Group->Get('NAME', $id));
		push @$pLog, $Group->Get('NAME', $id, '') . '(' . $Group->Get('EXPL', $id, '') . ')';
		$Group->Delete($id);
	}
	
	# 設定の保存
	$Group->Save($Sys, 1);
	
	return 0;
}

#============================================================================================================
#	Module END
#============================================================================================================
1;
