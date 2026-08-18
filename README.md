# ad_ter —— 终端广告

把「广告」塞进你的 Linux 终端。

## 特性

- **开屏广告**：每次打开交互式终端，先清屏，弹出「今日精选」广告横幅 + 链接 + 倒计时。
- **命令拦截**：`ls` / `pwd` 有 30% 概率在输出末尾插一条带链接的广告。
- **Ctrl+C 跳过**：倒计时期间按 Ctrl+C 直接跳过广告，进入终端。
- **一键卸载**：`~/.ad_ter/install.sh --uninstall` 清理干净，不留痕迹。

## 效果预览

```
  ================================================
              今 日 精 选 广 告
  ================================================

  ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
  ┃ 震惊！隔壁老王看了都说好的神秘链接 ┃
  ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

   https://example.com/shock

  [广告剩余 5 秒...]
```

## 安装

```bash
./install.sh            # 安装（复制文件 + 写入 bash/zsh 配置）
```

安装器会：

1. 把脚本复制到 `~/.ad_ter/`；
2. 往 `~/.bashrc` / `~/.zshrc` 追加一行 `source`。

> 仅限普通用户运行，root 执行会被拒绝。
> 装完重新开终端，或 `source ~/.bashrc`（`source ~/.zshrc`）立即生效。

## 卸载

```bash
~/.ad_ter/install.sh --uninstall
```

## 广告数据（ads.txt）

`~/.ad_ter/ads.txt` 每行一条，格式 `标题|URL`，空行和 `#` 开头行会被忽略：

```
屠龙宝刀，点击就送|https://example.com/dragon-blade
学 Python 到某机构，输入优惠码 LINUX 享 8 折|https://example.com/python-course
```

标题中英文皆可，统一渲染为自适应宽度的框线横幅。

## 目录结构

```
ad_ter/
├── install.sh    # 安装 / 卸载器
├── ad_ter.sh     # 开屏广告核心（被 shell source 加载）
├── ads.txt       # 广告数据
└── README.md
```

## 兼容性

- 系统：主流 Linux 发行版（Debian / Ubuntu / Fedora / Arch / openSUSE / CentOS 等），已实测 Debian/Ubuntu 系。
- Shell：bash / zsh。
- 依赖：零依赖，仅用系统自带命令。

## 未来展望

说不定未来真有丧心病狂的公司往终端中塞入类似的广告呢。