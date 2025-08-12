# solve bug ssh zsh-vi-mode will caplitalizes the last character
unset zle_bracketed_paste

# Clipboard handling functions
function _get_clipboard_cache_file() {
    echo "${HOME}/.cache/zsh_vimode_clipboard.txt"
}

function _ensure_clipboard_cache() {
    local cache_file="$(_get_clipboard_cache_file)"
    local cache_dir="$(dirname "$cache_file")"
    # 确保目录存在且有权限
    if [[ ! -d "$cache_dir" ]]; then
        mkdir -p "$cache_dir" || {
            echo "Failed to create cache directory: $cache_dir" >&2
            return 1
        }
    fi
    # 确保文件存在且有权限
    if [[ ! -f "$cache_file" ]]; then
        touch "$cache_file" || {
            echo "Failed to create cache file: $cache_file" >&2
            return 1
        }
    fi
}

_ensure_clipboard_cache

function zsh_vimode_copy() {
    local content
    content=$(command cat)
    # Always send to system clipboard
    echo -n "$content" | copy
    # In SSH, also save to cache file
    if [[ -n "$SSH_CONNECTION" || -n "$SSH_CLIENT" ]]; then
        echo -n "$content" > "$(_get_clipboard_cache_file)"
    fi
}

function zsh_vimode_paste() {
    if [[ -n "$SSH_CONNECTION" || -n "$SSH_CLIENT" ]]; then
        # Remote SSH session - use cache file
        command cat "$(_get_clipboard_cache_file)"
    else
        get_from_clipboard
    fi
}

# 优化后的单个字符删除函数
my_zvm_vi_delete_char() {
    # 保存原始内容
    local original_buffer=$BUFFER
    local original_cursor=$CURSOR
    # 如果光标在行尾，不做任何操作
    if [[ $CURSOR -eq ${#BUFFER} ]]; then
        return
    fi
    # 直接操作 BUFFER 删除当前字符
    BUFFER="${BUFFER:0:$CURSOR}${BUFFER:$((CURSOR + 1))}"
    # 将被删除的字符存入 CUTBUFFER
    CUTBUFFER="${original_buffer:$CURSOR:1}"
    # 复制到剪贴板
    echo "$CUTBUFFER" | zsh_vimode_copy
    # 保持光标位置不变（除非在行尾）
    if [[ $CURSOR -gt ${#BUFFER} ]]; then
        CURSOR=${#BUFFER}
    fi
    # 更新显示
    zle redisplay
}

# zsh-vi-mode plugin enable copy cmd to system clipboard in vi mode
# ref: https://github.com/jeffreytse/zsh-vi-mode/issues/19
my_zvm_vi_yank() {
    zvm_vi_yank
    echo "$CUTBUFFER" | zsh_vimode_copy 
}
my_zvm_vi_delete() {
    zvm_vi_delete
    echo "$CUTBUFFER" | zsh_vimode_copy 
}
my_zvm_vi_change() {
    zvm_vi_change
    echo "$CUTBUFFER" | zsh_vimode_copy 
}
my_zvm_vi_change_eol() {
    zvm_vi_change_eol
    echo "$CUTBUFFER" | zsh_vimode_copy 
}
my_zvm_vi_substitute() {
    zvm_vi_substitute
    echo "$CUTBUFFER" | zsh_vimode_copy 
}
my_zvm_vi_substitute_whole_line() {
    zvm_vi_substitute_whole_line
    echo "$CUTBUFFER" | zsh_vimode_copy
}
my_zvm_vi_put_after() {
    CUTBUFFER=$(zsh_vimode_paste)
    zvm_vi_put_after
    zvm_highlight clear # zvm_vi_put_after introduces weird highlighting
}
my_zvm_vi_replace_selection() {
    CUTBUFFER=$(zsh_vimode_paste)
    zvm_vi_replace_selection
}
my_zvm_vi_put_before() {
    CUTBUFFER=$(zsh_vimode_paste)
    zvm_vi_put_before
    zvm_highlight clear # zvm_vi_put_before introduces weird highlighting
}
# Add these functions for D and Y commands
my_zvm_vi_delete_to_eol() {
    # Save the text from cursor to end of line
    CUTBUFFER="${BUFFER:$CURSOR}"
    # Copy to clipboard
    echo -n "$CUTBUFFER" | zsh_vimode_copy
    # Delete the text
    BUFFER="${BUFFER:0:$CURSOR}"
    # Update display
    zle redisplay
}

function _flash_selection() {
    # 保存原始光标位置和模式
    local original_cursor=$CURSOR
    local original_mode=$KEYMAP
    # 进入 visual 模式并选中到行尾
    zle visual-mode
    zle end-of-line
    zle redisplay
    # 短暂延迟（0.1秒）
    sleep 0.1
    # 再次调用 visual-mode 来切换回 normal 模式
    zle visual-mode
    CURSOR=$original_cursor
    zle redisplay
}
my_zvm_vi_yank_to_eol() {
    # Yank text from cursor to end of line
    CUTBUFFER="${BUFFER:$CURSOR}"
    # Copy to clipboard
    echo -n "$CUTBUFFER" | zsh_vimode_copy
    _flash_selection
}

# Then add these bindings in the zvm_after_lazy_keybindings function
zvm_after_lazy_keybindings() {
    zvm_define_widget my_zvm_vi_yank
    zvm_define_widget my_zvm_vi_delete
    zvm_define_widget my_zvm_vi_change
    zvm_define_widget my_zvm_vi_change_eol
    zvm_define_widget my_zvm_vi_put_after
    zvm_define_widget my_zvm_vi_put_before
    zvm_define_widget my_zvm_vi_substitute
    zvm_define_widget my_zvm_vi_substitute_whole_line
    zvm_define_widget my_zvm_vi_replace_selection
    zvm_define_widget my_zvm_vi_delete_char
    zvm_define_widget my_zvm_vi_delete_to_eol  # Add this
    zvm_define_widget my_zvm_vi_yank_to_eol    # Add this

    zvm_bindkey vicmd 'C' my_zvm_vi_change_eol
    zvm_bindkey vicmd 'D' my_zvm_vi_delete_to_eol  # Add this
    zvm_bindkey vicmd 'P' my_zvm_vi_put_before
    zvm_bindkey vicmd 'S' my_zvm_vi_substitute_whole_line
    zvm_bindkey vicmd 'Y' my_zvm_vi_yank_to_eol    # Add this
    zvm_bindkey vicmd 'p' my_zvm_vi_put_after
    zvm_bindkey vicmd 'x' my_zvm_vi_delete_char 

    zvm_bindkey visual 'p' my_zvm_vi_replace_selection
    zvm_bindkey visual 'c' my_zvm_vi_change
    zvm_bindkey visual 'd' my_zvm_vi_delete
    zvm_bindkey visual 's' my_zvm_vi_substitute
    zvm_bindkey visual 'x' my_zvm_vi_delete
    zvm_bindkey visual 'y' my_zvm_vi_yank
}
