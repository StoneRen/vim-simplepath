"
" 自定义项目功能
" 
"


" {{{ 初始化
function! s:init()
	if !exists('Pro_File')
		if has('unix') || has('macunix')
			let g:Pro_File = $HOME . '/.vim_pro_list'
		else
			let g:Pro_File = $VIM . '/_vim_pro_list'
			if has('win32')
				" MS-Windows
				if $USERPROFILE != ''
					let g:Pro_File = $USERPROFILE . '\_vim_pro_list'
				endif
			endif
		endif
	endif

	if !filereadable(g:Pro_File)		
		let initData=[]
		call writefile(initData,g:Pro_File)
	endif
endfunction
" }}}


" {{{ 加载列表
function! s:load_list()
	if filereadable(g:Pro_File)
		let s:Pro_Dirs = readfile(g:Pro_File)
	else 
		echo "配置出错"
	endif
endfunction
" }}}

" {{{ 打开文件夹
function! s:Open_Dir(dir)
	if isdirectory(expand(a:dir))
		execute "tabnew ".a:dir
	else
		echohl "不是有效的路径"
	endif

endfunction
" }}}

" {{{ 命令行自动补全
function! s:Pro_Complete(ArgLead, CmdLine, CursorPos)
	call s:init()
	call s:load_list()
	if a:ArgLead == ''
		" Return the complete list of MRU files
		return s:Pro_Dirs
	else
		" Return only the files matching the specified pattern
		return filter(copy(s:Pro_Dirs), 'v:val =~? a:ArgLead')
	endif
endfunction
" }}}


" {{{ 打开小窗口
function! s:Pro_Open_win(...)
	call s:load_list()
	if a:0 == 0
		"silent! 0put = s:Pro_Dirs
		exec 'botright 10 split '.g:Pro_File
	else
		let m = filter(copy(s:Pro_Dirs), 'stridx(v:val, a:1) != -1')
		if len(m) == 0
			" No match. Try using it as a regular expression
			let m = filter(copy(s:Pro_Dirs), 'v:val =~# a:1')
		endif
		silent! 0put =m

	endif

	" 不产生buffer文件,否则还需要保存
	setlocal buftype=nofile
	setlocal bufhidden=delete
	setlocal noswapfile
	setlocal nowrap
	setlocal nobuflisted

	" 回车可以直接打开文件
	nnoremap <buffer> <silent> <CR>
				\ :call <SID>Pro_Open_Select_Dir()<CR>
	vnoremap <buffer> <silent> <CR>
				\ :call <SID>Pro_Open_Select_Dir()<CR>
endfunction

" }}}

" {{{ 打开列表中指定的文件夹
function! s:Pro_Open_Select_Dir()
	let fname = getline(a:firstline, a:lastline)
	silent! close
	execute "tabnew ".fname[0]
endfunction
" }}}


" {{{ 添加新路径
function! s:Pro_Create_path(r)
	call s:init()
	call s:load_list()
	let l=[]
	let curDir = getcwd()
	" 判断是否已经添加过
	let idx = index (s:Pro_Dirs,curDir)
	
	if idx != -1
		if a:r == 'y'
			call remove(s:Pro_Dirs,idx)
			echo "路径: ".curDir ." 已经存在,进行更新"
		else
			echo "路径: ".curDir ." 已经保存"
			return
		endif
	endif

	call extend(l,s:Pro_Dirs)
	call add(l,curDir)
	if a:r == 'y'
		call extend(l,split(globpath(curDir, '*'), '\n'))
	endif
	call writefile(l,g:Pro_File)
	"execute 'tabnew '.g:Pro_File
	echo "路径: ".curDir ." 已经保存"
endfunction
" }}}

" {{{ 打开文件列表
function! s:Pro_Open_List()
	execute "tabnew ".g:Pro_File
endfunction
" }}}

" {{{ 操作命令
function! s:Pro_Cmd(pat)
	call s:init()
	call s:load_list()

	if a:pat == ''
		call s:Pro_Open_win()
		return 
	endif

	let m = filter(copy(s:Pro_Dirs), 'stridx(v:val, a:pat) != -1')
	if len(m) > 0
		if len(m) == 1
			execute "tabnew ".m[0]
			return
		endif
	else
		echo '没有匹配的结果'
	endif
endfunction
" }}}


" {{{ 操作快捷键
command! -nargs=? -complete=customlist,s:Pro_Complete OP
			\ call s:Pro_Cmd(<q-args>)

command! OPC call s:Pro_Create_path(<q-args>)
command! OPR call s:Pro_Create_path("y")
command! OPO call s:Pro_Open_List()
" }}}

