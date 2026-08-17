#!/usr/bin/env bash
# install.sh — ad_ter 终端整活广告 安装/卸载脚本
# 用法:
#   ./install.sh              # 安装（复制文件 + 写入 bash/zsh 配置 + 可选依赖）
#   ./install.sh --skip-deps  # 安装，但跳过 qrencode 自动安装
#   ./install.sh --uninstall  # 卸载（清理 rc + 删除 ~/.ad_ter）

set -euo pipefail

SKIP_DEPS=0   # 1 = 跳过 qrencode 自动安装（也可用 --skip-deps）

AD_TER_DIR="$HOME/.ad_ter"
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 写入 rc 的三行内容。单引号保持 $HOME/$PATH 字面量，供 shell 启动时再展开。
COMMENT_LINE='# ad_ter 终端整活广告（卸载: ad-cleaner --uninstall）'
SOURCE_LINE='[ -f "$HOME/.ad_ter/ad_ter.sh" ] && source "$HOME/.ad_ter/ad_ter.sh"'
PATH_LINE='case ":$PATH:" in *"$HOME/.ad_ter"*) ;; *) export PATH="$HOME/.ad_ter:$PATH";; esac'

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; NC='\033[0m'
say()  { printf '%b\n' "$*"; }
ok()   { printf "${GREEN}✓${NC} %b\n" "$*"; }
warn() { printf "${YELLOW}!${NC} %b\n" "$*"; }
err()  { printf "${RED}✗${NC} %b\n" "$*"; }

# 可选依赖：qrencode（二维码）。尽力而为，失败不阻断安装。
install_deps() {
  [ "$SKIP_DEPS" = "1" ] && { warn "已跳过可选依赖安装（--skip-deps）"; return 0; }

  if command -v qrencode >/dev/null 2>&1; then
    ok "可选依赖 qrencode（二维码）已就绪"
    return 0
  fi

  if ! command -v apt-get >/dev/null 2>&1 || ! command -v sudo >/dev/null 2>&1; then
    warn "缺少 qrencode（当前系统无 apt-get/sudo，跳过自动安装；二维码将显示为占位符）"
    return 0
  fi

  say "尝试安装可选依赖 qrencode（需要 sudo 密码，取消不影响使用）"
  if sudo apt-get install -y qrencode; then
    ok "已安装 qrencode"
  else
    warn "自动安装失败（可能无网络或取消密码）。不影响使用，二维码将显示为占位符。"
  fi
}

# 将 ad_ter 三行追加到某个 rc 文件（幂等：已安装则跳过）
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
    printf '%s\n' "$PATH_LINE"
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
  for f in ad_ter.sh install.sh ad-cleaner; do
    if [ -f "$SRC_DIR/$f" ]; then
      cp "$SRC_DIR/$f" "$AD_TER_DIR/$f"
      ok "已复制: $f -> $AD_TER_DIR/$f"
    else
      err "缺少文件: $SRC_DIR/$f"
      return 1
    fi
  done
  chmod +x "$AD_TER_DIR/ad-cleaner"

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
  # macOS 登录 shell 覆盖（只追加到已存在的文件，绝不新建 .bash_profile，
  # 以免在 Linux 上新建后抢占 .profile 的加载）
  if [ -f "$HOME/.bash_profile" ]; then
    append_rc "$HOME/.bash_profile"
  elif [ -f "$HOME/.profile" ]; then
    append_rc "$HOME/.profile"
  fi

  # 3. 可选依赖（qrencode 二维码）
  install_deps

  say ""
  ok "安装完成！"
  say "  立即生效: source ~/.bashrc   （或 ~/.zshrc）"
  say "  卸载方式: ad-cleaner --uninstall  或  $AD_TER_DIR/install.sh --uninstall"
}

do_uninstall() {
  say "开始卸载 ad_ter ..."
  clean_rc "$HOME/.bashrc"
  clean_rc "$HOME/.zshrc"
  clean_rc "$HOME/.bash_profile"
  clean_rc "$HOME/.profile"
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
  --skip-deps)    SKIP_DEPS=1; do_install ;;
  *)              do_install ;;
esac
