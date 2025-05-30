function fish_prompt
    set raw_dir (prompt_pwd)
    if test "$raw_dir" = /
        set last_dir /
    else
        set last_dir (string split "/" $raw_dir)[-1]
    end
    printf '\033[38;5;93m[\033[0m'
    printf '\033[38;5;14m%s\033[0m' $last_dir
    printf '\033[38;5;93m]\033[0m'
    printf '\033[38;5;14m❯ \033[0m'
end

# OLD PROMT:
# PROMPT='%{%F{93}%}[%{%F{14}%}%1~%{%F{93}%}]%{%f%}%{%F{14}%}❯%{%f%}'
# RPROMPT='%{%F{253}%}$(branch=$(git symbolic-ref --short HEAD 2>/dev/null) && printf "(%s)" "$branch")%{%f%}'
