#!/usr/bin/env bash
# install.sh — ad_ter 终端整活广告 安装/卸载脚本
# 用法:
#   ./install.sh              # 安装（复制文件 + 写入 bash/zsh 配置）
#   ./install.sh --uninstall  # 卸载（清理 rc + 删除 ~/.ad_ter）

set -euo pipefail

AD_TER_DIR="$HOME/.ad_ter"
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 写入 rc 的两行内容。单引号保持 $HOME 字面量，供 shell 启动时再展开。
COMMENT_LINE='# ad_ter 终端整活广告（卸载: ~/.ad_ter/install.sh --uninstall）'
SOURCE_LINE='[ -f "$HOME/.ad_ter/ad_ter.sh" ] && source "$HOME/.ad_ter/ad_ter.sh"'

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; NC='\033[0m'
say()  { printf '%b\n' "$*"; }
ok()   { printf "${GREEN}✓${NC} %b\n" "$*"; }
warn() { printf "${YELLOW}!${NC} %b\n" "$*"; }
err()  { printf "${RED}✗${NC} %b\n" "$*"; }

# 将 ad_ter 两行追加到某个 rc 文件（幂等：已安装则跳过）
append_rc() {
  local file="$1"
  [ -f "$file" ] || touch "$file"
  if grep -qF "$SOURCE_LINE" "$file"; then
    warn "已安装，跳过: $file"
    return 0
  fi
  # 文件非空且不以换行结尾时，先补一个换行，避免内容粘连
  if [ -s "$file" ] && [ -n "$(tail -c 1 "$file")" ]; then
    printf '\n' >> "$file"
  fi
  {
    printf '%s\n' "$COMMENT_LINE"
    printf '%s\n' "$SOURCE_LINE"
  } >> "$file"
  ok "已写入: $file"
}

# 清理某个 rc 文件里的 ad_ter 相关行
clean_rc() {
  local file="$1"
  [ -f "$file" ] || return 0
  if grep -qF 'ad_ter' "$file"; then
    grep -vF 'ad_ter' "$file" > "$file.tmp" || true
    mv "$file.tmp" "$file"
    ok "已清理: $file"
  fi
}

do_install() {
  say "=== ad_ter 终端整活广告 安装器 ==="

  # 1. 复制文件到 ~/.ad_ter
  mkdir -p "$AD_TER_DIR"
  local f
  for f in ad_ter.sh install.sh; do
    if [ -f "$SRC_DIR/$f" ]; then
      cp "$SRC_DIR/$f" "$AD_TER_DIR/$f"
      ok "已复制: $f -> $AD_TER_DIR/$f"
    else
      err "缺少文件: $SRC_DIR/$f"
      return 1
    fi
  done

  # ads.txt 仅在不存在时复制，保留用户自定义内容
  if [ -f "$AD_TER_DIR/ads.txt" ]; then
    warn "ads.txt 已存在，保留你的自定义内容（重置请删除后重装）"
  elif [ -f "$SRC_DIR/ads.txt" ]; then
    cp "$SRC_DIR/ads.txt" "$AD_TER_DIR/ads.txt"
    ok "已复制: ads.txt -> $AD_TER_DIR/ads.txt"
  fi

  # 2. 写入 bash / zsh 配置
  append_rc "$HOME/.bashrc"
  append_rc "$HOME/.zshrc"

  say ""
  ok "安装完成！"
  say "  立即生效: source ~/.bashrc   （或 ~/.zshrc）"
  say "  卸载方式: $AD_TER_DIR/install.sh --uninstall"
}

do_uninstall() {
  say "开始卸载 ad_ter ..."
  clean_rc "$HOME/.bashrc"
  clean_rc "$HOME/.zshrc"
  if [ -d "$AD_TER_DIR" ]; then
    rm -rf "$AD_TER_DIR"
    ok "已删除目录: $AD_TER_DIR"
  fi
  say "卸载完成。重新打开终端即完全脱离广告。"
}

# 仅允许普通用户运行：root 安装会写进 /root/.ad_ter 与 /root/.bashrc，非本意
if [ "$(id -u)" -eq 0 ]; then
  err "本脚本仅限普通用户运行，请不要用 root 执行。"
  exit 1
fi

case "${1:-}" in
  --uninstall|-u) do_uninstall ;;
  *)              do_install ;;
esac
