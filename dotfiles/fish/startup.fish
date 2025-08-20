if status is-interactive
    # Diable welcome msg:
    set -g fish_greeting

    # PATH scripts
    set -gx PATH $HOME/.local/bin $PATH

    # ----------------------------------------------------------------
    # ------------------ Git auto commit messages --------------------
    # ----------------------------------------------------------------

    function git
        set -l subcmd $argv[1]
        switch $subcmd
            case c
                # git c <msg>  → use <msg> as commit message
                # git c        → auto-commit with timestamp
                if test (count $argv) -gt 1
                    command git commit -m "$argv[2..-1]"
                else
                    command git commit -m (date '+%Y-%m-%d %H:%M:%S')
                end

            case lts
                # always auto-commit with LTS prefix
                set -l ts (date '+%Y-%m-%d %H:%M:%S')
                command git commit -m "lts: $ts"

            case '*'
                # any other git command, just pass through
                command git $argv
        end
    end

    # ----------------------------------------------------------------
    # ------------------------- !! commands --------------------------
    # ----------------------------------------------------------------

    function bind_bang
        switch (commandline -t)
            case "!"
                commandline -t $history[1]
                commandline -f repaint
            case "*"
                commandline -i !
        end
    end

    function bind_dollar
        switch (commandline -t)
            case "!"
                commandline -t ""
                commandline -f history-token-search-backward
            case "*"
                commandline -i '$'
        end
    end

    function fish_user_key_bindings
        bind ! bind_bang
        bind '$' bind_dollar
    end

    # ----------------------------------------------------------------
    # ----------------------------- eGPU -----------------------------
    # ----------------------------------------------------------------

    function egpu
        if lspci | grep -qi "NVIDIA"
            echo "[egpu] NVIDIA GPU detected. Running on eGPU: $argv"
            env DRI_PRIME=1 $argv
        else
            echo "[egpu] No NVIDIA GPU found. Running normally: $argv"
            command $argv
        end
    end

    # ----------------------------------------------------------------
    # ----------------------------- Aliases --------------------------
    # ----------------------------------------------------------------

    # Define aliases:
    alias reload='reconfigure reload'
    alias rebuild='reconfigure rebuild'
    alias upgrade='reconfigure upgrade'
    alias update='reconfigure update'

end
