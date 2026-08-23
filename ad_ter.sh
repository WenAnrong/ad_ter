#!/usr/bin/env bash
# 由 .bashrc / .zshrc 通过 source 加载。
# 注意：本文件会被 source 进用户的交互 shell，因此严禁使用 set -e/-u/pipefail，
# 以免污染用户 shell 环境。

# 防止同一 shell 被重复加载（例如 .bash_profile 与 .bashrc 同时被读取）
if [ -n "${_AD_TER_LOADED:-}" ]; then
  return 0 2>/dev/null || exit 0
fi
_AD_TER_LOADED=1

# ---- 可配置项 ----
AD_TER_DIR="$HOME/.ad_ter"
AD_TER_ADS="$AD_TER_DIR/ads.txt"
AD_TER_COUNTDOWN="${AD_TER_COUNTDOWN:-5}"   # 广告倒计时秒数

# ---- 基础判断 ----
_is_terminal() { [ -t 0 ] && [ -t 1 ]; }

# ---- 随机醒目配色 ----
# 只在广告自身输出上上色，不触碰 ls/pwd 的正常着色
_AD_TER_RESET='\033[0m'

# 从「醒目色板」随机取一个颜色码（亮色 + 加粗，深色终端下最抢眼）
_rand_color() {
  case $((RANDOM % 8)) in
    0) printf '%b' '\033[1;91m'        ;; # 亮红
    1) printf '%b' '\033[1;92m'        ;; # 亮绿
    2) printf '%b' '\033[1;93m'        ;; # 亮黄
    3) printf '%b' '\033[1;94m'        ;; # 亮蓝
    4) printf '%b' '\033[1;95m'        ;; # 亮品红
    5) printf '%b' '\033[1;96m'        ;; # 亮青
    6) printf '%b' '\033[1;97m'        ;; # 亮白
    7) printf '%b' '\033[1;38;5;208m'  ;; # 橙（256 色，不支持的终端自动忽略）
  esac
}

# 从 ads.txt 随机取一行（过滤空行与 # 注释）；没有 shuf 时用 awk 兜底
_random_ad() {
  local pool
  pool=$(grep -vE '^[[:space:]]*(#|$)' "$AD_TER_ADS" 2>/dev/null) || return 1
  [ -z "$pool" ] && return 1
  if command -v shuf >/dev/null 2>&1; then
    printf '%s\n' "$pool" | shuf -n 1
  else
    printf '%s\n' "$pool" | awk 'BEGIN{srand()} {a[NR]=$0} END{print a[int(rand()*NR)+1]}'
  fi
}

# ---- 命令拦截：ls / pwd，30% 概率在输出末尾插一条广告 ----
# 仅在 stdout 是真终端（[ -t 1 ]）时插入，重定向/管道一律不插，避免污染文件与管道。
# 必须先 unalias：交互 shell 会展开别名，直接写 `ls() {` 会被展开成 `ls --color=auto() {` 而报语法错误。
unalias ls 2>/dev/null
unalias pwd 2>/dev/null

_print_hook_ad() {
  local ad title url color
  ad=$(_random_ad) || return 0
  title="${ad%%|*}"
  url="${ad#*|}"
  # 标题做成 OSC 8 超链接（终端支持即可点击）；URL 同时明文显示，兼容不支持超链接的终端
  # 每次插入随机取一个醒目颜色，reset 放最后保证不污染后续命令输出
  color=$(_rand_color)
  printf '%b>> \033]8;;%s\033\\%s\033]8;;\033\\ (%s)%b\n' \
    "$color" "$url" "$title" "$url" "$_AD_TER_RESET"
}

ls() {
  # unalias 后显式补回 --color=auto，保持 Debian/Ubuntu 默认的彩色输出
  command ls --color=auto "$@"
  if [ -t 1 ] && [ $((RANDOM % 100)) -lt 30 ]; then
    _print_hook_ad
  fi
}

pwd() {
  builtin pwd "$@"
  if [ -t 1 ] && [ $((RANDOM % 100)) -lt 30 ]; then
    _print_hook_ad
  fi
}

# 大字输出：中英文统一用「自适应宽度框线横幅」呈现标题；框线与标题文字可分别染色
_big() {
  local text="$1" fg="$2" box="$3" w rule
  # 计算显示宽度（CJK 按 2 列）；无 wc -L 时退化为字符数近似
  w=$(printf '%s' "$text" | wc -L 2>/dev/null | tr -d ' ')
  case "$w" in
    ''|0|*[!0-9]*) w=${#text} ;;
  esac
  w=$((w + 2))
  rule=$(printf '%*s' "$w" '')
  rule=${rule// /━}   # 多字节安全替换（tr 按字节处理会截断 UTF-8）
  printf '\n'
  printf '  %b┏%s┓%b\n' "$box" "$rule" "$_AD_TER_RESET"
  printf '  %b┃%b %s %b┃%b\n' "$box" "$fg" "$text" "$box" "$_AD_TER_RESET"
  printf '  %b┗%s┛%b\n' "$box" "$rule" "$_AD_TER_RESET"
}

# 倒计时：Ctrl+C 直接跳过广告
_countdown() {
  local secs="$1" i c
  c=$(_rand_color)
  _AD_TER_SKIP=0
  trap '_AD_TER_SKIP=1' INT
  for (( i = secs; i > 0; i-- )); do
    printf "\r  %b[广告剩余 %d 秒...]%b  " "$c" "$i" "$_AD_TER_RESET"
    sleep 1
    [ "$_AD_TER_SKIP" = "1" ] && break
  done
  printf '\n'
  trap - INT
}

# 开屏广告主流程
_show_splash() {
  _is_terminal || return 0

  local ad title url
  local c_head c_box c_title c_url
  ad=$(_random_ad) || return 0
  title="${ad%%|*}"
  url="${ad#*|}"

  # 头部、框线、标题、链接各自独立随机取色，每次开屏都是一套新配色
  c_head=$(_rand_color)
  c_box=$(_rand_color)
  c_title=$(_rand_color)
  c_url=$(_rand_color)

  clear
  printf '\n'
  printf '  %b================================================%b\n' "$c_head" "$_AD_TER_RESET"
  printf '%b              今 日 精 选 广 告%b\n' "$c_head" "$_AD_TER_RESET"
  printf '  %b================================================%b\n' "$c_head" "$_AD_TER_RESET"
  printf '\n'
  _big "$title" "$c_title" "$c_box"
  printf '\n'
  printf '  %b%s%b\n' "$c_url" "$url" "$_AD_TER_RESET"
  printf '\n'
  _countdown "$AD_TER_COUNTDOWN"
}

_show_splash
