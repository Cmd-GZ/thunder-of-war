#!/bin/bash
# ---------------------------------------------------------------------------
# 用户态安装中文 TeX 依赖（ctex / xeCJK / zhnumber）到 ./texmf
#
# 为什么需要这一步：
#   本机发行版提供的 TeX Live 是「partial」安装，含 xelatex 但缺中文宏包，
#   且 /usr/share 与 $HOME 均只读，无法用系统级 tlmgr 安装。
#   因此把宏包装进仓库内的 texmf/，构建时通过 TEXMFHOME 指向它。
#   texmf/ 已写入 .gitignore（体积大、可复现）。
#
# 前置条件：可访问 CTAN 镜像（默认 https://mirror.ctan.org/systems/texlive/tlnet）
# 说明：会下载约 100 MB；安装后请勿手工编辑 texmf/ 内的文件。
# ---------------------------------------------------------------------------
set -euo pipefail

cd "$(dirname "$0")/.."

REPO="${TLMIRROR:-https://mirror.ctan.org/systems/texlive/tlnet}"

if ! command -v tlmgr >/dev/null 2>&1; then
  echo "错误：未找到 tlmgr，请先安装 TeX Live。" >&2
  exit 1
fi

mkdir -p texmf
export TEXMFHOME="$PWD/texmf"

echo "==> 初始化用户态 texmf 树"
tlmgr --usermode init-usertree || true

echo "==> 从 $REPO 安装 ctex / xeCJK / zhnumber"
tlmgr --usermode --repository "$REPO" install ctex xecjk zhnumber fandol

# tlmgr 会把 base/l3kernel/tools 等「重复件」一并装进用户树，它们与系统的
# 2026 版格式文件版本不一致，会导致：
#   ! LaTeX Error: Mismatched LaTeX support files detected.
# 因此只保留中文相关目录，其余删除，让系统自带的保持一致。
echo "==> 清理与系统冲突的重复宏包"
for pkg in amsmath base firstaid graphics l3kernel latexconfig lm tools tex-ini-files; do
  rm -rf "texmf/tex/latex/$pkg"
done

echo "==> 刷新文件名数据库"
mktexlsr texmf >/dev/null 2>&1 || true

echo "==> 自检"
TEXMFHOME="$PWD/texmf" kpsewhich ctex.sty xeCJK.sty zhnumber.sty

echo "完成。现在可以运行 ./build.sh"
