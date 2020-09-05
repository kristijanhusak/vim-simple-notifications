let s:hl_by_type = {
      \ 'error': 'NotificationError',
      \ 'warning': 'NotificationWarning',
      \ }

function! s:setup_colors() abort
  let warning_fg = ''
  let warning_bg = ''
  let error_fg = ''
  let error_bg = ''
  let warning_bg = synIDattr(hlID('WarningMsg'), 'bg')
  let warning_fg = synIDattr(hlID('WarningMsg'), 'fg')
  if empty(warning_bg)
    let warning_bg = warning_fg
    let warning_fg = '#FFFFFF'
  endif

  let error_bg = synIDattr(hlID('Error'), 'bg')
  let error_fg = synIDattr(hlID('Error'), 'fg')
  if empty(error_bg)
    let error_bg = error_fg
    let error_fg = '#FFFFFF'
  endif

  silent! exe 'hi NotificationError guifg='.error_fg.' guibg='.error_bg
  silent! exe 'hi NotificationWarning guifg='.warning_fg.' guibg='.warning_bg
endfunction

function! Notification(msg, ...) abort
  call s:setup_colors()
  let buf = nvim_create_buf(v:false, v:true)
  let opts = get(a:, 1, {})
  let width = get(opts, 'width', 30)
  let delay = get(opts, 'delay', 5000)
  let type = get(opts, 'type', 'info')
  call nvim_buf_set_lines(buf, 0, -1, v:false, [a:msg])
  let opts = {
        \ 'relative': 'editor',
        \ 'row': 0,
        \ 'col': &columns - width - 1,
        \ 'width': width,
        \ 'height': len(split(a:msg,'.\{'.width.'}\zs')),
        \ 'style': 'minimal'
        \ }
  let win = nvim_open_win(buf, v:false, opts)
  call nvim_win_set_option(win, 'wrap', v:true)
  let lines = nvim_buf_get_lines(buf, 0, -1, v:false)
  call nvim_win_set_option(win, 'signcolumn', 'yes')
  if has_key(s:hl_by_type, type)
    call nvim_win_set_option(win, 'winhl', 'Normal:'.s:hl_by_type[type])
  endif
  call timer_start(delay, {-> nvim_win_close(win, v:true)})
endfunction
