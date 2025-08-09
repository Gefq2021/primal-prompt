#!/bin/bash
# Primal Prompt - Prompt personalizado para terminal con información de Git
# Copyright (c) 2025 Gerardo F. Quispe
# Licencia MIT - Ver LICENSE para más información

# ╔══════════════════════════════════════════════════════════════════════╗
# ║  CONFIGURACIÓN AVANZADA DEL PROMPT BASH CON GIT BRANCH Y STATUS      ║
# ║     Personalización desarrollada por Gerardo F. Quispe - 2025        ║
# ╚══════════════════════════════════════════════════════════════════════╝
# Personalizacion desarrollada por Gerardo Fabián Quispe - 2025
# Incluye:
# - Rama git con colores
# - Estados de archivos (modified/staged/untracked) con colores distintos y números
# - Salto de linea antes del prompt
# - Lineas en blanco entre comandos


# ╔══════════════════════════════════════════════════════════════════════╗
# ║ 1.     CONFIGURACIÓN BASICA DE COLORES EN EL  PROMPT                 ║
# ╚══════════════════════════════════════════════════════════════════════╝
# Forzar el uso de colores en el prompt si están disponibles
force_color_prompt=yes

# Verifica si se puede usar color con 'tput' (es decir, si el terminal lo soporta)
if [ -n "$force_color_prompt" ]; then
  if tput setaf 1 >&/dev/null; then
    color_prompt=yes
  else
    color_prompt=
  fi
fi

# ╔══════════════════════════════════════════════════════════════════════╗
# ║  2.    FUNCIÓN PARA MOSTRAR LA RAMA GIT ACTUAL EN EL PROMPT          ║
# ╚══════════════════════════════════════════════════════════════════════╝
parse_git_branch() {
  # Verifica si estamos en un repositorio Git
  git rev-parse --is-inside-work-tree &>/dev/null || return

  # Obtiene el nombre de la rama actual y lo devuelve sin colores
  local branch=$(git symbolic-ref --short HEAD 2>/dev/null)
  [ -n "$branch" ] && echo "⎇[$branch]"
}

# ╔══════════════════════════════════════════════════════════════════════╗
# ║  3.    FUNCIÓN PARA MOSTRAR EL ESTADO DE GIT:                        ║
# ║        MODIFICADOS / STAGED / UNTRACKED                              ║
# ╚══════════════════════════════════════════════════════════════════════╝
# Orden y colores específicos:
#  - Rojo (M): Modificados no preparados
#  - Verde (S): Staged (preparados para commit)
#  - Gris (U): Unstracked (Archivos no rastreados)

parse_git_status() {
  git rev-parse --is-inside-work-tree &>/dev/null || return

  # Contar archivos en cada estado
  local modified=$(git diff --name-only | wc -l)
  local staged=$(git diff --cached --name-only | wc -l)
  local untracked=$(git ls-files --others --exclude-standard | wc -l)

  # Construir string de estado en el orden específico
  local status=""
  [[ $modified -gt 0 ]]   && status+="M:$modified "   # Modificados (rojo)
  [[ $staged -gt 0 ]]     && status+="S:$staged "     # Staged (verde)
  [[ $untracked -gt 0 ]]  && status+="U:$untracked "  # Untracked (gris)

  # Quita el espacio final si existe
  status=$(echo "$status" | sed 's/ $//')
  [ -n "$status" ] && echo "$status"
}

# ╔══════════════════════════════════════════════════════════════════════╗
# ║  4.    CONTROL DE LÍNEA VACÍA ENTRE COMANDOS EJECUTADOS EN BASH      ║
# ╚══════════════════════════════════════════════════════════════════════╝

# Variables auxiliares para controlar si mostrar la línea en blanco
export __SHOW_BLANK_LINE=0
export __LAST_CMD=""

insert_blank_line() {
  local current_cmd
  current_cmd=$(history 1 | sed 's/^[ ]*[0-9]\+[ ]*//')

  if [ "$__SHOW_BLANK_LINE" -eq 1 ] && [ "$current_cmd" != "$__LAST_CMD" ]; then
    echo
  fi

  __LAST_CMD="$current_cmd"
  __SHOW_BLANK_LINE=1
}

# Registrar la función anterior para que se ejecute antes de mostrar el prompt
PROMPT_COMMAND=insert_blank_line

# ╔══════════════════════════════════════════════════════════════════════╗
# ║  5.    DEFINICIÓN FINAL DEL PROMPT SEGÚN SI HAY COLOR O NO           ║
# ╚══════════════════════════════════════════════════════════════════════╝

if [ "$color_prompt" = yes ]; then
  PS1='${debian_chroot:+($debian_chroot)}'
  PS1+='\[\033[01;32m\]\u@\h\[\033[00m\]:'               # usuario@host en verde
  PS1+='\[\033[01;34m\]\w\[\033[00m\] '                  # ruta actual en azul
  PS1+='\[\033[1;36m\]$(parse_git_branch)\[\033[0m\]'    # rama Git en celeste
  
  # Estado Git con colores y formato alfanumerico
  PS1+=' $(
    status=$(parse_git_status);
    if [ -n "$status" ]; then
      colored_status="";
      # Procesar cada estado con su color correspondiente
      for item in $status; do
        case $item in
          M:*) colored_status+="\[\033[1;31m\]${item}\[\033[0m\] " ;;  # Rojo para modificados
          S:*) colored_status+="\[\033[1;32m\]${item}\[\033[0m\] " ;;  # Verde para staged
          U:*) colored_status+="\[\033[1;37m\]${item}\[\033[0m\] " ;;  # Gris para untracked
        esac
      done;
      echo "(${colored_status% })";  # Eliminar espacio final y mostrar entre paréntesis
    fi
  )'
  
  PS1+='\n\$ '        # nueva línea con $
else
  # Versión sin colores
  PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w $(parse_git_branch) ($(parse_git_status))\n\$ '
fi

# Limpia las variables para no dejar residuos en el entorno
unset color_prompt force_color_prompt


