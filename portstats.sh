#!/bin/bash
IPT="/sbin/iptables"
SCRIPT_PATH="$(dirname "$(readlink -f "$0")")"
SCRIPT_NAME="$(basename "$0")"
CONFIG_FILE="${SCRIPT_PATH}/portstats.conf"
RUN_LOG="${SCRIPT_PATH}/portstats.log"
[ -x "$(command -v numfmt)" ] && FMT="numfmt" ||FMT="pretty_print"
declare -r TRUE=0
declare -r FALSE=1
declare -a mon_ports
declare -a old_ports
log_folder="${SCRIPT_PATH}"
ports_list="3128 9090"
add_iptable_chains()
{
  if ! ($IPT-save -t filter | grep TRAFFIC >/dev/null); then
    $IPT -N TRAFFIC-INPUT   && \
    $IPT -t filter -I INPUT -j TRAFFIC-INPUT
    $IPT -N TRAFFIC-OUTPUT  && \
    $IPT -t filter -I OUTPUT -j TRAFFIC-OUTPUT
  fi
}
del_iptable_chains()
{
  if ($IPT-save -t filter | grep TRAFFIC >/dev/null); then
    $IPT -t filter -D OUTPUT -j TRAFFIC-OUTPUT && \
    $IPT -F TRAFFIC-OUTPUT && \
    $IPT -X TRAFFIC-OUTPUT
    $IPT -t filter -D INPUT -j TRAFFIC-INPUT && \
    $IPT -F TRAFFIC-INPUT && \
    $IPT -X TRAFFIC-INPUT
  fi
}
add_iptable_rules()
{
  $IPT -F TRAFFIC-INPUT
  $IPT -F TRAFFIC-OUTPUT
  for port in "${mon_ports[@]}"; do
    $IPT -t filter -A TRAFFIC-INPUT -p tcp --dport "${port}"
    $IPT -t filter -A TRAFFIC-OUTPUT -p tcp --sport "${port}"
  done;
}
add_cron()
{
  tmp_cron_file="/tmp/crontab"
  script="${SCRIPT_PATH}/${SCRIPT_NAME}"
  crontab -l > "${tmp_cron_file}"
  sed -i "/${SCRIPT_NAME}/d" "${tmp_cron_file}"
  echo "0  * * * * ${script} run" >> "${tmp_cron_file}"
  crontab "${tmp_cron_file}"
  rm -f "${tmp_cron_file}"
}
del_cron()
{
  tmp_cron_file="/tmp/crontab"
  crontab -l > "${tmp_cron_file}"
  sed -i "/$SCRIPT_NAME/d" "${tmp_cron_file}"
  crontab "${tmp_cron_file}"
  rm -f "${tmp_cron_file}"
}

check_ports()
{
  [ -z "$1" ] && return ${FALSE}
  read -ra ports <<< "$1"
  isuniq=$(echo "$1"|tr ' '  '\n' | sort -n | uniq -d)
  [ -n "$isuniq" ] && echo -n "Warning:duplicate ports!" && return ${FALSE}
  for port in "${ports[@]}"; do
    [[ ! "${port}" =~ ^([0-9]{1,4}|[1-5][0-9]{4}|6[0-4][0-9]{3}|65[0-4] \
       [0-9]{2}|655[0-2][0-9]|6553[0-5])$ ]] \
       && echo -n "Warning:Incorrect port format!" && return ${FALSE}
  done
  return ${TRUE}
}

pretty_print()
{
  B="$1"
  while :; do
    [ $B -lt 1024 ] && printf "${B}B" && break
    KB=$(((B+512)/1024))
    [ $KB -lt 1024 ] && printf "${KB}K" && break
    MB=$(((KB+512)/1024))
    [ $MB -lt 1024 ] && printf "${MB}M" && break
    GB=$(((MB+512)/1024))
    [ $GB -lt 1024 ] && printf "${GB}G" && break
    printf "$(((GB+512)/1024))T"
    break
  done
}
read_config()
{
  if [[  -f $CONFIG_FILE ]];then
    ports_list=$(awk -F= '/^ports=/ {print $2}' "$CONFIG_FILE")
    log_folder=$(awk -F= '/^log_folder=/ {print $2}' "$CONFIG_FILE")
  else
    echo Error: There is no config file, please install first!
    exit 1
  fi
}
setup_config()
{
  echo "Input your monitor ports [1-65535] separated by spaces"
  while :; do
    read -rp "ports(enter=$ports_list):" input_ports_list
    [ -z "${input_ports_list}" ] && input_ports_list="${ports_list}"
    check_ports "${input_ports_list}" && break || echo "please retry"
  done
  echo "Specify the log file save path"
  while :; do
    read -rp "path(enter=$log_folder):" input_log_folder
    [ -z "${input_log_folder}" ] && input_log_folder="${log_folder}"
    break
  done
  echo "config successful！"
  echo "ports:${input_ports_list}"
  echo "log folder path：${input_log_folder}"
  echo "ports=${input_ports_list}" > "${CONFIG_FILE}"
  echo "log_folder=${input_log_folder}" >> "${CONFIG_FILE}"
}
check_ports_change()
{
 is_ports_change=0
  if (( "${#old_ports[@]}" != "${#mon_ports[@]}" )); then
    is_ports_change=1
  else
    for(( i=0; i<"${#old_ports[@]}"; i++ )); do
      if (( "${old_ports[i]}" != "${mon_ports[i]}" ));then
        is_ports_change=1
      fi
    done;
  fi
}

reset_ports_traffic()
{
  for port in "${mon_ports[@]}"; do
    printf "%8s %5s %8s %8s %10s %10s %10s %10s\n" "${now}" "${port}" 0 0 \
    0 0 0 0 >> "${today_log}"
  done;
  $IPT -Z
}
run()
{
  today="$(date "+%Y-%m-%d")"
  monthlylog="${log_folder}/$(date "+%Y-%m")-sum.log"
  today_log="${log_folder}/${today}.log"
  now="$(date "+%T")"
  echo "${now}: portstats started" >> "${RUN_LOG}"
  if  [[ ! -d "${log_folder}" ]]; then
    mkdir "${log_folder}"
  fi
  [ -z "${ports_list}" ] && echo "ERROR: no monitor ports,exit" && exit 1
  sort_ports="$(echo "${ports_list}"|tr ' '  '\n'|sort -un)"
  mapfile -t mon_ports <<< "${sort_ports}"
  old_ports_list="$($IPT -vn -L TRAFFIC-OUTPUT|awk -F: '/spt/ {print $2}')"
  if [ -z "${old_ports_list}" ]; then
    add_iptable_rules
    reset_ports_traffic
    exit 1
  fi
  sort_ports=$(echo "${old_ports_list}"|sort -un)
  mapfile -t old_ports <<< "${sort_ports}"
  check_ports_change
  if  [[ "${is_ports_change}" != 0 ]]; then
    echo -n "${now}: port changed:" >> "${RUN_LOG}"
    echo "From ports=${old_ports[*]} to ${mon_ports[*]}" \
          >> "${RUN_LOG}"
    if [[ ! -f "${today_log}" ]] ; then
      new_daily_stats
    else
      hourly_stats "${old_ports[*]}" "${today_log}"
    fi
    add_iptable_rules
    reset_ports_traffic
    exit 1
  fi
  if [[ ! -f "${today_log}" ]]; then
    new_daily_stats
  else
    hourly_stats "${mon_ports[*]}" "${today_log}"
  fi
}
hourly_stats()
{
  read -ra stat_ports <<< "$1"
  dailylog="$2"
  traffic="$($IPT -L -nvx)"
  for port in "${stat_ports[@]}"; do
    last_input=$(grep "^[0-1][0-9]:.*\b$port\b" "$dailylog"|
                awk 'END {print $5}')
    [ ! "${last_input}" ] && last_input=0
    last_output=$(grep "^[0-1][0-9]:.*\b$port\b" "$dailylog"|
                awk 'END {print $6}')
    [ ! "${last_output}" ] && last_output=0
    total_input=$(echo "${traffic}" |grep -w "dpt:$port"|awk '{print $2}')
    total_output=$(echo "${traffic}"|grep -w "spt:$port"|awk '{print $2}')
    input_byte="$(( total_input - last_input ))"
    output_byte="$(( total_output - last_output ))"
    [ "${input_byte}" -gt 0 ] && input="$("$FMT" "$input_byte" "--to=si")" \
                                 || input="0B"
    [ "${output_byte}" -gt 0 ] && output="$("$FMT" "$output_byte" "--to=si" )"\
                                 || output="0B"
    printf "%8s %5s %8s %8s %10s %10s %10s %10s\n" "${now}" "${port}" \
           "${input}" "${output}" "${total_input}" "${total_output}"  \
           "${input_byte}" "${output_byte}" >> "${dailylog}"
  done;
}

new_daily_stats()
{
  yesterday="$(date --date=' 1 days ago' "+%Y-%m-%d")"
  yesterday_log="${log_folder}/${yesterday}.log"
  if [ -f "${yesterday_log}" ]; then
    hourly_stats "${mon_ports[*]}" "${yesterday_log}"
    daily_sum
  fi
  printf "%8s %5s %8s %8s %10s %10s %10s %10s\n" "Time" "Port" "Input" "Output"\
      "TotalIn" "TotalOut" "inBytes" "outBytes" > "${today_log}"
  reset_ports_traffic|tr  '\n' ' '
}
daily_sum()
{
  allports="$(awk '/[0-2][0-9]:/ {print $2}' "${yesterday_log}"|sort -un)"
  mapfile -t ports <<< "${allports}"
  i=0
  for port in "${ports[@]}"; do
    inBytes[i]=$(grep -w "$port" "$yesterday_log"|
                awk '/[0-9][0-9]:/ {sum += $7};END {print sum}')
    outBytes[i]=$(grep -w "$port" "$yesterday_log"|
                awk '/[0-9][0-9]:/ {sum += $8};END {print sum}')
    input="$("$FMT"  "${inBytes[i]}" "--to=si")"
    output="$("$FMT" "${outBytes[i]}" "--to=si" )"
    printf "%-8s %5s %8s %8s %10s %10s\n" "Total" "${port}" "${input}" \
            "${output}" "${inBytes[i]}" "${outBytes[i]}" >> "${yesterday_log}"
    ((i++))
  done;
  add_monthly_stats "${ports[*]}" "${inBytes[*]}" "${outBytes[*]}"
}
add_monthly_stats()
{
  read -ar ports <<< "$1"
  read -ar inBytes <<< "$2"
  read -ar outBytes <<< "$3"
  if [ ! -f "${monthlylog}" ]; then
    printf "%10s %5s %8s %8s %10s %10s\n" "Date" "Port" "Input" "Output" \
                  "inBytes" "outBytes" > "${monthlylog}"

    last_month="$(date --date="$(date +%Y-%m-15) -1 month" "+%Y-%m")"
    last_month_log="${log_folder}/${last_month}-sum.log"
    [[ -f "${last_month_log}" ]] && monthly_sum
  fi
  i=0
  for port in "${ports[@]}"; do
    input="$("$FMT" "${inBytes[i]}"  "--to=si")"
    output="$("$FMT" "${outBytes[i]}"  "--to=si")"
    printf "%-10s %5s %8s %8s %10s %10s\n" "${yesterday}" "${port}" "${input}"  \
            "${output}" "${inBytes[i]}" "${outBytes[i]}" >> "${monthlylog}"
    ((i++))
  done
}
monthly_sum()
{
  allports="$(awk '/[0-9]{4}-/ {print $2}' "${last_month_log}"|sort -un )"
  mapfile -t ports <<< "${allports}"
  i=0
  for port in "${ports[@]}"; do
    inBytes[i]=$(grep -w "$port" "$last_month_log"|
                awk '/[0-9]{4}-/  {sum += $5};END {print sum}')
    outBytes[i]=$(grep -w "$port" "$last_month_log"|
                awk '/[0-9]{4}-/  {sum += $6};END {print sum}')
    input="$("$FMT" "${inBytes[i]}"  "--to=si")"
    output="$("$FMT" "${outBytes[i]}"  "--to=si")"
    printf "%-10s %5s %8s %8s %10s %10s\n" "Total" "${port}" "${input}" \
            "${output}" "${inBytes[i]}" "${outBytes[i]}" >> "${last_month_log}"
    ((i++))
  done;
}
is_root(){
 # root user has user id (UID) zero.
 [ "$(id -u)" -eq 0 ] && echo 1 ||  echo 0
}
main()
{
  if [ ! "$(is_root)" ]; then
    echo "Error:You need to run this script as a root user." && exit
  fi
  action="$1"
  case "${action}" in
    install)
      add_iptable_chains
      add_cron
      setup_config
      ;;
    config)
      read_config
      setup_config
      ;;
    run)
      add_iptable_chains
      read_config
      run
      ;;
    uninstall)
      del_iptable_chains
      del_cron
      ;;
    *)
      [[ -z "${action}" ]] && echo "Argument can't be empty" \
                           || echo "Argument error! [${action} ]"
      echo "Usage: $SCRIPT_NAME {install|uninstall|run|config}"
      exit
    ;;
  esac
}
main "$@"
