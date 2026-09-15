_tmig() {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  local cmds="verify doctor license health probe status infra-status infra-reconcile release ui-web"
  COMPREPLY=( $(compgen -W "$cmds" -- "$cur") )
}
complete -F _tmig tmig
