function fish_prompt
    # Figure out the last path 
    set raw_dir (prompt_pwd)
    if test "$raw_dir" = /
        set last_dir /
    else
        set last_dir (string split "/" $raw_dir)[-1]
    end

    if set -q SSH_CONNECTION
        # SSH mode: big red banner + host + server IP
        set host (hostname)
        set parts (string split ' ' -- $SSH_CONNECTION)  # client_ip client_port server_ip server_port
        set server_ip $parts[3]



        # Directory + prompt in high-contrast colors
        printf '\033[38;5;208m[\033[0m'
        printf '\033[38;5;220m%s\033[0m' $host
        printf '\033[38;5;196m@\033[0m'
        printf '\033[38;5;220m%s\033[0m' $server_ip
        printf '\033[38;5;208m/\033[0m'
        printf '\033[38;5;220m%s\033[0m' $last_dir
        printf '\033[38;5;208m]\033[0m'
        printf '\033[38;5;220m❯ \033[0m'
    else
        # Your original local prompt
        printf '\033[38;5;93m[\033[0m'
        printf '\033[38;5;14m%s\033[0m' $last_dir
        printf '\033[38;5;93m]\033[0m'
        printf '\033[38;5;14m❯ \033[0m'
    end
end

# OLD PROMT:
# PROMPT='%{%F{93}%}[%{%F{14}%}%1~%{%F{93}%}]%{%f%}%{%F{14}%}❯%{%f%}'
# RPROMPT='%{%F{253}%}$(branch=$(git symbolic-ref --short HEAD 2>/dev/null) && printf "(%s)" "$branch")%{%f%}'
