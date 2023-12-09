#1/bin/sh

while
  getopts t:u: arg
do
  case "$arg" in
    (t) usertype="${OPTARG}";;
    (u) username="${OPTARG}";;
    (?)
      echo "Usage: $0 [-t usertype] [-u username]" 1>&2
      exit 1
      ;;
  esac
done
shift $((${OPTIND} - 1))

_prompt="${usertype:+(${usertype:-}) }survey"
_ps_msg() {
  printf "%s%s\n" "${_prompt}% " "$1" 1>&2
}
_ps_cmd() {
  printf "%s" "${_prompt}: " 1>&2
  read -r cmd arg
}
_ps_line() {
  printf "%s" "${_prompt}> " 1>&2
  read -r line
}

case "${usertype}" in
  ('')
    _ps_msg "Input your usertype"
    find . \( -path . -o -prune \) -type d -a -not -name ".*" |
    sed -nE 's/^\.\//- /; p;' 1>&2
    _ps_line
    usertype="${line:?}"
    ;;
esac

if
  test ! -d "${usertype}"
then
  _ps_msg "error: Invalid usertype: ${usertype}"
  _ps_msg "Check valid usertype"
  exit 2
else
  _prompt="${usertype:+(${usertype:-}) }survey"
fi

if
  test ! -f "${usertype}/questions/.index"
then
  find "${usertype}/questions" \( -path "${usertype}/questions" -o -prune \) -type f -a -not -name ".*" |
  sort -n >"${usertype}/questions/.index"
fi

if
  test ! -f "${usertype}/answers/.index"
then
  find "${usertype}/answers" \( -path "${usertype}/answers" -o -prune \) -type f -a -not -name ".*" |
  sort -n >"${usertype}/answers/.index"
fi

_ps_msg "Enter '?', 'h' or 'help' for help."
while
  _ps_cmd
do
  case "${cmd}" in
    ('?'|h|help)
      cat 1>&2 <<-EOF
?|h|help:
  help
q|quit:
  quit program
p [N]|print [N]:
  print all or N-th question with answer (not write)
e N|edit N:
  edit N-th answer (e.g. e 1)
n|username:
  set username
w|write:
  output to file (beginner-username.yaml)
r N|reset N:
  reset N-th answer
R!|reset-all:
  RESET ALL ANSWERS!
EOF
      ;;
    (q|quit)
      break
      ;;
    (p|print)
      case "${arg}" in
        ("")
          {
            printf '%s\n' "type: ${usertype}" "questions:"
            paste "${usertype}/questions/.index" "${usertype}/answers/.index" |
            xargs cat
          }
          ;;
        (*)
          if
            test "${arg}" -lt 1 -o "${arg}" -gt "${_max_qtns:=$(wc -l <"${usertype}/answers/.index")}"
          then
            _ps_msg "warning: Invalid question number: ${arg}"
            continue
          fi
          paste "${usertype}/questions/.index" "${usertype}/answers/.index" |
          sed -nE "${arg}p" |
          xargs cat
          ;;
      esac |
      less
      ;;
    (e|edit)
      case "${VISUAL:=${EDITOR}}" in
        ('')
          _ps_msg "Input your editor command (e.g. vim)"
          _ps_line
          if
            ! command -v "${line}" 2>/dev/null
          then
            _ps_msg "warning: Cannot find editor command: ${line}"
            continue
          fi
          VISUAL="${line}"
          ;;
      esac
      if
        test "${arg}" -lt 1 -o "${arg}" -gt "${_max_qtns:=$(wc -l <"${usertype}/answers/.index")}"
      then
        _ps_msg "warning: Invalid answer number: ${arg}"
        continue
      fi
      fname="$(sed -nE "${arg}p" <"${usertype}/answers/.index")"
      cp "${fname}" "${fname}.tmp"
      ${VISUAL} "${fname}.tmp"
      # justify prefix spaces
      if
        ! diff "${fname}" "${fname}.tmp" >/dev/null
      then
        sed -nE 's/^[[:blank:]]*/    /; p;' <"${fname}.tmp" >"${fname}"
      fi
      rm "${fname}.tmp"
      ;;
    (n|username)
      _ps_msg "Input your username (current: ${username})"
      _ps_line
      case "${line:-${username}}" in
        ('')
          _ps_msg "warning: Empty username!"
          continue
          ;;
        ("${username}")
          continue
          ;;
      esac
      username="${line}"
      ;;
    (w|write|export)
      case "${username}" in
        ('')
          _ps_msg "Unset username"
          continue
          ;;
      esac
      {
        printf '%s\n' "type: ${usertype}" "questions:"
        paste "${usertype}/questions/.index" "${usertype}/answers/.index" |
        xargs cat
      } >"${usertype}-${username}.yaml"
      ;;
    (r|reset)
      case "${arg}" in
        ('')
          _ps_msg "warning: Empty number"
          continue
          ;;
      esac
      if
        test "${arg}" -lt 1 -o "${arg}" -gt "${_max_qtns:=$(wc -l <"${usertype}/answers/.index")}"
      then
        _ps_msg "warning: Invalid question number: ${arg}"
        continue
      fi
      fname="$(sed -nE "${arg}p" <"${usertype}/answers/.index")"
      cp "${usertype}/.skel/${fname#*/}" "${fname}"
      ;;
    (R!|reset-all)
      cp "${usertype}/.skel/answers/"* "${usertype}/answers"
      ;;
    (*)
      _ps_msg "warning: Invalid command: ${cmd}"
      continue
      ;;
  esac
done
