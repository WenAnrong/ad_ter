# ad_ter —— 终端整活广告

把「开屏广告 + 会员去广告」塞进你的 Debian/Ubuntu 终端，纯属整活，博君一笑。

## 特性

- **开屏广告**：每次打开交互式终端，先清屏，弹出「今日精选」广告横幅 + 链接 + 倒计时。
- **Ctrl+C 也跳不过**：倒计时期间按 Ctrl+C 会提示「操作失败，非 VIP 用户无法跳过广告」，倒计时照走。
- **会员系统**：`ad-cleaner --buy-vip` 显示一个（假）支付二维码，扫码后「验证支付」并自动开通会员，之后不再弹广告。
- **一键卸载**：`ad-cleaner --uninstall` 清理干净，不留痕迹。
- **安全边界**：只在真终端（`[ -t 0 ] && [ -t 1 ]`）触发，不会污染管道、重定向或 SSH 自动化脚本。

## 效果预览

```
  ================================================
              今 日 精 选 广 告
  ================================================

  ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
  ┃ 震惊！隔壁老王看了都说好的神秘链接 ┃
  ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

   https://example.com/shock

  [广告剩余 5 秒... 按 Ctrl+C 购买会员跳过]
```

## 安装

```bash
./install.sh            # 安装（复制文件 + 写入 bash/zsh 配置 + 强制安装 qrencode）
```

安装器会：

1. 把脚本复制到 `~/.ad_ter/`；
2. 往 `~/.bashrc` / `~/.zshrc` 追加一行 `source`；
3. 把 `~/.ad_ter` 加进 `PATH`，使 `ad-cleaner` 可直接调用；
4. 强制安装依赖：`sudo apt-get install -y qrencode`（装不上则安装中止）。

> 仅限普通用户运行，root 执行会被拒绝。
> 装完重新开终端，或 `source ~/.bashrc`（`source ~/.zshrc`）立即生效。

## 使用

```bash
ad-cleaner --buy-vip      # 扫码「支付 ¥99」开通 Linux Pro 纯净版（其实谁扫都能开）
ad-cleaner --status       # 查看当前会员状态
ad-cleaner --uninstall    # 彻底卸载
```

「开通」本质是写入标志文件 `~/.ad_ter/vip`：文件存在即视为会员，开屏广告自动跳过。

## 广告数据（ads.txt）

`~/.ad_ter/ads.txt` 每行一条，格式 `标题|URL`，空行和 `#` 开头行会被忽略：

```
屠龙宝刀，点击就送|https://example.com/dragon-blade
学 Python 到某机构，输入优惠码 LINUX 享 8 折|https://example.com/python-course
```

标题中英文皆可，统一渲染为自适应宽度的框线横幅。二维码链接在 `ad-cleaner` 顶部的 `AD_TER_VIP_URL` 里改。

## 目录结构

```
ad_ter/
├── install.sh    # 安装 / 卸载器
├── ad_ter.sh     # 开屏广告核心（被 shell source 加载）
├── ad-cleaner    # 会员系统命令（--buy-vip / --status / --uninstall）
├── ads.txt       # 广告数据
└── README.md
```

## 兼容性

- 系统：Debian / Ubuntu（仅保证这两个发行版可用）。
- Shell：bash / zsh。
- 依赖：`qrencode`（安装时通过 apt 强制安装），其余零依赖。

## 免责声明

仅供自娱自乐 / 发给**知情同意**的朋友整活用。请勿未经同意安装到他人机器，也不要用于任何真实骚扰或破坏场景；安装器已预留 `--uninstall` 逃生通道。
