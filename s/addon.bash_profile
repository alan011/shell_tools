complete -F _my_func s

_my_func(){ 
    local cur opts
    cur="${COMP_WORDS[COMP_CWORD]}"
    opts=`cat ~/.my_hosts | awk '{print $1}'`
    if [[ ${cur} == * ]]; then 
        COMPREPLY=($(compgen -W "${opts}" -- ${cur}))
        return 0
    fi
}

