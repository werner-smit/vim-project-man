let g:workspace_dir='/home/werner/workspace/'
let g:project_loaded = 0

function! LoadProject(name)
    let g:project_loaded = 0
    let pname = a:name
    let proj_dict = s:getProjectDict()
    let proj_path = get(proj_dict, pname)
    if proj_path == '0'
        echo 'Project "'.pname.'" not found.'
        return
    endif
    let proj_path = proj_path . '/'
    if isdirectory(proj_path)
	let g:project_dir= proj_path
    else
	let g:project_dir= g:workspace_dir . proj_path . '/'
    endif

    exe 'cd ' . g:project_dir
    if findfile('.project', g:project_dir)
    	exe 'source ' . g:project_dir . '.project'
    endif
    "echo 'Changing project dir to: ' . g:project_dir 
    if findfile('Session.vim', g:project_dir)
    	exe 'source '.g:project_dir.' Session.vim'
    	echo 'Loading Session.vim'
    endif
    
    let project_file = g:project_dir.'.load_project'
    if filereadable(project_file)
    	for _file in readfile(project_file)
	    exe 'e '._file
	    "echo 'Loading '._file
	endfor
    else
    	echo 'No .load_project file found in '.project_file
    endif

    let g:project_loaded = 1
    set tags=./tags;~/
endfunction

function! BufffersList()
  let all = range(0, bufnr('$'))
  let res = []
  for b in all
    if buflisted(b)
      call add(res, b)
    endif
  endfor
  return res
endfunction

function! SaveProject()
    let tablist = []
    if g:project_loaded != 1
        return
    endif
    for i in BufffersList()
	let fname = bufname(i+0)
	if filereadable(fname)
	    call add(tablist, fname)
	endif
    endfor
    if exists("g:project_dir")
        let save_file = g:project_dir . '/' . '.load_project'
    else
    	echo "No project loaded.."
    	return
    endif
    call writefile(tablist, save_file)
endfunction

function! s:getProjectDict()
    let project_list = $HOME.'/.vim/.projects'
    let proj_dict = {}
    for _file in readfile(project_list)
        let _path_lst = split(_file, ':')
        if len(_path_lst) > 0
            let proj_dict[_path_lst[0]] = _path_lst[1] 
        endif
    endfor
    return proj_dict
endfunction

function! s:saveProjectDict(proj_dict)
    let new_lst = []
    let project_list = $HOME.'/.vim/.projects'
    for kv in items(a:proj_dict)
        call add(new_lst,join(kv,':'))
    endfor
    call writefile(new_lst, project_list)
endfunction

function! AddProject(...)
    let pname = input('Project name: ')
    let ppath = input('Project path: ', getcwd(), "dir")
    let new_lst = []
    let proj_dict = s:getProjectDict()
    let proj_dict[pname] = getcwd()
    call s:saveProjectDict(proj_dict)
    call LoadProject(pname)
    return 
    for _file in readfile(project_list)
        let _path_lst = split(_file, ':')
        if pname == _path_lst[0]
            call add(new_lst, join([pname,ppath],':'))
            let found = 1
        else
            call add(new_lst, _file)
        endif
    endfor
    if !exists("found")
        call add(new_lst, join([pname,getcwd()],':'))
    endif
    call writefile(new_lst, project_list)
endfunction

function! s:ProjectList(ArgLead, CmdLine, CursorPos)
    let paths = filter(keys(s:getProjectDict()), 'v:val=~? a:ArgLead')
    let names = []
    for path in paths
    	call add(names,split(path, '/')[-1:][0])
    endfor
    return names
endfunction

function! s:ProjectList_1(ArgLead, CmdLine, CursorPos)
    let paths = filter(split(globpath(g:workspace_dir, '*'), '\n'), 'v:val=~? a:ArgLead')
    let names = [getcwd().'/']
    for path in paths
    	call add(names,split(path, '/')[-1:][0])
    endfor
    return names
endfunction

command! -bang -nargs=? PRJAdd call AddProject()
command! -bang -complete=customlist,s:ProjectList -nargs=? PRJLoad call LoadProject('<args>')
command! -bang -nargs=? PRJSave call SaveProject()

" autocmd BufNew * call SaveProject()
autocmd BufReadPost * call SaveProject()
